/*
=== Description ===

This script launches a dialog window that handles the iterative processing of an arbitrary hologram stack
obtained from either experiment or simulation through the Iterative Parametric Phase Shift (IPPS) method
to yield an object phase map with reduced residual fringes compared to that of the standard Phase Shift (PS).

Additional details can be found at the following source :
[Nogier, A. (2025). Microscopie electronique operando pour l'etude de memoires magnetiques (Doctoral dissertation, Universite Grenoble Alpes [2020-....]).]

=== Input ===

> [Required] This script requires the existence of a hologram stack (real 3D image, Nx * Ny * Nz) on the workspace.
> [Optional] This script can require the existence of a real 1D image containing the starter initial phase values.

=== Requirements ===

> This script does not perform image realignments:
  potential effects of sample drift during acquisition must be corrected beforehand on the hologram stack.

> Hologram order does not matter, nor does any missing slice in the hologram stack,
  except when choosing the <Assume linear> option for the initial phase repartition guess at the start.

> The exact initial phase values targeted during acquisition do not matter either,
  as the actual values can be read from the stack itself to serve as a starter guess anyway.

=== Best use case ===

> A somewhat regular initial phase distribution across a whole number of fringes yields the best results in the final phase map,
  but any distribution is fine as long as at least 2 whole fringes are covered with sufficient, non-redundant values.

> Typically, 5 to 10 iterations are enough to reach a stable minimal residual fringe height:
  a reduction factor of ~10 compared to PS can be expected from an experimental hologram stack with ~50 slices.

=== Output ===

> This script outputs the following objects:
	- "Fringe visibility":
		a 2D real image (Nx * Ny) showing the recovered fringe visibility profile.
	- "Electron wavefront phase":
		a 2D real image (Nx * Ny) showing the recovered electron wave phase map still containing a linear gradient originating from the biprism.
	- "Object phase": 
		a 2D real image (Nx * Ny) showing the corrected phase map with reduced residual fringes and no biprism gradient.
	- "Initial phases":
		a 2D real image (m * Nz) showing each guess of the initial phases repartition across each iteration,
		where m is the maximum number of iterations chosen by the user at the start. 

=== Dialog buttons ===

> [Start] : Launches the iterative process.
	The <Setup> and <Options> dialog boxes must be filled accordingly beforehand.

> [Next] : Proceeds to the next iteration.
	The <Residual fringes> dialog box  must be filled accordingly beforehand.

> [Stop] : Stops the process.
	All images remain open on the workspace and can be saved individually by the user.

> [Recalculate]:
	Proceeds to recalculate the "Object phase" image using the opened "Electron wave phase" image
	and the provided <q-vector> dialog fields.
	This button does not perform any iteration and is independent from the rest of the process.


Created on 2024-12-06 by Augustin Nogier
*/



// Creates a new image from the selected ROI.
// Crops to ROI in the (X, Y) plane but keeps all slices in the (Z) direction.
// @param img: 2D or 3D real image
image CreateImageFromROI(image img)
{
	number size_x = img.ImageGetDimensionSize(0)
	number size_y = img.ImageGetDimensionSize(1)
	number size_z = img.ImageGetDimensionSize(2)

	// Get image display
	imagedisplay disp = img.ImageGetImageDisplay(0)
	number count_ROI = disp.imageDisplayCountROIs()
	
	// Declare ROI edges
	number top, left, bottom, right
	
	// Check for ROI presence - Throw an error if absent
	if (count_ROI != 0)
	{
		// Get ROI edges
		ROI region = disp.ImageDisplayGetROI(0)
		if (region.ROIIsRectangle())
		{	
			region.ROIGetRectangle(top, left, bottom, right)
			
			// Trim ROI edges to image borders
			top = max(top, 0)
			left = max(left, 0)
			bottom = min(bottom, size_y)
			right = min(right, size_x)
			
			// Verbose
			Result( "ROI : [" + left + ", " + top + ", " + right + ", " + bottom + "]\n" )
		}
		else
		{
			beep()
			okdialog("The selected Region Of Interest (ROI) on " + img.GetName() + " must be rectangular.")
			exit(0)
		}
	}
	else
	{
		beep()
		okdialog("Please select a Region Of Interest (ROI) on " + img.GetName())
		exit(0)
	}
	
	// Crop to ROI in XY plane, no crop in Z axis, no binning
	image cropped_img := img.slice3(left,top,0,0,right-left,1,1,bottom-top,1,2,size_z,1)
	
	return cropped_img
}

