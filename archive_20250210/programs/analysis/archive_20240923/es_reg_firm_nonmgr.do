// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Include non-manager line in baseline graph			
	
*--------------------------*
* ANALYSIS
*--------------------------*

// baseline graphs -- store the estimates

	do "${analysis}/es_reg_firm_baseline"
	
// non-manager events	

	use "${data}/archive_20240725/evt_panel_m_emp", clear

	// sample restrictions
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	
	// adding event type variables
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	
	// outcome variable: employees hired from origin firm / employees hired total
	// important: in this case, I have to remove the poached individuals from both the numerator and denominator
	
	gen ratio_unbal = (d_h_emp_o - d_h_emp_o_pc) / (d_h_emp	- d_h_emp_o_pc)
	
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
	
		// graph nonmgr: non-mgr in origin; non-mgr in destination 
		
		eststo gnonmgr_`var': reghdfe ratio_`var' $evt_vars if type_emp == 1 ///
				& ym_rel >= -9, absorb(event_id) vce(cluster event_id)
					
	}			

// figures

	clear 
	
	foreach g in 1 2 3 {
	foreach var in unbal bal {
	
	coefplot (g`g'_`var', recast(connected) keep(${evt_vars}) msymbol(T) mcolor(emerald) mlcolor(emerald) msize(small) ///
		  levels(95) lcolor(emerald%60) ciopts(lcolor(emerald%60)) lpattern(dash)) ///
		 (gnonmgr_`var', recast(connected) keep(${evt_vars}) msymbol(X) mcolor(cranberry) mlcolor(cranberry) msize(small) ///
		  levels(95) lcolor(cranberry%60) ciopts(lcolor(cranberry%60)) lpattern(dash_dot)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months Relative to Poaching Event") ///
		 ytitle("Ratio: (Non-Mgrs Hired from Origin Firm)" "/ (Non-Mgs Hired Total)") ylabel(-.02(.02).12) ///
		 legend(order(2 "Mgr is Poached" 4 "Non-Mgr is Poached") rows(1) region(lcolor(white)) pos(12) ring(0)) ///
		 
		 
		 graph export "${results}/es_reg_firm_nonmgr_g`g'_`var'.pdf", as(pdf) replace 
		 graph export "${results}/es_reg_firm_nonmgr_g`g'_`var'.png", as(png) replace 
		 
	}
	}
