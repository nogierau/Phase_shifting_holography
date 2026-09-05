from base_structure import Map
import numpy as np


class Wavefront(Map):

    def __init__(self, amplitude:Map, phase:Map): # TODO add check for same scale
        super().__init__(values=amplitude.values * np.exp(1j * phase.values))


class SimpleHologram(Map):
    """Generic class for 2-dimensional Map() sub-instance with real positive values,
    representing a hologram"""

    def __init__(self, wavefront:Wavefront):
        super().__init__(values=np.pow(np.abs(1 + wavefront.values), 2))

    def read_initial_phase(self) -> float: # TODO
        pass

class OpticalHologram(Map):
    pass