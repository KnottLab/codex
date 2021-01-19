"""Class defining metadata for codex object"""
from json import JSONDecoder
from preprocessing.xml_decoder import XMLDecoder


class Metadata:

    def __init__(self, file_content, decoder=JSONDecoder()):
        self.file_content = file_content
        self.decoder = decoder
        self.metadata = dict()

    def decode_metadata(self, roi=None, nx=None, ny=None, markers=None, marker_names=None, exposure_times=None,
                        cycle_folders=None):
        """Implement your own XML decoder"""
        if isinstance(self.decoder, XMLDecoder):
            self.metadata = self.decoder.decode(file_content_xml=self.file_content[0],
                                                file_content_xlif=self.file_content[1],
                                                cycle_folders=cycle_folders)
        else:
            decoded_data = self.decoder.decode(s=self.file_content)
            # Want to use default dict instead?
            self.metadata['ncl'] = decoded_data.get('numCycles')
            self.metadata['nch'] = decoded_data.get('numChannels')
            self.metadata['nx'] = nx or decoded_data.get('regionHeight')
            self.metadata['ny'] = ny or decoded_data.get('regionWidth')
            self.metadata['nz'] = decoded_data.get('numZPlanes')
            self.metadata['ox'] = decoded_data.get('tileOverlapX')
            self.metadata['oy'] = decoded_data.get('tileOverlapY')
            self.metadata['tileWidth'] = decoded_data.get('tileWidth')
            self.metadata['width'] = decoded_data.get('width')
            self.metadata['tileHeight'] = decoded_data.get('tileHeight')
            self.metadata['height'] = decoded_data.get('height')
            self.metadata['resolution'] = 0.001 * decoded_data.get('xyResolution')
            self.metadata['wavelengths'] = decoded_data.get('wavelengths')
            self.metadata['roi'] = roi
            self.metadata['cycle_folders'] = []
            self.metadata['markers'] = markers
            self.metadata['marker_names'] = marker_names
            self.metadata['exposure_times'] = exposure_times

        return self.metadata
