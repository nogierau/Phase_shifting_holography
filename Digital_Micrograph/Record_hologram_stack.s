/*
=== Description ===
This script uses the Electron Microscope Beam Tilt to acquire a linearly phase-shifted hologram stack automatically,
which can be further processed using the Iterative Parametric Phase Shift (IPPS) method
to yield a phase map with reduced residual fringes compared to that of the standard Phase Shift (PS).

=== Requirements ===
> According to the acquisition and processing framework of IPPS,
  the target values of initial phases are irrelevant as they are not under any hypothesis,
  so that no Beam Tilt calibration is needed.
  
> Output spatial resolution does not depend on fringe spacing.

> However, the IPPS requires identical contrast and visibility profiles between holograms:
  it is therefore necessary to ensure that the exposure conditions are rigorously constant throughout the entire acquisition.

> The effects of sample drift can nevertheless be made negligible by using a small enough individual exposure time.

=== Best use case ===

> Wider, cleaner fringes are always better for signal quality but can reduce the usable hologram region
  because of the presence of stronger Fresnel modulation patterns, depending on the microscope setup.

> A whole number of fringes shifted between the first and last holograms yields minimal errors and noise in the final phase map;
  however, the difference becomes insignificant beyond a total shift of 2 whole fringes,
  such that precision on the exact phase shift amount is no longer required if the user goes for more.

> It is advised to run the script once in a vacuum region to ensure that these criteria are met before exposing the sample.


Created on 2024-12-06 by Augustin Nogier
*/


// === Settings ===

// Image acquisition settings
number camID = CameraGetActiveCameraID()	// Microscope camera ID
number dt = 0.2								// Elementary exposure time (s)
number m = 50								// Total number of images in the final stack
number Nx, Ny								// Image size (px)
CameraGetSize(camID, Nx, Ny)					

// Beam tilt settings
number tilt_x_step = 1				// Beam Tilt horizontal step (arbitrary unit)
number tilt_y_step = 0				// Beam Tilt vertical step (arbitrary unit)
number tilt_x_0, tilt_y_0			// Initial Beam Tilt values
EMGetBeamTilt(tilt_x_0, tilt_y_0)

// Verbose
Result("\n===== Image acquisition settings =====\n")
Result("camID : " + camID + "\n")
Result("Image size : (" + Nx + " * " + Ny + ")\n")
Result("Exposure time : " + dt + " s\n")
Result("Numer of images : " + m + "\n")

Result("\n===== Beam tilt settings =====\n")
Result("Step X : " + tilt_x_step + "\n")
Result("Step Y : " + tilt_y_step + "\n")
Result("Initial Beam Tilt : (" + tilt_x_0 + " ; " + tilt_y_0 + ")\n")


// === Hologram stack acquisition ===

// Creating data structure
image hologram_stack := RealImage("Hologram stack", 8, Nx, Ny, m)

// For each slice
for (number i = 0; i < m; i++)
{
	// Recording hologram as slice i
	image hologram = CameraAcquire(camID, dt, 1, 1)			// Replace by [camID, dt, 2, 2] or similar to use binning
	hologram_stack.slice2(0,0,i,0,Nx,1,1,Ny,1) = hologram	// syntax for slice i : [x0, y0, z0, dim0, length0, stride0, dim1, length1, stride1]
	
	// Stepping Beam Tilt
	EMChangeBeamTilt(tilt_x_step, tilt_y_step)
	EMWaitUntilReady()
}

// Resetting Beam Tilt after the recording is complete
EMSetBeamTilt(tilt_x_0, tilt_y_0)
EMWaitUntilReady()

// Showing output hologram stack
ShowImage(hologram_stack)