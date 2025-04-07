// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Calculating wages of coworkers

*--------------------------*
* BUILD
*--------------------------*

// organizing data set

	use "output/data/cowork_panel_m_rs_dir", clear
	
	// identifying poached coworkers
	
		gen pc_coworker = (pc_individual == 0) & (ym_rel>=0) & (plant_id[_n-1] != d_plant) & (plant_id == d_plant)
		
			tab pc_coworker
		
		egen n_pc_coworkers = max(pc_coworker), by(event_id)
		
			egen unique = tag(event_id)
			tab n_pc_coworkers if unique == 1
			
		egen total_pc_coworkers = sum(pc_coworker), by(event_id)	
		
	// what do we want to calculate here?
		
	collapse (mean) wage_real_ln total_pc_coworkers if pc_coworker == 1, by(event_id)
	rename wage_real_ln wage_real_ln_cw 
		
	save "output/data/wage_real_ln_cw", replace
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
