#!/usr/bin/env python

import numpy as np
import pickle

import glob
import os

from pybasic import basic
import argparse

import ray

@ray.remote
def run_basic(cycle, channel, input_dirs):
    images = []
    for d in input_dirs:
        fname = f'{d}/cycle{cycle}_channel{channel}.npz'
        if not os.path.exists(fname):
            continue

        imgs = np.load(fname)['image_stack']
        print(f'file {fname} loaded stack: {imgs.shape}', flush=True)
        images.append(imgs.copy())

    images = np.concatenate(images, axis=-1)
    print(f'cycle {cycle} channel {channel} images: {images.shape}')

    flatfield, darkfield = basic(images, segmentation=None, _working_size=256)
    return flatfield, darkfield


if __name__ == '__main__':
    alphabet = list('abcdefghijklmopqrstuvwxyz1234567890ABCDEFGHIJKLMOPQRSTUVWXYZ')
    parser = argparse.ArgumentParser()
    parser.add_argument('--output_path', type=str, required=True)
    parser.add_argument('--cycles', type=int, required=True)
    parser.add_argument('--channels', type=int, required=True)
    parser.add_argument('--input_dirs', nargs='+', required=True)
    parser.add_argument('-j', type=int, default=8)
    parser.add_argument('--short_name', type=str, default=''.join(np.random.choice(alphabet, 5)), 
                                        help='to make the ray temp dir unique')

    ARGS = parser.parse_args()

    flatfield_dict = {}
    darkfield_dict = {}

    # ray.init(num_cpus=ARGS.j)
    ray.init(num_cpus=ARGS.j, logging_level="ERROR", object_store_memory=int(1.23e11),
             _temp_dir=f"/scratch/ingn/tmp/ray_{ARGS.short_name}")

    print(f'Reading shading input files from...')
    for d in ARGS.input_dirs:
        print(d)


    futures = {}
    for cycle in range(ARGS.cycles):
        for channel in range(ARGS.channels):
            futures[f'cycle{cycle}_channel{channel}'] = run_basic.remote(cycle, channel, ARGS.input_dirs)

    for cycle in range(ARGS.cycles):
        for channel in range(ARGS.channels):
            ff , df = ray.get(futures[f'cycle{cycle}_channel{channel}'])

            flatfield_dict[f'cycle{cycle}_channel{channel}'] = ff.copy()
            darkfield_dict[f'cycle{cycle}_channel{channel}'] = df.copy()

    combined_dict = {'flatfield': flatfield_dict, 'darkfield': darkfield_dict}

    print(f'Writing reference dict to {ARGS.output_path}')
    pickle.dump(combined_dict, open(ARGS.output_path, 'wb'))
                    

