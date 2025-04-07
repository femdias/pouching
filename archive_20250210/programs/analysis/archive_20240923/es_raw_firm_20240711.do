// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Event study around poaching events -- raw averages		
	
*--------------------------*
* ANALYSIS
*--------------------------*

foreach e in dir spv emp {

	use "output/data/evt_panel_m_`e'", clear
	
	// sample restrictions
	merge m:1 event_id using "temp/sample_selection_`e'", keep(match) nogen
		
	// outcome variables
	
		// total number of hires in destination plant
		gen d_h = d_h_dir + d_h_spv + d_h_emp
	
		// total number of employees in destination plant
		* gen d_emp = d_emp_dir + d_emp_spv + d_emp_emp // already in data set
		
		// num: total number of hires in destination plant
		// den: total number of employees in destination plant
		gen d_h_d_emp = d_h / d_emp
		
		// number of hirings from origin plant (only poached individuals)
		gen d_h_o_pc = d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc
		
		// number of hirings from origin plant (excluding poached individuals)
		gen d_h_o_sanspc = (d_h_dir_o + d_h_spv_o + d_h_emp_o) - d_h_o_pc
		
		// num: number of hirings from origin plant (excluding poached individuals) 
		// den: total number of hires in destination plant (excluding poached individuals) 
		gen d_h_o_d_h_sanspc = d_h_o_sanspc / (d_h - d_h_o_pc)
		gen d_h_o_d_h_sanspc_0  = d_h_o_d_h_sanspc
		replace d_h_o_d_h_sanspc_0 = 0 if d_h_o_d_h_sanspc_0 == .
	 
		// number of employees from origin plant (only poached individuals)
		*gen d_emp_o_pc = d_emp_dir_o_pc + d_emp_spv_o_pc + d_emp_emp_o_pc // already in data set
		
		// number of employees from origin plant (excluding poached individuals)
		gen d_emp_o_sanspc = (d_emp_dir_o + d_emp_spv_o + d_emp_emp_o) - d_emp_o_pc
		
		// num: number of employees from origin plant (excluding poached individuals)
		// den: total number of employees in destination plant (excluding poached individuals)
		gen d_emp_o_d_emp_sanspc = d_emp_o_sanspc / (d_emp - d_emp_o_pc)
		
		// num: cumulative hires of employees from origin plant (excluding poached individual)
		// den: cumulative hires of employees in destionation plant (excluding poached individual)
		gen d_h_sanspc = d_h - d_h_o_pc
		tsset event_id ym_rel
		bysort event_id (ym_rel) : gen cuml_d_h_o_sanspc = sum(d_h_o_sanspc)
		bysort event_id (ym_rel) : gen cuml_d_h_sanspc = sum(d_h_sanspc)
		gen cuml_d_h_o_d_h_sanspc = cuml_d_h_o_sanspc / cuml_d_h_sanspc
		gen cuml_d_h_o_d_h_sanspc_0 = cuml_d_h_o_d_h_sanspc
		replace cuml_d_h_o_d_h_sanspc_0 = 0 if cuml_d_h_o_d_h_sanspc_0 == .		
			
	// collapsing by ym_rel & setting up a panel
	
	collapse (mean) d_h d_emp d_h_d_emp d_h_o_pc d_h_o_sanspc d_h_o_d_h_sanspc d_h_o_d_h_sanspc_0 ///
		d_emp_o_pc d_emp_o_sanspc d_emp_o_d_emp_sanspc cuml_d_h_o_d_h_sanspc cuml_d_h_o_d_h_sanspc_0, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	// saving this data set
	gen evt = "`e'" 
	save "temp/es_raw_firm_`e'", replace
	
	// graphing
	
	/*
	
	local vars d_h d_emp d_h_d_emp d_h_o_pc d_h_o_sanspc d_h_o_d_h_sanspc d_h_o_d_h_sanspc_0 ///
		d_emp_o_pc d_emp_o_sanspc d_emp_o_d_emp_sanspc cuml_d_h_o_d_h_sanspc cuml_d_h_o_d_h_sanspc_0
	
	local td_h			""Number of New Hires (Monthly)""
	local td_emp			""Number of Employees (Monthly)""
	local td_h_d_emp		""Share of New Hires (Monthly)" "Relative to Monthly Employment""
	local td_h_o_pc 		""Number of New Poached Workers (Monthly)""
	local td_h_o_sanspc		""Number of New Hires (Monhtly)" "from Same Firm as Poached Worker""
	local td_h_o_d_h_sanspc		""Share of New Hires (Monthly)" "from Same Firm as Poached Worker""
	local td_h_o_d_h_sanspc_0	""Share of New hires (Monthly)" "from Same Firm as Poached Worker""	
	local td_emp_o_pc		""Cumulative Number of Poached Workers (Monthly)""
	local td_emp_o_sanspc		""Cumulative Number of Coworkers (Monthly)" "from Same Firm as Poached Worker""
	local td_emp_o_d_emp_sanspc	""Cumulative Share of Coworkers (Monthly)" "from Same Firm as Poached Worker""
	local tcuml_d_h_o_d_h_sanspc	""Share of Cumulative Hires" "from Same Firm as Poached Worker""
	local tcuml_d_h_o_d_h_sanspc_0 	""Share of Cumulative hires" "from Same Firm as Poached Worker""
	
	
	foreach var of local vars {
	
	tsline `var' if ym_rel >= -9, recast(connect) msymbol(T) mcolor(gs8) mlcolor(gs8) msize(small) ///
		lcolor(gs8%60) lpattern(dash) ///
		xline(-3, lcolor(black) lpattern(dash)) plotregion(lcolor(white)) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Months Relative to Poaching Event") ///
		xlabel(-9(3)12) ///
		ytitle(`t`var'')
	
		graph export "output/results/es_raw_firm_`e'_`var'.pdf", as(pdf) replace
		
	}
	
	*/
	
	// summary figs
	
	tsline d_emp if ym_rel >= -9, recast(connect) msymbol(T) mcolor(gs8) mlcolor(gs8) msize(small) ///
		lcolor(gs8) lpattern(dot) ytitle("Number of Employees (Monthly)") ///
		ylabel(200(100)700) ||  ///
	tsline d_h if ym_rel >= -9, recast(bar) yaxis(2) color(gs8) lcolor(gs2%60) ///
		ytitle("Number of Hires (Monthly)", axis(2)) ylabel(5(10)45, axis(2)) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Months Relative to Poaching Event") xlabel(-9(3)12) xline(-0.5, lpattern(dot) lcolor(gs8) lwidth(5)) ///
		legend(order(1 "Employees" 2 "New Hires") region(lcolor(white)) pos(6) col(2)) ///
		text(700 2.8 "Poaching event", size(medsmall) color(gs8))
		
		graph export "output/results/es_raw_firm_`e'_emp_h.pdf", as(pdf) replace
	
} 

