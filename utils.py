def keep_relevant_class(func):
    """Decorator used to return a subclass of <Map> instead of <Map> itself, if relevant"""

    def foo(el, *args, **kwargs):
        from structures import Map, BinaryMap

        if isinstance(el, BinaryMap):
            return func(el, cls=BinaryMap, *args, **kwargs)
        else:
            return func(el, cls=Map, *args, **kwargs)

    return foo
