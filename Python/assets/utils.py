import numpy as np


def keep_relevant_class(func):
    """Decorator used to return a subclass of <Map> instead of <Map> itself, if relevant"""

    def wrapper(el, *args, **kwargs):
        from base_structure import Grid, Volume

        if isinstance(el, Volume):
            return func(el, cls=Volume, *args, **kwargs)
        else:
            return func(el, cls=Grid, *args, **kwargs)

    return wrapper


def distance_sq_norm(x: tuple, y: tuple, r: tuple = None):
    """Euclidean normalized squared distance between two set of index coordinates"""

    if r is None:
        return np.sum(
            np.square(
                np.asarray(x) - np.asarray(y)
            )
        )
    else:
        return np.sum(
            np.square(
                (np.asarray(x) - np.asarray(y)) / np.asarray(r)
            )
        )
