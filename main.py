from base_structure import Stack, Grid, Volume, Template
from volumes import Zeros, Ones, Box, Ellipsoid
from visuals import RealImage2D
from optics import SimpleHologram
import numpy as np

# TODO image scales
# TODO data visualization for 3D maps
# TODO data visualization for complex values
# TODO image plotting : make wrapper instead of parent class
# TODO reduce Volume() values to 1-bit size instead of full 64-bits (bool ?)
# TODO proper separation of Grid() and Map() and the like with @keep_relevant_class
# TODO Grid() compatibility with vectorial values


if __name__ == '__main__':

    f = lambda x:np.pi
    g = lambda y:0.8
    h = lambda z:1.

    square = Box(shape=(100,100), region=[(20,-20), (20,-20)])

    phase = Template(func=f, volume=square)
    amplitude = Template(func=g, volume=square, fallback=h)

    print(phase.values)

    RealImage2D.show(amplitude)