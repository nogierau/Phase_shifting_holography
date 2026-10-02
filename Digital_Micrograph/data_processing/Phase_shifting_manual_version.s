/*
=== Description ===
This script processes an arbitrary hologram stack obtained from either experiment or simulation,
using a general approach of the Phase Shifting method to yield the object phase map,
and Fourier Transforms to evaluate rough guesses for the initial phases.
It then uses the characteristics (user input) of the residual fringes in the phase map (as described by calculations)
to suggest a correction for the initial phase values that, if used in the next iteration of the Phase Shifting method,
may yield reduced residual fringes.

Additional details can be found at the following source:
[Nogier, A. (2025). Microscopie electronique operando pour l'etude de memoires magnetiques (Doctoral dissertation, Universite Grenoble Alpes [2020-....]).]

=== Input ===

> This script takes a single real image stack as input

=== Requirements ===
> This script does not perform image realignments:
  potential effects of sample drift during acquisition must be corrected beforehand.

> Hologram order does not matter, nor does any missing slice.

> The exact initial phase values targeted during acquisition do not matter either,
  as the actual values will be read from the stack itself to serve as a rough guess for the Phase Shifting algorithm anyway.

=== Best use case ===
> A somewhat regular initial phase distribution across a whole number of fringes yields the best results in the final phase map,
  but any distribution is fine as long as at least 2 whole fringes are covered with sufficient, non-redundant values.

=== Output ===

> This script outputs the following objects:
	- a 2D real image showing the recovered electron wave phase map, still containing a linear gradient originating from the biprism.
	- a 2D real image showing the corrected phase map without the biprism gradient, using user inupt values
	- a 2D real image showing the recovered fringes visibility profile
	- a (2*m) real image showing rough guesses and suggested corrections of the initial phase values for each hologram,
		caculated using the hologram Fourier Transform and the provided residual fringes characteristics


Created on 2024-12-06 by Augustin Nogier
*/



// ===================================================
// ==================== Functions ====================

// Function for roughly guessing the initial phase of a single hologram FFT image
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

// Function for computing the dot product of two 1D images
	number dot(image a, image b)
	{
		return sum(a * b)
	}


// ===================================================
// =================== Main script ===================

// === Experimental data recollection ===

	// Hologram stack
	image hologram_stack := GetFrontImage()
	number Nx = hologram_stack.ImageGetDimensionSize(0)		// X size (px)
	number Ny = hologram_stack.ImageGetDimensionSize(1)		// Y size (px)
	number m = hologram_stack.ImageGetDimensionSize(2)		// Number of hologram slices

	// Verbose
	Result("\n=== Iterative Parametric Phase Shifting ===\n")
	Result("Stack size : (" + Nx + " ; " + Ny + " ; " + m + ")\n")


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
			region.ROIGetRectangle(top, left, bottom, right)
			
			// Trimming ROI edges to image borders
			top = max(top, 0)
			left = max(left, 0)
			bottom = min(bottom, Ny)
			right = min(right, Nx)
			
			// Verbose
			Result( "ROI : [" + left + ", " + top + ", " + right + ", " + bottom + "]\n" )
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

	// Saving ROI as a cropped stack, without binning
	image cropped_stack := hologram_stack.slice3(left,top,0,0,right-left,1,1,bottom-top,1,2,m,1)


// === Rough guess for initial phase values from ROI ===

	// User input : maximum iterations for the correction process
	number max_iterations
	GetNumber("Maximum iterations", 5, max_iterations)	// returns 0 if user cancel

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


