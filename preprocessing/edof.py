import cv2
import numpy as np
import scipy.ndimage as ndimage
from utilities.utility import (read_tile_at_z_leica_1, read_tile_at_z_leica_2)
import ray
#from pybasic import basic

#coef = np.iinfo(np.uint16).max

@ray.remote
def edof_loop(tileWidth, nz, real_tiles, cycle_folders, Ntiles, region, directory_structure, cl, ch, x, y):

    image_s = np.zeros((tileWidth, tileWidth, nz), dtype=np.uint16)

    if real_tiles[x,y] != 'x':
        for z in range(nz):
            if directory_structure == 'leica_1':
                image = read_tile_at_z_leica_1(cycle_folders, Ntiles, region, real_tiles, cl, ch, x, y, z)
            elif directory_structure == 'leica_2':
                image = read_tile_at_z_leica_2(cycle_folders, Ntiles, region, real_tiles, cl, ch, x, y, z)

            if image is None:
                raise Exception("Image at above path isn't present")
            image_s[:, :, z] = image

        print(f"calculating EDOF from stack: {image_s.shape} ({image_s.dtype})")
        edof_image, success = calculate_focus_stack(image_s)

        # flatfield, darkfield = basic(images=image_s/coef, segmentation=None, _working_size=256)#, _lambda_s=1, _lambda_darkfield=1)
        # print(f"applying shading correction: {edof_image.shape} {flatfield.shape} {darkfield.shape}")
        # edof_image = (((edof_image/coef - darkfield) / flatfield) * coef).astype(np.uint16)

    else:
      edof_image = None
      success = False

    image_id = ray.put(edof_image)
    print(f"placing EDOF image in shared mem: {edof_image.shape} ({edof_image.dtype}) ID: {image_id}")
    del edof_image
    return image_id, success


def calculate_focus_stack(image, processor='CPU'):
    """Turn this method into a class if more than one focus stack method is needed"""
    m, n, p = image.shape
    alpha = 0.2
    nh_size = 9
    sth = 13

    # Compute fmeasure
    f_measure = np.zeros((m, n, p))
    for focus in range(p):
        focused_image = image[:, :, focus].copy()
        focused_image = focused_image.astype('float') / 65535
        f_measure[:, :, focus] = calculate_gfocus(focused_image, nh_size)

    # Compute smeasure
    u, s, gauss, max_values = calculate_gauss(np.array(range(p)), f_measure)

    error = np.zeros((m, n))
    for focus in range(p):
        error += abs(f_measure[:, :, focus] - gauss * np.exp(-(focus - u) ** 2 / (2 * s ** 2)))
        f_measure[:, :, focus] = f_measure[:, :, focus] / max_values

    inverse_psnr = ndimage.uniform_filter(error / (p * max_values), size=nh_size, mode='nearest')

    signal = 20 * np.log10(1 / inverse_psnr)
    signal = np.nan_to_num(signal, copy=True, nan=np.min(signal), posinf=np.min(signal), neginf=np.min(signal))

    phi = 0.5 * (1 + np.tanh(alpha * (signal - sth))) / alpha

    if np.isnan(phi).any():
        print("Cannot create fused image -- returning a middle slice")
        n_imgs = image.shape[-1]
        index_out = int(n_imgs/2)
        image_out = image[:,:,index_out].copy()
        return image_out, False

    else:
        phi = ndimage.median_filter(phi, size=(3, 3), mode='constant')

        # compute weights
        for focus in range(p):
            f_measure[:, :, focus] = 0.5 + 0.5 * np.tanh(phi * (f_measure[:, :, focus] - 1))

        # fuse images
        normalization_factor = np.sum(f_measure, axis=2)
        fused_image = np.sum((image.astype('float') * f_measure), axis=2) / normalization_factor

        return fused_image.astype('uint16'), True


def calculate_gfocus(image, width_size):
    weights = np.ones(shape=(width_size, width_size)) / (width_size ** 2)
    filtered_image = ndimage.correlate(image, weights, mode='nearest')
    filtered_image = (image - filtered_image) ** 2
    filtered_image = ndimage.correlate(filtered_image, weights, mode='nearest')
    return filtered_image


def calculate_gauss(x, y):
    step = 1
    m, n, p = y.shape
    max_values, index_values = y.max(axis=2), y.argmax(axis=2)
    mesh_n, mesh_m = np.meshgrid(range(n), range(m))
    index_values_f = index_values.flatten('F')
    index_values_f[index_values_f <= step] = step + 1
    index_values_f[index_values_f >= p - (step + 2)] = p - (step + 2)

    # create 3 indices
    index_1 = np.ravel_multi_index([mesh_m.flatten('F'), mesh_n.flatten('F'), index_values_f - (step + 1)],
                                   dims=(m, n, p), order='F')
    index_2 = np.ravel_multi_index([mesh_m.flatten('F'), mesh_n.flatten('F'), index_values_f], dims=(m, n, p),
                                   order='F')
    index_3 = np.ravel_multi_index([mesh_m.flatten('F'), mesh_n.flatten('F'), index_values_f + (step + 1)],
                                   dims=(m, n, p), order='F')

    index_1[index_values.flatten('F') <= step] = index_3[index_values.flatten('F') <= step]
    index_3[index_values.flatten('F') >= step] = index_1[index_values.flatten('F') >= step]

    x_1 = np.reshape(x[index_values_f - (step + 1)], (m, n), order='F')
    x_2 = np.reshape(x[index_values_f], (m, n), order='F')
    x_3 = np.reshape(x[index_values_f + (step + 1)], (m, n), order='F')

    # create 3 y sub-arrays
    y_1 = np.reshape(np.log(y.ravel('F')[index_1]), (m, n), order='F')
    y_2 = np.reshape(np.log(y.ravel('F')[index_2]), (m, n), order='F')
    y_3 = np.reshape(np.log(y.ravel('F')[index_3]), (m, n), order='F')

    c = ((y_1 - y_2) * (x_2 - x_3) - (y_2 - y_3) * (x_1 - x_2)) / (
            (x_1 ** 2 - x_2 ** 2) * (x_2 - x_3) - (x_2 ** 2 - x_3 ** 2) * (x_1 - x_2))

    # array values for b slightly diverge
    b = ((y_2 - y_3) - c * (x_2 - x_3) * (x_2 + x_3)) / (x_2 - x_3)
   
    c[c == 0] = 1

    sqrt_array = (-1 / (2 * c)).astype('complex')
    s = np.sqrt(sqrt_array)

    # array values for u slightly diverge
    u = b * s ** 2

    # array values for a slightly diverge
    a = y_1 - b * x_1 - c * x_1 ** 2

    gauss = np.exp(a + u ** 2 / (2 * s ** 2))

    return u, s, gauss, max_values
