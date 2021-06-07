import numpy as np
import pandas as pd
import cv2
import pickle

from eval_alignment import get_shifts, scatter_shifts, color_shifts
import argparse
import glob
import os

from matplotlib import pyplot as plt
from matplotlib import rcParams
rcParams['figure.facecolor'] = (1,1,1,1)
rcParams['svg.fonttype'] = 'none'

# given an output folder formatted: [root_dir]/[sample_id]/4_stitching/[sample_id]*.tif,
# 1. load the first DAPI channel (A)
# 2. find the subsequent DAPI channels (B, C, D, etc.)
# 3. calculate the sub-tile shifts, between (A,B), (A,C), (A,D), etc.
# 4. save shifts in some output dir [out_dir]/[sample_id]/subtile_shifts 
# 5. draw summary plots, save them 

parser = argparse.ArgumentParser()
parser.add_argument('root_dir')
parser.add_argument('sample_id')
parser.add_argument('out_dir')
ARGS = parser.parse_args()

outdir = f'{ARGS.out_dir}/{ARGS.sample_id}/subtile_shifts'
if not os.path.exists(outdir):
  os.makedirs(outdir)
  

def find_images(srch_base):
  srch = f'{srch_base}/*DAPI*.tif'
  all_imgs = sorted(glob.glob(srch))
  ref_img = all_imgs[0]
  cycle_imgs = all_imgs[1:]

  return ref_img, cycle_imgs


# pre-alignment
srch_base = f'{ARGS.root_dir}/{ARGS.sample_id}/1_shading_correction'
ref_path, pre_cycle_paths = find_images(srch_base) 

# post-alignment
srch_base = f'{ARGS.root_dir}/{ARGS.sample_id}/2_cycle_alignment'
_, post_cycle_paths = find_images(srch_base) 

print(ref_path)
print(pre_cycle_paths)
print(post_cycle_paths)

ref_img = cv2.imread(ref_path, -1)
print(ref_img.shape)

fig1 = plt.figure()
ax1 = fig1.add_subplot(1,1,1)

fig2 = plt.figure()
ax2 = fig2.add_subplot(1,1,1)


for cycle_index, (pre_f, post_f) in enumerate(zip(pre_cycle_paths, post_cycle_paths)):
  pre_img = cv2.imread(pre_f, -1)
  post_img = cv2.imread(post_f, -1)

  pre_shifts = get_shifts(ref_img, pre_img, tilesize=500, overlap=0.0)
  post_shifts = get_shifts(ref_img, post_img, tilesize=500, overlap=0.0)

  print(pre_shifts.shape, post_shifts.shape)

  pre_rgb = color_shifts(pre_shifts)
  post_rgb = color_shifts(post_shifts)

  np.save(f'{outdir}/cycle_{cycle_index}_uncorrected_shifts.npy', pre_shifts)
  np.save(f'{outdir}/cycle_{cycle_index}_corrected_shifts.npy', post_shifts)

  ax1.imshow(pre_rgb)
  ax1.axis('off')
  fig1.savefig(f'{outdir}/cycle_{cycle_index}_uncorrected_insitu.png',
               bbox_inches='tight', transparent=True)
  scatter_shifts(pre_shifts, pre_rgb, lims=6, ax=ax2,
                  save = f'{outdir}/cycle_{cycle_index}_uncorrected_scatter.svg')
  ax1.clear()
  ax2.clear()


  ax1.imshow(post_rgb)
  ax1.axis('off')
  fig1.savefig(f'{outdir}/cycle_{cycle_index}_corrected_insitu.png',
               bbox_inches='tight', transparent=True)
  scatter_shifts(post_shifts, post_rgb, lims=6, ax=ax2,
                  save = f'{outdir}/cycle_{cycle_index}_corrected_scatter.svg')
  ax1.clear()
  ax2.clear()
