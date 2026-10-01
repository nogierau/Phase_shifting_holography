from visuals import RealImage2D
from presets import FlatSquare, Flower

# TODO apodization
# TODO convert np.ndarray to scipy.ndimage
# TODO image scales
# TODO image plotting : make wrapper instead of parent class
# TODO data visualization for complex values
# TODO proper separation of Grid() and Map() and the like with @keep_relevant_class
# TODO Grid() compatibility with vectorial values
# TODO data visualization for 3D maps
# TODO simulate magnetization
# TODO materials and MIP
# TODO image saving to .tif
# TODO generate phase-shifted stacks
# TODO realistic wavefront propagation


if __name__ == '__main__':

    f = Flower(shape=(100,100), radius=40, angle=20.)
    q = FlatSquare(shape=(100,100), width=50, value=1j, fallback_value=1, dtype=complex)

    RealImage2D.show(q)

    # comment for checking that commits still work fine








