"""Main script to perform steps"""

# Break this file atomically once we implement new steps

# Step 1: Pre-processing

from model import codex, metadata
from preprocessing import process_codex_images, xml_decoder
import pandas as pd
from pathlib import Path
import numpy as np

if __name__ == '__main__':

    dataset_metadata = pd.read_csv(filepath_or_buffer='./utilities/CODEX_dataset_metadata.csv')

    codex_object = codex.Codex(dataset=dataset_metadata, index=31)

    print(codex_object)

    base_path = Path(codex_object.data_path + "/" + codex_object.sample_id)

    cycle_folders = [folder for folder in base_path.iterdir() if folder.is_dir()]
    cycle_folders = cycle_folders[1:]

    xml_file_path = list(base_path.glob('.xml'))
    xlif_file_path = cycle_folders[1] / 'Metadata' / 'TileScan 1.xlif'

    with open(xml_file_path[0], 'r') as f, open(xlif_file_path, 'r') as g:
        xml_content = f.read()
        xlif_content = g.read()

    codex_metadata = metadata.Metadata(file_content=[xml_content, xlif_content], decoder=xml_decoder.XMLDecoder())

    metadata_dict = codex_metadata.decode_metadata(cycle_folders=cycle_folders)

    print("Codex metadata is: " + str(metadata_dict))

    codex_object.metadata = metadata_dict

    process_codex = process_codex_images.ProcessCodex(codex_object=codex_object)

    for channel in range(codex_object.metadata['nch']):
        for cycle in range(codex_object.metadata['ncl']):
            image = process_codex.apply_edof(cycle, channel)
            print("EDOF done. Saving file.")
            np.save(file='edof.npy', arr=image)