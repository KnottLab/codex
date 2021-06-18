from image_registration import chi2_shift
import seaborn as sns
import numpy as np
import cv2

import itertools
from scipy.stats import pearsonr

from matplotlib import pyplot as plt
from matplotlib import rcParams
from matplotlib.colors import hsv_to_rgb
from matplotlib.colors import rgb2hex

def get_shifts(ref, query, tilesize=200, overlap=0, min_mean=300, 
               border = 50, 
               xnorm=np.inf, ynorm=np.inf):
  assert np.all(ref.shape == query.shape)
  h,w = ref.shape
  nh = int(np.ceil((h-border) / tilesize))
  nw = int(np.ceil((w-border) / tilesize))
  nh += int(nh * overlap)
  nw += int(nw * overlap)
  hcoords = np.linspace(border, h-border-tilesize, nh, dtype='int')
  wcoords = np.linspace(border, w-border-tilesize, nw, dtype='int')
  
  shifts = np.zeros((nh,nw,3),dtype='float')
  
  for i,hc in enumerate(hcoords):
    for j,wc in enumerate(wcoords):
      r = ref[hc:hc+tilesize, wc:wc+tilesize]
      q = query[hc:hc+tilesize, wc:wc+tilesize]
      if np.mean(r) < min_mean:
        xoff=0
        yoff=0
      else:
          xoff, yoff, exoff, eyoff = chi2_shift(r, q, return_error=True, upsample_factor='auto')
      #if np.abs(xoff)>xnorm:
      #    xoff=0
      #if np.abs(yoff)>ynorm:
      #    yoff=0
      # cor = pearsonr(r.ravel(), q.ravel())
      shifts[i,j,:] = xoff, yoff, np.mean(r)
          
  return shifts

def cart2polar(x,y):
  theta = np.rad2deg(np.arctan2(y,x))
  if (x<0) & (y>0):
    theta = 0+theta
  if (x<0) & (y<0):
    theta = 360+theta
  if (x>0) & (y<0):
    theta = 360+theta
          
  r = np.sqrt(x**2 + y**2)
  return r, theta/360

def color_shifts(shifts, r_norm=None):
  hsv = np.zeros_like(shifts)
  for i,j in itertools.product(range(shifts.shape[0]), range(shifts.shape[1])):
    comp = shifts[i,j,:2]
    r,theta = cart2polar(comp[0],comp[1])
    hsv[i,j,:] = theta, r, 1
      
  if r_norm is None: 
    hsv[:,:,1] /= hsv[:,:,1].max()
  else:
    rlayer = hsv[:,:,1].copy()
    rlayer[rlayer>r_norm] = r_norm
    rlayer = rlayer/r_norm
    hsv[:,:,1] = rlayer
  
  rgb = np.zeros_like(hsv)
  for i,j in itertools.product(range(shifts.shape[0]), range(shifts.shape[1])):
    color = hsv_to_rgb(hsv[i,j,:])
    rgb[i,j,:] = color
  
  return rgb


def scatter_shifts(shifts, rgb, lims=None, save=None, ax=None):
  xs = []
  ys = []
  colors = []
  for i,j in itertools.product(range(shifts.shape[0]), range(shifts.shape[1])):
    xs.append(shifts[i,j,0])
    ys.append(shifts[i,j,1])
    colors.append(rgb2hex(rgb[i,j,:]))
      
  if lims is None:
    xtnt = np.max(np.abs(xs))
    ytnt = np.max(np.abs(ys))
    lims = np.max([xtnt, ytnt])
  
  if ax is None:
    plt.figure(figsize=(2,2))
    ax = plt.gca()

  ax.set_aspect('equal')
  ax.scatter(xs, ys, color=colors, lw=0.1, ec='k')
  ax.set_xlabel('xoff')
  ax.set_ylabel('yoff')
  ax.axhline(0, color='k', lw=0.5, zorder=0)
  ax.axvline(0, color='k', lw=0.5, zorder=0)
  ax.set_xlim([-lims, lims])
  ax.set_ylim([-lims, lims])
  
  if save is not None:
    plt.savefig(save, bbox_inches='tight', transparent=True)
