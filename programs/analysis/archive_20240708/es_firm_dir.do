// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Event study around poaching events (director)

*--------------------------*
* BUILD
*--------------------------*

// auxiliary data set: identifying events where the poached director stays in the new firm

	use "output/data/cowork_panel_m_rs_dir", clear
	
	// identifying the poached individuals among the coworkers
	
	bysort event_id cpf: gen pc = ym_rel == 0 & (dir[_n-1] == 1) & (plant_id[_n-1] == o_plant) & (plant_id == d_plant)
	
		// test: do all events have a poached individual?
		*egen test = max(pc), by(event_id) // yes!
		
	// expanding for the entire individual and only keeping them
	
	egen pc_individual = max(pc), by(event_id cpf)
	keep if pc_individual == 1
	
	// employed in d_plant after the poaching in all months
	gen emp_d_plant = (plant_id == d_plant) & ym_rel >= 0
	egen total_emp_d_plant = sum(emp_d_plant), by(event_id cpf)
	
	// identifying these events
	collapse (max) total_emp_d_plant, by(event_id) 
	
	// saving
	save "temp/total_emp_d_plant", replace
			
	
*--------------------------*
* ANALYSIS
*--------------------------*

// all figures

	use "output/data/evt_panel_m_rs_dir", clear

	// sample restrictions
	
		// dropping outlier events
		drop if event_id == 100 // hire thousands of employees; probably tranfers or reporting issue

		// keeping events with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25 & n_emp_pos < .
		
		// keeping events where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13 & total_emp_d_plant < .
	
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
		
				/*
		
				// event study around the poaching event
				
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
				
				
				local evt_vars evt_l12 evt_l11 evt_l10 evt_l9 evt_l8 evt_l7 evt_l6 evt_l5 evt_l4 evt_l3 evt_l2 evt_zero ///
					evt_f0 evt_f1 evt_f2 evt_f3 evt_f4 evt_f5 evt_f6 evt_f7 evt_f8 evt_f9 evt_f10 evt_f11 evt_f12
				
				areg d_h_o_d_h_sanspc_0 `evt_vars', absorb(event_id) vce(cluster event_id) 
				
				coefplot, omitted keep(evt_l12 evt_l11 evt_l10 evt_l9 evt_l8 evt_l7 evt_l6 evt_l5 evt_l4 evt_l3 evt_l2 evt_zero ///
					evt_f0 evt_f1 evt_f2 evt_f3 evt_f4 evt_f5 evt_f6 evt_f7 evt_f8 evt_f9 evt_f10 evt_f11 evt_f12) vertical ///
					yline(0)
					
				*/
	
	/* WE TESTED THIS, BUT WE'RE NOT USING THIS RESTRICTION IN THE MAIN SPECIFICATION
	// identifying events where the wage increase was positive -- ADD THIS AS A VARIABLE TO THE DATA SET WHEN CONSTRUCTING IT
	merge m:1 event_id using "temp/wage_delta_pos"
	keep if wage_delta_pos == 1
	*/
				
			
	// collapsing by ym_rel & setting up a panel
	
	collapse (mean) d_h d_emp d_h_d_emp d_h_o_pc d_h_o_sanspc d_h_o_d_h_sanspc d_h_o_d_h_sanspc_0 ///
		d_emp_o_pc d_emp_o_sanspc d_emp_o_d_emp_sanspc cuml_d_h_o_d_h_sanspc cuml_d_h_o_d_h_sanspc_0, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	// graphing
	
	local vars d_h d_emp d_h_d_emp d_h_o_pc d_h_o_sanspc d_h_o_d_h_sanspc d_h_o_d_h_sanspc_0 ///
		d_emp_o_pc d_emp_o_sanspc d_emp_o_d_emp_sanspc cuml_d_h_o_d_h_sanspc cuml_d_h_o_d_h_sanspc_0
	
	local ld_h			"0(4)20"
	local ld_emp			"350(25)500"
	local ld_h_d_emp		"0(.01).06"
	local ld_h_o_pc 		"0(.25)1.25"
	local ld_h_o_sanspc		"0(.25).75"
	local ld_h_o_d_h_sanspc		"0(.01).04"
	local ld_h_o_d_h_sanspc_0	"0(.01).04"	
	local ld_emp_o_pc		"0(.25)1.25"
	local ld_emp_o_sanspc		"0(.5)2.5"
	local ld_emp_o_d_emp_sanspc	"0(.0025).01"
	local lcuml_d_h_o_d_h_sanspc	"0(.005).015"
	local lcuml_d_h_o_d_h_sanspc_0 	"0(.005).015" 
	
	local td_h			""Number of new hires (monthly)""
	local td_emp			""Number of employees (monthly)""
	local td_h_d_emp		""Share of new hires (monthly)" "relative to monthly employment""
	local td_h_o_pc 		""Number of new poached directors (monthly)" "from same firm as poached manager""
	local td_h_o_sanspc		""Number of new hires (monhtly)" "from same firm as poached manager""
	local td_h_o_d_h_sanspc		""Share of new hires (monthly)" "from same firm as poached manager""
	local td_h_o_d_h_sanspc_0	""Share of new hires (monthly)" "from same firm as poached manager""	
	local td_emp_o_pc		""Cumulative number of directors (monthly)" "from same firm as poached manager""
	local td_emp_o_sanspc		""Cumulative number of employees (monthly)" "from same firm as poached manager""
	local td_emp_o_d_emp_sanspc	""Cumulative share of employees (monthly)" "from same firm as poached manager""
	local tcuml_d_h_o_d_h_sanspc	""Share of cumulative hires" "from same firm as poached manager""
	local tcuml_d_h_o_d_h_sanspc_0 	""Share of cumulative hires" "from same firm as poached manager""
	
	
	foreach var of local vars {
	
	tsline `var', recast(connect) mcolor(gs8) lcolor(gs8) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(3)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle(`t`var'') ylabel(`l`var'', grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		name(`var', replace)
	
		graph export "output/results/es_dir_`var'.pdf", as(pdf) replace
		
	}
	
	// for fig 5: line: d_emp; bar: d_h
	
	tsline d_emp, recast(connect) mcolor(gs1) m(Oh) lcolor(gs1) ///
		ytitle("Number of employees (monthly)") ylabel(300(50)500, grid glpattern(dot) glcolor(gs13*.3) gmax) ||  ///
		tsline d_h, recast(bar) yaxis(2) color(gs8%60) ///
		ytitle("Number of hires (monthly)", axis(2)) ylabel(5(5)25, grid glpattern(dot) glcolor(gs13*.3) gmax axis(2)) ///
			graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(3)12) xline(-0.5, lpattern(dot) lcolor(gs13) lwidth(5)) ///
		legend(order(1 "Employees" 2 "New Hires") region(lcolor(white)) pos(6) col(2)) ///
		text(500 3.2 "Poaching event", size(medsmall) color(gs8))
		
		graph export "output/results/es_dir_emp_h.pdf", as(pdf) replace
