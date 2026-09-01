import matplotlib.pyplot as plt
from typing import override
from structures import Map

class Image:

    @staticmethod
    def show(*args, **kwargs):
        pass


class Image2D(Image):

    @staticmethod
    @override
    def show(el:Map):
        """Generates a view of a 2D Map() instance.
        In case of complex values, the imaginary part is discarded."""
        if el.values.ndim == 2:
            plt.imshow(el.values.real.transpose())
            plt.colorbar()
            plt.show()


class Image3D(Image):

    @staticmethod
    @override
    def show(el: Map):
        pass