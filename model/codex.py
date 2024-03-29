"""Class representing the CODEX object"""


class Codex:
    """Metadata is to be read from JSON and XML files"""

    """
    questions about future useage of the Codex object

    - a concatenation operation for multiple __processed__ objects: Codex1, and Codex2

        Concatenation between the same tissue, we would append to the list of channels,
        and perform a global alignment of Codex1 to Codex2 or vice versa.

        Concatenation between two different samples would require that they were both
        run with the same set of stains, and under similar imaging conditions (wavelenght, exposure time)
        and would result in the side-by-side concat of the images, either actually or virtually
        by shifting the nucleus coordinates.

        Need to track the unique identity of the samples being concatenated.


    - Does it make sense for initialization of a Codex object from a dataset path to immediately
    trigger the preprocessing pipeline?


    - save() method
        questions for save(): save all images somehow within the Codex object -- so the whole thing
        could be structured in HDF5 or ???
        or maintain a data store, like the MATLAB version, where images are stored as loose TIFFs
        and Codex object has hooks to those images? we'd need to manage transferring data to another machine.

    - related to save(), load(), what would that look like?

    """

    def __init__(self, data_path, sample_id, region):
        self.sample_id = sample_id
        self.data_path = data_path
        self.region = region # for processing slides with multiple ROI's
        # self.fixation = dataset.at[index, 'fixation']
        # self.organ = dataset.at[index, 'organ']
        # self.species = dataset.at[index, 'species']
        # self.lab = dataset.at[index, 'lab']
        # self.processed = False # this should be a flag we set only after processing is done
        # self.processor = dataset.at[index, 'processor']
        self._metadata = None
        self._cycle_alignment_info = None
        self._background_1 = None
        self._background_2 = None

    @property
    def background_1(self):
        return self._background_1

    @background_1.setter
    def background_1(self, value):
        self._background_1  = value

    @background_1.deleter
    def background_1(self):
        del self._background_1

    @property
    def background_2(self):
        return self._background_2

    @background_2.setter
    def background_2(self, value):
        self._background_2 = value

    @background_2.deleter
    def background_2(self):
        del self._background_2

    @property
    def cycle_alignment_info(self):
        return self._cycle_alignment_info

    @cycle_alignment_info.setter
    def cycle_alignment_info(self, value):
        self._cycle_alignment_info = value

    @cycle_alignment_info.deleter
    def cycle_alignment_info(self):
        del self._cycle_alignment_info

    @property
    def metadata(self):
        return self._metadata

    @metadata.setter
    def metadata(self, value):
        self._metadata = value

    @metadata.deleter
    def metadata(self):
        del self._metadata


    def __repr__(self):
        return "Codex(sample_ID=%s, data_path=%s)" % (self.sample_id, self.data_path)
