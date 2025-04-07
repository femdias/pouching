// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2024

// Purpose: Reconstructing the list of employee events

*--------------------------*
* BUILD
*--------------------------*

// 1. Reconstructing the list of employee events

	use "output/data/archive_20240506/cowork_panel_m_rs_emp", clear

	// make sure that all events have a poached individual following the old criteria
	
	bysort event_id cpf: gen pc = ym_rel == 0 & (dir == 0 & spv == 0) & (plant_id[_n-1] == o_plant) & (plant_id == d_plant)
	
		// test: do all events have a poached individual?
		egen test = max(pc), by(event_id)
		tab test // yes!
		drop test
		
	// moving to an event-level data set
	
	egen unique = tag(event_id d_plant pc_ym o_plant)
	keep if unique == 1
	drop unique
	
		// testing for duplicates within event_id
		duplicates tag event_id, generate(dupli)
		tab dupli // no duplicates! perfect!
		
	// this is the list of events I lost! save it
	
	keep event_id d_plant pc_ym o_plant 
	save "temp/rec_evt_m_rs_emp", replace
	
