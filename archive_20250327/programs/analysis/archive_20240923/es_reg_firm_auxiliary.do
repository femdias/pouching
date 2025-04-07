// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Auxiliary baseline graph			
	
*--------------------------*
* ANALYSIS
*--------------------------*

	use "${data}/evt_panel_m_dir", clear

	// sample restrictions
	merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
	
	// adding event type variables
	merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
	
	// outcome variable: supervisors hired from origin firm / supervisor hired total
	gen ratio_unbal = d_h_spv_o / d_h_spv
	
		// version where . is replaced with 0
		gen ratio_bal = ratio_unbal
		replace ratio_bal = 0 if ratio_unbal == .
			
	// event time dummies		
					
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
		
	// regressions -- event study
	
	foreach var in unbal bal {
	
		// graph 1: director in origin; director in destination 
		
		eststo g1_`var': reghdfe ratio_`var' $evt_vars if type_dir == 1 ///
				& ym_rel >= -9, absorb(event_id) vce(cluster event_id)
			
	}			

	// figures

	clear 
	
	foreach g in 1 {
	foreach var in unbal bal {
	
	coefplot (g`g'_`var', recast(connected) keep(${evt_vars}) msymbol(T) mcolor(emerald) mlcolor(emerald) msize(small) ///
		  levels(95) lcolor(emerald%60) ciopts(lcolor(emerald%60)) lpattern(dash)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months Relative to Poaching Event") ///
		 ytitle("Ratio: (Mgrs Hired from Origin Firm)" "/ (Mgrs Hired Total)") ylabel(-.02(.02).12)
		 
		 graph export "${results}/es_reg_firm_auxiliary_g`g'_`var'.pdf", as(pdf) replace 
		 graph export "${results}/es_reg_firm_auxiliary_g`g'_`var'.png", as(png) replace 
		 
	}
	}
