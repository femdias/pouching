// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: February 2025

// Purpose: Calculate industry growth (employment)

*--------------------------*
* BUILD
*--------------------------*

	forvalues ym = 552/695 { // industry variable only available after ym=552 (2006m1)
	
		use "${data}/rais_m/rais_m`ym'", clear
	
		keep cnae20_class
		
		// 2-digit industry
		tostring cnae20_class, replace format(%05.0f)
		rename cnae20_class cnae20_class_2d
		
		// collapsing at the industry level
		gen count = 1
		collapse (sum) n_emp=count, by(cnae20_class_2d)
		gen ym = `ym'
		
		order cnae20_class_2d ym n_emp
		sort cnae20_class_2d
		
		save "${temp}/industrygrowth_m`ym'", replace
	
	}
	
	// appending all months
	
	clear
	
	forvalues ym=552/695 {
		
		append using "${temp}/industrygrowth_m`ym'"
		
	}
	
	save "${data}/industrygrowth_m", replace
	
			// ORGANIZE AS A PANEL DATA SET
			// CALCULATA DELTAS (EMPLOYMENT GROWTH)
	
	
*--------------------------*
* EXITING
*--------------------------*

clear

forvalues ym=552/695 {
	
	cap erase "${temp}/industrygrowth_m`ym'.dta"
	
}

	
	
