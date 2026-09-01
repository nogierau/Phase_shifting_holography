import numpy as np
from typing import Self


class Map:
    """Generic n-dimensional array-like object"""

    def __init__(self, values:np.ndarray=0):
        self.values = np.asarray(values)


class Hologram(Map):
    """Generic 2-dimensional Map() sub-instance with real positive values,
    representing a hologram"""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.initial_phase = None

    def read_initial_phase(self) -> float:
        pass


class BinaryMap(Map):
    """Generic n-dimensional Map() sub-instance with binary values,
    representing a solid shape in n dimensions"""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def extrude(self, other:Self) -> Self:
        pass


class Stack:
    """Generic 1-dimensional set of Map() instances"""

    def __init__(self, slices:list[Map]):
        self.slices = slices

    def __getitem__(self, item):
        return self.slices[item]
