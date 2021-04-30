"""Main script to perform steps"""

# Break this file atomically once we implement new steps

# Step 1: Pre-processing

from model import codex, metadata
from model.tile import Tile
from preprocessing import process_codex_images, xml_decoder, stitching
import pandas as pd
from pathlib import Path
import numpy as np
import pickle as pkl
import ray
import sys
import cv2
import os
from skimage.morphology import octagon
import scipy.ndimage as ndimage
import argparse



if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Codex pipeline arguments')
   
    parser.add_argument('--data_path', metavar='Data path', type=str, required=True, help='Data path to read CODEX raw data from')
    parser.add_argument('--sample_id', metavar='Sample ID', type=str, required=True, help='Sample ID for the codex data')
    parser.add_argument('--output_path', metavar='Output path', type=str, required=True, help='Output path for results')
    parser.add_argument('--xml_path', metavar='XML file path', type=str, required=True, help='Experiment XML information')
    parser.add_argument('--region', type=int, required=True, help='Region number from the multiple regions to scan from')
    parser.add_argument('-j', type=int, default=1, required=False, help='Number of CPUs to use')
    args = parser.parse_args()

    codex_object = codex.Codex(data_path=args.data_path, region=args.region, sample_id=args.sample_id)


    edofdir = f'{args.output_path}/0_edof'
    shadingdir = f'{args.output_path}/1_shading_correction'
    cycledir = f'{args.output_path}/2_cycle_alignment'
    backgrounddir = f'{args.output_path}/3_background_subtract'
    stitchingdir = f'{args.output_path}/4_stitching'

    os.makedirs(args.output_path, exist_ok=True)
    os.makedirs(edofdir, exist_ok=True)
    os.makedirs(shadingdir, exist_ok=True)
    os.makedirs(cycledir, exist_ok=True)
    os.makedirs(backgrounddir, exist_ok=True)
    os.makedirs(stitchingdir, exist_ok=True)


    base_path = Path(codex_object.data_path + "/" + codex_object.sample_id)
    print("Base path is: " + str(base_path))

    cycle_folders = sorted([folder for folder in base_path.iterdir() if folder.is_dir()])
    cycle_folders = cycle_folders[1:]

    #xml_file_path = list(base_path.glob('*.xml'))
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
    j = None
    cycle_range = [0, codex_object.metadata['ncl'] - 1] + list(range(1, codex_object.metadata['ncl'] - 1))
    print("Cycle range is: " + str(cycle_range))

    print("Setting up Ray")
    ray.init(num_cpus=args.j, logging_level="ERROR")

    for channel in range(codex_object.metadata['nch']):
        for cycle, cycle_index in zip(cycle_range, range(codex_object.metadata['ncl'])):
            image = process_codex.apply_edof(cycle, channel)

            edofpath = f'{edofdir}/{args.sample_id}_reg{args.region:02d}_cycle{cycle:02d}_channel{channel:02d}_{codex_object.metadata["marker_array"][cycle][channel]}.tif'
            print(f"EDOF done. Saving file. --> {edofpath}")
            cv2.imwrite(edofpath, image)


            print("Shading correction reached")
            image = process_codex.shading_correction(image, cycle, channel)
            shadingpath = f'{shadingdir}/{args.sample_id}_reg{args.region:02d}_cycle{cycle:02d}_channel{channel:02d}_{codex_object.metadata["marker_array"][cycle][channel]}.tif'
            print(f"shading correction done. Saving file. --> {shadingpath}")
            cv2.imwrite(shadingpath, image)

            if channel == 0 and cycle == 0:
                print("Reference DAPI image does not need cycle alignment. Stashing image for cycle reference.")
                image_ref = image.copy()
            elif cycle > 0 and channel == 0:
                cycle_alignment_info = process_codex.cycle_alignment_get_transform(image_ref, image)
                codex_object.cycle_alignment_info.append(cycle_alignment_info)
                image = process_codex.cycle_alignment_apply_transform(image_ref, image, cycle_alignment_info)
            else:
                image = process_codex.cycle_alignment_apply_transform(image_ref, image, codex_object.cycle_alignment_info[cycle_index - 1])

            cyclepath = f'{cycledir}/{args.sample_id}_reg{args.region:02d}_cycle{cycle:02d}_channel{channel:02d}_{codex_object.metadata["marker_array"][cycle][channel]}.tif'
            print(f"cycle alignment done. Saving file. --> {cyclepath}")
            cv2.imwrite(cyclepath, image)

            if channel > 0:
                if cycle == 0:
                    codex_object.background_1.append(image)
                elif cycle == codex_object.metadata['ncl'] - 1:
                    codex_object.background_2.append(image)
                else:
                    image = process_codex.background_subtraction(image, codex_object.background_1[channel - 1],
                                                                 codex_object.background_2[channel - 1], cycle, channel)

                    backgroundpath = f'{backgrounddir}/{args.sample_id}_reg{args.region:02d}_cycle{cycle:02d}_channel{channel:02d}_{codex_object.metadata["marker_array"][cycle][channel]}.tif'
                    print(f"Background subtraction done. Saving file. --> {backgroundpath}")
                    cv2.imwrite(backgroundpath, image)

            print("Stitching started")
            if channel == 0 and cycle == 0:
                image_shared = ray.put(image)
                stitching_object.init_stitching(image_shared, image_width=codex_object.metadata['tileWidth'],
                                                overlap_width=codex_object.metadata['width'])
                first_tile = stitching_object.find_first_tile()
                j, m, mask = stitching_object.stitch_first_tile(first_tile, image,
                                                                codex_object.metadata['tileWidth'],
                                                                codex_object.metadata['width'])
                
                del image_shared
                print('First tiles placed. placing the rest of the tiles')
                first_tile.stitching_index = 0
                k = 0
                while np.sum(mask) < np.sum(codex_object.metadata['real_tiles']!='x'):
                    tile_1, tile_2, registration = stitching_object.find_tile_pairs(mask)
                    tile_2.x_off = registration.get('xoff') + tile_1.x_off
                    tile_2.y_off = registration.get('yoff') + tile_1.y_off
                    tile_2.stitching_index = k
                    j, m, mask = stitching_object.stitch_tiles(image, codex_object.metadata['tileWidth'], 
                                                               codex_object.metadata['width'], j, m, mask, tile_2,
                                                               tile_2.x_off, tile_2.y_off)
                    k += 1

                ## Correct corners
                #dilated_m = cv2.dilate(m, octagon(1, 1), iterations=1)
                #m = ((dilated_m - m) > 0).astype('uint8')
                #m = cv2.dilate(m, octagon(1, 2), iterations=1)
                #jf = ndimage.uniform_filter(j, size=5, mode='constant')
                #j[m > 0] = jf[m > 0]

            else:
                tiles = stitching_object.tiles.flatten()
                tile_perm = np.argsort([t.stitching_index if isinstance(t, Tile) else 999 for t in tiles])
                #tiles.sort(key=lambda t:t.stitching_index)
                for tile in tiles[tile_perm]:
                    if not isinstance(tile, Tile):
                        continue
                    j, m, mask = stitching_object.stitch_tiles(image, codex_object.metadata['tileWidth'], 
                                                               codex_object.metadata['width'], j, m, None, tile, 
                                                               tile.x_off, tile.y_off)

            stitchingpath = f'{stitchingdir}/{args.sample_id}_reg{args.region:02d}_cycle{cycle:02d}_channel{channel:02d}_{codex_object.metadata["marker_array"][cycle][channel]}.tif'
            print(f"Stitching done. Saving file. --> {stitchingpath}")
            cv2.imwrite(stitchingpath, j)

