"""
This script is an example on generating a basic hologram using a simple cosine model.
"""

from optics import BasicHologram, Wavefront
from presets import FlatSquare, Gradient, Constant
import numpy as np
from visuals import RealImage2D


if __name__ == '__main__':

    # Setting the image shape in pixels
    shape = (200, 150)

    # Object amplitude and phase maps
    obj_a = FlatSquare(shape=shape, width=50, value=.8, fallback_value=1.)
    obj_p = FlatSquare(shape=shape, width=50, value=np.pi, fallback_value=0.)

    # Reference amplitude and phase maps
    ref_a = Constant(shape=shape, value=1.)
    ref_p = Constant(shape=shape, value=0.)

    # Biprism phase gradient
    bip_p = Gradient(shape=shape, slope=(0.048, 0.014))         # slope unit is in px^-1

    # Total object wavefront
    obj_w = Wavefront(amplitude=obj_a, phase=obj_p + bip_p)     # Biprism gradient in a given direction

    # Total reference wavefront
    ref_w = Wavefront(amplitude=ref_a, phase=ref_p - bip_p)     # Biprism gradient in the other direction

    # Creating a simple hologram using a cosine model
    # The fringe spatial frequency (q_vector) is equal to 2 * slope
    holo = BasicHologram(obj_wavefront=obj_w, ref_wavefront=ref_w)

    # 2D display
    RealImage2D.show(holo)
