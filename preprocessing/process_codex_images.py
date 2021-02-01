"""Class for processing codex images"""
import scipy.ndimage as ndimage
import cv2
import numpy as np
from utilities.utility import read_tile_at_z, num2str
import sys


class ProcessCodex:

    def __init__(self, codex_object):
        self.codex_object = codex_object

    def apply_edof(self, cl, ch, processor='CPU'):
        k = 1
        images = None
        for x in range(self.codex_object.metadata['nx'] + 1):
            images_temp = None
            if (x + 1) % 2 == 0:
                y_range = range(self.codex_object.metadata['ny'], -1, -1)
            else:
                y_range = range(self.codex_object.metadata['ny'] + 1)

            for y in y_range:
                print("Processing : " + self.codex_object.metadata['marker_names_array'][cl][ch] + " CL: " + str(cl) + " CH: " + str(ch) + " X: " + str(x) + " Y: " + str(y))
                image_s = np.zeros((self.codex_object.metadata['tileWidth'], self.codex_object.metadata['tileWidth'],
                                    self.codex_object.metadata['nz']))
                for z in range(self.codex_object.metadata['nz']):
                    image = read_tile_at_z(self.codex_object, cl, ch, x, y, z)
                    if image is None:
                       raise Exception("Image at above path isn't present")
                    image_s[:, :, z] = image

                image = self._calculate_focus_stack(image_s)
                if images_temp is None:
                    images_temp = image
                else:
                    images_temp = np.concatenate((images_temp, image), 1)
                print(images_temp.shape)
                k += 1

            if images is None:
                images = images_temp
            else:
                images = np.concatenate((images, images_temp))
            print(images.shape)

        return images

    def _calculate_focus_stack(self, image, processor='CPU'):
        """Turn this method into a class if more than one focus stack method is needed"""
        m, n, p = image.shape
        alpha = 0.2
        nh_size = 9
        sth = 13

        # Compute fmeasure
        f_measure = np.zeros((m, n, p))
        for focus in range(p):
            focused_image = image[:, :, focus]
            focused_image = focused_image.astype('float') / 65535
            f_measure[:, :, focus] = self._calculate_gfocus(focused_image, nh_size)
        
        # Compute smeasure
        u, s, gauss, max_values = self._calculate_gauss(np.array(range(p)), f_measure)

        error = np.zeros((m, n))
        for focus in range(p):
            error += abs(f_measure[:, :, focus] - gauss * np.exp(-(focus - u) ** 2 / (2 * s ** 2)))
            f_measure[:, :, focus] = f_measure[:, :, focus] / max_values

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
                f_measure[:, :, focus] = 0.5 + 0.5 * np.tanh(phi * (f_measure[:, :, focus] - 1))

            # fuse images
            normalization_factor = np.sum(f_measure, axis=2)
            fused_image = np.sum((image.astype('float') * f_measure), axis=2) / normalization_factor

            return fused_image.astype('uint16')

    def _calculate_gfocus(self, image, width_size):
        weights = np.ones(shape=(width_size, width_size)) / (width_size ** 2)
        filtered_image = ndimage.correlate(image, weights, mode='nearest')
        filtered_image = (image - filtered_image) ** 2
        filtered_image = ndimage.correlate(filtered_image, weights, mode='nearest')
        return filtered_image

    def _calculate_gauss(self, x, y):
        step = 1
        m, n, p = y.shape
        max_values, index_values = y.max(axis=2), y.argmax(axis=2)
        mesh_n, mesh_m = np.meshgrid(range(n), range(m))
        np.save("/common/shaha4/shaha4/mesh_n.npy", mesh_n)
        np.save("/common/shaha4/shaha4/mesh_m.npy", mesh_m)
        print(mesh_n.shape)
        index_values_f = index_values.flatten('F')
        index_values_f[index_values_f <= step] = step + 1
        index_values_f[index_values_f >= p - (step + 2)] = p - (step + 2)
        np.save("/common/shaha4/shaha4/index_values_f.npy", index_values_f)

        # create 3 indices
        index_1 = np.ravel_multi_index([mesh_m.flatten('F'), mesh_n.flatten('F'), index_values_f - (step + 1)],
                                       dims=(m, n, p), order='F')
        index_2 = np.ravel_multi_index([mesh_m.flatten('F'), mesh_n.flatten('F'), index_values_f], dims=(m, n, p), order='F')
        index_3 = np.ravel_multi_index([mesh_m.flatten('F'), mesh_n.flatten('F'), index_values_f + (step + 1)],
                                       dims=(m, n, p), order='F')
        
        print(index_1.shape, index_2.shape, index_3.shape)

        index_1[index_values.flatten('F') <= step] = index_3[index_values.flatten('F') <= step]
        index_3[index_values.flatten('F') >= step] = index_1[index_values.flatten('F') >= step]
        
        print("Saving index array")
        
        np.save('/common/shaha4/shaha4/index_1.npy', index_1) 
        np.save('/common/shaha4/shaha4/index_3.npy', index_3)
        print(index_1.shape, index_3.shape)
       
        x_1 = np.reshape(x[index_values_f - (step + 1)], (m, n), order='F')
        x_2 = np.reshape(x[index_values_f], (m, n), order='F')
        x_3 = np.reshape(x[index_values_f + (step + 1)], (m, n), order='F')
       
        print("saving x array")
        np.save("/common/shaha4/shaha4/x_1.npy", x_1)
        np.save("/common/shaha4/shaha4/x_2.npy", x_2)
        np.save("/common/shaha4/shaha4/x_3.npy", x_3)

        # create 3 y sub-arrays
        y_1 = np.reshape(np.log(y.ravel('F')[index_1]), (m, n), order='F')
        y_2 = np.reshape(np.log(y.ravel('F')[index_2]), (m, n), order='F')
        y_3 = np.reshape(np.log(y.ravel('F')[index_3]), (m, n), order='F')

        print("Saving y1 array")

        np.save('/common/shaha4/shaha4/y_1.npy', y_1)
        np.save('/common/shaha4/shaha4/y_2.npy', y_2)
        np.save('/common/shaha4/shaha4/y_3.npy', y_3)
        
        c = ((y_1 - y_2) * (x_2 - x_3) - (y_2 - y_3) * (x_1 - x_2)) / (
                (x_1 ** 2 - x_2 ** 2) * (x_2 - x_3) - (x_2 ** 2 - x_3 ** 2) * (x_1 - x_2))
        
        np.save('/common/shaha4/shaha4/c.npy', c)

        # array values for b slightly diverge
        b = ((y_2 - y_3) - c * (x_2 - x_3) * (x_2 + x_3)) / (x_2 - x_3)
        np.save('/common/shaha4/shaha4/b.npy', b)
        
        sqrt_array = (-1 / (2 * c)).astype('complex')
        s = np.sqrt(sqrt_array)
        np.save('/common/shaha4/shaha4/s.npy', s)
        
        # array values for u slightly diverge
        u = b * s ** 2
        np.save('/common/shaha4/shaha4/u.npy', u)

        # array values for a slightly diverge
        a = y_1 - b * x_1 - c * x_1 ** 2
        np.save('/common/shaha4/shaha4/a.npy', a)

        gauss = np.exp(a + u ** 2 / (2 * s ** 2))
        np.save('/common/shaha4/shaha4/gauss.npy', gauss)

        return u, s, gauss, max_values