// Computes the initial phase of a single hologram using the side band central value in Fourier space
// @param img_FFT: 2D complex image, RealFFT() of a hologram
number GetInitialPhaseFromFFT(compleximage img_FFT)
{
	number size_x = img_FFT.ImageGetDimensionSize(0)
	number size_y = img_FFT.ImageGetDimensionSize(1)
	
	image img_modulus = img_FFT.abs()
	
	// Eliminate 0-order peak in modulus image
	img_modulus.SetPixel(size_x/2, size_y/2, 0)
	
	// Get side band peak position from modulus image
	number id_x, id_y
	max(img_modulus, id_x, id_y) // We don't care which peak is selected, since the FFT is Hermitian
	
	// Get initial phase value from side band peak
	return img_FFT.GetPixel(id_x, id_y).phase()
}

// Removes a linear gradient background in a given image
// @param img: 2D real image
// @param vect_x, vect_y: X and Y coordinates of the gradient vector
image RemoveLinearBackground(image img, number vect_x, number vect_y)
{	
	number size_x = img.ImageGetDimensionSize(0)
	number size_y = img.ImageGetDimensionSize(1)
	
	image background = RealImage("", 8, size_x, size_y)
	background = vect_x * (icol - size_x/2) + vect_y * (irow - size_y/2)	// Dot product
	
	return img - background
}

// Wraps an image in a given interval with Euclidean division
// @param img: real image, any dimension
// @param low, high: boundaries of the output values : [low, high[
image Wrap(image img, number low, number high)
{
	return (img - min(img)) % (high - low) + low
}

// Computes the dot product of two vectors
// @param a, b: 1D real images
number Dot(image a, image b)
	{
		return sum(a * b)
	}

// Writes a starter guess for the initial phases values of every hologram 
// @param values: 2D real image, the saved initial phase values for each hologram and iteration
// @param method: number in {0; 1; 2}, identifier of the chosen method for computing the initial phase values
//				: 0 >> Use a linear repartition across [0, span[
//				: 1 >> Use provided external values
//				: 2 >> Compute values using Fourier Transform of the holograms
// @param cropped_stack: 3D real image, a cropped portion of the hologram stack using CreateImageFromROI()
// @param span: real positive number, marks the endpoint of the linear phase distribution in [0, span[
// @param provided: 1D real image, contains provided values of initial phases for each hologram of the stack
void WriteStarterGuessFromMethod(image &values, number method, image cropped_stack, number span, image provided)
{
	number size_x = cropped_stack.ImageGetDimensionSize(0)
	number size_y = cropped_stack.ImageGetDimensionSize(1)
	number size_z = cropped_stack.ImageGetDimensionSize(2)
	
	// Requirements :
	// values.ImageGetDimensionSize(0) == ...		// The maximum number of iterations (user-provided)
	// values.ImageGetDimensionSize(1) == size_z	// The total number of slices
	
	// Method 0: assume a linear phase repartition
	if (method == 0); values.slice1(0,0,0,1,size_z,1) = icol * span / size_z	// In [0, span[

	// Method 1: use provided values
	else if (method == 1); values.slice1(0,0,0,1,size_z,1) = provided		// 1D image
	
	// Method 2: compute phases from FFT side peaks
	else if (method == 2);
	{
		// For each slice
		for (number s = 0; s < size_z; s++)
		{	
			// Extract slice s and compute FFT
			compleximage slice_FFT = cropped_stack.slice2(0,0,s,0,size_x,1,1,size_y,1).realFFT()
			
			// Get an estimation of the initial phase and write it down
			values.SetPixel(0, s, GetInitialPhaseFromFFT(slice_FFT))
		}
	}
	else {}
}