// raw event study figures combining the three event

	clear
	
	append using "temp/es_raw_firm_dir"
	append using "temp/es_raw_firm_spv"
	append using "temp/es_raw_firm_emp"
 
	tsline d_h_o_d_h_sanspc_0 if ym_rel >= -9 & evt == "dir", recast(connect) msymbol(T) ///
		mcolor(emerald) mlcolor(emerald) msize(small) lcolor(emerald%60) lpattern(dash) || ///
	tsline d_h_o_d_h_sanspc_0 if ym_rel >= -9 & evt == "spv", recast(connect) msymbol(O) ///
		mcolor(maroon) mlcolor(maroon) msize(small) lcolor(maroon%60) lpattern(dash) || ///
	tsline d_h_o_d_h_sanspc_0 if ym_rel >= -9 & evt == "emp", recast(connect) msymbol(Dh) ///
		mcolor(navy) mlcolor(navy) msize(small) lcolor(navy%60) lpattern(dash)  ///
		ytitle("Share of New Hires (Monthly)" "from Same Firm as Poached Worker") ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Months Relative to Poaching Event") xlabel(-9(3)12) xline(-3, lpattern(dash) lcolor(black)) ///
		legend(order(1 "Mgr: Director" 2 "Mgr: Supervisor" 3 "Not Mgr") region(lcolor(white)) pos(6) col(3)) 
		
		graph export "output/results/es_raw_firm.pdf", as(pdf) replace
		
		
		
		
	
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
