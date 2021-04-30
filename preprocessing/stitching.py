"""Class for stitching algorithm"""
import numpy as np
import cv2
from skimage.morphology import octagon
from model.tile import Tile
from image_registration import chi2_shift
from image_registration.fft_tools import shift
from utilities.utility import corr2
import ray


def dumpimg(pth,img):
  img = (255*(img/np.max(img.ravel()))).astype(np.uint8)
  cv2.imwrite(pth, img) 



class Stitching:
    """Stitching algorithm for microscopic images. It consists of the following steps:

    1. Calculate neighbors using `imdilate` of opencv.
    2. For each neigbor, calculate registration transform using astropy(overlap).
    3. Look into the details of the actual stitching.

    """

    def __init__(self, codex_object):
        """
        :param codex_object: CODEX object
        """
        self.codex_object = codex_object
        self.nx = self.codex_object.metadata['nx']
        self.ny = self.codex_object.metadata['ny']
        self._tiles = np.zeros((self.nx, self.ny), dtype='object')

    @property
    def tiles(self):
        return self._tiles

    @tiles.setter
    def tiles(self, value):
        self._tiles = value

    @tiles.deleter
    def tiles(self):
        del self._tiles

    def stitch_first_tile(self, first_tile, image, image_width, overlap_width):
        image_subset = image[first_tile.x * image_width:(first_tile.x + 1) * image_width,
                       first_tile.y * image_width:(first_tile.y + 1) * image_width]
        j = np.zeros((self.codex_object.metadata['nx'] * (image_width - overlap_width) + overlap_width,
                     self.codex_object.metadata['ny'] * (image_width - overlap_width) + overlap_width), dtype=np.uint16)
        m = np.zeros((self.codex_object.metadata['nx'] * (image_width - overlap_width) + overlap_width,
                     self.codex_object.metadata['ny'] * (image_width - overlap_width) + overlap_width))
        j[first_tile.x * (image_width - overlap_width):(first_tile.x + 1) * (image_width - overlap_width) + overlap_width,
          first_tile.y * (image_width - overlap_width): (first_tile.y + 1) * (image_width - overlap_width) + overlap_width] = image_subset + 1

        m[first_tile.x * (image_width - overlap_width): (first_tile.x + 1) * (image_width - overlap_width) + overlap_width,
          first_tile.y * (image_width - overlap_width): (first_tile.y + 1) * (
                    image_width - overlap_width) + overlap_width] = np.ones(image_subset.shape)

        mask = np.zeros((self.codex_object.metadata['nx'], self.codex_object.metadata['ny']))
        mask[first_tile.x, first_tile.y] = 1

        return j, m, mask

    def find_first_tile(self):
        print("Finding the first tile")
        max_correlation = 0
        first_tile = self._tiles.ravel()[0]
        for tile in self._tiles.ravel()[1:len(self._tiles) - 1]:
            if not isinstance(tile, Tile):
              continue
            correlation_list = []
            for other_tile_id, registration in tile.registration_details.items():
                correlation = registration.get('final_correlation')
                correlation_list.append(correlation)
            avg_correlation = np.mean(correlation_list)
            if avg_correlation > max_correlation:
                max_correlation = avg_correlation
                first_tile = tile

        return first_tile

    def stitch_tiles(self, image, image_width, overlap_width, j, m, mask, tile_2, x_off, y_off):
        x_2, y_2 = tile_2.x, tile_2.y
        image_subset = image[x_2*image_width : (x_2 + 1) * image_width, y_2 * image_width : (y_2 + 1) * image_width]
        print("x_off= {0:2.3f} y_off= {1:2.3f}".format(x_off, y_off))

        x_start = x_2 * (image_width - overlap_width) + int(np.ceil(x_off))
        x_end = min(x_start + image_width, j.shape[0])
        y_start = y_2 * (image_width - overlap_width) + int(np.ceil(y_off))
        y_end = min(y_start + image_width, j.shape[1])

        x_start = max(0, x_start)
        y_start = max(0, y_start)
        dx = x_end - x_start
        dy = y_end - y_start

        print("X_start and X_end are {0} and {1}".format(x_start, x_end))
        print("Y_start and Y_end are {0} and {1}".format(y_start, y_end))

        ## Debugging images -- keep this around and allow a user to turn it on with a --debug flag later
        # j2 = j.copy()
        # jmax = np.max(j2.ravel())
        # j2[x_start:x_start+10, y_start:y_end] = jmax
        # j2[x_start:x_end, y_start:y_start + 10] = jmax
        # j2[x_end - 10:x_end, y_start:y_end] = jmax
        # j2[x_start:x_end, y_end - 10 : y_end] = jmax

        # dumpimg('/storage/tmp/stitching/s/1_j.png', j2)
        # dumpimg('/storage/tmp/stitching/s/2_img.png', image_subset)
        
        # jtmp = np.zeros_like(j) 
        # jtmp[x_start:x_end, y_start:y_end] = image_subset[:dx, :dy].astype('uint16')
        # jstack = np.dstack([j, jtmp, np.zeros_like(j)])
        # dumpimg('/storage/tmp/stitching/s/4_j.png', jstack[:,:,::-1])

        # j[x_start:x_end, y_start:y_end] += warped_image.astype('uint16') * (j[x_start:x_end, y_start:y_end] == 0).astype('uint16')
        # m[x_start:x_end, y_start:y_end] += (warped_image > 0).astype('uint8')

        j[x_start:x_end, y_start:y_end] += image_subset[:dx,:dy].astype('uint16') * (j[x_start:x_end, y_start:y_end] == 0).astype('uint16')
        m[x_start:x_end, y_start:y_end] = 1
        if mask is not None:
           mask[x_2, y_2] = 1

        return j, m, mask


    def find_tile_pairs(self, mask):
        tile_indices = np.argwhere(mask > 0)
        max_correlation = 0
        tile_1, tile_2 = None, None
        for index in tile_indices:
            x, y = index
            print("Finding tile pairs for index {0} and {1}".format(x, y))
            # temp_tile_1 = self._tiles[y + x * self.codex_object.metadata['ny']]
            temp_tile_1 = self._tiles[x,y]
            neighbor_indices = temp_tile_1.neighbors
            # registration_details = temp_tile_1.registration_details
            for i, neighbor in enumerate(neighbor_indices):
                x_n, y_n = neighbor
                #temp_tile_2 = self._tiles[y_n + x_n * self.codex_object.metadata['ny']]
                temp_tile_2 = self._tiles[x_n, y_n]
                registration = temp_tile_2.registration_details[(x,y)]
                correlation = registration.get('final_correlation')
                if correlation > max_correlation and mask[x, y] == 1 and mask[x_n, y_n] == 0:
                    max_correlation = correlation
                    tile_1 = temp_tile_1
                    tile_2 = temp_tile_2

        registration = tile_2.registration_details[(tile_1.x,tile_1.y)]
        return tile_1, tile_2, registration


    def init_stitching(self, image_shared, image_width, overlap_width):
        # Step 1: calculate neighbors for each tile
        self.calculate_neighbors()
        futures = []
        for tile in self._tiles.ravel():
            if not isinstance(tile, Tile):
              continue
            registration_transform_dict = {}
            for neighbor in tile.neighbors:
                fn = get_registration_transform.remote(tile.x, tile.y, neighbor[0],
                                                       neighbor[1], image_shared, image_width,
                                                       overlap_width)
                futures.append(fn)

        reg_info = ray.get(futures)
        i = 0
        for tile in self._tiles.ravel():
            if not isinstance(tile, Tile):
              continue
            registration_transform_dict = {}
            for neighbor in tile.neighbors:
                initial_corr, final_corr, xoff, yoff = reg_info[i]
                i += 1
                registration_transform = {"initial_correlation": initial_corr, "final_correlation": final_corr,
                                          "xoff": xoff, "yoff": yoff}
                registration_transform_dict[(neighbor[0], neighbor[1])] = registration_transform

            tile.registration_details = registration_transform_dict


    #@ray.remote
    #def get_registration_transform(self, x1, y1, x2, y2, image, image_width, overlap_width):
    #    """Get transform that maximizes correlation between overlaping regions."""
    #    tile_1 = image[x1 * image_width:(x1 + 1) * image_width, y1 * image_width:(y1 + 1) * image_width]
    #    tile_2 = image[x2 * image_width:(x2 + 1) * image_width, y2 * image_width:(y2 + 1) * image_width]
    #    overlap_tile_1 = tile_1
    #    overlap_tile_2 = tile_2

    #    # Get overlaps
    #    if x2 > x1: # tile1 below tile2
    #        overlap_tile_1 = tile_1[image_width - overlap_width:, :]
    #        overlap_tile_2 = tile_2[:overlap_width, :]
    #        overlapping_edge = 'top'
    #    elif x2 < x1: # tile1 above tile2
    #        overlap_tile_1 = tile_1[:overlap_width, :]
    #        overlap_tile_2 = tile_2[image_width - overlap_width:, :]
    #        overlapping_edge = 'bottom'
    #    elif y2 > y1: # tile1 left of tile2
    #        overlap_tile_1 = tile_1[:, image_width - overlap_width:]
    #        overlap_tile_2 = tile_2[:, :overlap_width]
    #        overlapping_edge = 'left'
    #    elif y2 < y1: # tile1 right of tile2
    #        overlap_tile_1 = tile_1[:, :overlap_width]
    #        overlap_tile_2 = tile_2[:, image_width - overlap_width:]
    #        overlapping_edge = 'right'

    #    print(f'registering tile2 ({x2},{y2}) to tile1 ({x1},{y1}) on the {overlapping_edge} edge')


    #    initial_correlation = corr2(overlap_tile_1, overlap_tile_2)
    #    xoff, yoff, xeoff, yeoff = chi2_shift(overlap_tile_1, overlap_tile_2, return_error=True, upsample_factor='auto')
    #    shifted_image = shift.shift2d(overlap_tile_2, -xoff, -yoff)

    #    warped_correlation = corr2(overlap_tile_1[shifted_image > 0], shifted_image[shifted_image > 0])

    #    # For some reason when tiles are stacked vertically, xoff and yoff need to swap
    #    if overlapping_edge in ['top', 'bottom']:   # tile1 below tile2
    #        xoff, yoff = yoff, xoff
    #    
    #    return initial_correlation, warped_correlation, xoff, yoff


    def calculate_neighbors(self):
        """Calculate neighbors using the imdilate function. """

        for x in range(self.nx):
            for y in range(self.ny):
                if self.codex_object.metadata['real_tiles'][x, y] == 'x':
                    continue

                neighbor_image = np.zeros((self.nx, self.ny))
                neighbor_image[x, y] = 1
                kernel = octagon(1, 1)
                dilated_image = cv2.dilate(neighbor_image, kernel, iterations=1)
                dilated_image = dilated_image - neighbor_image
                dilated_image[self.codex_object.metadata['real_tiles']=='x'] = 0
                neighbor_indices = np.argwhere(dilated_image == 1)
                tile = Tile(x, y)
                tile.neighbors = neighbor_indices
                self.tiles[x,y] = tile

