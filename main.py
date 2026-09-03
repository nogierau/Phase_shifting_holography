from base_structure import Stack, Grid, Hologram, BinaryGrid
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

    a = Grid(values=np.array([(1,2), (4,5), (7,8)]))

    print(a.values)
    b = a.zero_padding(border_width=2)

    print(b.values)