// === Iterative Parametric Phase Shifting ===

	// H0, H-, H+ quantities
	compleximage H0 := ComplexImage("H0", 16, Nx, Ny)
	compleximage H1 := ComplexImage("H-", 16, Nx, Ny)
	compleximage H2 := ComplexImage("H+", 16, Nx, Ny)

	// A, B, B* hologram Fourier bands
	compleximage A  := ComplexImage("A",  16, Nx, Ny)
	compleximage B  := ComplexImage("B",  16, Nx, Ny)
	compleximage Bs := ComplexImage("B*", 16, Nx, Ny)

	// Output maps
	image phase := RealImage("Phase", 8, Nx, Ny)
	image visibility := RealImage("Visibility", 8, Nx, Ny)
	image flattened_phase := RealImage("Flattened phase", 8, Nx, Ny)
	
	// Useful quantities
	complexnumber sigma_p, sigma_2p, sigma_n, sigma_2n
	complexnumber R, Rs, S, Ss
	number Delta, Lambda, X
	
	// Hologram fringes q-vector coordinates
	TagGroup q_DLG, q_DLGItems
	q_DLG = DLGCreateDialog( "Please enter the q-vector coordinates", q_DLGItems)

	TagGroup q_x_tg, q_y_tg
	q_DLGitems.DLGAddElement(DLGCreateRealField("q-vector X coordinate :", q_x_tg, (1/20) * (24/25), 24, 16))		// Default values suited for example data
	q_DLGitems.DLGAddElement(DLGCreateRealField("q-vector Y coordinate :", q_y_tg, (1/20) * (7/25), 24, 16))

	if (!Alloc(UIframe).Init(q_DLG).Pose())
	{
		Throw( "User abort." )
	}
	
	// Intermediary quantities
	compleximage chi_vector := ComplexImage("Chi vector", 8, m)
	image mu := RealImage("Mu vector", 8, m)
	image nu := RealImage("Nu vector", 8, m)	
		
	// Iterative process
	for (number i = 0; i < max_iterations + 1; i++)
	{
		// Verbose
		Result("Iteration : " + i + "\n")
		
		// Initial phase distribution obtained from previous iteration
		image initial_phases_current_guess := initial_phases.slice1(i,0,0,1,m,1)
	
		// Sum along every slice using the current initial phases distribution guess
		H0 = project(hologram_stack, 2)																	// Natural sum
		H1 = project(hologram_stack * exp(complex(0,-1) * initial_phases_current_guess[iplane, 0]), 2)	// Weighted sum
		H2 = project(hologram_stack * exp(complex(0, 1) * initial_phases_current_guess[iplane, 0]), 2)	// Weighted sum

		// Matrix coefficients
		sigma_p = sum(exp(complex(0,1) * initial_phases_current_guess))
		sigma_n = sum(exp(complex(0,-1) * initial_phases_current_guess))
		sigma_2p = sum(exp(complex(0,2) * initial_phases_current_guess))
		sigma_2n = sum(exp(complex(0,-2) * initial_phases_current_guess))

		// Inverse matrix coefficients
		Delta = real(m**2 - sigma_p * sigma_n)
		Lambda = real(m**2 - sigma_2p * sigma_2n)

		R = sigma_2p * sigma_n - m * sigma_p
		Rs = sigma_2n * sigma_p - m * sigma_n

		S = sigma_p**2 - m * sigma_2p
		Ss = sigma_n**2 - m * sigma_2n

		// Matrix determinant (ignoring a factor of m)
		X = real(Delta**2 - S * Ss)

		// Verbose
		Result("\t> Normalized matrix determinant (0<...<1) : " + X / m**4 + "\n")	// Should ideally be close to 1

		// Fourier bands matrix calculation
		A  = (m / X) * (Lambda * H0 + R     * H1 + Rs    * H2)
		B  = (m / X) * (Rs     * H0 + Delta * H1 + Ss    * H2)
		Bs = (m / X) * (R      * H0 + S     * H1 + Delta * H2)

		// Final phase calculation (still containing q background)
		phase = phase(B)
		visibility = abs(B)		
	
		// Removing q-gradient background
		flattened_phase = phase.remove_q_background(q_x_tg.DLGGetValue(), q_y_tg.DLGGetValue()).wrap()
	
		// Output
			// 2D fringe visibility map
			visibility.ShowImage()
			
			// 2D electron wavefront phase map
			phase.ShowImage()			// Note: a staircase-like profile is expected
			
			// 2D object phase map
			flattened_phase.ShowImage() // Note: if there is a residual gradient, then the q-vector coordinates must be re-evaluated
		
		// Avoid doing the last correction (will not be used anyway), otherwise continue
		if (i == max_iterations)
		{
			break
		}
	
		// === Residual fringes correction ===

		// User input: residual fringes measured amplitude and phase
		TagGroup residual_DLG, residual_DLGItems
		residual_DLG = DLGCreateDialog( "Please enter the residual fringes characteristics", residual_DLGItems)

		TagGroup C_N_tg, Phi_N_tg
		residual_DLGitems.DLGAddElement(DLGCreateRealField("Measured amplitude :", C_N_tg, 0.1, 24, 16))
		residual_DLGitems.DLGAddElement(DLGCreateRealField("Measured phase :", Phi_N_tg, 0., 24, 16))

		if (!Alloc(UIframe).Init(residual_DLG).Pose())
		{
			okdialog("Process has stopped after " + i + " iteration(s).")
			break
		}
		
		number C_N = C_N_tg.DLGGetValue() * X	// Accounting for the multiplicative factor in the amplitude term
		number Phi_N = Phi_N_tg.DLGGetValue()
		
		// Intermediary quantities
		chi_vector = m * (Delta + exp(complex(0,1) * initial_phases_current_guess)* Rs + exp(complex(0,2) * initial_phases_current_guess) * Ss)
		mu = abs(chi_vector) * cos(2 * initial_phases_current_guess - chi_vector.phase())
		nu = abs(chi_vector) * sin(2 * initial_phases_current_guess - chi_vector.phase())

		// Correction suggestion for the next batch of initial phases
		image initial_phases_corrections := ((dot(nu, nu) * mu - dot(mu, nu) * nu) * C_N * cos(Phi_N) + (dot(mu, mu) * nu - dot(mu, nu) * mu) * C_N * sin(Phi_N)) / (dot(mu, mu) * dot(nu, nu) - dot(mu, nu)**2)
		
		// Writing next batch of initial phases
		initial_phases.slice1(i+1,0,0,1,m,1) = initial_phases_current_guess - initial_phases_corrections
	}

	// Output
	// Note : initial_phases[col=0, row] = rough starter guess for the initial phase of slice <row> of the hologram stack
	// Note : initial_phases[col>0, row] = corrected guess for the initial phase of slice <row> used at iteration <col>
	initial_phases.ShowImage()