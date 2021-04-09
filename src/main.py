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

if __name__ == '__main__':

    dataset_metadata = pd.read_csv(filepath_or_buffer='../utilities/CODEX_dataset_metadata.csv')

    print(dataset_metadata)

    codex_object = codex.Codex(dataset=dataset_metadata, index=31)

    print(codex_object)

    base_path = Path(codex_object.data_path + "/" + codex_object.sample_id)

    print("Base path is: " + str(base_path))

    cycle_folders = sorted([folder for folder in base_path.iterdir() if folder.is_dir()])
    cycle_folders = cycle_folders[1:]

    xml_file_path = list(base_path.glob('*.xml'))
    xlif_file_path = cycle_folders[0] / 'Metadata' / 'TileScan 1.xlif'

    print("XLIF file path is: " + str(xlif_file_path))
    print("XML file path is: " + str(xml_file_path))

    with open(xml_file_path[0], 'r') as f, open(xlif_file_path, 'r') as g:
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
    cycle_range = [0]
    print("Cycle range is: " + str(cycle_range))

    for channel in range(1):
        for cycle, cycle_index in zip(cycle_range, range(codex_object.metadata['ncl'])):
            # image = process_codex.apply_edof(cycle, channel)
            print("EDOF done. Saving file.")
            image = np.load('edof.npy')
            # np.save(file='edof.npy', arr=image)

            print("Shading correction reached")

            # image = process_codex.shading_correction(image, cycle, channel)
            # np.save(file='shading_correction.npy', arr=image)
            image = np.load('shading_correction.npy')

            if channel == 0 and cycle == 0:
                image_ref = image
            elif cycle > 0 and channel == 0:
                cycle_alignment_info, image = process_codex.cycle_alignment_get_transform(image_ref, image)
                codex_object.cycle_alignment_info.append(cycle_alignment_info)
            else:
                image = process_codex.cycle_alignment_apply_transform(image_ref, image,
                                                                      codex_object.cycle_alignment_info[
                                                                          cycle_index - 1])

            if channel > 0:
                if cycle == 0:
                    codex_object.background_1.append(image)
                elif cycle == codex_object.metadata['ncl'] - 1:
                    codex_object.background_2.append(image)
                else:
                    image = process_codex.background_subtraction(image, codex_object.background_1[channel - 1],
                                                                 codex_object.background_2[channel - 1], cycle, channel)

                    print("Background subtraction done")
                    np.save("background_subtraction_{0}.npy".format(
                        codex_object.metadata['marker_names_array'][cycle][channel]), image)

            print("Stitching started")
            if channel == 0 and cycle == 0:
                tiles = stitching_object.init_stitching(image, image_width=codex_object.metadata['tileWidth'],
                                                        overlap_width=codex_object.metadata['width'])
                with open("tiles.pkl", "wb") as f:
                    pkl.dump(tiles, f)
                first_tile = stitching_object.find_first_tile()
                j, m, mask = stitching_object.stitch_first_tile(first_tile, image,
                                                                codex_object.metadata['tileWidth'],
                                                                codex_object.metadata['width'])
                k = 0
                while not np.all(mask):
                    tile_1, tile_2, registration = stitching_object.find_tile_pairs(mask)
                    tile_2.x_off = registration.get('xoff') + tile_1.x_off
                    tile_2.y_off = registration.get('yoff') + tile_1.y_off
                    tile_1.stitching_index = k
                    k += 1
                    tile_2.stitching_index = k
                    j, mask = stitching_object.stitch_tiles(image, codex_object.metadata['tileWidth'], codex_object.metadata['width'], j, mask, tile_2,
                                                            tile_2.x_off, tile_2.y_off)
            else:
                tiles = stitching_object.tiles
                tiles.sort(key=lambda t:t.stitching_index)
                print('Tiles array is {0}'.format(tiles))
                for tile in tiles:
                    j, mask = stitching_object.stitch_tiles(image, codex_object.metadata['tileWidth'], codex_object.metadata['width'], j, None, tile, tile.x_off, tile.y_off)

            print("Stitching done")
            with open("stitch.pkl", "wb") as f:
                pkl.dump(j, f, -1)
            print("Stitching file saved")