/*	
	
// primary figure only -- heterogeneity by destination firm size

	use "output/data/evt_panel_m_rs_dir", clear

	// sample restrictions
	
		// dropping outlier events
		drop if event_id == 100 // hire thousands of employees; probably tranfers or reporting issue

		// keeping events with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25 & n_emp_pos < .
		
		// keeping events where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13 & total_emp_d_plant < .
	
	// outcome variable
	
		// total number of hires in destination plant
		gen d_h = d_h_dir + d_h_spv + d_h_emp
		
		// number of hirings from origin plant (only poached individuals)
		gen d_h_o_pc = d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc
		
		// number of hirings from origin plant (excluding poached individuals)
		gen d_h_o_sanspc = (d_h_dir_o + d_h_spv_o + d_h_emp_o) - d_h_o_pc
		
		// num: number of hirings from origin plant (excluding poached individuals) 
		// den: total number of hires in destination plant (excluding poached individuals) 
		gen d_h_o_d_h_sanspc = d_h_o_sanspc / (d_h - d_h_o_pc)
		gen d_h_o_d_h_sanspc_0  = d_h_o_d_h_sanspc
		replace d_h_o_d_h_sanspc_0 = 0 if d_h_o_d_h_sanspc_0 == .
		
	// heterogeneneity
	
	summ d_emp if ym_rel == 0, detail // median is 231
	gen d_emp_0_temp = d_emp if ym_rel == 0
	egen d_emp_0 = max(d_emp_0_temp), by(event_id)
	drop d_emp_0_temp
	gen d_emp_0_g = (d_emp_0 >= 231)
	 
	// collapsing by ym_rel & setting up a panel
	
	collapse (mean) d_h_o_d_h_sanspc d_h_o_d_h_sanspc_0, by(d_emp_0_g ym_rel)
				
	order d_emp_0_g
	tsset d_emp_0_g ym_rel
	
	// graphing
	
	local vars d_h_o_d_h_sanspc d_h_o_d_h_sanspc_0

	local ld_h_o_d_h_sanspc		"0(.01).06"
	local ld_h_o_d_h_sanspc_0	"0(.02).06"	

	local td_h_o_d_h_sanspc		""Share of new hires (monthly)" "from same firm as poached manager""
	local td_h_o_d_h_sanspc_0	""Share of new hires (monthly)" "from same firm as poached manager""	
	
	foreach var of local vars {
	
	tsline `var' if d_emp_0_g == 0, recast(connect) mcolor(navy) m(Oh) || ///
	tsline `var' if d_emp_0_g == 1, recast(connect) mcolor(cranberry) m(D) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle(`t`var'') ylabel(`l`var'', grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		legend(order(1 "Below Median" 2 "Above Median") region(lcolor(white))) ///
		name(`var', replace)
	
		graph export "output/results/es_dir_`var'_d_emp.pdf", as(pdf) replace
		
	}	
	

// primary figure only -- heterogeneity by origin firm size

	// calculating origin firm size
	
	use "output/data/cowork_panel_m_rs_dir", clear
	keep if ym_rel == -12
	bysort event_id: gen o_emp = _N
	egen unique = tag(event_id)
	keep if unique ==1
	keep event_id o_emp
	save "temp/o_emp", replace
	
	// now for the analysis...

	use "output/data/evt_panel_m_rs_dir", clear

	// sample restrictions
	
		// dropping outlier events
		drop if event_id == 100 // hire thousands of employees; probably tranfers or reporting issue

		// keeping events with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25 & n_emp_pos < .
		
		// keeping events where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13 & total_emp_d_plant < .
	
	// outcome variable
	
		// total number of hires in destination plant
		gen d_h = d_h_dir + d_h_spv + d_h_emp
		
		// number of hirings from origin plant (only poached individuals)
		gen d_h_o_pc = d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc
		
		// number of hirings from origin plant (excluding poached individuals)
		gen d_h_o_sanspc = (d_h_dir_o + d_h_spv_o + d_h_emp_o) - d_h_o_pc
		
		// num: number of hirings from origin plant (excluding poached individuals) 
		// den: total number of hires in destination plant (excluding poached individuals) 
		gen d_h_o_d_h_sanspc = d_h_o_sanspc / (d_h - d_h_o_pc)
		gen d_h_o_d_h_sanspc_0  = d_h_o_d_h_sanspc
		replace d_h_o_d_h_sanspc_0 = 0 if d_h_o_d_h_sanspc_0 == .
		
	// heterogeneneity
	
	merge m:1 event_id using "temp/o_emp", keep(match)
	summ o_emp, detail // median is 159
	gen o_emp_g = (o_emp >= 159)
	 
	// collapsing by ym_rel & setting up a panel
	
	collapse (mean) d_h_o_d_h_sanspc d_h_o_d_h_sanspc_0, by(o_emp_g ym_rel)
				
	order o_emp_g
	tsset o_emp_g ym_rel
	
	// graphing
	
	local vars d_h_o_d_h_sanspc d_h_o_d_h_sanspc_0

	local ld_h_o_d_h_sanspc		"0(.01).06"
	local ld_h_o_d_h_sanspc_0	"0(.02).06"	

	local td_h_o_d_h_sanspc		""Share of new hires (monthly)" "from same firm as poached manager""
	local td_h_o_d_h_sanspc_0	""Share of new hires (monthly)" "from same firm as poached manager""	
	
	foreach var of local vars {
	
	tsline `var' if o_emp_g == 0, recast(connect) mcolor(navy) m(Oh) || ///
	tsline `var' if o_emp_g == 1, recast(connect) mcolor(cranberry) m(D) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle(`t`var'') ylabel(`l`var'', grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		legend(order(1 "Below Median" 2 "Above Median") region(lcolor(white))) ///
		name(`var', replace)
	
		graph export "output/results/es_dir_`var'_o_emp.pdf", as(pdf) replace
		
	}
