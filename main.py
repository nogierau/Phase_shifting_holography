from structures import Stack, Map, Hologram, BinaryMap
from shape_presets import Box, Ones, Sphere
from plotting_tools import Image2D
import numpy as np

# TODO image scales
# TODO data visualization for 3D maps
# TODO data visualization for complex values
# TODO image plotting : make wrapper instead of parent class


if __name__ == '__main__':

    a = BinaryMap(values=np.array([1,1,1,1,0,0,0,0]))
    b = BinaryMap(values=np.array([1,1,0,0,1,1,0,0]))
    c = BinaryMap(values=np.array([1,0,1,0,1,0,1,0]))

    x = BinaryMap(values=np.array([[0,0,0,0], [1,1,1,1]]))
    y = BinaryMap(values=np.array([[0,0,1,1], [0,0,1,1]]))
    z = BinaryMap(values=np.array([[0,1,0,1], [0,1,0,1]]))

    abc = BinaryMap.extrude_(x, a)
    print(abc.shape)
    print(abc.values)

