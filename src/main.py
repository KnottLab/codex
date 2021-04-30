"""Main script to perform steps"""

# Break this file atomically once we implement new steps

# Step 1: Pre-processing

from model import codex, metadata
from preprocessing import process_codex_images, xml_decoder, stitching
import pandas as pd
from pathlib import Path
import numpy as np
import pickle as pkl
import sys
import cv2
from skimage.morphology import octagon
import scipy.ndimage as ndimage
import argparse
from utilities.utility import image_as_uint8

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Codex pipeline arguments')
   
    parser.add_argument('--data_path', metavar='Data path', type=str, required=True, help='Data path to read CODEX raw data from')
    parser.add_argument('--sample_id', metavar='Sample ID', type=str, required=True, help='Sample ID for the codex data')
    parser.add_argument('--output_path', metavar='Output path', type=str, required=True, help='Output path for results')
    parser.add_argument('--region', type=int, required=True, help='Region number from the multiple regions to scan from')
    parser.add_argument('--xml_path', type=str, required=True, help='File path for XML that stores metadata')
    args = parser.parse_args()

    codex_object = codex.Codex(data_path=args.data_path, region=args.region, sample_id=args.sample_id)


    base_path = Path(codex_object.data_path + "/" + codex_object.sample_id)
    output_path = Path(args.output_path + "/" + codex_object.sample_id)
    edof_path = output_path / "edof"
    stitching_path = output_path / "stitching"
    background_path = output_path / "bg_subtraction"
    shading_correction_path = output_path / "shading_correction"
    cycle_alignment_path = output_path / "cycle_alignment"

    edof_path.mkdir(parents=True, exist_ok=True)
    stitching_path.mkdir(parents=True, exist_ok=True)
    background_path.mkdir(parents=True, exist_ok=True)
    shading_correction_path.mkdir(parents=True, exist_ok=True)
    cycle_alignment_path.mkdir(parents=True, exist_ok=True)
  

    print("Base path is: " + str(base_path))
    print("Output path is: " + str(output_path))

    cycle_folders = sorted([folder for folder in base_path.iterdir() if folder.is_dir()])
    cycle_folders = cycle_folders[1:]

    xml_file_path = args.xml_path
    if codex_object.region == 0:
        xlif_file_path = cycle_folders[0] / 'Metadata' / 'TileScan 1.xlif'
    else:
        xlif_file_path = cycle_folders[0] / 'TileScan 1' / 'Metadata' / f'Region {codex_object.region}.xlif'
        if not xlif_file_path.exists():
            xlif_file_path = cycle_folders[0] / 'TileScan 1' / 'Metadata' / f'Position {codex_object.region}.xlif'

    print("XLIF file path is: " + str(xlif_file_path))
    print("XML file path is: " + str(xml_file_path))

    with open(xml_file_path, 'r') as f, open(xlif_file_path, 'r') as g:
        xml_content = f.read()
        xlif_content = g.read()

    codex_metadata = metadata.Metadata(file_content=[xml_content, xlif_content], decoder=xml_decoder.XMLDecoder())

    metadata_dict = codex_metadata.decode_metadata(cycle_folders=cycle_folders)

    print("Codex metadata is: " + str(metadata_dict))

    codex_object.metadata = metadata_dict

    codex_object.cycle_alignment_info = []
    codex_object.background_1 = []
    codex_object.background_2 = []

    process_codex = process_codex_images.ProcessCodex(codex_object=codex_object)
    stitching_object = stitching.Stitching(codex_object)

    image_ref = None
    first_tile = None
    cycle_range = [0, codex_object.metadata['ncl'] - 1] + list(range(1, codex_object.metadata['ncl'] - 1))
    print("Cycle range is: " + str(cycle_range))

    for channel in range(codex_object.metadata['nch']):
        for cycle, cycle_index in zip(cycle_range, range(codex_object.metadata['ncl'])):
            image = process_codex.apply_edof(cycle, channel)
            print("EDOF done. Saving file.")
            # image = np.load('edof.npy')
            
            cv2.imwrite(str(edof_path) + "/" + "edof_{0}_{1}.tif".format(cycle, channel), image)

            print("Shading correction reached")

            image = process_codex.shading_correction(image, cycle, channel)
            cv2.imwrite(str(shading_correction_path) + "/" + "shading_correction_{0}_{1}.tif".format(cycle, channel), image)
            # image = np.load('shading_correction.npy')
            # print("Image shape is {0}".format(image.shape))

            if channel == 0 and cycle == 0:
                image_ref = image
            elif cycle > 0 and channel == 0:
                cycle_alignment_info, image = process_codex.cycle_alignment_get_transform(image_ref, image)
                codex_object.cycle_alignment_info.append(cycle_alignment_info)
            else:
                image = process_codex.cycle_alignment_apply_transform(image_ref, image,
                                                                      codex_object.cycle_alignment_info[
                                                                          cycle_index - 1])
                cv2.imwrite(str(cycle_alignment_path) + "/" + "cycle_alignment_{0}_{1}.tif".format(cycle, channel), image)

            if channel > 0:
                if cycle == 0:
                    codex_object.background_1.append(image)
                elif cycle == codex_object.metadata['ncl'] - 1:
                    codex_object.background_2.append(image)
                else:
                    image = process_codex.background_subtraction(image, codex_object.background_1[channel - 1],
                                                                 codex_object.background_2[channel - 1], cycle, channel)

                    print("Background subtraction done")
                    cv2.imwrite(str(background_path) + '/' + 'background_subtraction_{0}_{1}.tif'.format(cycle, channel), image)
                 

            print("Stitching started")
            if channel == 0 and cycle == 0:
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
                    k += 1

                # Correct corners
                dilated_m = cv2.dilate(m, octagon(1, 1), iterations=1)
                m = ((dilated_m - m) > 0).astype('uint8')
                m = cv2.dilate(m, octagon(1, 2), iterations=1)
                jf = ndimage.uniform_filter(j, size=5, mode='constant')
                j[m > 0] = jf[m > 0]
                j = image_as_uint8(j)
                cv2.imwrite(str(stitching_path) + '/' + 'stitch_{0}_{1}.tif'.format(cycle, channel), j)
            else:
                tiles = stitching_object.tiles.flatten().tolist()
                print(tiles)
                tiles.sort(key=lambda t:t.stitching_index)
                j, m, mask = stitching_object.stitch_first_tile(tiles[0], image, codex_object.metadata['tileWidth'], codex_object.metadata['width'])
                for tile in tiles[1:]:
                    print("Stitching index of tile is {0}".format(tile.stitching_index))
                    j, m, mask = stitching_object.stitch_tiles(image, codex_object.metadata['tileWidth'], codex_object.metadata['width'], j, m, 
                                                               None, tile, tile.x_off, tile.y_off)
                    j = image_as_uint8(j)    
                    cv2.imwrite(str(stitching_path) + '/' + 'stitch_{0}_{1}.tif'.format(cycle, channel), j)
