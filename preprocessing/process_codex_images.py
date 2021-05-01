"""Class for processing codex images"""
import numpy as np
from utilities.utility import read_tile_at_z, corr2
from .edof import edof_loop
from image_registration import chi2_shift
from image_registration.fft_tools import shift
from skimage.morphology import octagon
import cv2
import ray
from pybasic import basic


class ProcessCodex:
    """ Preprocessing modules to prepare CODEX scans for analysis

    Required modules
    - Extended Depth of Field (EDOF)
    - Background subtraction
    - Cycle alignment
    - Stitching

    Optional modules:
    - Leica deformation correction


    Module descriptions

    EDOF
    - Find the z-plane with the sharpest focus for each location in an image

    Background subtraction
    - Get background intensity for each tile from the first Blank channel 
        at the given wavelength
    - Subtract background from each channel of every cycle

    Cycle alignment
    - Landmark alignment between imaging cycles
    - Reference is always the first DAPI channel
    - For each cycle estimate the warping transformation that aligns the current 
        cycle’s DAPI channel to the reference DAPI.
    - Save the transform parameters
    - Apply the same transform to all non-DAPI channels for each cycle

    Stitching
    - Join adjacent tiles by matching the content of their overlapping areas
    - Estimate the correlation in the overlapping regions between all tiles
    - Starting at the best correlation, perform stitching
    - Continue with the next best correlation, etc. 


    Args:
        codex_object (Codex): Codex metadata to use

    """

    def __init__(self, codex_object):
        self.codex_object = codex_object

    def apply_edof(self, cl, ch, processor='CPU'):
        """ Select in-focus planes from a z-stack

        For each tile in a CODEX image, load the data, process the z-stack and 
        return the EDOF images concatenated in a pseudo-whole slide image form.

        Args:
            cl (int): The cycle number
            ch (int): The channel number
            processor (str): Device to use for computing EDOF (one of CPU, GPU)
        
        Returns:
            images (np.uint16): Concatenated images processed by EDOF
        """
        images = None
        futures = []
        for x in range(self.codex_object.metadata['nx']):
            if (x + 1) % 2 == 0:
                y_range = range(self.codex_object.metadata['ny']-1, -1, -1)
            else:
                y_range = range(self.codex_object.metadata['ny'])

            for y in y_range:
                if self.codex_object.metadata['real_tiles'][x,y]=='x':
                    continue
                print("Building remote function for : " + self.codex_object.metadata['marker_names_array'][cl][ch] + \
                      " CL: " + str(cl) + " CH: " + str(ch) + " X: " + str(x) + " Y: " + str(y))

                futures.append(edof_loop.remote(self.codex_object, cl, ch, x, y))


        print("Running EDOF functions remotely")
        edof_images = ray.get(futures)
        k = 0
        print("Assembling EDOF images for channel")
        for x in range(self.codex_object.metadata['nx']):
            images_temp = None
            if (x + 1) % 2 == 0:
                y_range = range(self.codex_object.metadata['ny']-1, -1, -1)
            else:
                y_range = range(self.codex_object.metadata['ny'])

            for y in y_range:
                if self.codex_object.metadata['real_tiles'][x,y]=='x':
                    image = np.zeros((self.codex_object.metadata['tileWidth'], 
                                      self.codex_object.metadata['tileWidth']),
                                     dtype=np.uint16)
                else:
                    image = edof_images[k]
                    k += 1


                if images_temp is None: # Build row
                    images_temp = image
                else:
                    #print(f'concatenating images: {image.shape} {images_temp.shape}')
                    if (x + 1) % 2 == 0:
                        images_temp = np.concatenate((image, images_temp), 1)
                    else:
                        #print(f'concatenating images: {images_temp.shape} {image.shape}')
                        images_temp = np.concatenate((images_temp, image), 1)
                print(f'building row {images_temp.shape}')

            if images is None:
                images = images_temp
            else:
                #print(f'concatenating rows: {images.shape} {images_temp.shape}')
                images = np.concatenate((images, images_temp), 0)
            print(f'building columns {images.shape} placed {k} tiles so far')
            print(images.shape)

        return images


    def background_subtraction(self, image, background_1, background_2, cycle, channel):
        """ Apply background subtraction 

        Args:
            image: Input images with EDOF applied

        Returns:
            image: Image with background subtracted
        """
        print("Background subtraction started for cycle {0} and channel {1}".format(cycle, channel))

        background_1[background_1 > image] = image[background_1 > image]
        background_2[background_2 > image] = image[background_2 > image]
        kernel_1 = octagon(1, 1)
        image = cv2.morphologyEx(image, cv2.MORPH_CLOSE, kernel_1)
        background_1 = cv2.morphologyEx(background_1, cv2.MORPH_CLOSE, kernel_1)
        background_2 = cv2.morphologyEx(background_2, cv2.MORPH_CLOSE, kernel_1)
        kernel_2 = octagon(5, 2)
        image = cv2.morphologyEx(image, cv2.MORPH_TOPHAT, kernel_2)
        background_1 = cv2.morphologyEx(background_1, cv2.MORPH_TOPHAT, kernel_2)
        background_2 = cv2.morphologyEx(background_2, cv2.MORPH_TOPHAT, kernel_2)
        a = (self.codex_object.metadata['ncl'] - cycle - 1) / (self.codex_object.metadata['ncl'] - 3)
        b = 1 - a
        image = image - a * background_1 - b * background_2
        image = image + 1
        image[np.logical_not(np.logical_and(np.logical_and(image > 0, background_1 > 0), background_2 > 0))] = 0

        return image.astype(np.uint16)

    # @ray.remote
    # def _get_transform(self, image_ref, image, x, y, width):
    #     image_ref_subset = image_ref[x * width:(x + 1) * width, y * width:(y + 1) * width]
    #     image_subset = image[x * width:(x + 1) * width, y * width:(y + 1) * width]
    #     print(image_subset.shape)
    #     xoff, yoff, exoff, eyoff = chi2_shift(image_ref_subset, image_subset, return_error=True,
    #                                           upsample_factor='auto')

    #     initial_correlation = corr2(image_subset, image_ref_subset)
    #     final_correlation = corr2(image_subset, image_ref_subset)
    #     return xoff, yoff, initial_correlation, final_correlation

    def cycle_alignment_get_transform(self, image_ref, image):
        """ Get and stash a cycle alignment transformation

        Populate self.codex_object.cycle_alignment{cl}

        We use chi2_shift algorithm from astropy to register the image.

        Args:
            image: A DAPI channel image from any cycle after the first
        """

        print("Putting image_ref and image into RAY shared memory")
        image_ref_shared = ray.put(image_ref)
        image_shared = ray.put(image)

        width = self.codex_object.metadata['tileWidth']
        futures = []
        print("Making cycle alignment jobs")
        for x in range(self.codex_object.metadata['nx']):
            for y in range(self.codex_object.metadata['ny']):
                if self.codex_object.metadata['real_tiles'][x,y]=='x':
                    continue
                futures.append(get_transform.remote(image_ref_shared, image_shared, x, y, width))

        print("Running cycle alignment jobs remotely")
        alignment_info = ray.get(futures)
        k = 0
        shift_list = []
        initial_correlation_list = []
        final_correlation_list = []
        for x in range(self.codex_object.metadata['nx']):
            for y in range(self.codex_object.metadata['ny']):
                if self.codex_object.metadata['real_tiles'][x,y]=='x':
                    continue
                xoff, yoff, initial_correlation, final_correlation = alignment_info[k]

                image_ref_subset = image_ref[x * width:(x + 1) * width, y * width:(y + 1) * width]
                image_subset = image[x * width:(x + 1) * width, y * width:(y + 1) * width]

                shift_list.append((xoff, yoff))
                initial_correlation_list.append(initial_correlation)
                image_subset = shift.shift2d(image_subset, -xoff, -yoff)
                final_correlation_list.append(final_correlation)
                k+=1

        print("Shift list size is: " + str(len(shift_list)))
        print(shift_list)
        cycle_alignment_info = {"shift": shift_list, "initial_correlation": initial_correlation_list,
                                "final_correlation": final_correlation_list}

        del image_ref_shared
        del image_shared

        return cycle_alignment_info


    def cycle_alignment_apply_transform(self, image_ref, image, cycle_alignment_info, cycle, channel, cycle_alignment_dict):
        """ Get and stash a cycle alignment transformation

        Assert that self.codex_object.cycle_alginment{cl} exists
        If no transform is found, calculate it
        Apply the transform

        This function modifies `image` 

        Args:
            image: Any channel image from any cycle after the first

        Returns:
            aligned_image
        """
        print("Applying cycle alignment")
        width = self.codex_object.metadata['tileWidth']
        shift_list = cycle_alignment_info.get('shift')
        shift_index = 0
        x_list = cycle_alignment_dict.get('x_coordinate')
        y_list = cycle_alignment_dict.get('y_coordinate')
        cycle_list = cycle_alignment_dict.get('cycle')
        channel_list = cycle_alignment_dict.get('channel')
        initial_corr_list = cycle_alignment_dict.get('initial_correlation')
        final_corr_list = cycle_alignment_dict.get('final_correlation')
        
        for x in range(self.codex_object.metadata['nx']):
            for y in range(self.codex_object.metadata['ny']):
                if self.codex_object.metadata['real_tiles'][x,y]=='x':
                    continue
                xoff, yoff = shift_list[shift_index] 
                shift_index += 1

                image_ref_subset = image_ref[x * width:(x + 1) * width, y * width:(y + 1) * width]
                image_subset = image[x * width:(x + 1) * width, y * width:(y + 1) * width]
                initial_correlation = corr2(image_ref_subset, image_subset)
                image_subset = shift.shift2d(image_subset, -xoff, -yoff)
                final_correlation = corr2(image_ref_subset, image_subset)
                image[x * width:(x + 1) * width, y * width:(y + 1) * width] = image_subset
                x_list.append(x)
                y_list.append(y)
                cycle_list.append(cycle)
                channel_list.append(channel)
                initial_corr_list.append(initial_correlation)
                final_corr_list.append(final_correlation)

        return image, cycle_alignment_dict


    def shading_correction(self, image, cycle, channel):
        image_list = []
        print("Shading correction started for cycle {} and channel {}".format(cycle, channel))
        width = self.codex_object.metadata['tileWidth']
        for x in range(self.codex_object.metadata['nx']):
            for y in range(self.codex_object.metadata['ny']):
                if self.codex_object.metadata['real_tiles'][x,y]=='x':
                    continue
                image_subset = image[x * width : (x + 1) * width, y * width : (y + 1) * width]
                image_list.append(image_subset)

        image_array = np.dstack(image_list)
        print("Image array has shape {}".format(image_array.shape))
        flatfield, darkfield = basic(images=image_array, segmentation=None)
        print("Flatfield has shape {} and darkfield has shape {}".format(flatfield.shape, darkfield.shape))
        for x in range(self.codex_object.metadata['nx']):
            for y in range(self.codex_object.metadata['ny']):
                image_subset = image[x * width:(x + 1) * width, y * width: (y + 1) * width]
                image[x * width: (x+1) * width, y * width : (y+1) * width] = ((image_subset.astype('double') - darkfield) / flatfield).astype('uint16')

        return image + 1


@ray.remote
def get_transform(image_ref, image, x, y, width):
    image_ref_subset = image_ref[x * width:(x + 1) * width, y * width:(y + 1) * width]
    image_subset = image[x * width:(x + 1) * width, y * width:(y + 1) * width]
    print(image_subset.shape)
    xoff, yoff, exoff, eyoff = chi2_shift(image_ref_subset, image_subset, return_error=True,
                                            upsample_factor='auto')

    initial_correlation = corr2(image_subset, image_ref_subset)
    final_correlation = corr2(image_subset, image_ref_subset)
    return xoff, yoff, initial_correlation, final_correlation
