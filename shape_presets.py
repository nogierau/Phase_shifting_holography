import numpy as np
from structures import BinaryMap
from typing import Union


class Ones(BinaryMap):
    """Binary n-dimensional Map() sub-instance containing ones everywhere"""

    def __init__(self, shape:tuple):
        super().__init__(np.ones(shape, dtype=int))


class Box(BinaryMap):
    """Binary n-dimensional Map() sub-instance containing ones inside a specified rectangle-like region"""

    def __init__(self, shape:Union[tuple, int], region:list[tuple]): # region = [(start,end), (start,end)...]
        values = np.zeros(shape, dtype=int)
        values[*[slice(
            region[dim][0],
            region[dim][1]
        ) for dim in range(values.ndim)]] = 1
        super().__init__(values)

class Sphere(BinaryMap):
    """Binary n-dimensional Map() sub-instance containing ones inside a specified spheroïdal region"""

    def __init__(self, shape:tuple, center:tuple, radii:tuple):
        values = np.zeros(shape, dtype=int)

        def distance(x:tuple, y:tuple):
            """Euclidean squared distance between two points of a map"""
            return sum(
                np.square(
                    (x[dim] - y[dim]) / radii[dim]
                ) for dim in range(values.ndim)
            )

        for pos, _ in np.ndenumerate(values):
            values[pos] = 1 if distance(pos, center) < 1 else 0

        super().__init__(values)


class Circle(Sphere):
    pass

class Square(Box):
    pass

class Rectangle(Box):
    pass

class Cylinder(BinaryMap):
    pass





