// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 7
// "Raided workers are, on average, of higher ability than non-raided workers"
// This analysis: match quality (how long are raided vs. non-raided workers employed) 

*--------------------------*
* ANALYSIS
*--------------------------*

	// looping over windows
	*foreach w in 1 2 3 {
	foreach w in 3 {

	use "${temp}/workers_`w'y", clear
	
	drop if ym > ym(2017,12)
	
	levelsof ym, local(months)
	
	foreach ym of local months {
	
		use "${data}/rais_m/rais_m`ym'", clear
		
		keep cpf ym plant_id 
		
		merge 1:1 cpf ym using "${temp}/workers_`w'y"
		keep if _merge == 3
		drop _merge
		
		save "${temp}/`w'y_`ym'", replace
	
	}
	}
	
	
	
	
	
	
