// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: February 2025

// Purpose: Identify years/months when a joint movement took place

*--------------------------*
* BUILD
*--------------------------*

	forvalues y=2004/2016 {
	
		use "${JointMovements}/JointMovements_`y'", clear
		
		// we might be capturing some movements across firms
		// we want to identify the cases when this is happening
		keep if joint_acrossfirm == 1
		
		// keeping what we need
		keep plant_id joint_acrossfirm
		gen year = `y'
		destring plant_id, force replace
		format plant_id %14.0f
		
		save "${temp}/jointmvt_`y'", replace
		
	}
	
	clear
	
	forvalues y=2004/2016 {
		
		append using "${temp}/jointmvt_`y'"
		
	}
	
	save "${data}/jointmvt", replace
	
*--------------------------*
* CLEANING
*--------------------------*	

	forvalues y=2004/2016 {
		
		cap rm "${temp}/jointmvt_`y'.dta"
		
	}
