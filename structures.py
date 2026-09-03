import numpy as np
from typing import Self, Union


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
    representing a n-dimensional volume"""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def project_on(self, axis:int) -> Map:
        """Performs an orthonormal projection of <self.values> along a specified <axis>"""

        return Map(
            values=np.sum(
                self.values,
                axis=axis
            )
        )

    def extend_to(self, new_shape:tuple, axis:Union[tuple, int]) -> Self:
        """Generates a higher-dimensional BinaryMap() instance containing repeated copies
        of <self.values> broadcasted on the specified <axis>"""

        # Assert that the provided shapes of <axis> and <self.values> match
        assert np.all(
            np.take(new_shape, axis) == np.asarray(self.shape)
        )

        # New empty data structure
        new_values = np.zeros(
            shape=new_shape,
            dtype=int
        )

        # Broadcasting <self.values> onto <new.values> along the specified <axis>
        for pos, _ in np.ndenumerate(new_values):
            new_values[pos] = self[
                tuple(
                    np.asfortranarray( # Catch the case where type(axis) == int
                        np.take(pos, axis)
                    )
                )
            ]

        return BinaryMap(values=new_values)

    @staticmethod
    def or_(*args:Map) -> Map: # <Self> class type hinting inside a @staticmethod is not supported
        """Performs an element-wise binary OR operation on all <arg.values> at once"""

        return BinaryMap(
            values=np.clip(
                np.sum(
                    np.array([arg.values for arg in args]),
                    axis=0
                ),
                a_min=0,
                a_max=1
            )
        )

    @staticmethod
    def and_(*args:Map) -> Map: # <Self> class type hinting inside a @staticmethod is not supported
        """Performs an element-wise binary AND operation on all <arg.values> at once"""

        return BinaryMap(
            values=np.prod(
                np.array([arg.values for arg in args]),
                axis=0
            )
        )

    @staticmethod
    def extrude_(*args:Map) -> Map:
        """Performs an extrusion of all <arg.values> along each other at once,
        by computing every product combination."""

        # Adding every <arg.shape> in a single tuple
        new_shape = tuple(
            np.concatenate(
                [arg.shape for arg in args],
                axis=0
            )
        )

        # Cumulative dimension indexes to keep track of which <axis> belong to which <arg.values>
        cumul_dim_id = np.cumsum([0] + [arg.ndim for arg in args])

        # List of BinaryMap() instances all extended to the same <new_shape> along their respective <axis>
        extended_maps_list = [
            arg.extend_to(
                new_shape=new_shape,
                axis=tuple(range(cumul_dim_id[i], cumul_dim_id[i+1]))
            ) for i, arg in enumerate(args)
        ]

        # Element-wise AND operation between all extended BinaryMap() instances
        return BinaryMap.and_(*extended_maps_list)


class Hologram(Map):
    """Generic 2-dimensional Map() sub-instance with real positive values,
    representing a hologram"""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.initial_phase = None
        self.q_vector = None

    def read_initial_phase(self) -> float: # TODO
        pass


class Stack:
    """Generic 1-dimensional set of Map() instances"""

    def __init__(self, slices:list[Map]):
        self.slices = slices

    def __getitem__(self, item):
        return self.slices[item]
