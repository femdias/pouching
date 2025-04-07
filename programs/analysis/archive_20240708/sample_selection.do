// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Sample selection

*--------------------------*
* BUILD
*--------------------------*

// auxiliary data set: identifying events where the poached director stays in the new firm

	use "output/data/cowork_panel_m_rs_dir", clear
	
	// identifying the poached individuals among the coworkers
	
	bysort event_id cpf: gen pc = ym_rel == 0 & (dir[_n-1] == 1) & (plant_id[_n-1] == o_plant) & (plant_id == d_plant)
	
		// test: do all events have a poached individual?
		*egen test = max(pc), by(event_id) // yes!
		
	// expanding for the entire individual and only keeping them
	
	egen pc_individual = max(pc), by(event_id cpf)
	keep if pc_individual == 1
	
	// employed in d_plant after the poaching in all months
	gen emp_d_plant = (plant_id == d_plant) & ym_rel >= 0
	egen total_emp_d_plant = sum(emp_d_plant), by(event_id cpf)
	
	// identifying these events
	collapse (max) total_emp_d_plant, by(event_id) 
	
	// saving
	save "temp/total_emp_d_plant", replace
	
// auxiliary data set: identifying events of interest, after imposing all sample restrictions

	use "output/data/evt_panel_m_rs_dir", clear

	// sample restrictions
	
		// dropping outlier events
		drop if event_id == 100 // hire thousands of employees; probably tranfers or reporting issue

		// keeping events with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25 & n_emp_pos < .
		
		// keeping events where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13 & total_emp_d_plant < .
		
	// listing events
	egen unique = tag(event_id)
	keep if unique == 1
	keep event_id d_plant pc_ym
	
	save "output/data/sample_selection_dir", replace
	
// dropping temp files

erase "temp/total_emp_d_plant.dta"	
	
