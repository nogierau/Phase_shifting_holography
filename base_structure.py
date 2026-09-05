import numpy as np
from typing import Self, Union, Callable
from utils import keep_relevant_class


class Grid:
    """Generic parent class for n-dimensional array-like objects"""

    def __init__(self, values:np.ndarray=0):
        self.values = np.asarray(values)

    def __getitem__(self, item):
        return self.values[item]

    def __getattr__(self, item):
        return self.values.__getattribute__(item)

    def project_on(self, axis:int) -> Self:
        """Performs an orthonormal projection of <self.values> along a specified <axis>"""

        return Grid(
            values=np.sum(
                self.values,
                axis=axis
            )
        )

    # @keep_relevant_class
    def extend_to(self, new_shape:tuple, axis:Union[tuple, int], cls:type=None) -> Self: # TODO compatibility with vector-valued Grid()
        """Generates a higher-dimensional Grid() instance containing repeated copies
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

        # Broadcasting <self.values> onto <new_values> along the specified <axis>
        for pos, _ in np.ndenumerate(new_values):
            new_values[pos] = self[
                tuple(
                    np.asfortranarray( # Catch the case where type(axis) == int
                        np.take(pos, axis)
                    )
                )
            ]

        # return cls(values=new_values)
        return Grid(values=new_values)

    # @keep_relevant_class
    def zero_padding(self, border_width:int, cls:type=None) -> Self: # TODO compatibility with vector-valued Grid()
        """Generates a larger Grid() instance containing <self.values> in a central region
        bordered by a belt of zeros in every dimension"""

        # New empty data structure
        new_values = np.zeros(
            shape=tuple(np.asarray(self.shape) + 2 * border_width),
            dtype=self.dtype
        )

        # Broadcasting <self.values> onto the central region of <new_values>
        for pos, val in np.ndenumerate(self.values):
            new_values[tuple(np.asarray(pos) + border_width)] = val

        # return cls(values=new_values)
        return Grid(values=new_values)


class Volume(Grid):
    """Generic child class for Grid() sub-instances containing binary (boolean) values"""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    @staticmethod
    def or_(*args): # <Self> class type hinting inside a @staticmethod is not supported
        """Performs an element-wise binary OR operation on all <arg.values> at once"""

        return Volume(
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
    def and_(*args): # <Self> class type hinting inside a @staticmethod is not supported
        """Performs an element-wise binary AND operation on all <arg.values> at once"""

        return Volume(
            values=np.prod(
                np.array([arg.values for arg in args]),
                axis=0
            )
        )

    @staticmethod
    def extrude_(*args): # <Self> class type hinting inside a @staticmethod is not supported
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

        # List of Volume() instances all extended to the same <new_shape> along their respective <axis>
        extended_maps_list = [
            arg.extend_to(
                new_shape=new_shape,
                axis=tuple(range(cumul_dim_id[i], cumul_dim_id[i+1]))
            ) for i, arg in enumerate(args)
        ]

        # Element-wise AND operation between all extended Volume() instances
        return Volume.and_(*extended_maps_list)


class Map(Grid):
    """Generic child class for Grid() sub-instances associated with real-space positions"""

    def __init__(self, scale:float=1., *args, **kwargs):
        self.scale = scale
        super().__init__(*args, **kwargs)

    def __add__(self, other):
        return Map(scale=self.scale, values=self.values + other.values)


class Template(Map):
    """Generic child class for Map() sub-instances that evaluate a function on a given support"""

    def __init__(self, func:Callable, volume:Volume, fallback:Callable=lambda _:0,
                 dtype:type=None, *args, **kwargs): # TODO add apodization width and function
        """Generates a Map() sub-instance containing evaluations of <func()> wherever <volume.values> is one,
        and <fallback()> everywhere else.

        :param func: Callable
            Function taking a tuple of position indexes as an input.
            The main function to evaluate.
        :param fallback: Callable, optional
            Function taking a tuple of position indexes as an input.
            The fallback function.
        :param volume: Volume
            Support for the evaluation of func().
        :param dtype: type, optional
            The output type of both func() and fallback()."""

        # Empty data structure
        values = np.zeros(
            shape=volume.shape,
            dtype=dtype
        )

        # Calling func() wherever <vol.values> is one and fallback() everywhere else
        for pos, val in np.ndenumerate(volume.values):
            values[pos] = func(pos) if val else fallback(pos)

        super().__init__(values=values, *args, **kwargs)


class Stack:
    """Generic 1-dimensional set of Map() instances"""

    def __init__(self, slices:list[Grid]):
        self.slices = slices

    def __getitem__(self, item):
        return self.slices[item]