// Computes the coefficients of the matrix used in the Parametric Phase Shifting equations, as well as its inverse.
// @param vect: 1D real image, the current initial phase values for each hologram
// @param sigma_p, sigma_n: complex numbers, non-diagonal coefficients of the matrix, complex conjugates of each other
// @param sigma_2p, sigma_2n: complex numbers, non-diagonal coefficients of the matrix, complex conjugates of each other
// @param delta, lambda: real positive numbers, diagonal coefficients of the inverse matrix
// @param R, Rs: complex numbers, non-diagonal coefficients of the inverse matrix, complex conjugates of each other
// @param S, Ss: complex numbers, non-diagonal coefficients of the inverse matrix, complex conjugates of each other
// @param X: real positive number, determinant of the matrix (up to a constant multiplicative factor)
void ComputeMatrixCoefficients(image vect, number N, complexnumber &sigma_p, complexnumber &sigma_n, complexnumber &sigma_2p, complexnumber &sigma_2n, number &delta, number &lambda, complexnumber &R, complexnumber &Rs, complexnumber &S, complexnumber &Ss, number &X)
{
	// Matrix coefficients
	sigma_p = sum(exp(complex(0,1) * vect))
	sigma_n = sum(exp(complex(0,-1) * vect))
	sigma_2p = sum(exp(complex(0,2) * vect))
	sigma_2n = sum(exp(complex(0,-2) * vect))
	
	// Inverse matrix coefficients
	delta = real(N**2 - sigma_p * sigma_n)
	lambda = real(N**2 - sigma_2p * sigma_2n)

	R = sigma_2p * sigma_n - N * sigma_p
	Rs = sigma_2n * sigma_p - N * sigma_n

	S = sigma_p**2 - N * sigma_2p
	Ss = sigma_n**2 - N * sigma_2n
	
	// Determinant (ignoring a factor of Nz, the numbers of holograms)
	X = real(delta**2 - S * Ss)		// Real determinant is actually X/Nz
}


// Main class
// Contains all methods that use user-provided values from the dialog window
class MainDialog: UIFrame
{
	// Gets an image from a DLGCreateImagePopup() dialog selection 
	image GetSelectedImage(object self, taggroup image_popup)
	{
		string image_label
		image_popup.DLGGetValue(image_label)
		
		return FindImageByLabel(image_label.left(image_label.find(":")))	// Sure, why not
	}
	
	// Stops the process entirely resets buttons and fields on the dialog window
	// Called manually when pressing the <Stop> button
	// Called automatically at the end of the process
	void StopButtonOnPress(object self)
	{
		// Re-enable all dialog objects at the end of the process
		self.SetElementIsEnabled("start_button", 1)
		self.SetElementIsEnabled("box_1", 1)
		self.SetElementIsEnabled("box_2", 1)
		self.SetElementIsEnabled("box_3", 1)
		self.SetElementIsEnabled("box_4", 0)
		
		// Reset iteration counter to 0
		self.LookupElement("current_iteration").DLGValue(0)
	}
	
	// Computes the object phase from the wavefront phase by correcting the linear gradient background originating from the biprism
	// Called manually when pressing the <Recalculate> button
	// Called automatically after each iteration
	void RecalculateButtonOnPress(object self)
	{
		// Get tags from dialog window
		TagGroup q_x_tag = self.LookupElement("q_x")
		TagGroup q_y_tag = self.LookupElement("q_y")
		
		// Get values from tags
		number q_x = q_x_tag.DLGGetValue()
		number q_y = q_y_tag.DLGGetValue()
		
		// Get global images (must be opened on workspace)
		image wavefront_phase := GetNamedImage("Electron wavefront phase")
		image object_phase := GetNamedImage("Object phase")
		
		// Recalculate gradient correction
		object_phase = wavefront_phase.RemoveLinearBackground(2*Pi()*q_x, 2*Pi()*q_y).Wrap(-Pi(), Pi())	// Factor of 2*pi originates from the definition of the q-vector
		
		// Image display updates automatically
	}
	
