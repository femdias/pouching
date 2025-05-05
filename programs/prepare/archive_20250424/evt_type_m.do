// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: identifying event types (using destination occupation)

*--------------------------*
* BUILD
*--------------------------*

foreach e in spv dir emp {
	
	forvalues ym=528/683 {		
	
	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
	
	if _N > 0 {

		gen d_pc_dir = (pc == 1 & dir ==1)
		gen d_pc_spv = (pc == 1 & spv ==1)
		gen d_pc_emp = (pc == 1 & dir == 0 & spv == 0)
		
		collapse (max) d_pc_dir d_pc_spv d_pc_emp, by(event_id)
			
		save "${temp}/type_`e'_`ym'", replace
	}
	
	}
	
	clear
	
	forvalues ym=528/683 {
		
		cap append using "${temp}/type_`e'_`ym'"
		
	}
	
	// labeling variables
	
	label var d_pc_dir "Poached individual is a director at dest. firm"
	label var d_pc_spv "Poached individual is a supervisor at dest. firm"
	label var d_pc_emp "Poached individual is a worker at dest. firm"
	
	// these are not mutually exclusive categories
	// e.g., if two individuals are poached, one might be hired as a director and the other as a supervisor
	// we remove these cases from the analysis
		
	gen n_types = d_pc_dir + d_pc_spv + d_pc_emp
	drop if n_types != 1
	drop n_types
	
	save "${data}/evt_type_m_`e'", replace
				
}

*--------------------------*
* EXIT
*--------------------------*

clear

foreach e in spv dir emp {
forvalues ym=528/683 {
	
	cap rm "${temp}/type_`e'_`ym'.dta"
	
}
}










