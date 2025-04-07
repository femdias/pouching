// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: July 2024

// Purpose: Event study around poaching events
// Heterogeneity by origin firm size				
	
*--------------------------*
* ANALYSIS
*--------------------------*
	
foreach e in dir spv emp mgr {
	
if "`e'" != "mgr" {	

	use "output/data/evt_panel_m_`e'", clear

	// sample restrictions
	merge m:1 event_id using "temp/sample_selection_`e'", keep(match) nogen
	
} 

if "`e'" == "mgr" {

	use "output/data/evt_panel_m_dir", clear
	merge m:1 event_id using "temp/sample_selection_dir", keep(match) nogen
	tempfile dir
	save `dir'
	
	use "output/data/evt_panel_m_spv", clear
	merge m:1 event_id using "temp/sample_selection_spv", keep(match) nogen
	tempfile spv
	save `spv'
	
	use `dir', clear
	append using `spv'	
	
} 

	gen d_size_temp = d_emp if ym_rel == 0
	egen d_size = max(d_size_temp), by(event_id)
	
		label var d_size "Firm Size (Destination)"
		summ d_size if ym_rel == 0, detail

	gen size_g = .
	replace size_g = 1 if d_size <= 199
	replace size_g = 2 if d_size >= 200 & d_size <= 399
	replace size_g = 3 if d_size >= 400 & d_size <= 799
	replace size_g = 4 if d_size >= 800 & d_size < .
	
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
	
	foreach t in 1 2 3 4 {
			
	eststo `e'_`t': reghdfe d_h_o_d_h_sanspc_0 $evt_vars if ym_rel >= -9 & size_g == `t', ///
		    absorb(event_id d_plant) vce(cluster event_id) 
		        
	
	}
	
	// figures
	
	coefplot (`e'_1, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(emerald) mlcolor(emerald) msize(small) ///
		  levels(95) lcolor(emerald%60) ciopts(lcolor(emerald%60)) lpattern(dash)) ///
		 (`e'_2, recast(connected) keep(${evt_vars}) msymbol(O) mcolor(maroon) mlcolor(maroon) msize(small) ///
		  levels(95) lcolor(maroon%60) ciopts(lcolor(maroon%60)) lpattern(dash)) ///
		 (`e'_3, recast(connected) keep(${evt_vars}) msymbol(Dh) mcolor(navy) mlcolor(navy) msize(small) ///
		  levels(95) lcolor(navy%60) ciopts(lcolor(navy%60)) lpattern(dash)) ///
		 (`e'_4, recast(connected) keep(${evt_vars}) msymbol(X) mcolor(orange_red) mlcolor(orange_red) msize(small) ///
		  levels(95) lcolor(orange_red%60) ciopts(lcolor(orange_red%60)) lpattern(dash)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Up to 199" 4 "200-399" 6 "400-799" 8 "800+") rows(1) region(lcolor(white)) pos(12) ring(0)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months Relative to Poaching Event") ///
		 ytitle("Share of New Hires (Monthly)" "from Same Firm as Poached Worker") ylabel(-.02(.02).08)
		 
		 graph export "output/results/es_reg_firm_destinationsize_`e'.pdf", as(pdf) replace
		 
							
}	
