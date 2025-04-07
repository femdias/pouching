// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: identifying event types (using destination occupation)

*--------------------------*
* BUILD
*--------------------------*

*foreach e in spv dir emp dir5 {
foreach e in emp {
	
	forvalues ym=528/683 {		
	
	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
	
	if _N > 0 {

		gen d_dir = (pc == 1 & dir ==1)
		gen d_spv = (pc == 1 & spv ==1)
		gen d_emp = (pc == 1 & dir == 0 & spv == 0)
		
		collapse (max) d_dir d_spv d_emp, by(event_id)
			
		save "${temp}/type_`e'_`ym'", replace
	}
	
	}
	
	clear
	
	forvalues ym=528/683 {
		
		cap append using "${temp}/type_`e'_`ym'"
		
	}
	
	rename d_emp type_emp
	rename d_dir type_dir
	rename d_spv type_spv
	
	save "${data}/evt_type_m_`e'", replace
			
}

*--------------------------*
* EXIT
*--------------------------*

clear

foreach e in spv dir emp dir5 {
forvalues ym=528/683 {
	
	cap rm "${temp}/type_`e'_`ym'.dta"
	
}
}










