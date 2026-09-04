from base_structure import Map


class SimpleHologram(Map):
    """Generic class for 2-dimensional Map() sub-instance with real positive values,
    representing a hologram"""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.initial_phase = None
        self.q_vector = None

    def read_initial_phase(self) -> float: # TODO
        pass

class OpticalHologram(Map):
    pass