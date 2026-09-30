# Phase Shifting Holography

Python and DigitalMicrograph scripts for phase-shifting electron holography data processing.\
Additional details on calculations and mathematical results can be found [here](https://theses.hal.science/tel-05674141/).

## Current state of the repository

> This repository is in a build-up phase as of **september 30, 2026**

### Python scripts

The current capabilities of the provided Python scripts include:

* Generating arbitrary n-dimensional shapes
* Generating arbitrary n-dimensional maps of scalar values
* Generating arbitrary 2-dimensional scalar maps
* Generating arbitrary wavefronts
* Generating simple holograms with arbitrary characteristics
* Visualizing 2D and 1D real scalar maps
* Various useful presets

### DigitalMicrograph scripts

The current capabilities of DigitalMicrograph scripts include:

* Piloting an electron microscope to record a phase-shifted hologram stack using beam tilt
* Performing a manual implementation of the Iterative Parametric Phase-Shifting routine on an arbitrary hologram stack using a user-selected region of interest

## TODO

### Python scripts

The remaining tasks to implement in Python scripts include, in no particular order:

* Adding map support for physical image scale
* Adding map compatibility with vectorial values
* Adding support for 3D map visualization
* Simulating the 2D magnetic phase map generated from a 3D magnetization map
* Adding information about known materials and chemical elements
* Saving images as .tif or .dm5
* Generating phase-shifted hologram stacks
* Simulating realistic optical wavefront propagation and realistic holograms
* Provide example scripts

### DigitalMicrograph scripts

The remaining tasks to implement in DigitalMicrograph scripts include, in no particular order:

* Implementing an automated version of the Iterative Parametric Phase Shift routine
* Implementing a user-friendly way to evaluate residual fringe characteristics in an experimental setup
