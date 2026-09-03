from base_structure import Stack, Grid, Hologram, BinaryGrid, Generator
from volumes import Zeros, Ones, Box, Ellipsoid
from visuals import RealImage2D
import numpy as np

# TODO image scales
# TODO data visualization for 3D maps
# TODO data visualization for complex values
# TODO image plotting : make wrapper instead of parent class
# TODO reduce BinaryGrid values to 1-bit size instead of full 64-bits (bool ?)
# TODO proper separation of Grid() and Map() with @keep_relevant_class
# TODO Grid() compatibility with vectorial values


if __name__ == '__main__':

    f = lambda x:np.sum(x)
    g = lambda y:-np.sum(y)

    # vol = Box(shape=(100, 100), region=[(10,-10), (20,-20)])
    vol = Ellipsoid(shape=(100,100), center=(80,5), radii=(30, 65))
    print(vol.values)

    a = Generator(func=f, volume=vol, fallback=g, dtype=int)

    b = a.zero_padding(border_width=15)

    RealImage2D.show(b)