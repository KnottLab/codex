"""Class for processing codex images"""
import numpy as np
from utilities.utility import read_tile_at_z, corr2
from .edof import calculate_focus_stack
from image_registration import chi2_shift
from image_registration.fft_tools import shift
from skimage.morphology import octagon
import cv2
from pybasic.pybasic import basic


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
        k = 1
        images = None
        for x in range(self.codex_object.metadata['nx'] + 1):
            images_temp = None
            if (x + 1) % 2 == 0:
                y_range = range(self.codex_object.metadata['ny'], -1, -1)
            else:
                y_range = range(self.codex_object.metadata['ny'] + 1)

            for y in y_range:
                print("Processing : " + self.codex_object.metadata['marker_names_array'][cl][ch] + " CL: " + str(
                    cl) + " CH: " + str(ch) + " X: " + str(x) + " Y: " + str(y))
                image_s = np.zeros((self.codex_object.metadata['tileWidth'], self.codex_object.metadata['tileWidth'],
                                    self.codex_object.metadata['nz']))

                if self.codex_object.metadata['real_tiles'][x,y] != '':
                    for z in range(self.codex_object.metadata['nz']):
                        image = read_tile_at_z(self.codex_object, cl, ch, x, y, z)
                        if image is None:
                            raise Exception("Image at above path isn't present")
                        image_s[:, :, z] = image

                    image = calculate_focus_stack(image_s)

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
        image[not (image > 0 and background_1 > 0 and background_2 > 0)] = 0
        return image

    def cycle_alignment_get_transform(self, image_ref, image):
        """ Get and stash a cycle alignment transformation

        Populate self.codex_object.cycle_alignment{cl}

        We use chi2_shift algorithm from astropy to register the image.

        Args:
            image: A DAPI channel image from any cycle after the first
        """
        width = self.codex_object.metadata['tileWidth']
        shift_list = []
        initial_correlation_list = []
        final_correlation_list = []
        print("Calculating cycle alignment")
        for x in range(self.codex_object.metadata['nx']):
            for y in range(self.codex_object.metadata['ny']):
                if self.codex_object.metadata['real_tiles'][x,y] == '':
                    continue
                image_ref_subset = image_ref[x * width:(x + 1) * width, y * width:(y + 1) * width]
                image_subset = image[x * width:(x + 1) * width, y * width:(y + 1) * width]
                print(image_subset.shape)
                xoff, yoff, exoff, eyoff = chi2_shift(image_ref_subset, image_subset, return_error=True,
                                                      upsample_factor='auto')
                shift_list.append((xoff, yoff))
                initial_correlation = corr2(image_subset, image_ref_subset)
                initial_correlation_list.append(initial_correlation)
                image_subset = shift.shift2d(image_subset, -xoff, -yoff)
                final_correlation = corr2(image_subset, image_ref_subset)
                final_correlation_list.append(final_correlation)

        print("Shift list size is: " + str(len(shift_list)))
        print(shift_list)
        cycle_alignment_info = {"shift": shift_list, "initial_correlation": initial_correlation_list,
                                "final_correlation": final_correlation_list}
        return cycle_alignment_info, image

    def cycle_alignment_apply_transform(self, image_ref, image, cycle_alignment_info):
        """ Get and stash a cycle alignment transformation

        Assert that self.codex_object.cycle_alginment{cl} exists
        If no transform is found, calculate it
        Apply the transform

        Args:
            image: Any channel image from any cycle after the first

        Returns:
            aligned_image
        """
        print("Applying cycle alignment")
        width = self.codex_object.metadata['tileWidth']
        shift_list = cycle_alignment_info.get('shift')
        initial_correlation_list = []
        final_correlation_list = []
        for x in range(self.codex_object.metadata['nx']):
            for y in range(self.codex_object.metadata['ny']):

                if self.codex_object.metadata['real_tiles'][x,y] == '':
                    continue

                xoff, yoff = shift_list[x + 3 * y]
                image_ref_subset = image_ref[x * width:(x + 1) * width, y * width:(y + 1) * width]
                image_subset = image[x * width:(x + 1) * width, y * width:(y + 1) * width]
                initial_correlation = corr2(image_ref_subset, image_subset)
                initial_correlation_list.append(initial_correlation)
                image_subset = shift.shift2d(image_subset, -xoff, -yoff)
                final_correlation = corr2(image_ref_subset, image_subset)
                final_correlation_list.append(final_correlation)
        return image

    def shading_correction(self, image, cycle, channel):
        image_list = []
        print("Shading correction started for cycle {} and channel {}".format(cycle, channel))
        width = self.codex_object.metadata['tileWidth']
        for x in range(self.codex_object.metadata['nx'] + 1):
            for y in range(self.codex_object.metadata['ny'] + 1):
                image_subset = image[x * width : (x + 1) * width, y * width : (y + 1) * width]
                image_list.append(image_subset)
        image_array = np.dstack(image_list)
        print("Image array has shape {}".format(image_array.shape))
        flatfield, darkfield = basic(images=image_array, segmentation=None)
        print("Flatfield has shape {} and darkfield has shape {}".format(flatfield.shape, darkfield.shape))
        np.save(file='flatfield.npy', arr=flatfield)
        np.save(file='darkfield.npy', arr=darkfield)
        for x in range(self.codex_object.metadata['nx'] + 1):
            for y in range(self.codex_object.metadata['ny'] + 1):
                image_subset = image[x * width:(x + 1) * width, y * width: (y + 1) * width]
                image[x * width: (x+1) * width, y * width : (y+1) * width] = ((image_subset.astype('double') - darkfield) / flatfield).astype('uint16')

        return image + 1

    def stitch_images(self, image, image_width, overlap_width, j, mask, stitching_object, cycle, channel):
        """ Stitch neighboring tiles in an orderly fashion

        Args:
            image: Any channel image

        Returns:
            aligned_image:
        """
        pass