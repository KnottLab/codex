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

alphabet = list('abcdefghijklmnopqrstuvwxyz1234567890')


def img2uint8(img):
    s = np.quantile(img.ravel(), 0.9999)
    img_uint = img.copy().astype(np.float16)
    img_uint[img_uint > s] = s
    img_uint = img_uint / s
    img_uint = (img_uint * 255).astype(np.uint8) # convert to uint8 does rounding for us
    return img_uint


def stack_shading_input(image, codex_object):
    image_stack = []
    dtype_max = np.iinfo(np.uint16).max
    width = codex_object.metadata['tileWidth']
    for x in range(codex_object.metadata['nx']):
        for y in range(codex_object.metadata['ny']):
            if codex_object.metadata['real_tiles'][x,y]=='x':
                continue
            image_subset = image[x * width : (x + 1) * width, y * width : (y + 1) * width].copy()
            image_subset = image_subset / dtype_max

            image_stack.append(image_subset.copy())
    return np.dstack(image_stack)


def parse_leica_1(base_path, xml_file_path, region):
    cycle_folders = sorted([folder for folder in base_path.iterdir() if folder.is_dir()])
    print("")
    # cycle folders also end in a number
    cycle_folders = cycle_folders[1:]
    cycle_folders = [folder for folder in cycle_folders if folder.name[-1].isdigit()]

    xml_file_path = args.xml_path
    if region == 0:
        xlif_file_path = cycle_folders[0] / 'Metadata' / 'TileScan 1.xlif'
    else:
        xlif_file_path = cycle_folders[0] / 'TileScan 1' / 'Metadata' / f'Region {region}.xlif'
        if not xlif_file_path.exists():
            xlif_file_path = cycle_folders[0] / 'TileScan 1' / 'Metadata' / f'Position {region}.xlif'

    print("Leica DIR structure 1: XLIF file path is: " + str(xlif_file_path))
    print("Leica DIR structure 1: XML file path is: " + str(xml_file_path))

    with open(xml_file_path, 'r') as f, open(xlif_file_path, 'r') as g:
        xml_content = f.read()
        xlif_content = g.read()

    return cycle_folders, xml_content, xlif_content


