from base_structure import Grid, Template
from volumes import Ones, Box, Ellipsoid
from utils import distance_sq_norm
from typing import Any
import numpy as np


class ConstantTemplatePreset(Template):

    def __init__(self, shape: tuple | int, value: Any, *args, **kwargs):
        super().__init__(func=lambda _: value, volume=Ones(shape=shape), *args, **kwargs)


class GradientTemplatePreset(Template):

    def __init__(self, shape: tuple | int, q_vector: tuple | int, *args, **kwargs):

        # Linear function such that func(0,...,0) = 0
        func = lambda pos: 2 * np.pi * np.dot(pos, q_vector)

        super().__init__(func=func, volume=Ones(shape=shape), *args, **kwargs)


class FlatSquareTemplatePreset(Template):

    def __init__(self, shape: tuple | int, width: int, value: Any,
                 fallback_value: Any = 0., *args, **kwargs): # TODO inherit apodization from base_structure.Template

        # Centered square region
        volume = Box(shape=shape, region=[((l - width)//2, - (l - width)//2) for l in shape])

        super().__init__(func=lambda _: value, volume=volume, fallback=lambda _: fallback_value, *args, **kwargs)


class FlowerTemplatePreset(Template):

    def __init__(self, shape: tuple | int, radius: int, angle: float, *args, **kwargs):

        # Image center coordinates
        center = tuple(np.asarray(shape) // 2)

        # Main function
        def func(pos:tuple):

            r = np.sqrt(distance_sq_norm(pos, center))

            return (
                    np.sin(
                        np.pi * ((pos[0] - shape[0]/2) * np.cos(angle) - (pos[1] - shape[1]/2) * np.sin(angle)) / radius
                    ) *
                    np.sin(
                        np.pi * ((pos[1] - shape[1]/2) * np.cos(angle) + (pos[0] - shape[0]/2) * np.sin(angle)) / radius
                    ) *
                    np.cos (np.pi / 2 * r/radius)
            )

        # Function support
        volume = Ellipsoid(shape=shape, center=center, radii=tuple([radius] * len(shape)))

        super().__init__(func=func, volume=volume, *args, **kwargs)


# And also for generating phase-shifted stacks...