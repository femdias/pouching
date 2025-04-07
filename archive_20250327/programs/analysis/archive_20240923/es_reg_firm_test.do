// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: July 2024

// Purpose: Event study around poaching events			
	
*--------------------------*
* ANALYSIS
*--------------------------*

	local title_dir "Mgr: Director"
	local title_spv "Mgr: Supervisor"
	local title_emp "Not Mgr"
	local title_mgr "Manager"

*foreach e in dir spv emp mgr {
foreach e in mgr {
	
if "`e'" != "mgr" {	

	use "${data}/evt_panel_m_`e'", clear

	// sample restrictions
	merge m:1 event_id using "${temp}/sample_selection_`e'", keep(match) nogen
	
} 

if "`e'" == "mgr" {

	use "${data}/evt_panel_m_dir", clear
	merge m:1 event_id using "${temp}/sample_selection_dir", keep(match) nogen
	tempfile dir
	save `dir'
	
	use "${data}/evt_panel_m_spv", clear
	merge m:1 event_id using "${temp}/sample_selection_spv", keep(match) nogen
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
		
			// organize this!
			gen ratio = d_h_emp_o / d_h_emp
			replace ratio = 0 if ratio == .
			
			*gen ratio = d_h_dir_o / d_h_dir
			*replace ratio = 0 if ratio == .
			
			
			*gen ratio = d_h_spv_o / d_h_spv
			*replace ratio = 0 if ratio == . | ratio < 0
			egen  any_spv = max(d_h_spv_o), by(event_id)
			egen  any_dir = max(d_h_dir_o), by(event_id)
			*egen any = max(d_h_spv_o), by(event_id)

		// version where missing points are replaced with a 0
		gen d_h_o_d_h_sanspc_0 = d_h_o_d_h_sanspc
		replace d_h_o_d_h_sanspc_0 = 0 if d_h_o_d_h_sanspc_0 == .
		
 
			
			
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
	/*		
	eststo `e'_ini: reghdfe d_h_o_d_h_sanspc_0 $evt_vars if pc_ym >= ym(2004,1) & pc_ym <= ym(2007,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id) 
		
	eststo `e'_sec: reghdfe d_h_o_d_h_sanspc_0 $evt_vars if pc_ym >= ym(2008,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		
	eststo 	`e'_all: reghdfe d_h_o_d_h_sanspc_0 $evt_vars if pc_ym >= ym(2004,1) & pc_ym <= ym(2016,12) ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		*/
		
		
		*eststo `e'_all: reghdfe ratio $evt_vars if pc_ym >= ym(2004,1) & pc_ym <= ym(2016,12) & any_max > 0 ///
		*& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		
		eststo 	`e'_all: reghdfe ratio $evt_vars if pc_ym >= ym(2004,1) & pc_ym <= ym(2016,12)  ///
		& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		
		*eststo `e'_all: reghdfe ratio $evt_vars if pc_ym >= ym(2004,1) & pc_ym <= ym(2016,12) & any_spv > 0 & any_dir > 0 ///
		*& ym_rel >= -9, absorb(event_id d_plant) vce(cluster event_id)
		
}
					
clear

// figures

	local e mgr

*foreach p in ini sec all {
foreach p in all {	
	
	coefplot (`e'_`p', recast(connected) keep(${evt_vars}) msymbol(T) mcolor(emerald) mlcolor(emerald) msize(small) ///
		  levels(95) lcolor(emerald%60) ciopts(lcolor(emerald%60)) lpattern(dash)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "`title_`e''") rows(1) region(lcolor(white)) pos(2) ring(0)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months Relative to Poaching Event") ///
		 ytitle("Share of New Hires (Monthly)" "from Same Firm as Poached Worker") ///
		 name(`e'_`p'_1, replace)
		 *ylabel(-.02(.02).08)
		 
		 *graph export "${results}/es_reg_firm_test_`p'_`e'.pdf", as(pdf) replace
		 

}

