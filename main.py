from base_structure import Stack, Grid, Volume, Template, Map
from volumes import Zeros, Ones, Box, Ellipsoid
from visuals import RealImage2D
from optics import Wavefront
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
    g = lambda x:1.

    v = Box(shape=(5,5), region=[(1,-1), (2,-2)])

    p = Template(func=f, volume=v)
    a = Template(func=g, volume=v, fallback=g)

    w = Wavefront(amplitude=a, phase=p)

    print(w.shape)
    print(w[2,2])
    print(w.values)

