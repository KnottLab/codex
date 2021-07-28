import argparse
import numpy as np

if __name__ == '__main__':
    alphabet = list('abcdefghijklmnopqrstuvwxyz1234567890')

    parser = argparse.ArgumentParser(description='Codex pipeline arguments')
   
    parser.add_argument('--data_path', metavar='Data path', type=str, required=True, help='Data path to read CODEX raw data')
    parser.add_argument('--sample_id', metavar='Sample ID', type=str, required=True, help='Sample ID for the codex data')
    parser.add_argument('--output_path', metavar='Output path', type=str, required=True, help='Output path for results')
    parser.add_argument('--xml_path', metavar='XML file path', type=str, required=True, help='Experiment XML information')
    parser.add_argument('--region', type=int, required=True, help='Region number from the multiple regions to scan from')
    parser.add_argument('-j', type=int, default=1, required=False, help='Number of CPUs to use')
    parser.add_argument('--debug', action='store_true', help='Whether to make and save intermediate images')
    parser.add_argument('--debug_stitching', action='store_true', 
                        help='Whether to make and save intermediate stitching images for every single tile.')
    parser.add_argument('--ray_object_store_bytes', type=int, default=None,
                        help='Size of shared memory for ray processes, in bytes. '+\
                             '~16-32GB should be more than enough. Default is to auto-set according to the ray settings.')
    parser.add_argument('--short_name', type=str, default=''.join(np.random.choice(alphabet, 5)), 
                                        help='to make the ray temp dir unique')
    parser.add_argument('--clobber', action='store_true', help='Whether to always overwrite existing output. default=False')
    parser.add_argument('--get_shading_input', action='store_true', 
                         help='Save the result of EDOF only and exit. '+\
                              'This should be used to process a flatfield and darkfield image for the sample '+\
                              'in order to apply a uniform shading correction to each tile & region.')
    parser.add_argument('--precomputed_shading', type=str, default=None, required=False, 
                         help='If set, use the flatfield and darkfield images at the given path '+\
                              'instead of estimating for each region.')

                                                      
    args = parser.parse_args()