def parse_leica_2(base_path, xml_file_path, region):
    container_folder = sorted([folder for folder in base_path.iterdir() if folder.is_dir()])[0]
    print(f'Leica DIR structure 2: container folder: {container_folder}')

    cycle_folders = sorted([folder for folder in container_folder.iterdir() if folder.is_dir() and 'TileScan' in folder.name])
    xlif_file_path = cycle_folders[0] / 'Metadata' / f'Region {region}.xlif'
    
    print("Leica DIR structure 2: XLIF file path is: " + str(xlif_file_path))
    print("Leica DIR structure 2: XML file path is: " + str(xml_file_path))

    with open(xml_file_path, 'r') as f, open(xlif_file_path, 'r') as g:
        xml_content = f.read()
        xlif_content = g.read()

    return cycle_folders, xml_content, xlif_content


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Codex pipeline arguments')
   
    parser.add_argument('--data_path', metavar='Data path', type=str, required=True, 
                                help='Data path to read CODEX raw data')
    parser.add_argument('--sample_id', metavar='Sample ID', type=str, required=True, 
                                help='Sample ID for the codex data')
    parser.add_argument('--output_path', metavar='Output path', type=str, required=True, 
                                help='Output path for results')
    parser.add_argument('--xml_path', metavar='XML file path', type=str, required=True, 
                                help='Experiment XML information')
    parser.add_argument('--region', type=int, required=True, 
                                help='Region number from the multiple regions to scan from')
    parser.add_argument('-j', type=int, default=1, required=False, 
                                help='Number of CPUs to use')
    parser.add_argument('--debug', action='store_true', 
                                help='Whether to make and save intermediate images')
    parser.add_argument('--debug_stitching', action='store_true', 
                                help='Whether to make and save intermediate stitching images for every single tile.')
    parser.add_argument('--ray_object_store_bytes', type=int, default=None,
                                help='Size of shared memory for ray processes, in bytes. '+\
                                '~16-32GB should be more than enough. Default is to auto-set according to the ray settings.')
    parser.add_argument('--short_name', type=str, default=''.join(np.random.choice(alphabet, 5)), 
                                help='to make the ray temp dir unique')
    parser.add_argument('--ray_temp', type=str, default='/tmp', 
                                help='base path for temporary storage. Used by ray in case the alotted object store size is exceeded.')
    parser.add_argument('--clobber', action='store_true', 
                                help='Whether to always overwrite existing output. default=False')
    parser.add_argument('--get_shading_input', action='store_true', 
                                help='Save the result of EDOF only and exit. '+\
                                'This should be used to process a flatfield and darkfield image for the sample '+\
                                'in order to apply a uniform shading correction to each tile & region.')
    parser.add_argument('--precomputed_shading', type=str, default=None, required=False, 
                                help='If set, use the flatfield and darkfield images at the given path '+\
                                'instead of estimating for each region.')
    parser.add_argument('--directory_structure', type=str, default='leica_1', required=False, choices=['leica_1', 'leica_2'],
                                help='Switch to indicate what directory structure should be assumed to correctly '+\
                                'read metadata/image data from disk. Choices are: [leica_1, leica_2]')

                                                      
    args = parser.parse_args()

    codex_object = codex.Codex(data_path=args.data_path, region=args.region, sample_id=args.sample_id)


    edofdir = f'{args.output_path}/0_edof'
    shading_input_dir = f'{args.output_path}/1a_shading_correction_input'
    shadingdir = f'{args.output_path}/1_shading_correction'
    cycledir = f'{args.output_path}/2_cycle_alignment'
    backgrounddir = f'{args.output_path}/3_background_subtract'
    stitchingdir = f'{args.output_path}/4_stitching'
    stitching_db_dir = f'{args.output_path}/4_stitching_debug'
    finaldir = f'{args.output_path}/images'
    qcdir = f'{args.output_path}/qc'
    overlap_dir = f'{args.output_path}/overlapping_regions'
    uint8_dir = f'{args.output_path}/images_uint8'

    if os.path.isdir(finaldir) and not args.clobber:
        print('Found existing output directory and settings indicate to be safe.')
        print(f'output base: {args.output_path}')
        print('Run with --clobber to overwrite existing content at this output location')
        print('or supply a different output base with --output_path.')
        print('Exiting.')
        sys.exit(0)


    os.makedirs(args.output_path, exist_ok=True)
    os.makedirs(edofdir, exist_ok=True)
    os.makedirs(shadingdir, exist_ok=True)
    if args.get_shading_input:
        os.makedirs(shading_input_dir, exist_ok=True)
        print('Requested to run up to shading correction input only. Not creating additional outputs')
    else:
        os.makedirs(cycledir, exist_ok=True)
        os.makedirs(backgrounddir, exist_ok=True)
        os.makedirs(stitchingdir, exist_ok=True)
        os.makedirs(stitching_db_dir, exist_ok=True)
        os.makedirs(finaldir, exist_ok=True)
        os.makedirs(qcdir, exist_ok=True)
        os.makedirs(overlap_dir, exist_ok=True)
        os.makedirs(uint8_dir, exist_ok=True)


    base_path = Path(codex_object.data_path + "/" + codex_object.sample_id)
    print("Base path is: " + str(base_path))

    # cycle_folders = sorted([folder for folder in base_path.iterdir() if folder.is_dir()])
    # print("")
    # # cycle folders also end in a number
    # cycle_folders = cycle_folders[1:]
    # cycle_folders = [folder for folder in cycle_folders if folder.name[-1].isdigit()]

    # xml_file_path = args.xml_path
    # if codex_object.region == 0:
    #     xlif_file_path = cycle_folders[0] / 'Metadata' / 'TileScan 1.xlif'
    # else:
    #     xlif_file_path = cycle_folders[0] / 'TileScan 1' / 'Metadata' / f'Region {codex_object.region}.xlif'
    #     if not xlif_file_path.exists():
    #         xlif_file_path = cycle_folders[0] / 'TileScan 1' / 'Metadata' / f'Position {codex_object.region}.xlif'

    # print("XLIF file path is: " + str(xlif_file_path))
    # print("XML file path is: " + str(xml_file_path))

    # with open(xml_file_path, 'r') as f, open(xlif_file_path, 'r') as g:
    #     xml_content = f.read()
    #     xlif_content = g.read()

    if args.directory_structure == 'leica_1':
        cycle_folders, xml_content, xlif_content = parse_leica_1(base_path, args.xml_path, args.region)

    elif args.directory_structure == 'leica_2':
        cycle_folders, xml_content, xlif_content = parse_leica_2(base_path, args.xml_path, args.region)


    codex_metadata = metadata.Metadata(file_content=[xml_content, xlif_content], decoder=xml_decoder.XMLDecoder())
    metadata_dict = codex_metadata.decode_metadata(cycle_folders=cycle_folders)
    metadata_dict['directory_structure'] = args.directory_structure

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
    ray.init(num_cpus=args.j, logging_level="ERROR", _temp_dir=f"{args.ray_temp}/ray_{args.short_name}",
             object_store_memory=args.ray_object_store_bytes)

    cv2.setNumThreads(0)
    cycle_alignment_dict = {'cycle': [], 
                            'channel': [], 
                            'x_coordinate': [], 
                            'y_coordinate': [], 
                            'initial_correlation': [], 
                            'final_correlation': []}

    time_dict = {'cycle': [] , 'channel': [], 'time': [], 'function': []}

    if args.precomputed_shading is not None:
        shading_estimates = pkl.load(open(args.precomputed_shading, 'rb'))
        

    for channel in range(codex_object.metadata['nch']):
        for cycle, cycle_index in zip(cycle_range, range(codex_object.metadata['ncl'])):
            print("EDOF ready")
            # if args.debug and (channel > 0):
            #     input("continue ")

            # ===============================================================
            #
            #                       EDOF
            #
            # ===============================================================
            image, time = process_codex.apply_edof(cycle, channel)
            time_dict['cycle'].append(cycle)
            time_dict['channel'].append(channel)
            time_dict['time'].append(time)
            time_dict['function'].append('EDOF')
            if args.debug:
                edofpath = f'{edofdir}/'+\
                           f'{args.sample_id}_'+\
                           f'reg{args.region:02d}_'+\
                           f'cycle{cycle:02d}_'+\
                           f'channel{channel:02d}_'+\
                           f'{codex_object.metadata["marker_array"][cycle][channel]}.tif'

                print(f"EDOF done. Saving file. --> {edofpath}")
                cv2.imwrite(edofpath, image)



            # ===============================================================
            #
            #                       Shading correction
            #
            # ===============================================================

            if args.get_shading_input:
                image_stack = stack_shading_input(image, codex_object)
                shading_input_file = f'{shading_input_dir}/cycle{cycle}_channel{channel}.npz'
                np.savez(shading_input_file, image_stack=image_stack)
                print(f'Stashed shading input data for cycle {cycle} channel {channel}. Continuing.')
                continue


            if args.precomputed_shading:
                flatfield = shading_estimates['flatfield'][f'cycle{cycle}_channel{channel}']
                darkfield = shading_estimates['darkfield'][f'cycle{cycle}_channel{channel}']
            else:
                flatfield, darkfield = None, None


            print("Shading correction reached")
            if (channel==0) and (cycle==0):
                tissue_mask = process_codex.get_tissue_mask(image)

            image, time = process_codex.shading_correction(image, tissue_mask, cycle, channel, 
                                                           flatfield=flatfield,
                                                           darkfield=darkfield)
            time_dict['cycle'].append(cycle)
            time_dict['channel'].append(channel)
            time_dict['time'].append(time)
            time_dict['function'].append('Shading correction')
            if args.debug:
                shadingpath = f'{shadingdir}/'+\
                              f'{args.sample_id}_'+\
                              f'reg{args.region:02d}_'+\
                              f'cycle{cycle:02d}_'+\
                              f'channel{channel:02d}_'+\
                              f'{codex_object.metadata["marker_array"][cycle][channel]}.tif'

                print(f"shading correction done. Saving file. --> {shadingpath}")
                cv2.imwrite(shadingpath, image)


            # ===============================================================
            #
            #                       Cycle Alignment
            #
            # ===============================================================
            if channel == 0 and cycle == 0:
                print("Reference DAPI image does not need cycle alignment. Stashing image for cycle reference.")
                image_ref = image.copy()
            elif cycle > 0 and channel == 0:
                cycle_alignment_info, time_1 = process_codex.cycle_alignment_get_transform(image_ref, image)
                codex_object.cycle_alignment_info.append(cycle_alignment_info)
                image, cycle_alignment_dict, time_2 = process_codex.cycle_alignment_apply_transform(image_ref, image, 
                  cycle_alignment_info, cycle, channel, cycle_alignment_dict)
                time_dict['cycle'].append(cycle)
                time_dict['channel'].append(channel)
                time_dict['time'].append(time_1 + time_2)
                time_dict['function'].append('Cycle alignment')
            else:
                image, cycle_alignment_dict, time = process_codex.cycle_alignment_apply_transform(image_ref, image, 
                  codex_object.cycle_alignment_info[cycle_index - 1], cycle, channel, cycle_alignment_dict)
                time_dict['cycle'].append(cycle)
                time_dict['channel'].append(channel)
                time_dict['time'].append(time)
                time_dict['function'].append('Cycle alignment')
 
            if args.debug:
                cyclepath = f'{cycledir}/'+\
                            f'{args.sample_id}_'+\
                            f'reg{args.region:02d}_'+\
                            f'cycle{cycle:02d}_'+\
                            f'channel{channel:02d}_'+\
                            f'{codex_object.metadata["marker_array"][cycle][channel]}.tif'

                print(f"cycle alignment done. Saving file. --> {cyclepath}")
                cv2.imwrite(cyclepath, image)
            # if args.debug and (channel > 0):
            #     input("continue ")


            # ===============================================================
            #
            #                       Background subtraction
            #
            # ===============================================================
            if channel > 0:
                if cycle == 0:
                    codex_object.background_1.append(image.copy())
                elif cycle == codex_object.metadata['ncl'] - 1:
                    codex_object.background_2.append(image.copy())
                else:
                    image, time = process_codex.background_subtraction(image, codex_object.background_1[channel - 1],
                                                                 codex_object.background_2[channel - 1], cycle, channel)

                    backgroundpath = f'{backgrounddir}/'+\
                                     f'{args.sample_id}_'+\
                                     f'reg{args.region:02d}_'+\
                                     f'cycle{cycle:02d}_'+\
                                     f'channel{channel:02d}_'+\
                                     f'{codex_object.metadata["marker_array"][cycle][channel]}.tif'
                    if args.debug:
                        print(f"Background subtraction done. Saving file. --> {backgroundpath}")
                        cv2.imwrite(backgroundpath, image)

                    time_dict['cycle'].append(cycle)
                    time_dict['channel'].append(channel)
                    time_dict['time'].append(time)
                    time_dict['function'].append('Background subtraction')


            # ===============================================================
            #
            #                       Stitching
            #
            # ===============================================================
            print("Stitching started")
            if channel == 0 and cycle == 0:
                image_shared_stitch = ray.put(image)
                stitching_dict, time_init = stitching_object.init_stitching(image_shared_stitch, 
                                                image_width=codex_object.metadata['tileWidth'],
                                                overlap_width=codex_object.metadata['width'], overlap_directory=overlap_dir)
                first_tile, time_find = stitching_object.find_first_tile() 
                j, m, mask, time_first = stitching_object.stitch_first_tile(first_tile, image,
                                                                codex_object.metadata['tileWidth'],
                                                                codex_object.metadata['width'])
                del image_shared_stitch
                print('First tiles placed. placing the rest of the tiles')
                first_tile.stitching_index = 0
                k = 1
                time_stitch = time_init + time_find + time_first
                while np.sum(mask) < np.sum(codex_object.metadata['real_tiles']!='x'):
                    tile_1, tile_2, registration, time_pairs = stitching_object.find_tile_pairs(mask)
                    tile_2.x_off = registration.get('xoff') + tile_1.x_off
                    tile_2.y_off = registration.get('yoff') + tile_1.y_off
                    tile_2.stitching_index = k
                    j, m, mask, jdebug_fixed, jdebug_naive, time_tiles = stitching_object.stitch_tiles(image, 
                                                               codex_object.metadata['tileWidth'], 
                                                               codex_object.metadata['width'], j, m, mask, tile_2,
                                                               tile_2.x_off, tile_2.y_off, debug=args.debug)
                    time_stitch += time_pairs + time_tiles
                    k += 1

                    if args.debug_stitching:
                        stitching_db_path = f'{stitching_db_dir}/'+\
                                            f'{args.sample_id}_'+\
                                            f'reg{args.region:02d}_'+\
                                            f'cycle{cycle:02d}_'+\
                                            f'channel{channel:02d}_'+\
                                            f'{codex_object.metadata["marker_array"][cycle][channel]}_{k:03d}-1.tif'

                        print(f"Saving debug image. {jdebug_fixed.shape} --> {stitching_db_path}")
                        cv2.imwrite(stitching_db_path, jdebug_fixed[:,:,::-1])

                        stitching_db_path = f'{stitching_db_dir}/'+\
                                            f'{args.sample_id}_'+\
                                            f'reg{args.region:02d}_'+\
                                            f'cycle{cycle:02d}_'+\
                                            f'channel{channel:02d}_'+\
                                            f'{codex_object.metadata["marker_array"][cycle][channel]}_{k:03d}-2.tif'

                        print(f"Saving debug image. {jdebug_naive.shape} --> {stitching_db_path}")
                        cv2.imwrite(stitching_db_path, jdebug_naive[:,:,::-1])
                
                print(f"Saving stitching QC file at --> {qcdir}")     
                stitching_df = pd.DataFrame.from_dict(stitching_dict)
                stitching_df.to_csv(qcdir + "/stitching_data.csv") 
                
                time_dict['cycle'].append(cycle)
                time_dict['channel'].append(channel)
                time_dict['time'].append(time_stitch)
                time_dict['function'].append('Stitching')
                ## Correct corners
                #dilated_m = cv2.dilate(m, octagon(1, 1), iterations=1)
                #m = ((dilated_m - m) > 0).astype('uint8')
                #m = cv2.dilate(m, octagon(1, 2), iterations=1)
                #jf = ndimage.uniform_filter(j, size=5, mode='constant')
                #j[m > 0] = jf[m > 0]

            else:
                tiles = stitching_object.tiles.flatten()
                tile_perm = np.argsort([t.stitching_index if isinstance(t, Tile) else 999 for t in tiles])
                #tiles.sort(key=lambda t:t.stitching_index)i
                tiles = tiles[tile_perm]
                j, m, mask, time_stitch = stitching_object.stitch_first_tile(tiles[0], image, codex_object.metadata['tileWidth'], 
                  codex_object.metadata['width'])
                for tile in tiles[1:]:
                    if not isinstance(tile, Tile):
                        continue
                    # make stitching debug functions for the reference image only
                    j, m, mask, _, _, time_tiles = stitching_object.stitch_tiles(image, codex_object.metadata['tileWidth'], 
                                                               codex_object.metadata['width'], j, m, None, tile, 
                                                               tile.x_off, tile.y_off, debug=False)
                    time_stitch += time_tiles

                time_dict['cycle'].append(cycle)
                time_dict['channel'].append(channel)
                time_dict['time'].append(time_stitch)
                time_dict['function'].append('Stitching')

            if args.debug:
                stitchingpath = f'{stitchingdir}/'+\
                                f'{args.sample_id}_'+\
                                f'reg{args.region:02d}_'+\
                                f'cycle{cycle:02d}_'+\
                                f'channel{channel:02d}_'+\
                                f'{codex_object.metadata["marker_array"][cycle][channel]}.tif'
                print(f"Stitching done. Saving file. --> {stitchingpath}")
                cv2.imwrite(stitchingpath, j)

            # ===============================================================
            #
            #                       Finished; save
            #
            # ===============================================================
            final_image_path = f'{finaldir}/'+\
                               f'{args.sample_id}_'+\
                               f'reg{args.region:02d}_'+\
                               f'cycle{cycle:02d}_'+\
                               f'channel{channel:02d}_'+\
                               f'{codex_object.metadata["marker_array"][cycle][channel]}.tif'

            print(f"Channel done. Saving file. --> {final_image_path}")
            cv2.imwrite(final_image_path, j)


            uint8_image_path = f'{uint8_dir}/'+\
                               f'{args.sample_id}_'+\
                               f'reg{args.region:02d}_'+\
                               f'cycle{cycle:02d}_'+\
                               f'channel{channel:02d}_'+\
                               f'{codex_object.metadata["marker_array"][cycle][channel]}.png'

            print(f"Channel done. Saving uint8 image. --> {uint8_image_path}")
            cv2.imwrite(uint8_image_path, img2uint8(j))


            print(f"Saving cycle alignment file at ---> {qcdir}")
            cycle_alignment_df = pd.DataFrame.from_dict(cycle_alignment_dict)
            cycle_alignment_df.to_csv(qcdir + "/cycle_alignment.csv")
            time_df = pd.DataFrame.from_dict(time_dict)
            time_df.to_csv(qcdir + "/time_info.csv")


    # if args.get_shading_input:
    #     print(f'Saving shading input data with items:')
    #     for k,v in shading_input_dict.items():
    #         print(f'{k}: {v.shape}')

    #     print(f'Saving to: {shading_input_file}')
    #     pkl.dump(shading_input_dict, oepn(shading_input_file, 'w+'))
