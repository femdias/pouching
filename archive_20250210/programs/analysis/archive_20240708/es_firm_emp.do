// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Event study around poaching events (director + employees)

*--------------------------*
* BUILD
*--------------------------*

// temporary corrections

	use "output/data/archive_20240506/cowork_panel_m_rs_emp", clear
	
	// 1. only the events where an employee (dir == 0 & spv == 0) is poached
	
		// identifying the poached individuals among the coworkers
		
		bysort event_id cpf: gen pc = ym_rel == 0 & (dir[_n-1] == 0 & spv[_n-1] == 0) & (plant_id[_n-1] == o_plant) & (plant_id == d_plant)
		
		// expanding for the entire event
		egen pc_emp = max(pc), by(event_id)
		
		// ... & only keeping these events
		keep if pc_emp == 1
	
	// 2. only the events with d_plant in dir events
	
		preserve
		
				use "output/data/evt_panel_m_rs_dir", clear
				drop if event_id == 100
				keep d_plant
				duplicates drop
				save "temp/dir_d_plant", replace
		
		restore
		
		merge m:1 d_plant using "temp/dir_d_plant"
		keep if _merge == 3
		drop _merge
		
	// keeping only the list of events
	
	egen unique = tag(event_id)
	keep if unique == 1
	keep event_id
		
	save "temp/emp_list_events", replace
	
// events of interest: where the poached employee stays in the new firm

	use "output/data/archive_20240506/cowork_panel_m_rs_emp", clear

	// identifying the poached individuals among the coworkers -- this is based on the wrong/old definition
	
	bysort event_id cpf: gen pc = ym_rel == 0 & (dir == 0 & spv == 0) & (plant_id[_n-1] == o_plant) & (plant_id == d_plant)
		
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
	
