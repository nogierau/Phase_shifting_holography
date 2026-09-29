import numpy as np
from base_structure import Volume
from utils import distance_sq_norm


class Zeros(Volume):
    """Volume() sub-instance containing zeros everywhere"""

    def __init__(self, shape: tuple | int):
        super().__init__(values=np.zeros(shape=shape, dtype=bool))


class Ones(Volume):
    """Volume() sub-instance containing ones everywhere"""

    def __init__(self, shape: tuple | int):
        super().__init__(values=np.ones(shape=shape, dtype=bool))


class Box(Volume):
    """Volume() sub-instance containing ones inside a specified rectangle-like region"""

    def __init__(self, shape: tuple | int, region: list[tuple]):
        """Generates a Volume() sub-instance containing ones inside the specified <region>.

        :param shape: tuple or int
            The shape of the numpy array containing values
        :param region: list
            Contains the index boundaries for each dimension.
            syntax : region = [(start, end), (start, end) ...]"""

        # Empty data structure
        values = np.zeros(
            shape=shape,
            dtype=bool
        )

        # Filling the specified <region> with ones
        values[*[slice(
            region[dim][0],
            region[dim][1]
        ) for dim in range(values.ndim)]] = True

        super().__init__(values=values)


class Ellipsoid(Volume):
    """Volume() sub-instance containing ones inside a specified spheroïdal region"""

    def __init__(self, shape: tuple | int, center: tuple, radii: tuple):
        """Generates a Volume() sub-instance containing ones around a specified
        index <center> up to the specified index Euclidean <radii> for each dimension"""

        # Empty data structure
        values = np.zeros(
            shape=shape,
            dtype=bool
        )

        # Filling the spheroïdal region with ones
        for pos, _ in np.ndenumerate(values):
            values[pos] = distance_sq_norm(pos, center, radii) < 1

        super().__init__(values=values)
