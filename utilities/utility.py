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
        print(f"Inside time this function with {result}")
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


def read_tile_at_z(codex_obj, cl, ch, x, y, z):
    if codex_obj.metadata['cycle_folders']:
        # Areas consisting of a single tile are called 'Position' instead of 'Region'
        if codex_obj.metadata['Ntiles'] == 1:
            path = str(codex_obj.metadata['cycle_folders'][
                cl]) + '/TileScan 1--Z' + num2str(z, version='2') + '--C' + f'{ch:03d}' + '.tif'

        elif codex_obj.region == '0':
            path = str(codex_obj.metadata['cycle_folders'][
                cl]) + '/TileScan 1--Stage' + num2str(x * (codex_obj.metadata['ny'] + 1) + y,
                                                    version='2') + '--Z' + num2str(z, version='2') + '--C' + num2str(
                ch, version='2') + '.tif'

        else:
            path = str(codex_obj.metadata['cycle_folders'][cl]) + \
                '/TileScan 1/Region ' + str(codex_obj.region) +\
                '--Stage' + codex_obj.metadata['real_tiles'][x,y] + \
                '--Z' + f'{z:02d}' + \
                '--C' + f'{ch:02d}' + '.tif'

    else:
        path = codex_obj.data_path + '/' + codex_obj.sample_id + '/cyc' + num2str(cl) + '_reg00' + num2str(
            codex_obj.metadata['roi']) + '_00' + num2str((x - 1) * codex_obj.metadata['ny'] + y) + '_Z' + num2str(
            z) + '_CH' + num2str(ch) + '.tif'
    
    print("Reading tile at: " + path)

    return cv2.imread(path, -1)
