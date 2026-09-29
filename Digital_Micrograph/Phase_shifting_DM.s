/*
=== Description ===
This script processes an arbitrary hologram stack obtained from either experiment or simulation,
using the Iterative Parametric Phase Shift (IPPS) method to yield a phase map with reduced residual fringes
compared to that of the standard Phase Shift (PS).

Additional details can be found at the following source :
[Nogier, A. (2025). Microscopie électronique operando pour l'étude de mémoires magnétiques
(Doctoral dissertation, Université Grenoble Alpes [2020-....]).]

=== Input ===

> This script takes a single real image stack as input

=== Requirements ===
> This script does not perform image realignments:
  potential effects of sample drift during acquisition must be corrected beforehand.

> Hologram order does not matter, nor does any missing slice.

> The exact initial phase values targetted during acquisition do not matter either,
  as the actual values will be read from the stack itself to serve as a first guess for the IPPS algorithm anyway.

=== Best use case ===
> A somewhat regular initial phase distribution across a whole number of fringes yields the best results in the final phase map,
  but any distribution is fine as long as at least 2 whole fringes are covered with sufficient, non-redundant values.
  
> Typically, 5 to 10 iterations are enough to reach a stable minimal residual fringe height:
  a reduction factor of ~10 compared to PS can be expected from an experimental hologram stack with ~50 slices.

=== Output ===

> This script outputs the following objects:
	- a 2D real image showing the electron wave phase map, still containing a linear gradient originating from the biprism.
	- a plot of the initial phases distribution correction for each iteration
	- a plot of the residual fringe height across iterations


Created on 2024-12-06 by Augustin Nogier
*/




// ===================================================
// ==================== Functions ====================

// Function for extracting the initial phase of a single hologram FFT image
number get_initial_phase(compleximage img_FFT)
{
	number size_x = img_FFT.ImageGetDimensionSize(0)
	number size_y = img_FFT.ImageGetDimensionSize(1)
	
	image img_modulus = img_FFT.abs()
	
	// Eliminating 0-order peak
	img_modulus.SetPixel(size_x/2, size_y/2, 0)
	
	// Getting peak position from modulus image
	number id_x, id_y
	max(img_modulus, id_x, id_y) // We don't care which peak is selected, since the FFT is Hermitian
	
	// Getting initial phase from FFT peak value
	return img_FFT.GetPixel(id_x, id_y).phase()
}

// Function for removing a linear background in a phase map
image remove_q_background(image img, number q_x, number q_y)
{	
	number size_x = img.ImageGetDimensionSize(0)
	number size_y = img.ImageGetDimensionSize(1)
	
	image background = RealImage("", 8, size_x, size_y)
	background = 2 * Pi() * q_x * (icol - size_x/2) + 2 * Pi() * q_y * (irow - size_y/2)
	
	return img - background
}

// Function for wrapping a phase image in [-Pi(), Pi()[
image wrap(image img)
{
	return (img - min(img)) % (2*Pi()) - Pi()
}


// ===================================================
// =================== Main script ===================

// === Experimental data recollection ===

	// Hologram stack
	image hologram_stack := GetFrontImage()
	number Nx = hologram_stack.ImageGetDimensionSize(0)		// X size (px)
	number Ny = hologram_stack.ImageGetDimensionSize(1)		// Y size (px)
	number m = hologram_stack.ImageGetDimensionSize(2)		// Number of individual holograms

	// Verbose
	Result("\n\n=== Iterative Parametric Phase Shifting ===")
	Result("\nStack size : (" + Nx + " ; " + Ny + " ; " + m + ")")



// === User input ===
	
	// Selecting ROI on hologram stack for initial phases calculation
	imagedisplay disp = hologram_stack.ImageGetImageDisplay(0)
	number count_ROI = disp.imageDisplayCountROIs()

	// ROI edges
	number top, left, bottom, right

	// Checking for ROI presence - Throwing error if absent
	if (count_ROI != 0)
	{
		// Getting ROI edges
		ROI region = disp.ImageDisplayGetROI(0)
		if (region.ROIIsRectangle())
		{
			// ROI edges
			region.ROIGetRectangle(top, left, bottom, right)
			
			// Trimming ROI edges to image borders
			top = max(top, 0)
			left = max(left, 0)
			bottom = min(bottom, Ny)
			right = min(right, Nx)
			
			// Verbose
			Result( "\nROI : [" + left + ", " + top + ", " + right + ", " + bottom + "]" )
		}
		else
		{
			beep()
			okdialog("The selected Region Of Interest (ROI) must be rectangular.")
			exit(0)
		}
	}
	else
	{
		beep()
		okdialog("Please select a Region Of Interest (ROI) of the hologram stack.")
		exit(0)
	}

	// Saving ROI as a cropped stack, no binning
	image cropped_stack := hologram_stack.slice3(left,top,0,0,right-left,1,1,bottom-top,1,2,m,1)

