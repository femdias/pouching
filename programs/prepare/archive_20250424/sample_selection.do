// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: July 2024

// Purpose: Sample selection

*--------------------------*
* BUILD
*--------------------------*

foreach e in spv dir emp {

	use "${data}/evt_panel_m_`e'", clear
		
	// keeping event with complete panel
	bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
	keep if n_emp_pos >= 25 & n_emp_pos < .
	
	// saving list of selected events
	egen unique = tag(event_id)
	keep if unique == 1
	keep event_id
	
	// saving
	save "${data}/sample_selection_`e'", replace
	
}
