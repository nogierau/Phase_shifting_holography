from structures import Stack, Map, Hologram, BinaryMap
from shape_presets import Box, Ones, Sphere
import numpy as np

# TODO image scales
# TODO extrusion for binary shapes
# TODO data visualization for 2D and 3D, real and complex


if __name__ == '__main__':

    a = Box(shape=(4,5,6), region=[(1,3), (1,4), (1,5)])

    b = Sphere(shape=(10,10), center=(0,0), radii=(10,10))

    s = Stack(slices=[a, b])
    print(s[1].values)
