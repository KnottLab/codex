#!/usr/bin/env python

import numpy as np
import pytiff

import itertools
import argparse

import cv2
import os

from skimage.filters import median
from skimage.morphology import dilation, disk

from csbdeep.utils import Path, normalize
from stardist import random_label_cmap, _draw_polygons
from stardist.models import StarDist2D

#import logging
#logger = logging.getLogger("stardist")

def main(args, handle):

  """ for converting int32 to 4-channel uint8: https://stackoverflow.com/a/25298780 """
  dt=np.dtype((np.int32, {'f0':(np.uint8,0),'f1':(np.uint8,1),'f2':(np.uint8,2), 'f3':(np.uint8,3)}))

  if not os.path.isdir(args.output):
    os.makedirs(args.output)

  #if args.factor is not None:
  #  target_size = ( int(args.size * args.factor), int(args.size * args.factor) )

  # target_size = (args.target_size, args.target_size)
  page = handle.pages[args.page] 
  if args.subtract_page is not None:
    subtract_page = handle.pages[args.subtract_page]

  size = args.size
  #yy = np.linspace(0, h-size, n_y, dtype=np.int)
  #xx = np.linspace(0, w-size, n_x, dtype=np.int)


  model = StarDist2D(None, name=args.model_name, basedir=args.model_basedir)

  #total_nuclei = 0
  selem = disk(5)
  #for i, (x,y) in enumerate(itertools.product(xx, yy)):
    #img = (page[y:y+size,x:x+size] / 2**16).astype(np.float32)

  img = page[:]

  value_max = np.quantile(img, args.quantile_max)
  print(f'Normalizing image to {args.quantile_max}-quantile: {value_max}')

  img[img > value_max] = value_max
  img = img.astype(np.float32) / value_max

  #img = ((page[:] / (2**16-1)) * 255).astype(np.uint8)
  if args.factor is not None:
    #target_size = (int(img.shape[0] * args.factor), int(img.shape[0] * args.factor))
    img = cv2.resize(img, dsize=(0,0), fx=args.factor, fy=args.factor, interpolation=cv2.INTER_CUBIC)
  # else:
  #   img = img.astype(np.float32) / 255

  # Add 1 to the whole number of tiles in each dimension to enusre total coverage.
  h, w = img.shape[:2]
  n_y = int(np.ceil(h / size))
  n_x = int(np.ceil(w / size))
  print(f'[RUN_STARDIST_BIGIMG] cutting {h}, {w} into {n_y} {n_x}')

  
  img = median(img, selem=selem)
  img = normalize(img, axis=(0,1))

  print('preprocessed image: ', img.min(), img.max(), img.shape, img.dtype)

  if args.subtract_page is not None:
    subtract_img = (subtract_page[:] / 2**16).astype(np.float32)
    # subtract_img = normalize(subtract_img)
    img = img - subtract_img

  label_out = f'{args.output}/{os.path.basename(args.input)}'
  #labels, _ = model.predict_instances(img, n_tiles=(n_y, n_x))
  labels, _ = model.predict_instances_big(img, axes='YX', block_size=3096, min_overlap=128, n_tiles=(4,4))
  print(f'StarDist2D returned: {labels.shape}, {labels.max()} instances {labels.dtype}')

  print(f'Converting int32 to 3-channel uint8')
  labels = labels.view(dtype=dt)
  # Assume we have no more than 256 ** 3 (16,777,216) nuclei , so we only take the first 24 bits
  labels = np.dstack([ labels['f0'], labels['f1'], labels['f2'] ])
  print(f'Converted image: {labels.shape} {labels.dtype}')

  print(f'Writing to {label_out}: ')
  cv2.imwrite(label_out, labels)

  #n_nuclei = len(np.unique(labels.ravel())) - 1
  #total_nuclei += n_nuclei

    #if i % 50 == 0:
    #  print(f'[RUN_STARDIST]\t{i: 4d}/{len(xx)*len(yy)} TOTAL: {total_nuclei}')

    ### A completely removable debug procedure
    # if n_nuclei > 100 and args.debugging:
    #   img_o = img_o - subtract_img
    #   labels_o, _ = model.predict_instances(img_o)

    #   print(f'\timg_o: ({img_o.min()}, {img_o.max()}, {img_o.dtype})')
    #   print(f'\timg: ({img.min()}, {img.max()}, {img.dtype})')

    #   pp_out = f'{args.output}/DEBUG_x{x}_y{y}_01.png'
    #   m_out  = f'{args.output}/DEBUG_x{x}_y{y}_02.png'
    #   cv2.imwrite(pp_out, (img * 255).astype(np.uint8))
    #   edges = dilation(labels, selem=disk(1))
    #   edges = (edges - labels) > 0
    #   m_img = np.copy(labels)
    #   m_img[edges] = 0
    #   cv2.imwrite(m_out,  (m_img > 0).astype(np.uint8) * 255)

    #   pp_out = f'{args.output}/DEBUG_x{x}_y{y}_12.png'
    #   m_out  = f'{args.output}/DEBUG_x{x}_y{y}_13.png'
    #   cv2.imwrite(pp_out, (img_o * 255).astype(np.uint8))
    #   edges = dilation(labels_o, selem=disk(1))
    #   edges = (edges - labels_o) > 0 
    #   m_img = np.copy(labels_o)
    #   m_img[edges] = 0
    #   cv2.imwrite(m_out,  (m_img > 0).astype(np.uint8) * 255)


if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  parser.add_argument('-i', dest='input', type=str, help='A tiff image')
  parser.add_argument('-o', dest='output', type=str, help='A directory')

  parser.add_argument('--page', default=0, type=int,
                      help = '0-indexed page to use for the DAPI channel data.')

  parser.add_argument('--subtract_page', default=None, type=int,
                      help = '0-indexed page to subtract from the DAPI channel data.')

  parser.add_argument('--quantile_max', default=0.95, type=float,
                      help = 'The percentile value to use for max normalization. Values above are \
                              squished.')

  parser.add_argument('--size', default=256, type=int,
                      help = 'Pixel dimensions for processing through StarDist2D. \
                              n_tiles are inferred from this value and the input size.')

  # Note on factor: the CODEX microscope scans at a weird resolution ~0.33 um/px or something like that.
  # Depending on the tissue and average nucleus size this may/may not affect the performance
  parser.add_argument('--factor', default=None, type=float,
                      help = 'The up (factor > 1) or down (0 < factor < 1) factor to use for resizing prior to analysis.')

  parser.add_argument('--model_name', default='2D_dsb2018_codex2')
  parser.add_argument('--model_basedir', default='stardist_models')

  parser.add_argument('--debugging', action='store_true', 
                      help = 'Whether to calculate and save some intermediates / alternative pipeline outputs.')

  args = parser.parse_args()

  print(f'\n[STARDIST BIGIMG] opening file {args.input}')
  with pytiff.Tiff(args.input, 'r') as handle:
    main(args, handle)
