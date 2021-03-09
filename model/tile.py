"""Class representing the tile object"""

class Tile:
    """
    This class represents the tile of an image. It can be used to store neighbors of tiles and the like.
    """

    def __init__(self, x, y):
        self._neighbors = None
        self.x = x
        self.y = y
        self._registration_details = None

    @property
    def registration_details(self):
        return self._registration_details

    @registration_details.setter
    def registration_details(self, value):
        self._registration_details = value

    @registration_details.deleter
    def registration_details(self):
        del self._registration_details

    @property
    def neighbors(self):
        return self._neighbors

    @neighbors.setter
    def neighbors(self, value):
        self._neighbors = value

    @neighbors.deleter
    def neighbors(self):
        del self._neighbors