	// Performs an iteration of the Iterative Parametric Phase Shift process
	// Called manually when pressing the <Next> button
	// Called automatically only when pressing the <Start> button (0-th iteration)
	void NextButtonOnPress(object self)
	{
		// Disable dialog elements during the process
		self.SetElementIsEnabled("box_3", 0)
		self.SetElementIsEnabled("box_4", 0)
		
		// Get tags from dialog window
		TagGroup max_iterations_tag = self.LookupElement("max_iterations")
		TagGroup iter_tag = self.LookupElement("current_iteration")
		TagGroup hologram_stack_tag = self.LookupElement("hologram_stack")
		
		// Get values from tags
		number max_iterations = max_iterations_tag.DLGGetValue()
		number iter = iter_tag.DLGGetValue()
		
		// Special case for images selected through popups
		image hologram_stack := self.GetSelectedImage(hologram_stack_tag)
		
		// Get global images (must be opened on workspace)
		image initial_phases := GetNamedImage("Initial phases")
		image wavefront_phase := GetNamedImage("Electron wavefront phase")
		image visibility := GetNamedImage("Fringe visibility")
		image object_phase := GetNamedImage("Object phase")
		
		// Get hologram stack dimensions
		number Nx = hologram_stack.ImageGetDimensionSize(0)		// X size (px)
		number Ny = hologram_stack.ImageGetDimensionSize(1)		// Y size (px)
		number Nz = hologram_stack.ImageGetDimensionSize(2)		// Z size (px): number of hologram slices
		
		// Get hologram stack ROI
		ROI hologram_ROI = hologram_stack.ImageGetImageDisplay(0).ImageDisplayGetROI(0)
		
		// Declare local H0, H-, H+ quantities
		compleximage H0 := ComplexImage("H0", 16, Nx, Ny)
		compleximage H1 := ComplexImage("H-", 16, Nx, Ny)
		compleximage H2 := ComplexImage("H+", 16, Nx, Ny)

		// Declare local A, B, B* hologram Fourier bands
		compleximage A  := ComplexImage("A",  16, Nx, Ny)
		compleximage B  := ComplexImage("B",  16, Nx, Ny)
		compleximage Bs := ComplexImage("B*", 16, Nx, Ny)
		
		// Declare local useful quantities
		complexnumber sigma_p, sigma_2p, sigma_n, sigma_2n	// Matrix coefficients
		complexnumber R, Rs, S, Ss							// Inverse matrix coefficients
		number Delta, Lambda								// Inverse matrix coefficients
		number X											// Matrix determinant
		
		// Declare local intermediary 1D vectors
		compleximage chi_vector := ComplexImage("Chi vector", 8, Nz)
		image mu := RealImage("Mu vector", 8, Nz)
		image nu := RealImage("Nu vector", 8, Nz)
		
		// Verbose
		Result("Iteration : " + iter + "\n")
		
		// Filter for iteration 0
		if (iter == 0)
		{
			// The residual fringes in the object phase map do not exist at this point, so we need a separate routine.
			// This is handled by StartButtonOnPress()
		}
		else
		{
			// Get tags from dialog window
			TagGroup residual_amplitude_tag = self.LookupElement("residual_amplitude")
			TagGroup residual_phase_tag = self.LookupElement("residual_phase")
			
			// Compute matrix coefficients using the previous batch of initial phases
			image initial_phases_previous_guess := initial_phases.slice1(iter-1,0,0,1,Nz,1)
			ComputeMatrixCoefficients(initial_phases_previous_guess ,Nz, sigma_p, sigma_n, sigma_2p, sigma_2n, Delta, Lambda, R, Rs, S, Ss, X)
			
			// Compute C_N, Phi_N using matrix coefficients and dialog fields
			number C_N = residual_amplitude_tag.DLGGetValue() * X	// Accounting for the multiplicative factor in the amplitude term
			number Phi_N = residual_phase_tag.DLGGetValue()
			
			// Compute initial phase corrections
			chi_vector = Nz * (Delta + exp(complex(0,1) * initial_phases_previous_guess)* Rs + exp(complex(0,2) * initial_phases_previous_guess) * Ss)
			mu = abs(chi_vector) * cos(2 * initial_phases_previous_guess - chi_vector.phase())
			nu = abs(chi_vector) * sin(2 * initial_phases_previous_guess - chi_vector.phase())
			
			image initial_phases_corrections := ((dot(nu, nu) * mu - dot(mu, nu) * nu) * C_N * cos(Phi_N) + (dot(mu, mu) * nu - dot(mu, nu) * mu) * C_N * sin(Phi_N)) / (dot(mu, mu) * dot(nu, nu) - dot(mu, nu)**2)
			
			// Write the current batch of initial phases
			initial_phases.slice1(iter,0,0,1,Nz,1) = initial_phases_previous_guess - initial_phases_corrections
		}
		
		// Compute matrix coefficients using the current batch
		image initial_phases_current_guess := initial_phases.slice1(iter,0,0,1,Nz,1)
		ComputeMatrixCoefficients(initial_phases_current_guess ,Nz, sigma_p, sigma_n, sigma_2p, sigma_2n, Delta, Lambda, R, Rs, S, Ss, X)
		
		// Compute projections along every slice using the current batch
		H0 = project(hologram_stack, 2)																	// Natural sum
		H1 = project(hologram_stack * exp(complex(0,-1) * initial_phases_current_guess[iplane, 0]), 2)	// Weighted sum
		H2 = project(hologram_stack * exp(complex(0, 1) * initial_phases_current_guess[iplane, 0]), 2)	// Weighted sum
		
		// Verbose
		Result("\t> Normalized matrix determinant (0<...<1) : " + X / Nz**4 + "\n")	// Should ideally be close to 1
		
		// Compute the Fourier bands using matrix coefficients
		A  = (Nz / X) * (Lambda * H0 + R     * H1 + Rs    * H2)
		B  = (Nz / X) * (Rs     * H0 + Delta * H1 + Ss    * H2)
		Bs = (Nz / X) * (R      * H0 + S     * H1 + Delta * H2)
		
		// Compute the fringe visibility map
		visibility = abs(B)
		
		// Compute the wavefront phase
		wavefront_phase = phase(B)
		
		// Remove the linear gradient background in the object phase
		self.RecalculateButtonOnPress()
		
		// Output
		visibility.ShowImage()		// 2D fringe visibility map
		wavefront_phase.ShowImage()	// 2D electron wavefront phase map. Note: a staircase-like profile is expected
		object_phase.ShowImage() 	// 2D object phase map. Note: if there is a residual gradient, then the q-vector coordinates must be re-evaluated at the start or tweaked using the <Recalculate> button
		
		// Display hologram stack ROI on output images
		visibility.ImageGetImageDisplay(0).ImageDisplayAddROI(hologram_ROI)
		wavefront_phase.ImageGetImageDisplay(0).ImageDisplayAddROI(hologram_ROI)
		object_phase.ImageGetImageDisplay(0).ImageDisplayAddROI(hologram_ROI)
		
		// Limit iterations to maximum
		if (iter == max_iterations); self.StopButtonOnPress()
		else
		{
			// Add 1 to the iteration counter
			iter_tag.DLGValue(iter + 1)
			
			// Re-enable dialog elements
			self.SetElementIsEnabled("box_3", 1)
			self.SetElementIsEnabled("box_4", 1)
		}
	}
	
