from base_structure import Map
import numpy as np


class Wavefront(Map):

    def __init__(self, amplitude:Map, phase:Map): # TODO add check for same scale
        super().__init__(values=amplitude.values * np.exp(1j * phase.values))


class SimpleHologram(Map):
    """Generic class for 2-dimensional Map() sub-instance with real positive values,
    representing a hologram"""

    def __init__(self, wavefront:Wavefront, q_vector:tuple, initial_phase:float=0.):
        pass

    def read_initial_phase(self) -> float: # TODO
        pass

class OpticalHologram(Map):
    pass