// 1. plants are hiring

	use "output/data/rec_evt_panel_m_rs_emp", clear
	merge m:1 event_id using "temp/emp_list_events"
	keep if _merge == 3
	drop _merge

	// TOTAL number of hires in destination plant: d_h_dir + d_h_spv + d_h_emp
	gen number = d_h_dir + d_h_spv + d_h_emp
	
		/*
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
	
		
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		
		// keeping plant where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13
		
		
		
	// collapsing by evt_rel
	collapse (mean) number, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline number, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Number of hires (monthly)") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		ylabel(0(5)25) name(d_h_emp, replace)
	
		*graph export "output/results/es_hires_monthly.pdf", as(pdf) replace
	
		// on average, the number of hires is going up and they all experienced
		// a cluster hiring event in the month when they poached  a manager
		
// 2. net effect: plants are expanding!

	use "output/data/rec_evt_panel_m_rs_emp", clear
	merge m:1 event_id using "temp/emp_list_events"
	keep if _merge == 3
	drop _merge
	
	// number of employees in destination plant: d_emp_dir + d_emp_spv + d_emp_emp
	gen number = d_emp_dir + d_emp_spv + d_emp_emp

		/*
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
	
		
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		
		// keeping plant where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13
		
		
		
	// collapsing by evt_rel
	collapse (mean) number, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline number, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Plant size (monthly)") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax) ylabel(350(25)500)	///
		name(d_emp, replace)
	
// 3. relative to the number of people in their firm, how big is this hiring month?	
	
	use "output/data/rec_evt_panel_m_rs_emp", clear
	merge m:1 event_id using "temp/emp_list_events"
	keep if _merge == 3
	drop _merge

	// number of hires in destination plant: d_h_dir + d_h_spv + d_h_emp
	// number of employees in destination plant: d_emp_dir + d_emp_spv + d_emp_emp
	
	gen share = (d_h_dir + d_h_spv + d_h_emp) / (d_emp_dir + d_emp_spv + d_emp_emp)
	
		/*
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
	
		
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		
		// keeping plant where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13
		
		
	
	// collapsing by evt_rel
	collapse (mean) share, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline share, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Share of new hires" "relative to monthly employment") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax) ///
		name(d_h_emp_share, replace)
		

// 4. how many of these hires are the poached director from the origin firm?	
	
	use "output/data/rec_evt_panel_m_rs_emp", clear
	merge m:1 event_id using "temp/emp_list_events"
	keep if _merge == 3
	drop _merge
	
	// number of hirings from origin firm (only poached individuals): d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc
	gen number = d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc
	
		/*
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
	
		
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		
		// keeping plant where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13
		
		
	
	// collapsing by evt_rel
	collapse (mean) number, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline number, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Number of new hires (monthly)" "from the origin firm") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		name(d_h_emp_o_share, replace)
		
// 4. how many of these hires are the poached from the origin firm, excluding the poached director?	
	
	use "output/data/rec_evt_panel_m_rs_emp", clear
	merge m:1 event_id using "temp/emp_list_events"
	keep if _merge == 3
	drop _merge
	
	// number of hirings from origin firm: d_h_dir_o + d_h_spv_o + d_h_emp_o
	// number of hirings from origin firm (only poached individuals): d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc
	gen number = (d_h_dir_o + d_h_spv_o + d_h_emp_o) - (d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc)
	
		/*
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
	
		
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		
		// keeping plant where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13
		
		
	
	// collapsing by evt_rel
	collapse (mean) number, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline number, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Number of new hires (monthly)" "from the origin firm") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		name(d_h_emp_o_share, replace)		
		
		
// 4. how many of these hires are from the origin firm? (relative to number of monthly hires) -- excluding the poached individuals	
	
	use "output/data/rec_evt_panel_m_rs_emp", clear
	merge m:1 event_id using "temp/emp_list_events"
	keep if _merge == 3
	drop _merge
	
	// number of hirings from origin firm: d_h_dir_o + d_h_spv_o + d_h_emp_o
	// number of hirings from origin firm (only poached individuals): d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc
	// number of hirings: d_h_dir + d_h_spv + d_h_emp
	gen share = ((d_h_dir_o + d_h_spv_o + d_h_emp_o) - (d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc)) / ( (d_h_dir + d_h_spv + d_h_emp ) - (d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc))
	replace share = 0 if share == .
	/*
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
	*/
		
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		
		
		
		// keeping plant where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13
		
	
	// collapsing by evt_rel
	collapse (mean) share, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline share, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (employee poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Share of new hires (monthly)" "from same firm as poached employee") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		ylabel(0(.01).05) name(d_h_emp_o_share, replace)
		
// 5. number of employees from origin plant -- poached directors only

	use "output/data/archive_20240506/evt_panel_m_rs_emp", clear
	merge m:1 event_id using "temp/emp_list_events"
	keep if _merge == 3
	drop _merge
	
	gen number = d_emp_dir_o_pc + d_emp_spv_o_pc + d_emp_emp_o_pc
	
		
		/*
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
	
		
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		
		// keeping plant where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13
		
	
	// collapsing by evt_rel
	collapse (mean) number, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline number, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Number of employees from origin firm") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		name(d_emp_emp_o, replace)

// 5. number of employees from origin plant -- excluding poached directors

	use "output/data/archive_20240506/evt_panel_m_rs_emp", clear
	merge m:1 event_id using "temp/emp_list_events"
	keep if _merge == 3
	drop _merge
	
	gen number = (d_emp_dir_o + d_emp_spv_o + d_emp_emp_o) - (d_emp_dir_o_pc + d_emp_spv_o_pc + d_emp_emp_o_pc)
	
		
		/*
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
	
		
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		
		// keeping plant where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13
		
	
	// collapsing by evt_rel
	collapse (mean) number, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline number, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Number of employees from origin firm") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		name(d_emp_emp_o, replace)		
		
// 5. share of employees from origin plant -- excluding poached directors
	
	use "output/data/archive_20240506/evt_panel_m_rs_emp", clear
	merge m:1 event_id using "temp/emp_list_events"
	keep if _merge == 3
	drop _merge
	
	gen share = ((d_emp_dir_o + d_emp_spv_o + d_emp_emp_o) - (d_emp_dir_o_pc + d_emp_spv_o_pc + d_emp_emp_o_pc)) / ///
		((d_emp_dir + d_emp_spv + d_emp_emp) - (d_emp_dir_o_pc + d_emp_spv_o_pc + d_emp_emp_o_pc))
	
		/*
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
	
		
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		
		// keeping plant where the director stays in the destination plant
		merge m:1 event_id using "temp/total_emp_d_plant"
		drop if _merge == 2
		drop _merge
		keep if total_emp_d_plant >= 13
		
	
	// collapsing by evt_rel
	collapse (mean) share, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline share, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Cumulative share of employees (monthly)" "from same firm as poached manager") ///
		ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		name(d_emp_emp_o_share, replace)
		
// 5. cumulative hires of employees from origin plant
	
	use "output/data/archive_20240506/evt_panel_m_rs_emp", clear
	merge m:1 event_id using "temp/emp_list_events"
	keep if _merge == 3
	drop _merge
	
	gen d_h = (d_h_dir + d_h_spv + d_h_emp) - (d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc )
	gen d_h_o = (d_h_dir_o + d_h_spv_o + d_h_emp_o) - (d_h_dir_o_pc + d_h_spv_o_pc + d_h_emp_o_pc)
	
	
	tsset event_id ym_rel
	
	bysort event_id (ym_rel) : gen cuml_hire = sum(d_h)
	bysort event_id (ym_rel) : gen cuml_hire_o = sum(d_h_o)
	
	gen share = cuml_hire_o / cuml_hire
	
		/*
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
		
		
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		
		
		// keeping plant where the director stays in the destination plant
		bysort event_id: egen n_dir_pos_temp = count(d_emp_dir_o) if d_emp_dir_o >= 1 & d_emp_dir_o < . & ym_rel >= 0
		bysort event_id: egen n_dir_pos = max(n_dir_pos_temp)
		keep if n_dir_pos >= 13
		*/
	
	// collapsing by evt_rel
	collapse (mean) share, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline share, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Share of cumulative hires" "from same firm as poached manager") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		name(d_emp_emp_o_share, replace)
		

		
