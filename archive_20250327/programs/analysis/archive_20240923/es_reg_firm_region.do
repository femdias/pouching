// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: July 2024

// Purpose: Event study around poaching events	
// Heterogeneity by region			
	
*--------------------------*
* ANALYSIS
*--------------------------*

/*

	foreach e in dir spv emp {
	forvalues ym=528/575 {

		use "output/data/cowork_panel_m_`e'_`ym'", clear
		
		if _N > 0 {
		
			keep if pc_individual == 1
			keep if ym_rel == -12 | ym_rel == 0
			keep event_id ym_rel muni
			
			// dealing with cases where there is more than 1 poached individual
			egen unique = tag(event_id ym_rel)
			keep if unique == 1
			drop unique
			
			// reshape
			recode ym_rel (-12 = 0) (0 = 1)
			reshape wide muni, i(event_id) j(ym_rel)
			rename muni0 o_muni
			rename muni1 d_muni
			
			save "temp/region_`e'_`ym'", replace
		
		}
	}
	
	clear
	
	forvalues ym=528/575 {
		
		cap append using "temp/region_`e'_`ym'"
		
	}
	
	save "temp/region_`e'", replace
		
	}
	
*/	
	
foreach e in dir spv emp mgr {
	
if "`e'" != "mgr" {	

	use "output/data/evt_panel_m_`e'", clear

	// sample restrictions
	merge m:1 event_id using "temp/sample_selection_`e'", keep(match) nogen
	
	// merging with event type
	merge m:1 event_id using "temp/region_`e'", keep(match) nogen
	
} 

if "`e'" == "mgr" {

	use "output/data/evt_panel_m_dir", clear
	merge m:1 event_id using "temp/sample_selection_dir", keep(match) nogen
	merge m:1 event_id using "temp/region_dir", keep(match) nogen
	tempfile dir
	save `dir'
	
	use "output/data/evt_panel_m_spv", clear
	merge m:1 event_id using "temp/sample_selection_spv", keep(match) nogen
	merge m:1 event_id using "temp/region_spv", keep(match) nogen
	tempfile spv
	save `spv'
	
	use `dir', clear
	append using `spv'
	
} 

	gen o_uf = floor(o_muni / 10000)
	gen d_uf = floor(d_muni / 10000)
		
	gen change = (o_uf != d_uf)
	
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
	
	foreach t in 0 1 {
			
	eststo `e'_`t': reghdfe d_h_o_d_h_sanspc_0 $evt_vars if ym_rel >= -9 & change == `t', ///
		    absorb(event_id d_plant) vce(cluster event_id) 
		        
	
	}
	
	// figures
	
 
	coefplot (`e'_0, recast(connected) keep(${evt_vars}) msymbol(O) mcolor(maroon) mlcolor(maroon) msize(small) ///
		  levels(95) lcolor(maroon%60) ciopts(lcolor(maroon%60)) lpattern(dash)) ///
		 (`e'_1, recast(connected) keep(${evt_vars}) msymbol(Dh) mcolor(navy) mlcolor(navy) msize(small) ///
		  levels(95) lcolor(navy%60) ciopts(lcolor(navy%60)) lpattern(dash)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Same State" 4 "Different State") rows(1) region(lcolor(white)) pos(12) ring(0)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months Relative to Poaching Event") ///
		 ytitle("Share of New Hires (Monthly)" "from Same Firm as Poached Worker") ylabel(-.02(.02).08)
		 
		 graph export "output/results/es_reg_firm_region_`e'.pdf", as(pdf) replace	 
					
}
	
	
		
