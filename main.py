from structures import Stack, Map, Hologram, BinaryMap
from volumes import Box, Ones, Ellipsoid, Zeros, Sphere, Cube, Cylinder
from plotting_tools import RealImage2D
import numpy as np

# TODO image scales
# TODO data visualization for 3D maps
# TODO data visualization for complex values
# TODO image plotting : make wrapper instead of parent class
# TODO generic Map() zero-padding + replace Box().__init__() consequently


if __name__ == '__main__':

    a = Ellipsoid(shape=(11,11), center=(5,5), radii=(5,5))
    b = Ones(shape=4)

    ab = BinaryMap.extrude_(b, a)

    print(ab.values)