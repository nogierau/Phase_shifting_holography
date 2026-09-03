import numpy as np
from structures import BinaryMap
from typing import Union


class Zeros(BinaryMap):
    """BinaryMap() sub-instance containing zeros everywhere"""

    def __init__(self, shape: Union[tuple, int], *args, **kwargs):
        super().__init__(values=np.zeros(shape=shape, dtype=int), *args, **kwargs)


class Ones(BinaryMap):
    """BinaryMap() sub-instance containing ones everywhere"""

    def __init__(self, shape:Union[tuple, int], *args, **kwargs):
        super().__init__(values=np.ones(shape=shape, dtype=int), *args, **kwargs)


class Box(BinaryMap):
    """BinaryMap() sub-instance containing ones inside a specified rectangle-like region"""

    def __init__(self, shape:Union[tuple, int], region:list[tuple]):
        """Generates a n-dimensional BinaryMap() sub-instance containing ones inside the specified <region>.

        :param region: list containing [(start, end), (start, end) ...] index boundaries for each dimension"""

        # Empty data structure
        values = np.zeros(
            shape=shape,
            dtype=int
        )

        # Filling the specified <region> with ones
        values[*[slice(
            region[dim][0],
            region[dim][1]
        ) for dim in range(values.ndim)]] = 1

        super().__init__(values=values)


class Ellipsoid(BinaryMap):
    """BinaryMap() sub-instance containing ones inside a specified spheroïdal region"""

    def __init__(self, shape:tuple, center:tuple, radii:tuple):
        """Generates a n-dimensional BinaryMap() sub-instance containing ones around a specified
        index <center> up to the specified index Euclidean <radii> for each dimension"""

        # Empty data structure
        values = np.zeros(
            shape=shape,
            dtype=int
        )

        # Computing the Euclidean distance between two points
        def distance_sq_norm(x:tuple, y:tuple):
            """Euclidean normalized squared distance between two set of index coordinates"""

            return sum(
                np.square(
                    (x[dim] - y[dim]) / radii[dim]
                ) for dim in range(values.ndim)
            )

        # Filling the spheroïdal region with ones
        for pos, _ in np.ndenumerate(values):
            values[pos] = 1 if distance_sq_norm(pos, center) < 1 else 0

        super().__init__(values=values)
