from structures import Stack, Map, Hologram, BinaryMap
from shape_presets import Box, Ones, Sphere
from plotting_tools import Image2D
import numpy as np

# TODO image scales
# TODO extrusion for binary shapes
# TODO data visualization for 3D maps
# TODO data visualization for complex values
# TODO image plotting : make wrapper instead of parent class


if __name__ == '__main__':

    a = BinaryMap(values=np.array([1,1,1,1,0,0,0,0]))
    b = BinaryMap(values=np.array([1,1,0,0,1,1,0,0]))
    c = BinaryMap(values=np.array([1,0,1,0,1,0,1,0]))

    k = BinaryMap(values=np.array([[0,1,1], [1,0,1]]))

    x = b.extend_to(new_shape=(2, 3, 8), axis=2)

    y = BinaryMap.extrude(k, a)
    print(y.values)

