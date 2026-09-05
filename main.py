from base_structure import Stack, Grid, Volume, Template, Map
from volumes import Zeros, Ones, Box, Ellipsoid
from visuals import RealImage2D
from optics import Wavefront, SimpleHologram
from presets import GradientTemplatePreset, ConstantTemplatePreset, FlatSquareTemplatePreset, FlowerTemplatePreset
import numpy as np

# TODO convert np.ndarray to scipy.ndimage
# TODO image scales
# TODO data visualization for 3D maps
# TODO data visualization for complex values
# TODO image plotting : make wrapper instead of parent class
# TODO reduce Volume() values to 1-bit size instead of full 64-bits (bool ?)
# TODO proper separation of Grid() and Map() and the like with @keep_relevant_class
# TODO Grid() compatibility with vectorial values
# TODO image saving to .tif


if __name__ == '__main__':

    a = Volume(values=np.array([1,1,1,1,0,0,0,0]))
    b = Volume(values=np.array([1,1,0,0,1,1,0,0]))
    c = Volume(values=np.array([1,0,1,0,1,0,1,0]))

    x = Volume.extrude_(a, b)

    h = Template(func=lambda _:1j, volume=x, dtype=complex)

    print(h.values)






