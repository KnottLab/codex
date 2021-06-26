import sys
print(sys.path)
print(__file__)

from preprocessing.stitching import Stitching
import numpy as np
import cv2
import pickle

image = np.load('/storage/tmp-incoming/shading_correction.npy')
print(image.shape)

class CodexObject:
    def __init__(self):
        self.metadata = {
            'nx': 4,
            'ny': 9,
            'tileWidth': 2048,
            'width': 205,
        }

def dumpimg(img,pth):
  img = (255*(img/img.max())).astype(np.uint8)
  cv2.imwrite(pth, img) 

codex_object = CodexObject()
stitching_object = Stitching(codex_object)

stitching_object.init_stitching(image, image_width=codex_object.metadata['tileWidth'],
                                        overlap_width=codex_object.metadata['width'])

first_tile = stitching_object.find_first_tile()
j, m, mask = stitching_object.stitch_first_tile(first_tile, image,
                                                codex_object.metadata['tileWidth'],
                                                codex_object.metadata['width'])

first_tile.stitching_index = 0
k = 1
while not np.all(mask):
    tile_1, tile_2, registration = stitching_object.find_tile_pairs(mask)
    print(tile_1)
    tile_2.x_off = registration.get('xoff') + tile_1.x_off
    tile_2.y_off = registration.get('yoff') + tile_1.y_off
    tile_2.stitching_index = k
    print(tile_2)
    j, m, mask = stitching_object.stitch_tiles(image, codex_object.metadata['tileWidth'], 
                                               codex_object.metadata['width'], j, m, mask, tile_2,
                                               tile_2.x_off, tile_2.y_off)

    # temp = j.copy()
    # div = np.quantile(temp, 0.9999)
    # temp[temp > div] = div
    # temp /= div
    # temp *= 255
    # temp = temp.astype('uint8')
    # cv2.imwrite('/storage/tmp/stitching/stitch_{0}.tif'.format(k), temp)
    k += 1