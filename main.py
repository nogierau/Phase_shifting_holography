from structures import Stack, Map, Hologram, BinaryMap
from volumes import Zeros, Ones, Box, Ellipsoid
from visuals import RealImage2D
import numpy as np

# TODO image scales
# TODO data visualization for 3D maps
# TODO data visualization for complex values
# TODO image plotting : make wrapper instead of parent class
# TODO generic Map() zero-padding + replace Box().__init__() consequently
# TODO keep BinaryMap if relevant -> as a decorator


if __name__ == '__main__':

    a = Ellipsoid(shape=(11,11), center=(5,5), radii=(5,5))
    b = Ones(shape=(4,3))
    c = Map(values=np.array([1,2,3,4]))

    x = b.extend_to(new_shape=(4,2,3), axis=(0,2))
    print(x.values)
    print(x)

    print(type(Map))