	// Launches the first iteration of the Iterative Parametric Phase Shift process
	// Called manually when pressing the <Start> button
	// Never called automatically
	void StartButtonOnPress(object self)
	{
		// Disable all previous dialog objects until the whole process is finished
		self.SetElementIsEnabled("start_button", 0)
		self.SetElementIsEnabled("box_1", 0)
		self.SetElementIsEnabled("box_2", 0)
		self.SetElementIsEnabled("box_3", 0)
		self.SetElementIsEnabled("box_4", 0)
	
		// Get necessary tags from dialog window
		Taggroup max_iterations_tag = self.LookupElement("max_iterations")
		TagGroup hologram_stack_tag = self.LookupElement("hologram_stack")
		TagGroup initial_phases_starter_guess_method_tag = self.Lookupelement("initial_phases_starter_guess_method")
		TagGroup phase_span_tag = self.LookupElement("phase_span")
		TagGroup initial_phases_inherited_guess_tag = self.LookupElement("initial_phases_inherited_guess")
		
		// Get values from tags
		number max_iterations = max_iterations_tag.DLGGetValue()
		number initial_phases_starter_guess_method = initial_phases_starter_guess_method_tag.DLGGetValue()
		number phase_span = phase_span_tag.DLGGetValue()
		
		// Special case for images selected through popups
		image hologram_stack := self.GetSelectedImage(hologram_stack_tag)
		image initial_phases_inherited_guess := self.GetSelectedImage(initial_phases_inherited_guess_tag)
		
		// Get hologram stack dimensions
		number Nx = hologram_stack.ImageGetDimensionSize(0)		// X size (px)
		number Ny = hologram_stack.ImageGetDimensionSize(1)		// Y size (px)
		number Nz = hologram_stack.ImageGetDimensionSize(2)		// Z size (px): number of hologram slices
		
		// Create a cropped version of the hologram stack from the user-selected ROI
		image stack_ROI := CreateImageFromROI(hologram_stack)
		stack_ROI.ImageSetName("Hologram stack ROI")
		
		// Initialization: stack of 1D array of initial phase values as a 2D image
		image initial_phases := RealImage("Initial phases", 8, max_iterations + 1, Nz)
		initial_phases.ShowImage()
		
		// Starter guess for initial phases depending on the user-selected method
		initial_phases.WriteStarterGuessFromMethod(initial_phases_starter_guess_method, stack_ROI, phase_span, initial_phases_inherited_guess)
		
		// Create global output images, set their names
		image wavefront_phase := RealImage("Electron wavefront phase", 8, Nx, Ny)
		image visibility := RealImage("Fringe visibility", 8, Nx, Ny)
		image object_phase := RealImage("Object phase", 8, Nx, Ny)
		
		// Verbose
		Result("\n=== Iterative Parametric Phase Shift ===\n")
		Result("Stack size : (" + Nx + " ; " + Ny + " ; " + Nz + ")\n")
		
		// Perform the first (0-th) iteration of the Iterative Parametric Phase Shift method
		self.NextButtonOnPress()
	}
}


