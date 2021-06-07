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

# given an output folder formatted: [sample_id]/cycle**.tif,
# 1. load the first DAPI channel (A) (cycle_0_channel_0.tif)
# 2. find the subsequent DAPI channels (B, C, D, etc.) (cycle_*_channel_0.tif)
# 3. calculate the sub-tile shifts, between (A,B), (A,C), (A,D), etc.
# 4. save shifts in some output dir [output_dir]/[sample_id]/subtile_shifts 
# 5. draw summary plots, save them [output_dir]/[sample_id]/subtile_plots

parser = argparse.ArgumentParser()
parser.add_argument('root_dir')
parser.add_argument('sample_id')
parser.add_argument('out_dir')
ARGS = parser.parse_args()

outdir = f'{ARGS.out_dir}/{ARGS.sample_id}/subtile_shifts'
if not os.path.exists(outdir):
  os.makedirs(outdir)

def find_images(srch_base):
  srch = f'{srch_base}/cycle_*_channel_0.tif'
  all_imgs = sorted(glob.glob(srch))
  ref_img = all_imgs[0]
  cycle_imgs = all_imgs[1:]
  return ref_img, cycle_imgs



# post-alignment only
srch_base = f'{ARGS.root_dir}/{ARGS.sample_id}'
ref_path, post_cycle_paths = find_images(srch_base) 

ref_img = cv2.imread(ref_path, -1)
print(ref_img.shape)

fig1 = plt.figure()
ax1 = fig1.add_subplot(1,1,1)

fig2 = plt.figure()
ax2 = fig2.add_subplot(1,1,1)


for cycle_index, post_f in enumerate(post_cycle_paths):
  post_img = cv2.imread(post_f, -1)

  post_shifts = get_shifts(ref_img, post_img, tilesize=500, overlap=0.0)


  post_rgb = color_shifts(post_shifts)
  np.save(f'{outdir}/cycle_{cycle_index}_corrected_shifts_ashlar.npy', post_shifts)


  ax1.imshow(post_rgb)
  ax1.axis('off')
  fig1.savefig(f'{outdir}/cycle_{cycle_index}_corrected_insitu_ashlar.png',
               bbox_inches='tight', transparent=True)
  scatter_shifts(post_shifts, post_rgb, lims=6, ax=ax2,
                  save = f'{outdir}/cycle_{cycle_index}_corrected_scatter_ashlar.svg')
  ax1.clear()
  ax2.clear()
