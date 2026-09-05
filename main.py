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


if __name__ == '__main__':

    g = GradientTemplatePreset(shape=(100,100), q_vector=(4e-2, 3e-2))
    a = FlatSquareTemplatePreset(shape=(100,100), width=50, value=.8, fallback_value=1.)
    p = FlatSquareTemplatePreset(shape=(100,100), width=50, value=np.pi, fallback_value=0.)

    w = Wavefront(amplitude=a, phase=p + g)

    h = SimpleHologram(wavefront=w)
    RealImage2D.show(h)


    f = FlowerTemplatePreset(shape=(100,100), radius=50, angle=20.)
    y = ConstantTemplatePreset(shape=(100,100), value=1.)
    RealImage2D.show(f)

    u = Wavefront(amplitude=y, phase=f + g)

    i = SimpleHologram(wavefront=u)
    RealImage2D.show(i)






