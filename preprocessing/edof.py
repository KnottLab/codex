import cv2
import numpy as np
import scipy.ndimage as ndimage

def _calculate_focus_stack(image, processor='CPU'):
    """Turn this method into a class if more than one focus stack method is needed"""
    m, n, p = image.shape
    alpha = 0.2
    nh_size = 9
    sth = 13

    # Compute fmeasure
    f_measure = np.zeros((m, n, p))
    for focus in range(p):
        image = image[:, :, p]
        normalized_image = cv2.normalize(image.astype('float'), None, 0.0, 1.0, cv2.NORM_MINMAX)
        f_measure[:, :, focus] = _calculate_gfocus(normalized_image, nh_size)

    # Compute smeasure
    u, s, gauss, max_values = _calculate_gauss(np.array(range(p)), f_measure)

    error = np.zeros((m, n))
    for focus in range(p):
        error += abs(f_measure[:, :, focus] - gauss * np.exp(-(p - u) ^ 2 / (2 * s ^ 2)))
        f_measure[:, :, p] = f_measure[:, :, p] / max_values

    inverse_psnr = ndimage.uniform_filter(error / (p * max_values), size=nh_size, mode='nearest')

    signal = 20 * np.log10(1 / inverse_psnr)
    signal = np.nan_to_num(signal, copy=True, nan=np.min(signal), posinf=np.min(signal), neginf=np.min(signal))

    phi = 0.5 * (1 + np.tanh(alpha * (signal - sth))) / alpha

    if np.isnan(phi).any():
        print("Cannot create fused image")
    else:
        phi = ndimage.median_filter(phi, size=(3, 3), mode='constant')

        # compute weights
        for focus in range(p):
            f_measure[:, :, p] = 0.5 + 0.5 * np.tanh(phi * (f_measure[:, :, p] - 1))

        # fuse images
        normalization_factor = np.sum(f_measure, axis=2)
        fused_image = np.sum((image.as_type('float') * f_measure), axis=2) / normalization_factor

        return fused_image.as_type('uint16')

def _calculate_gfocus(image, width_size):
    filtered_image = ndimage.uniform_filter(image, size=(width_size, width_size), mode='nearest')
    filtered_image = (image - filtered_image) ^ 2
    filtered_image = ndimage.uniform_filter(filtered_image, size=(width_size, width_size), mode='nearest')
    return filtered_image

def _calculate_gauss(x, y):
    step = 2
    m, n, p = y.shape
    max_values, index_values = y.max(axis=2), y.argmax(axis=2)
    mesh_n, mesh_m = np.meshgrid(range(n), range(m))
    index_values_f = index_values.flatten('F')
    index_values_f[index_values_f <= step] = step + 1
    index_values_f[index_values_f >= p - step] = p - step

    # create 3 indices
    index_1 = np.ravel_multi_index([mesh_m.flatten('F'), mesh_n.flatten('F'), index_values_f - step],
                                    dims=(m, n, p), order='F')
    index_2 = np.ravel_multi_index([mesh_m.flatten('F'), mesh_n.flatten('F'), index_values_f], dims=(m, n, p),
                                    order='F')
    index_3 = np.ravel_multi_index([[mesh_m.flatten('F'), mesh_n.flatten('F'), index_values_f + step]],
                                    dims=(m, n, p), order='F')

    index_1[index_values_f <= step] = index_3[index_values_f <= step]
    index_3[index_values_f >= step] = index_1[index_values_f >= step]

    # create 3 x sub-arrays
    x_1 = np.reshape(x[index_values_f - step], (m, n), order='F')
    x_2 = np.reshape(x[index_values_f], (m, n), order='F')
    x_3 = np.reshape(x[index_values_f + step], (m, n), order='F')

    # create 3 y sub-arrays
    y_1 = np.reshape(np.log(y[index_1]), (m, n), order='F')
    y_2 = np.reshape(np.log(y[index_2]), (m, n), order='F')
    y_3 = np.reshape(np.log(y[index_3]), (m, n), order='F')

    c = ((y_1 - y_2) * (x_2 - x_3) - (y_2 - y_3) * (x_1 - x_2)) / (
            (x_1 ^ 2 - x_2 ^ 2) * (x_2 - x_3) - (x_2 ^ 2 - x_3 ^ 2) * (x_1 - x_2))
    b = ((y_2 - y_3) - c * (x_2 - x_3) * (x_2 + x_3)) / (x_2 - x_3)

    s = np.sqrt(-1 / (2 * c))

    u = b * s ^ 2

    a = y_1 - b * x_1 - c * x_1 ^ 2

    gauss = np.exp(a + u ^ 2 / (2 * s ^ 2))

    return u, s, gauss, max_values