// Makes the first box in the dialog window
TagGroup MakeBox_1()
{
	// Box initialization
	TagGroup box_items
	TagGroup box = DLGCreateBox("Setup", box_items)
	
	// Box layout
	box.DLGLayout(DLGCreateTableLayout(2, 2, 0))
	box.DLGExternalPadding(5,5)
	box.DLGInternalPadding(15,15)
	
	// Element tag groups
	TagGroup hologram_stack_label = DLGCreateLabel("Hologram stack")
	TagGroup hologram_stack_field = DLGCreateImagePopup()
	TagGroup max_iterations_label = DLGCreateLabel("Maximum iterations")
	TagGroup max_iterations_field = DLGCreateIntegerField(5)
	
	// Element anchors
	hologram_stack_label.DLGAnchor("West")
	hologram_stack_field.DLGAnchor("West")
	max_iterations_label.DLGAnchor("West")
	max_iterations_field.DLGAnchor("West")
	
	// Element dimensions
	hologram_stack_label.DLGWidth(20)
	hologram_stack_field.DLGWidth(20)		// Does not work as intended
	max_iterations_label.DLGWidth(20)
	max_iterations_field.DLGWidth(6)
	
	// Element identifiers
	hologram_stack_field.DLGIdentifier("hologram_stack")
	max_iterations_field.DLGIdentifier("max_iterations")
	
	// Add elements to box
	box_items.DLGAddElement(hologram_stack_label)
	box_items.DLGAddElement(hologram_stack_field, "Left")
	box_items.DLGAddElement(max_iterations_label)
	box_items.DLGAddElement(max_iterations_field, "Left")
	
	// Box identifier
	box.DLGIdentifier("box_1")
	
	return box
}

