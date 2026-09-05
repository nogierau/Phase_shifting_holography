from base_structure import Grid, Template
from volumes import Ones, Box
import numpy as np


class ConstantTemplatePreset(Template):

    def __init__(self, shape:tuple, value:float, *args, **kwargs):
        super().__init__(func=lambda _:value, volume=Ones(shape=shape), *args, **kwargs)


class GradientTemplatePreset(Template):

    def __init__(self, shape:tuple, q_vector:tuple, *args, **kwargs):

        # Linear function such that func(0,...,0) = 0
        func = lambda pos: 2 * np.pi * np.dot(pos, q_vector)

        super().__init__(func=func, volume=Ones(shape=shape), *args, **kwargs)


class FlatSquareTemplatePreset(Template):

    def __init__(self, shape:tuple, width:int, value:float, fallback_value:float=0., *args, **kwargs): # TODO inherit apodization from base_structure.Template

        # Centered square region
        volume = Box(shape=shape, region=[((l - width)//2, - (l - width)//2) for l in shape])

        super().__init__(func=lambda _:value, volume=volume, fallback=lambda _:fallback_value, *args, **kwargs)


class Cylinder(Grid):
    pass


class Flower(Template):
    pass

# And also for generating phase-shifted stacks...