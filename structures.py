import numpy as np
from typing import Self, Union, Optional, Any


class Map:
    """Generic n-dimensional array-like object"""

    def __init__(self, values:np.ndarray=0, scale:float=1.):
        self.values = np.asarray(values)
        self.scale = scale

    def __getitem__(self, item):
        return self.values[item]

    def __getattr__(self, item):
        return self.values.__getattribute__(item)


class BinaryMap(Map):
    """Generic n-dimensional Map() sub-instance with binary values,
    representing a solid shape in n dimensions"""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def project_on(self, axis:int) -> Map:
        """Orthonormal projection along a specified axis"""
        return Map(values=np.sum(self.values, axis=axis))

    def extend_to(self, new_shape:tuple, axis:Union[tuple, int]) -> Self:
        """Generates a higher-dimensional BinaryMap() instance containing copies of self.values
        along the specified axes"""
        assert np.all(np.take(new_shape, axis) == np.asarray(self.shape))

        new_values = np.zeros(shape=new_shape, dtype=int)

        for pos, _ in np.ndenumerate(new_values):
            new_values[pos] = self[tuple(np.asfortranarray(np.take(pos, axis)))]

        return BinaryMap(values=new_values)

    def union(self, other:Self) -> Self:
        """Element-wise binary OR operator"""
        return BinaryMap(values=np.clip(self.values + other.values, 0, 1))

    def intersection(self, other:Self) -> Self:
        """Element-wise binary AND operator"""
        return BinaryMap(values=self.values * other.values)

    def extrude(self, other:Self) -> Self:
        """"""
        new_shape = tuple(np.concatenate([self.shape, other.shape]))

        return BinaryMap.intersection(
            self.extend_to(new_shape=new_shape, axis=tuple(range(0, self.ndim))),
            other.extend_to(new_shape=new_shape, axis=tuple(range(self.ndim, self.ndim + other.ndim)))
        )

    @staticmethod
    def extrude_(*args): # TODO Does not work
        return BinaryMap(
            values=np.multiply(
                *np.meshgrid(
                    *[arg.values for arg in args],
                    indexing='ij'
                )
            )
        )


class Hologram(Map):
    """Generic 2-dimensional Map() sub-instance with real positive values,
    representing a hologram"""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.initial_phase = None
        self.q_vector = None

    def read_initial_phase(self) -> float:
        pass


class Stack:
    """Generic 1-dimensional set of Map() instances"""

    def __init__(self, slices:list[Map]):
        self.slices = slices

    def __getitem__(self, item):
        return self.slices[item]
