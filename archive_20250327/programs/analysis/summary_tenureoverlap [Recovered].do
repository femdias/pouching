// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: March 2025

// Purpose: Summary stats related to tenure overlap

*--------------------------*
* SET UP
*--------------------------*

// starting with one cohort

	foreach e in spv emp dir {
	forvalues ym=528/683 {
		
	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear	
		
		if _N > 0 {
	
		// stat 1: number of employees they overlap with for the full tenure
			
			// poached manager tenure when poached
			gen tenure_pc_temp = tenure_ym_pc if ym_rel == -1
			egen tenure_pc = max(tenure_pc_temp), by(event_id)
			replace tenure_pc = . if n_pc != 1 
			drop tenure_pc_temp
			
			// who they've overlap with the entire time
			gen full_overlap = (tenure_pc == tenure_overlap) 
			replace full_overlap = . if tenure_pc == . | tenure_overlap == .
		
		// stat 2: average tenure overlap
		* we already have a variable for this: tenure_overlap
		
		// stat 3: average tenure overlap with individuals who were raided
		gen tenure_overlap_raided = tenure_overlap if raid_individual == 1
		
		// collapse
		
		drop if pc_individual == 1
		egen unique = tag(event_id cpf)
		keep if unique == 1
		
		collapse (mean) full_overlap tenure_overlap tenure_overlap_raided ///
			(sum) full_overlap_sum=full_overlap tenure_overlap_sum=tenure_overlap ///
			tenure_overlap_raided_sum=tenure_overlap_raided, by(event_id)
		
		save "${temp}/tenureoverlap_`e'_`ym'", replace
		
		}
	
	}
	}
	
	// appending by event type
	
	foreach e in spv emp dir {
	
	clear
	
	forvalues ym=528/683 {
	
		cap append using "${temp}/tenureoverlap_`e'_`ym'"
	
	}
	
	save "${temp}/tenureoverlap_`e'", replace
	
	}
	
	

	
	
	
	
	
			
