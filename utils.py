def keep_relevant_class(func):
    """Decorator used to return a subclass of <Map> instead of <Map> itself, if relevant"""

    def wrapper(el, *args, **kwargs):
        from base_structure import Grid, Volume

        if isinstance(el, Volume):
            return func(el, cls=Volume, *args, **kwargs)
        else:
            return func(el, cls=Grid, *args, **kwargs)

    return wrapper
