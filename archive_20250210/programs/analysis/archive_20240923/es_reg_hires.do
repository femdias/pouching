// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: JULY 2024

// Purpose: Event study around poaching events (hire-level analysis)			
	
*--------------------------*
* ANALYSIS
*--------------------------*

// all figures

	use "output/data/hires_panel_m_dir", clear

	// sample restrictions

	merge m:1 event_id using "temp/evt_list_dir", keep(match) nogen
	
	// event time dummies
	
	gen ym_rel = ym - pc_ym
				
	forvalues i = -12/12 {
		if (`i' < 0) {
			local j = abs(`i')
			gen evt_l`j' = (ym_rel == `i')
		}
		else if `i' >= 0 {
			gen evt_f`i' = (ym_rel == `i') 
		}
	}
		
	// event zero for graphing purposes
	gen evt_zero = 1
	
// defining locals for regressions		
local evt_vars evt_l9 evt_l8 evt_l7 evt_l6 evt_l5 evt_l4 evt_l3 evt_zero evt_l1 ///
	       evt_f0 evt_f1 evt_f2 evt_f3 evt_f4 evt_f5 evt_f6 evt_f7 evt_f8 evt_f9 evt_f10 evt_f11 evt_f12
					
// now for the regressions

	// present different versions, modifying the baseline period!!!				

	*areg raid `evt_vars' if ym_rel >= -9 & poach == 0, absorb(event_id) vce(cluster event_id) 
	*reghdfe raid `evt_vars' if ym_rel >= -9 & poach == 0, absorb(event_id d_plant) vce(cluster event_id) 
	
	
	*coefplot, omitted keep(`evt_vars') vertical yline(0)
	
	coefplot, omitted keep(`evt_vars')  xline(0)
	
	
	
	
	
	
	
	
	
	reg raid `evt_vars' if ym_rel >= -9 & poach == 0 // not clear to me that we should have the event FE
	
	// note that this is NOT an event study -- we are not observing the same units over time
	// if we want something at the hire level, then we should probably have something more similar to Ian's paper
 
	
				
	coefplot, omitted keep(`evt_vars') vertical yline(0)
	

	
