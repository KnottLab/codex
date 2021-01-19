"""XML decoder for CODEX"""

import xml.etree.ElementTree as ET
import numpy as np
import math


class XMLDecoder:

    def __init__(self):
        self.decoded_content = dict()

    def _number_of_cycles(self, root):
        number = 0
        exposures = root.find('Exposures')
        for item in exposures.findall('ExposureItem'):
            active = item.find('Active').text
            if active == 'true':
                number += 1
        return number

    def _number_of_channels(self, root):
        channels = root.find('Channels')
        number = len(channels.findall('string'))
        return number

    def _number_of_xy_tiles(self, root):
        attachment = root.find('Element').find('Data').find('Image').find('Attachment')
        x = 0
        y = 0
        for tile in attachment.findall('Tile'):
            x = max(int(tile.get('FieldX')), x)
            y = max(int(tile.get('FieldY')), y)

        return x, y

    def _number_of_z_stacks(self, root):
        z_stacks = int(root.find('ZstackDepth').text)
        return z_stacks

    def _get_tile_width(self, root):
        dimension = root.find('Element').find('Data').find('Image').find('ImageDescription').find('Dimensions')
        width = int(dimension.find('DimensionDescription').get("NumberOfElements"))
        height = int(dimension.find('DimensionDescription').get('NumberOfElements'))
        overlap_x = 0
        overlap_y = 0

        attachments = root.find('Element').find('Data').find('Image').findall('Attachments')
        for a in attachments:
            if a.get("Name") == "HardwareSetting":
                atl = a.find("ATLCameraSettingDefinition")
                xy = atl.find('XYStageConfiguratorSettings')
                stitch = xy.find('StitchingSettings')
                overlap_x = float(stitch.get('OverlapPercentageX'))
                overlap_y = float(stitch.get('OverlapPercentageY'))

        overlap_width = math.floor((1 - overlap_x) * width)
        overlap_height = math.floor((1 - overlap_y) * height)

        return width, height, overlap_x, overlap_y, overlap_width, overlap_height

    def _get_resolutionh(self, root):
        dimension = root.find('Element').find('Data').find('Image').find('ImageDescription').find('Dimensions')
        width = int(dimension.find('DimensionDescription').get("NumberOfElements"))
        length = int(dimension.find('DimensionDescription').get('Length'))

        return (10 ^ 6) * length / width

    def _get_marker_names(self, root, num_cycles, num_channels):
        exposure_items = root.find('Exposures').findall('ExposureItem')
        marker_list = []
        marker_names = []
        for item in exposure_items:
            antibody = item.find('AntiBody').findall('string')
            for a in antibody:
                marker_names.append(a.text)

        for i, marker in iter(marker_names):
            marker_list[i] = marker + '_' + i

        marker_names_array = np.array(marker_names)
        marker_names_array = marker_names_array.reshape(shape=[num_cycles, num_channels], order='F')
        marker_list = np.array(marker_list)
        marker_array = marker_list.reshape(shape=[num_cycles, num_channels], order='F')
        return marker_names, marker_list, marker_array, marker_names_array

    def _get_exposure_times(self, root):
        exposure_item = root.find('Exposures').find('ExposureItem')
        exposure_time = exposure_item.find('ExposuresTime')
        decimal_values = []
        for decimal in exposure_time.findall('decimal'):
            decimal_values.append(int(decimal.text))
        return decimal_values

    def _get_wavelengths(self, root):
        exposure_item = root.find('Exposures').find('ExposureItem')
        wavelength = exposure_item.find('WaveLength')
        wavelength_values = []
        for values in wavelength.findall('decimal'):
            wavelength_values.append(int(values.text))
        return wavelength_values

    def _get_channels(self, root):
        channels = root.find("Channels")
        channel_names = []
        for name in channels.findall('string'):
            channel_names.append(name.text)
        return channel_names

    def decode(self, file_content_xml, file_content_xlif, cycle_folders):
        root_xml = ET.fromstring(file_content_xml)
        root_xlif = ET.fromstring(file_content_xlif)
        self.decoded_content['roi'] = 1
        self.decoded_content['ncl'] = self._number_of_cycles(root_xml)
        self.decoded_content['cycle_folders'] = cycle_folders
        self.decoded_content['nch'] = self._number_of_channels(root_xml)
        self.decoded_content['nz'] = self._number_of_z_stacks(root_xml)
        self.decoded_content['nx'], self.decoded_content['ny'] = self._number_of_xy_tiles(root_xlif)
        self.decoded_content['tileWidth'], self.decoded_content['tileHeight'], self.decoded_content['ox'], \
        self.decoded_content['oy'], self.decoded_content['width'], self.decoded_content[
            'height'] = self._get_tile_width(root_xlif)
        self.decoded_content['exposure_times'] = self._get_exposure_times(root_xml)
        self.decoded_content['channels'] = self._get_channels(root_xml)
        self.decoded_content['wavelengths'] = self._get_wavelengths(root_xml)
        self.decoded_content['resolution'] = self._get_resolutionh(root_xlif)
        self.decoded_content['marker_names'], self.decoded_content['markers'], \
        self.decoded_content['maker_array'], self.decoded_content['marker_names_array'] = self._get_marker_names(
            root_xml, self.decoded_content['numCycles'],
            self.decoded_content['numChannels'])

        return self.decoded_content
