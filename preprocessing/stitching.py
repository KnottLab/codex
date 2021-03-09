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

    # def find_first_tile(self):
    #     print("Finding the first tile")
    #     max_correlation = 0
    #     for tile in self._tiles[1:len(self._tiles)-1]:
    #        correlation = tile.registration_details

    def start_stitching(self, image, width):
        # Step 1: calculate neighbors for each tile
        self._tiles = self.calculate_neighbors()
        registration_transform_list = list()
        for tile in self._tiles:
            for neighbor in tile.neighbors:
                initial_corr, final_corr, xoff, yoff = self.get_registration_transform(tile.x, tile.y, neighbor[0],
                                                                                       neighbor[1], image, width)
                registration_transform = {"initial_correlation": initial_corr, "final_correlation": final_corr, "xoff": xoff, "yoff": yoff}
                registration_transform_list.append(registration_transform)

            tile.registration_details = registration_transform_list

        return self._tiles



    def get_registration_transform(self, x1, y1, x2, y2, image, width):
        """Get transform that maximizes correlation between overlaping regions."""
        tile_1 = image[x1 * width:(x1 + 1) * width, y1 * width:(y1 + 1) * width]
        tile_2 = image[x2 * width:(x2 + 1) * width, y2 * width:(y2 + 1) * width]
        overlap_tile_1 = tile_1
        overlap_tile_2 = tile_2

        # Get overlaps
        if x2 > x1:
            overlap_tile_1 = tile_1[-width:, :]
            overlap_tile_2 = tile_2[:width, :]
        elif x2 < x1:
            overlap_tile_1 = tile_1[:width, :]
            overlap_tile_2 = tile_2[-width:, :]
        elif y2 > y1:
            overlap_tile_1 = tile_1[:, -width:]
            overlap_tile_2 = tile_2[:, width:]
        elif y2 < y1:
            overlap_tile_1 = tile_1[:, width:]
            overlap_tile_2 = tile_2[:, -width:]

        xoff, yoff, xeoff, yeoff = chi2_shift(overlap_tile_1, overlap_tile_2, return_error=True, upsample_factor='auto')
        shifted_image = shift.shift2d(overlap_tile_2, -xoff, -yoff)

        initial_correlation = corr2(overlap_tile_1, overlap_tile_2)
        print("Before shifting the correlation is {0}".format(initial_correlation))

        warped_correlation = corr2(overlap_tile_1[shifted_image > 0], overlap_tile_2[shifted_image > 0])
        print("Warped correlation is {0}".format(warped_correlation))

        return initial_correlation, warped_correlation, -xoff, -yoff

    def calculate_neighbors(self):
        """Calculate neighbors using the imdilate function.
         :arg image: Image to calculate neighbors from
        """
        range_x = self.codex_object.metadata['nx']
        range_y = self.codex_object.metadata['ny']
        tiles = []
        for x in range(range_x):
            for y in range(range_y):
                neighbor_image = np.zeros(range_x, range_y)
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
