"""Utility functions for CODEX"""
import pandas as pd
import cv2
import numpy as np
import time


# This is a generic wrapper for any driver function you want to time
def time_this(f):
    def timed_wrapper(*args, **kw):
        start_time = time.time()
        result = f(*args, **kw)
        end_time = time.time()
        if isinstance(result, tuple):
           result += (end_time - start_time,)
        else:
           result = (result, end_time - start_time)
        print(f"Time inside time this function: {end_time - start_time}")
        # Time taken = end_time - start_time
        #print('| func:%r args:[%r, %r] took: %2.4f seconds |' % \
              # (f.__name__, args, kw, end_time - start_time))
        return result
    return timed_wrapper

def read_table(path):
    table = pd.read_csv(path)
    return table

def corr2(a, b):
    a = a - np.mean(a)
    b = b - np.mean(b)
    return (a*b).sum() / np.sqrt((a*a).sum() * (b*b).sum())


def num2str(x, version='1'):
    if version == '2':
        if x < 10:
            x = '0' + str(x)
        else:
            x = str(x)
    else:
        if x < 10:
            x = '00' + str(x)
        elif x < 100:
            x = '0' + str(x)
        else:
            x = str(x)
    return x


# def read_tile_at_z(codex_obj, cl, ch, x, y, z):
#     #print(f'n tiles: {codex_obj.metadatta["Ntiles"]}\tregion: {codex_obj.region}')
#     if codex_obj.metadata['cycle_folders']:
#         # Areas consisting of a single tile are called 'Position' instead of 'Region'
#         if codex_obj.metadata['Ntiles'] == 1:
#             path = str(codex_obj.metadata['cycle_folders'][
#                 cl]) + '/TileScan 1--Z' + num2str(z, version='2') + '--C' + f'{ch:03d}' + '.tif'
# 
#         elif codex_obj.region == 0:
#             # path = str(codex_obj.metadata['cycle_folders'][cl]) + '/TileScan 1--Stage' + num2str(x * (codex_obj.metadata['ny'] + 1) + y,
#             #                                         version='2') + '--Z' + num2str(z, version='2') + '--C' + num2str(ch, version='2') + '.tif'
# 
#             # path = str(codex_obj.metadata['cycle_folders'][cl]) + '/TileScan 1--Stage' + codex_obj.metadata['real_tiles'][x,y] +\
#             #        '--Z' + f'{z:02d}' + '--C' + f'{ch:02d}' + '.tif'
#             path = f'{codex_obj.metadata["cycle_folders"][cl]}/TileScan 1--Stage{codex_obj.metadata["real_tiles"][x,y]}'+\
#                    f'--Z{z:02d}--C{ch:02d}.tif'
# 
# 
#         else:
#             path = str(codex_obj.metadata['cycle_folders'][cl]) + \
#                    '/TileScan 1/Region ' + str(codex_obj.region) +\
#                    '--Stage' + codex_obj.metadata['real_tiles'][x,y] + \
#                    '--Z' + f'{z:02d}' + \
#                    '--C' + f'{ch:02d}' + '.tif'
# 
#     else:
#         path = codex_obj.data_path + '/' + codex_obj.sample_id + '/cyc' + num2str(cl) + '_reg00' + num2str(
#             codex_obj.metadata['roi']) + '_00' + num2str((x - 1) * codex_obj.metadata['ny'] + y) + '_Z' + num2str(
#             z) + '_CH' + num2str(ch) + '.tif'
#     
#     i = cv2.imread(path, -1)
#     print(f"region: {codex_obj.region} Reading tile at: {path} size: {i.shape} dtype: {i.dtype}")
# 
#     return i

def read_tile_at_z_leica_1(cycle_folders, Ntiles, region, real_tiles, cl, ch, x, y, z):
    #print(f'n tiles: {codex_obj.metadatta["Ntiles"]}\tregion: {codex_obj.region}')
    if cycle_folders:
        # Areas consisting of a single tile are called 'Position' instead of 'Region'
        if Ntiles == 1:
            path = str(cycle_folders[cl]) + '/TileScan 1--Z' + num2str(z, version='2') + '--C' + f'{ch:03d}' + '.tif'

        elif region == 0:
            # This is the other common case
            path = f'{cycle_folders[cl]}/TileScan 1--Stage{real_tiles[x,y]}'+\
                   f'--Z{z:02d}--C{ch:02d}.tif'


        else:
            # This is the most common case
            path = str(cycle_folders[cl]) +\
                   '/TileScan 1/Region ' + str(region) +\
                   '--Stage' + real_tiles[x,y] +\
                   '--Z' + f'{z:02d}' + \
                   '--C' + f'{ch:02d}' + '.tif'

    # else: # this is for reading some other kind of input format.
    #     path = codex_obj.data_path + '/' + codex_obj.sample_id + '/cyc' + num2str(cl) + '_reg00' + num2str(
    #         codex_obj.metadata['roi']) + '_00' + num2str((x - 1) * codex_obj.metadata['ny'] + y) + '_Z' + num2str(
    #         z) + '_CH' + num2str(ch) + '.tif'
    
    i = cv2.imread(path, -1)
    print(f"Leica DIR structure 1: region: {region} Reading tile at: {path} size: {i.shape} dtype: {i.dtype}")

    return i


def read_tile_at_z_leica_2(cycle_folders, Ntiles, region, real_tiles, cl, ch, x, y, z):
    if cycle_folders:
        # Areas consisting of a single tile are called 'Position' instead of 'Region'
        if Ntiles == 1:
            path = str(cycle_folders[cl]) + '/TileScan 1--Z' + num2str(z, version='2') + '--C' + f'{ch:03d}' + '.tif'

        elif region == 0:
            # This is the other common case
            path = f'{cycle_folders[cl]}/TileScan 1--Stage{real_tiles[x,y]}'+\
                   f'--Z{z:02d}--C{ch:02d}.tif'

        else:
            # This is the most common case
            path = str(cycle_folders[cl]) +\
                   '/Region ' + str(region) +\
                   '--Stage' + real_tiles[x,y] +\
                   '--Z' + f'{z:02d}' + \
                   '--C' + f'{ch:02d}' + '.tif'

    # else: # this is for reading some other kind of input format.
    #     path = codex_obj.data_path + '/' + codex_obj.sample_id + '/cyc' + num2str(cl) + '_reg00' + num2str(
    #         codex_obj.metadata['roi']) + '_00' + num2str((x - 1) * codex_obj.metadata['ny'] + y) + '_Z' + num2str(
    #         z) + '_CH' + num2str(ch) + '.tif'
    
    i = cv2.imread(path, -1)
    print(f"Leica DIR structure 2: region: {region} Reading tile at: {path} size: {i.shape} dtype: {i.dtype}")

    return i
