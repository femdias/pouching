// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Event study around poaching events (employees)

*--------------------------*
* BUILD
*--------------------------*

// temporary:

	use "output/data/evt_panel_m_rs_dir_CORRETO", clear
	
	egen unique = tag(d_plant)
	keep if unique == 1
	keep d_plant
	
	save "temp/list_d_plant", replace
	
	// identifying the events when a director was poached
	
	use "output/data/evt_panel_m_rs_emp_old", clear
	
	merge m:1 d_plant using "temp/list_d_plant"
	keep if _merge == 3
	
	save "output/data/evt_panel_m_rs_emp_CORRETO", replace
	
// 1. plants are hiring

	use "output/data/evt_panel_m_rs_emp_CORRETO", clear

	// number of hires in destination plant: d_h_emp
	gen number = d_h_emp
	
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
	
		/*
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		// keeping plant where the director stays in the destination plant
		bysort event_id: egen n_dir_pos_temp = count(d_emp_dir_o) if d_emp_dir_o >= 1 & d_emp_dir_o < . & ym_rel >= 0
		bysort event_id: egen n_dir_pos = max(n_dir_pos_temp)
		keep if n_dir_pos >= 13
		
	// collapsing by evt_rel
	collapse (mean) number, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline number, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Number of hires (monthly)") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		ylabel(0(4)20) name(d_h_emp, replace)
	
		// on average, the number of hires is going up and they all experienced
		// a cluster hiring event in the month when they poached  a manager
		
// 2. net effect: plants are expanding!

	use "output/data/evt_panel_m_rs_emp_CORRETO", clear
	
	// number of employees in destination plant: d_emp
	gen number = d_emp_emp

		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
		
		/*
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		// keeping plant where the director stays in the destination plant
		bysort event_id: egen n_dir_pos_temp = count(d_emp_dir_o) if d_emp_dir_o >= 1 & d_emp_dir_o < . & ym_rel >= 0
		bysort event_id: egen n_dir_pos = max(n_dir_pos_temp)
		keep if n_dir_pos >= 13
		
	// collapsing by evt_rel
	collapse (mean) number, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline number, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Plant size (monthly)") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax) ylabel(200(20)300)	///
		name(d_emp, replace)
		
		
	
// 3. relative to the number of people in their firm, how big is this hiring month?	
	
	/*
	use "output/data/evt_panel_m_rs_emp_CORRETO", clear

	// number of hires in destination plant: d_h_emp
	// number of employees in destination plant: d_emp_emp
	
	gen share = d_h_emp / d_emp_emp
	
		
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
		
		/*
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		// keeping plant where the director stays in the destination plant
		bysort event_id: egen n_dir_pos_temp = count(d_emp_dir_o) if d_emp_dir_o >= 1 & d_emp_dir_o < . & ym_rel >= 0
		bysort event_id: egen n_dir_pos = max(n_dir_pos_temp)
		keep if n_dir_pos >= 13
		
	
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
		*/

// 4. how many of these hires are from the origin firm?	
	
	use "output/data/evt_panel_m_rs_emp_CORRETO", clear
	
	// number of hirings from origin firm: d_h_emp_o
	// number of hirings: d_h_emp
	gen number = d_h_emp_o
	
		
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
		
		/*
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		// keeping plant where the director stays in the destination plant
		bysort event_id: egen n_dir_pos_temp = count(d_emp_dir_o) if d_emp_dir_o >= 1 & d_emp_dir_o < . & ym_rel >= 0
		bysort event_id: egen n_dir_pos = max(n_dir_pos_temp)
		keep if n_dir_pos >= 13
		
	
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
		
// 4. how many of these hires are from the origin firm? (relative to number of monthly hires)	
	
	use "output/data/evt_panel_m_rs_emp_CORRETO", clear
	
	// number of hirings from origin firm: d_h_emp_o
	// number of hirings: d_h_emp
	gen share = d_h_emp_o / d_h_emp
	replace share = 0 if share == .
		
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
		
		/*
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		// keeping plant where the director stays in the destination plant
		bysort event_id: egen n_dir_pos_temp = count(d_emp_dir_o) if d_emp_dir_o >= 1 & d_emp_dir_o < . & ym_rel >= 0
		bysort event_id: egen n_dir_pos = max(n_dir_pos_temp)
		keep if n_dir_pos >= 13
		
		
	
	// collapsing by evt_rel
	collapse (mean) share, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tsline share, recast(connect) mcolor(navy) m(Oh) ///
		graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (employee poached at t=-1, starts at t=0)") xlabel(-12(1)12) xline(-1, lpattern(dash) lcolor(gs13)) ///
		ytitle("Share of new hires (monthly)" "from same firm as poached employee") ylabel(, grid glpattern(dash) glcolor(gs13*.3) gmax)	///
		name(d_h_emp_o_share, replace) ylabel(0(.02).06)
		
// 5. number of employees from origin plant
	
	/*
	use "output/data/evt_panel_m_rs_dir_CORRETO", clear
	
	gen number = d_emp_emp_o
	*gen number = d_emp_dir_o
	
	
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
		
		
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		/*
		// keeping plant where the director stays in the destination plant
		bysort event_id: egen n_dir_pos_temp = count(d_emp_dir_o) if d_emp_dir_o >= 1 & d_emp_dir_o < . & ym_rel >= 0
		bysort event_id: egen n_dir_pos = max(n_dir_pos_temp)
		keep if n_dir_pos >= 13
		*/
	
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
		*/
		
// 5. share of employees from origin plant
	
	use "output/data/evt_panel_m_rs_dir_CORRETO", clear
	
	gen share = d_emp_emp_o / d_emp_emp
	
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
		
		/*
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		// keeping plant where the director stays in the destination plant
		bysort event_id: egen n_dir_pos_temp = count(d_emp_dir_o) if d_emp_dir_o >= 1 & d_emp_dir_o < . & ym_rel >= 0
		bysort event_id: egen n_dir_pos = max(n_dir_pos_temp)
		keep if n_dir_pos >= 13
		
	
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
	
	use "output/data/evt_panel_m_rs_dir_CORRETO", clear
	
	tsset event_id ym_rel
	
	bysort event_id (ym_rel) : gen cuml_hire = sum(d_h_emp)
	bysort event_id (ym_rel) : gen cuml_hire_o = sum(d_h_emp_o)
	
	gen share = cuml_hire_o / cuml_hire
	
		// excluding the largest firms
		bysort event_id: egen avg_emp = mean(d_emp)
		keep if avg_emp <= 1250
		
		/*
		// keeping plants with complete panel
		bysort event_id: egen n_emp_pos = count(d_emp) if d_emp > 0 & d_emp < .
		keep if n_emp_pos >= 25
		*/
		
		// keeping plant where the director stays in the destination plant
		bysort event_id: egen n_dir_pos_temp = count(d_emp_dir_o) if d_emp_dir_o >= 1 & d_emp_dir_o < . & ym_rel >= 0
		bysort event_id: egen n_dir_pos = max(n_dir_pos_temp)
		keep if n_dir_pos >= 13
	
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