@ray.remote
def get_registration_transform(x1, y1, x2, y2, image, image_width, overlap_width):
    """Get transform that maximizes correlation between overlaping regions."""
    tile_1 = image[x1 * image_width:(x1 + 1) * image_width, y1 * image_width:(y1 + 1) * image_width]
    tile_2 = image[x2 * image_width:(x2 + 1) * image_width, y2 * image_width:(y2 + 1) * image_width]
    overlap_tile_1 = tile_1
    overlap_tile_2 = tile_2

    # Get overlaps
    if x2 > x1: # tile1 below tile2
        overlap_tile_1 = tile_1[image_width - overlap_width:, :]
        overlap_tile_2 = tile_2[:overlap_width, :]
        overlapping_edge = 'top'
    elif x2 < x1: # tile1 above tile2
        overlap_tile_1 = tile_1[:overlap_width, :]
        overlap_tile_2 = tile_2[image_width - overlap_width:, :]
        overlapping_edge = 'bottom'
    elif y2 > y1: # tile1 left of tile2
        overlap_tile_1 = tile_1[:, image_width - overlap_width:]
        overlap_tile_2 = tile_2[:, :overlap_width]
        overlapping_edge = 'left'
    elif y2 < y1: # tile1 right of tile2
        overlap_tile_1 = tile_1[:, :overlap_width]
        overlap_tile_2 = tile_2[:, image_width - overlap_width:]
        overlapping_edge = 'right'

    print(f'registering tile2 ({x2},{y2}) to tile1 ({x1},{y1}) on the {overlapping_edge} edge')


    initial_correlation = corr2(overlap_tile_1, overlap_tile_2)
    xoff, yoff, xeoff, yeoff = chi2_shift(overlap_tile_1, overlap_tile_2, return_error=True, upsample_factor='auto')
    shifted_image = shift.shift2d(overlap_tile_2, -xoff, -yoff)

    warped_correlation = corr2(overlap_tile_1[shifted_image > 0], shifted_image[shifted_image > 0])

    # For some reason when tiles are stacked vertically, xoff and yoff need to swap
    if overlapping_edge in ['top', 'bottom']:   # tile1 below tile2
        xoff, yoff = yoff, xoff
    
    return initial_correlation, warped_correlation, xoff, yoff