cropped_stack.ShowImage()

// === First guess for initial phase values ===

	// User setting the maximum Iterative Parametric Phase Shift (IPPS) iteration depth
	number max_iterations
	GetNumber("Maximum iterations", 5, max_iterations)
	max_iterations = max_iterations.floor()

	// Stack of 1D array of initial phase values as a 2D image
	image initial_phases := RealImage("Initial phases", 8, max_iterations + 1, m)

	// Writing a first guess of the initial phases distribution
	for (number s = 0; s < m; s++) // For each slice
	{	
		// Extract slice s and compute FFT
		compleximage slice_FFT = cropped_stack.slice2(0,0,s,0,right-left,1,1,bottom-top,1).realFFT()
		
		// Get an estimation of the initial phase and write it down
		initial_phases.SetPixel(0, s, get_initial_phase(slice_FFT))
	}

initial_phases.ShowImage()


// === Iterative Parametric Phase Shift (IPPS) ===

	// H0, H-, H+ quantities
	compleximage H0 := ComplexImage("H0", 16, Nx, Ny)
	compleximage H1 := ComplexImage("H-", 16, Nx, Ny)
	compleximage H2 := ComplexImage("H+", 16, Nx, Ny)

	// A, B, B* hologram Fourier bands
	compleximage A  := ComplexImage("A",  16, Nx, Ny)
	compleximage B  := ComplexImage("B",  16, Nx, Ny)
	compleximage Bs := ComplexImage("B*", 16, Nx, Ny)

	// Output phase and visibility maps
	image phase := RealImage("Phase", 8, Nx, Ny)
	image visibility := RealImage("Visibility", 8, Nx, Ny)
	
	
	// For each iteration
	for (number i = 0; i < max_iterations; i++)
	{	
		// Verbose
		Result("\nIteration : " + (i + 1))
		
		// Initial phase distribution obtained from previous iteration
		image initial_phases_current_guess = initial_phases.slice1(i,0,0,1,m,1)
		
		// Sum along every slice using the current initial phases distribution guess
		H0 = project(hologram_stack, 2)																	// Natural sum
		H1 = project(hologram_stack * exp(complex(0,-1) * initial_phases_current_guess[iplane, 0]), 2)	// Weighted sum
		H2 = project(hologram_stack * exp(complex(0, 1) * initial_phases_current_guess[iplane, 0]), 2)	// Weighted sum

		// Inverse matrix coefficients
		complexnumber sigma_p = sum(exp(complex(0,1) * initial_phases_current_guess))
		complexnumber sigma_n = sum(exp(complex(0,-1) * initial_phases_current_guess))
		complexnumber sigma_2p = sum(exp(complex(0,1) * 2 * initial_phases_current_guess))
		complexnumber sigma_2n = sum(exp(complex(0,-1) * 2 * initial_phases_current_guess))

		complexnumber Delta = m**2 - sigma_p * sigma_n
		complexnumber Lambda = m**2 - sigma_2p * sigma_2n

		complexnumber R = sigma_2p * sigma_n - m * sigma_p
		complexnumber Rs = sigma_2n * sigma_p - m * sigma_n

		complexnumber S = sigma_p**2 - m * sigma_2p
		complexnumber Ss = sigma_n**2 - m * sigma_2n

		// Matrix determinant (ignoring a factor of m)
		complexnumber X = Delta**2 - S * Ss

		// Verbose
		Result("\n\t> Normalized matrix determinant (0<...<1) : " + real(X) / m**4)	// Should ideally be close to 1

		// Fourier bands matrix calculation
		A  = (m / X) * (Lambda * H0 + R     * H1 + Rs    * H2)
		B  = (m / X) * (Rs     * H0 + Delta * H1 + Ss    * H2)
		Bs = (m / X) * (R      * H0 + S     * H1 + Delta * H2)

		// Final phase calculation (still containing q background)
		phase = phase(B)
		visibility = abs(B)
		
		// Removing q-gradient background
		
			// Placeholder
			number q_x = (1/20) * (24/25)
			number q_y = (1/20) * (7/25)
		
		image flattened_phase = wrap(remove_q_background(phase, q_x, q_y))
		flattened_phase.ShowImage()
		
		
		// Measuring residual fringe height and position in phase ROI
		image cropped_phase := flattened_phase.slice2(left,top,0,0,right-left,1,1,bottom-top,1)
		cropped_phase.ShowImage()
		
		
		// Calculating initial phase correction
		
		
		// Writing next batch of initial phases and q-vector
	}

// ShowImage(phase)
// ShowImage(visibility)