// Makes the second box in the dialog window
TagGroup MakeBox_2()
{
	// Box initialization
	TagGroup box_items
	TagGroup box = DLGCreateBox("Options", box_items)
	
	// Box layout
	box.DLGLayout(DLGCreateTableLayout(1, 6, 0))
	box.DLGExternalPadding(5,5)
	box.DLGInternalPadding(15,15)
	
	// Element tag groups
	TagGroup radio_option = DLGCreateRadioList(2)
	TagGroup phase_span_label = DLGCreateLabel("Phase span")
	TagGroup phase_span_field = DLGCreateRealField(2*Pi())
	TagGroup initial_phases_inherited_guess_label = DLGCreateLabel("Starter values")
	TagGroup initial_phases_inherited_guess_field = DLGCreateImagePopup()

	// Radio items
	radio_option.DLGAddRadioItem("Assume linear", 0)
	radio_option.DLGAddRadioItem("Inherit values from...", 1)
	radio_option.DLGAddRadioItem("Measure from holograms", 2)
	
	// Element anchors
	radio_option.DLGAnchor("West")
	// ...
	
	// Element dimensions
	phase_span_field.DLGWidth(20)
	// ...
	
	// Element identifiers
	radio_option.DLGIdentifier("initial_phases_starter_guess_method")
	phase_span_field.DLGIdentifier("phase_span")
	initial_phases_inherited_guess_field.DLGIdentifier("initial_phases_inherited_guess")

	// Add elements to box
	box_items.DLGAddElement(radio_option)
	box_items.DLGAddElement(phase_span_label)
	box_items.DLGAddElement(phase_span_field, "Left")
	box_items.DLGAddElement(initial_phases_inherited_guess_label)
	box_items.DLGAddElement(initial_phases_inherited_guess_field)
	
	// Box identifier
	box.DLGIdentifier("box_2")
	
	return box
}

// Makes the third box in the dialog window
TagGroup MakeBox_3()
{
	// Box initialization
	TagGroup box_items
	TagGroup box = DLGCreateBox("q-vector", box_items)
	
	// Box layout
	box.DLGLayout(DLGCreateTableLayout(2, 3, 0))
	box.DLGExternalPadding(5,5)
	box.DLGInternalPadding(15,15)
	
	// Element tag groups
	TagGroup q_x_label = DLGCreateLabel("X coordinate")
	TagGroup q_x_field = DLGCreateRealField(0.048)
	TagGroup q_y_label = DLGCreateLabel("Y coordinate")
	TagGroup q_y_field = DLGCreateRealField(0.014)
	TagGroup recalculate_button = DLGCreatePushButton("Recalculate", "RecalculateButtonOnPress")
	
	// Element anchors
	q_x_label.DLGAnchor("West")
	q_x_field.DLGAnchor("West")
	q_y_label.DLGAnchor("West")
	q_y_field.DLGAnchor("West")
	recalculate_button.DLGAnchor("Center")
	
	// Element dimensions
	q_x_label.DLGWidth(15)
	q_x_field.DLGWidth(15)
	q_y_label.DLGWidth(15)
	q_y_field.DLGWidth(15)
	
	// Element identifiers
	q_x_field.DLGIdentifier("q_x")
	q_y_field.DLGIdentifier("q_y")
	recalculate_button.DLGIdentifier("recalculate_button")
	
	// Add elements to box
	box_items.DLGAddElement(q_x_label)
	box_items.DLGAddElement(q_x_field, "Left")
	box_items.DLGAddElement(q_y_label)
	box_items.DLGAddElement(q_y_field, "Left")
	box_items.DLgAddElement(recalculate_button)
	
	// Box identifier
	box.DLGIdentifier("box_3")
	
	return  box
}

