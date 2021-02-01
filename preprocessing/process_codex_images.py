"""Class for processing codex images"""
import numpy as np
from utilities.utility import read_tile_at_z, num2str
from .edof import _calculate_focus_stack


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

        For each image-bearing tile in a CODEX image, process the z-stack and 
        return the EDOF images concatenated in a pseudo-whole slide image form.

        Args:
            cl (int): The cycle number
            ch (int): The channel number
            processor (str): Device to use for computing EDOF (one of CPU, GPU)
        
        Returns:
            images (np.uint16): Concatenated images processed by EDOF
        """
        k = 1
        images = np.array([], dtype=np.uint16) 
        for x in range(self.codex_object.metadata['nx']):
            images_temp = np.array([], dtype=np.uint16)
            if x % 2 == 0:
                y_range = range(start=self.codex_object.metadata['ny'], step=-1, stop=0)
            else:
                y_range = range(stop=self.codex_object.metadata['ny'])


            for y in y_range:
                print("Processing : " + self.codex_object.metadata['marker_names_array'][cl][ch] + " CL: " + str(cl) + " CH: " + str(ch) + " X: " + str(x) + " Y: " + str(y))
                image_s = np.zeros((self.codex_object.metadata['tileWidth'], self.codex_object.metadata['tileWidth'],
                                    self.codex_object.metadata['nz']))
                for z in range(self.codex_object.metadata['nz']):
                    image = read_tile_at_z(self.codex_object, cl, ch, x, y, z)
                    if image is None:
                       raise Exception("Image at above path isn't present")
                    image_s[:, :, z] = image

                image = _calculate_focus_stack(image_s)

                images_temp = np.hstack((images_temp, image))
                k += 1

            images = np.vstack((images, images_temp))

        return images


    def background_subtraction(self, image):
        """ Apply background subtraction 

        Args:
            image: Input images withe EDOF applied

        Returns:
            image: Image with background subtracted
        """
        pass


    def cycle_alignment_get_transform(self, image, cl):
        """ Get and stash a cycle alignment transformation

        Populate self.codex_object.cycle_alignment{cl}

        Args:
            image: A DAPI channel image from any cycle after the first
        """
        pass


    def cycle_alignment_apply_transform(self, image, cl):
        """ Get and stash a cycle alignment transformation

        Assert that self.codex_object.cycle_alginment{cl} exists
        If no transform is found, calculate it
        Apply the transform

        Args:
            image: Any channel image from any cycle after the first

        Returns:
            aligned_image
        """
        pass



    def cycle_alignment_apply_transform(self, image, cl):
        """ Get and stash a cycle alignment transformation

        Assert that self.codex_object.cycle_alginment{cl} exists
        If no transform is found, calculate it
        Apply the transform

        Args:
            image: Any channel image from any cycle after the first

        Returns:
            aligned_image
        """
        pass


    def stitch_images(self, image):
        """ Stitch neighboring tiles in an orderly fashion

        Args:
            image: Any channel image

        Returns:
            aligned_image
        """
        pass
