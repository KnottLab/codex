"""Class representing the CODEX object"""


class Codex:
    """Metadata is to be read from JSON and XML files"""

    def __init__(self, dataset, index):
        self.sample_id = dataset.at[index, 'sample_id']
        self.data_path = dataset.at[index, 'data_path']
        self.fixation = dataset.at[index, 'fixation']
        self.organ = dataset.at[index, 'organ']
        self.species = dataset.at[index, 'species']
        self.lab = dataset.at[index, 'lab']
        self.processed = dataset.at[index, 'processed']
        self.processor = dataset.at[index, 'processor']
        self._metadata = None

    @property
    def metadata(self):
        return self._metadata

    @metadata.setter
    def metadata(self, value):
        self._metadata = value

    @metadata.deleter
    def metadata(self):
        del self._metadata