// Makes the fourth box in the dialog window
TagGroup MakeBox_4()
{
	// Box initialization
	TagGroup box_items
	TagGroup box = DLGCreateBox("Residual fringes", box_items)
	
	// Box layout
	box.DLGLayout(DLGCreateTableLayout(2, 3, 0))
	box.DLGExternalPadding(5,5)
	box.DLGInternalPadding(15,15)
	
	// Element tag groups
	TagGroup residual_amplitude_label = DLGCreateLabel("Amplitude")
	TagGroup residual_amplitude_field = DLGCreateRealField(0.1)
	TagGroup residual_phase_label = DLGCreateLabel("Phase")
	TagGroup residual_phase_field = DLGCreateRealField(0.0)
	TagGroup stop_button = DLGCreatePushButton("Stop", "StopButtonOnPress")
	TagGroup next_button = DLGCreatePushButton("Next", "NextButtonOnPress")
	
	// Element anchors
	residual_amplitude_label.DLGAnchor("West")
	residual_amplitude_field.DLGAnchor("West")
	residual_phase_label.DLGAnchor("West")
	residual_phase_field.DLGAnchor("West")
	stop_button.DLGAnchor("West")
	next_button.DLGAnchor("West")
	
	// Element dimensions
	residual_amplitude_label.DLGWidth(15)
	residual_amplitude_field.DLGWidth(15)
	residual_phase_label.DLGWidth(15)
	residual_phase_field.DLGWidth(15)
	
	// Element identifiers
	residual_amplitude_field.DLGIdentifier("residual_amplitude")
	residual_phase_field.DLGIdentifier("residual_phase")
	stop_button.DLGIdentifier("stop_button")
	next_button.DLGIdentifier("next_button")
	
	// Add elements to box
	box_items.DLGAddElement(residual_amplitude_label)
	box_items.DLGAddElement(residual_amplitude_field)
	box_items.DLGAddElement(residual_phase_label)
	box_items.DLGAddElement(residual_phase_field)
	box_items.DLGAddElement(stop_button)
	box_items.DLGAddElement(next_button, "Left")
	
	// Box identifier
	box.DLGIdentifier("box_4")
	
	return  box
}

// Creates and displays the main dialog window
void CreateMainDialog()
{	
	// Clear output text
	ClearResults()
	
	// Dialog position and dimensions
	TagGroup position = DLGBuildPositionFromApplication()
	position.TagGroupSetTagAsTagGroup("Width", DLGBuildAutoSize())		// If DLGBuildAbsoluteSize(number inches) is used, then unusable ghost popups appear
	position.TagGroupSetTagAsTagGroup("Height", DLGBuildAutoSize())
	position.TagGroupSetTagAsTagGroup("X", DLGBuildRelativePosition("Inside", 1))
	position.TagGroupSetTagAsTagGroup("Y", DLGBuildRelativePosition("Inside", 1))
	
	// Main dialog
	TagGroup dialog_items
	TagGroup dialog_tags = DLGCreateDialog("Main Dialog", dialog_items)
	dialog_tags.DLGPosition(position)
	
	// Boxes
	dialog_items.DLGAddElement(MakeBox_1())
	dialog_items.DLGAddElement(MakeBox_2())
	dialog_items.DLGAddElement(MakeBox_3())
	dialog_items.DLGAddElement(MakeBox_4())
	
	// Start button
	TagGroup start_button = DLGCreatePushButton("Start", "StartButtonOnPress")
	start_button.DLGIdentifier("start_button")
	dialog_items.DLGAddElement(start_button)
	
	// Iteration counter, initialized to zero
	TagGroup current_iteration = DLGCreateIntegerField(0)
	current_iteration.DLGIdentifier("current_iteration")
	dialog_items.DLGAddElement(current_iteration)
	
	// Create the dialog window
	object dialog_frame = Alloc(MainDialog)
	dialog_frame.Init(dialog_tags)
	dialog_frame.Display("Main Dialog")
	
	// Initialize disabled elements
	dialog_frame.SetElementIsEnabled("box_4", 0)
	dialog_frame.SetElementIsEnabled("current_iteration", 0)
	
	// Control for development purposes
	// dialog_items.TagGroupOpenBrowserWindow(0)
}

// Issues :
// > Popup width are auto-build

// TODO :
// > Catch cases depending on the method (missing providers) + check same size between stack Z and provided initial guess X
// > Choose which peak in FFT gives the initial phase (must be reliable even with noise)
// > Work with unique image ID instead of names (duplicates if restart)


// Main script
CreateMainDialog()