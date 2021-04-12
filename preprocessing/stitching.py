"""Class for stitching algorithm"""
import numpy as np
import cv2
from skimage.morphology import octagon
from model.tile import Tile
from image_registration import chi2_shift
from image_registration.fft_tools import shift
from utilities.utility import corr2


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
        self._tiles = []

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
                     self.codex_object.metadata['ny'] * (image_width - overlap_width) + overlap_width))
        m = np.zeros((self.codex_object.metadata['nx'] * (image_width - overlap_width) + overlap_width,
                     self.codex_object.metadata['ny'] * (image_width - overlap_width) + overlap_width))
        j[first_tile.x * (image_width - overlap_width):(first_tile.x + 1) * (image_width - overlap_width) + overlap_width,
        first_tile.y * (image_width - overlap_width): (first_tile.y + 1) * (
                    image_width - overlap_width) + overlap_width] = image_subset

        m[first_tile.x * (image_width - overlap_width): (first_tile.x + 1) * (image_width - overlap_width) + overlap_width,
        first_tile.y * (image_width - overlap_width): (first_tile.y + 1) * (
                    image_width - overlap_width) + overlap_width] = np.ones(image_subset.shape)

        mask = np.zeros((self.codex_object.metadata['nx'], self.codex_object.metadata['ny']))
        mask[first_tile.x, first_tile.y] = 1

        return j, m, mask

    def find_first_tile(self):
        print("Finding the first tile")
        max_correlation = 0
        first_tile = self._tiles[0]
        for tile in self._tiles[1:len(self._tiles) - 1]:
            correlation_list = []
            for registration in tile.registration_details:
                correlation = registration.get('final_correlation')
                correlation_list.append(correlation)
            avg_correlation = np.mean(correlation_list)
            if avg_correlation > max_correlation:
                max_correlation = avg_correlation
                first_tile = tile

        return first_tile

    def stitch_tiles(self, image, image_width, overlap_width, j, mask, tile_2, x_off, y_off):
        x_2, y_2 = tile_2.x, tile_2.y
        image_subset = image[x_2*image_width : (x_2 + 1) * image_width, y_2 * image_width : (y_2 + 1) * image_width]
        # this line is different from matlab, the matlab code uses imref2d to define co-ordinates
        warped_image = shift.shift2d(image_subset, -x_off, -y_off)
        dx = list(range(x_2 * (image_width - overlap_width), (x_2 + 1) * (image_width - overlap_width) + overlap_width))
        dx = [x + x_off for x in dx]
        dy = list(range(y_2 * (image_width - overlap_width), (y_2 + 1) * (image_width - overlap_width) + overlap_width))
        dy = [y + y_off for y in dy]
        if max(dx) > j.shape[0]:
            j = np.concatenate((j, np.zeros((max(dx) - j.shape[0], j.shape[1]))))
        if max(dy) > j.shape[1]:
            j = np.concatenate((j, np.zeros((j.shape[0], max(dy) - j.shape[1]))), 1)

        j[dx, dy] = j[dx, dy] + warped_image.astype('uint16') * (j[dx, dy] == 0).astype('uint16')
        if mask:
            mask[x_2, y_2] = 1

        return j, mask

    def find_tile_pairs(self, mask):
        tile_indices = np.argwhere(mask > 0)
        max_correlation = 0
        registration = None
        tile_1, tile_2 = None, None
        for index in tile_indices:
            x, y = index
            temp_tile_1 = self._tiles[x + y * self.codex_object.metadata['ny']]
            neighbor_indices = temp_tile_1.neighbors
            registration_details = temp_tile_1.registration_details
            for i, neighbor in enumerate(neighbor_indices):
                x_n, y_n = neighbor
                temp_tile_2 = self._tiles[x_n + y_n * self.codex_object.metadata['ny']]
                registration = registration_details[i]
                correlation = registration.get('final_correlation')
                if correlation > max_correlation and mask[x, y] == 1 and mask[x_n, y_n] == 0:
                    max_correlation = correlation
                    tile_1 = temp_tile_1
                    tile_2 = temp_tile_2
        return tile_1, tile_2, registration

    def init_stitching(self, image, image_width, overlap_width):
        # Step 1: calculate neighbors for each tile
        self._tiles = self.calculate_neighbors()
        for tile in self._tiles:
            registration_transform_list = list()
            for neighbor in tile.neighbors:
                initial_corr, final_corr, xoff, yoff = self.get_registration_transform(tile.x, tile.y, neighbor[0],
                                                                                       neighbor[1], image, image_width,
                                                                                       overlap_width)
                registration_transform = {"initial_correlation": initial_corr, "final_correlation": final_corr,
                                          "xoff": xoff, "yoff": yoff}
                registration_transform_list.append(registration_transform)

            tile.registration_details = registration_transform_list

        return self._tiles

    def get_registration_transform(self, x1, y1, x2, y2, image, image_width, overlap_width):
        """Get transform that maximizes correlation between overlaping regions."""
        tile_1 = image[x1 * image_width:(x1 + 1) * image_width, y1 * image_width:(y1 + 1) * image_width]
        tile_2 = image[x2 * image_width:(x2 + 1) * image_width, y2 * image_width:(y2 + 1) * image_width]
        overlap_tile_1 = tile_1
        overlap_tile_2 = tile_2

        print(tile_1.shape, tile_2.shape)

        # Get overlaps
        if x2 > x1:
            overlap_tile_1 = tile_1[image_width - overlap_width:, :]
            overlap_tile_2 = tile_2[:overlap_width, :]
        elif x2 < x1:
            overlap_tile_1 = tile_1[:overlap_width, :]
            overlap_tile_2 = tile_2[image_width - overlap_width:, :]
        elif y2 > y1:
            overlap_tile_1 = tile_1[:, image_width - overlap_width:]
            overlap_tile_2 = tile_2[:, :overlap_width]
        elif y2 < y1:
            overlap_tile_1 = tile_1[:, :overlap_width]
            overlap_tile_2 = tile_2[:, image_width - overlap_width:]

        print(overlap_tile_1.shape, overlap_tile_2.shape)
        initial_correlation = corr2(overlap_tile_1, overlap_tile_2)
        xoff, yoff, xeoff, yeoff = chi2_shift(overlap_tile_1, overlap_tile_2, return_error=True, upsample_factor='auto')
        shifted_image = shift.shift2d(overlap_tile_2, -xoff, -yoff)

        print("Before shifting the correlation is {0}".format(initial_correlation))

        warped_correlation = corr2(overlap_tile_1[shifted_image > 0], shifted_image[shifted_image > 0])
        print("Warped correlation is {0}".format(warped_correlation))

        return initial_correlation, warped_correlation, xoff, yoff

    def calculate_neighbors(self):
        """Calculate neighbors using the imdilate function.
         :arg image: Image to calculate neighbors from
        """
        range_x = self.codex_object.metadata['nx']
        range_y = self.codex_object.metadata['ny']
        tiles = []
        for x in range(range_x):
            for y in range(range_y):

                if self.codex_object.metadata['real_tiles'][x,y] == 'x':
                    continue

                neighbor_image = np.zeros((range_x, range_y))
                neighbor_image[x, y] = 1
                print("Neighbor image is: " + str(neighbor_image))
                kernel = octagon(1, 1)
                dilated_image = cv2.dilate(neighbor_image, kernel, iterations=1)
                dilated_image = dilated_image - neighbor_image
                print("Dilated image is: " + str(dilated_image))
                neighbor_indices = np.argwhere(dilated_image == 1)
                print("Neighbor indices are: " + str(neighbor_indices))
                tile = Tile(x, y)
                tile.neighbors = neighbor_indices
                tiles.append(tile)

        return tiles
