// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: July 2024

// Purpose: Event study around poaching events			
	
*--------------------------*
* ANALYSIS
*--------------------------*

*foreach e in dir spv emp mgr {
foreach e in dir spv {	
	
if "`e'" != "mgr" {	

	use "${data}/evt_panel_m_`e'", clear

	// sample restrictions
	merge m:1 event_id using "${data}/sample_selection_`e'", keep(match) nogen
	
} 

if "`e'" == "mgr" {

	use "${data}/evt_panel_m_dir", clear
	merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
	tempfile dir
	save `dir'
	
	use "${data}/evt_panel_m_spv", clear
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	tempfile spv
	save `spv'
	
	use `dir', clear
	append using `spv'
	
} 	
	
	// outcome variable: percentage of hires from origin firm

		// total number of hires in destination plant
		gen d_h = d_h_dir + d_h_spv + d_h_emp
			
		// number of hirings from origin plant (only poached individuals)
		gen d_h_o_pc = d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc
			
		// number of hirings from origin plant (excluding poached individuals)
		gen d_h_o_sanspc = (d_h_dir_o + d_h_spv_o + d_h_emp_o) - d_h_o_pc			
			
		// num: number of hirings from origin plant (excluding poached individuals) 
		// den: total number of hires in destination plant (excluding poached individuals) 
		gen d_h_o_d_h_sanspc = d_h_o_sanspc / (d_h - d_h_o_pc)
	
		// version where missing points are replaced with a 0
		gen d_h_o_d_h_sanspc_0 = d_h_o_d_h_sanspc
		replace d_h_o_d_h_sanspc_0 = 0 if d_h_o_d_h_sanspc_0 == .
		
	// outcome variable: percentage of employees hired from origin firm
 	
		// num: number of employees hired from origin plant (by definition, this excludes poached individuals)
		// den: total number of employees hiref in destination plant (excluding poached individuals)
		
		
		*gen d_h_emp_o_d_h_sanspc = (d_h_emp_o - d_h_emp_o_pc) / (d_h_emp - d_h_emp_o_pc)
		
		
				gen d_h_emp_o_d_h_sanspc = (d_h_emp_o) / (d_h - d_h_o_pc)
		
		// version where missing points are replaced with a 0
		gen d_h_emp_o_d_h_sanspc_0 = d_h_emp_o_d_h_sanspc
		replace d_h_emp_o_d_h_sanspc_0 = 0 if d_h_emp_o_d_h_sanspc_0 == .
		
	// outcome variable: percentage of supervisors hired from origin firm
	
		gen d_h_spv_o_d_h_sanspc = d_h_spv_o / (d_h - d_h_o_pc)
		
		// version where missing points are replaced with a 0
		gen d_h_spv_o_d_h_sanspc_0 = d_h_spv_o_d_h_sanspc
		replace d_h_spv_o_d_h_sanspc_0 = 0 if d_h_spv_o_d_h_sanspc_0 == .
		
			
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
		
	// regression -- event study
	
	
	// outcome variable: percentage of hires from origin firm
		
	eststo 	`e'_all_all: reghdfe d_h_o_d_h_sanspc_0 $evt_vars if pc_ym >= ym(2004,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
	
	// outcome variable: percentage of employees hired from origin firm
		
	eststo 	`e'_emp_all: reghdfe d_h_emp_o_d_h_sanspc_0 $evt_vars if pc_ym >= ym(2004,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		
	// outcome variable: percentage of supervisors hired from origin firm
	
	eststo 	`e'_spv_all: reghdfe d_h_spv_o_d_h_sanspc_0 $evt_vars if pc_ym >= ym(2004,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
}

// figures -- August 22, 2024

	 
	coefplot (dir_all_all, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(emerald) mlcolor(emerald) msize(small) ///
		  levels(95) lcolor(emerald%60) ciopts(lcolor(emerald%60)) lpattern(dash)) ///
		 (spv_all_all, recast(connected) keep(${evt_vars}) msymbol(O) mcolor(maroon) mlcolor(maroon) msize(small) ///
		  levels(95) lcolor(maroon%60) ciopts(lcolor(maroon%60)) lpattern(dash)) /// 
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Mgr: Director" 4 "Mgr: Supervisor") rows(1) region(lcolor(white)) pos(12) ring(0)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months Relative to Poaching Event") ///
		 ytitle("Share of New Hires (Monthly)" "from Same Firm as Poached Worker") ylabel(-.02(.02).08)
		 
		 graph export "${results}/es_reg_firm_all_all.pdf", as(pdf) replace
		 
	coefplot (dir_emp_all, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(emerald) mlcolor(emerald) msize(small) ///
		  levels(95) lcolor(emerald%60) ciopts(lcolor(emerald%60)) lpattern(dash)) ///
		 (spv_emp_all, recast(connected) keep(${evt_vars}) msymbol(O) mcolor(maroon) mlcolor(maroon) msize(small) ///
		  levels(95) lcolor(maroon%60) ciopts(lcolor(maroon%60)) lpattern(dash)) /// 
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Mgr: Director" 4 "Mgr: Supervisor") rows(1) region(lcolor(white)) pos(12) ring(0)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months Relative to Poaching Event") ///
		 ytitle("Share of New Hires (Monthly)" "from Same Firm as Poached Worker") ylabel(-.02(.02).08)
		 
		 graph export "${results}/es_reg_firm_emp_all.pdf", as(pdf) replace
		 
		 /*
		 
	coefplot (dir_spv_all, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(emerald) mlcolor(emerald) msize(small) ///
		  levels(95) lcolor(emerald%60) ciopts(lcolor(emerald%60)) lpattern(dash)) /// 
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Mgr: Director") rows(1) region(lcolor(white)) pos(12) ring(0)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months Relative to Poaching Event") ///
		 ytitle("Share of New Hires (Monthly)" "from Same Firm as Poached Worker") ylabel(-.02(.02).08)
		 
		 graph export "${results}/es_reg_firm_spv_all.pdf", as(pdf) replace	 
	 


	
/* 

// figures -- July 3, 2024 meeting
	
	coefplot (dir, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(emerald) mlcolor(emerald) msize(small) ///
		  levels(95) lcolor(emerald%60) ciopts(lcolor(emerald%60)) lpattern(dash)) ///
		 (spv, recast(connected) keep(${evt_vars}) msymbol(O) mcolor(maroon) mlcolor(maroon) msize(small) ///
		  levels(95) lcolor(maroon%60) ciopts(lcolor(maroon%60)) lpattern(dash)) ///
		 (emp, recast(connected) keep(${evt_vars}) msymbol(Dh) mcolor(navy) mlcolor(navy) msize(small) ///
		  levels(95) lcolor(navy%60) ciopts(lcolor(navy%60)) lpattern(dash)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Mgr: Director" 4 "Mgr: Supervisor" 6 "Not Mgr") rows(1) region(lcolor(white)) pos(12) ring(0)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months Relative to Poaching Event") ///
		 ytitle("Share of New Hires (Monthly)" "from Same Firm as Poached Worker") ylabel(-.02(.02).08)
		 
		 graph export "output/results/es_reg_firm.pdf", as(pdf) replace
		 

	coefplot (mgr, recast(connected) keep(${evt_vars}) msymbol(O) mcolor(maroon) mlcolor(maroon) msize(small) ///
		  levels(95) lcolor(maroon%60) ciopts(lcolor(maroon%60)) lpattern(dash)) ///
		 (emp, recast(connected) keep(${evt_vars}) msymbol(Dh) mcolor(navy) mlcolor(navy) msize(small) ///
		  levels(95) lcolor(navy%60) ciopts(lcolor(navy%60)) lpattern(dash)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Manager" 4 "Not Manager") rows(1) region(lcolor(white)) pos(12) ring(0)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months Relative to Poaching Event") ///
		 ytitle("Share of New Hires (Monthly)" "from Same Firm as Poached Worker") ylabel(-.02(.02).08)
		 
	graph export "output/results/es_reg_firm_mgr.pdf", as(pdf) replace	 

