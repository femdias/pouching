// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Wage analysis (distribution before vs. after poaching)

*--------------------------*
* ANALYSIS
*--------------------------*

use "output/data/cowork_panel_m_rs_dir", clear
	
	// sample selection 
	merge m:1 event_id using "output/data/sample_selection_dir", keep(match) nogen
	 
	// only one observaton per poached individual
	keep if pc_individual == 1
	egen unique = tag(event_id cpf)
	keep if unique == 1
	
	// hypothesis: managers earn more after being poached
	
		twoway (kdensity wage_l12) ///
			(kdensity wage_0) 
			
		summ wage_l12 wage_0, detail // 18% increase (8.03 vs. 8.21)
		
		gen wage_delta = wage_0 - wage_l12
		summ wage_delta, detail // increases in most cases
		
		gen wage_delta_pos = (wage_delta >0 & wage_delta < .)
		tab wage_delta_pos // increases in 70.59% of the cases
		
