// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Summary stats for draft

*--------------------------*
* ANALYSIS
*--------------------------*

// number of workers and movements between two firms

	/*
	
	use "output/data/rais_m_rs", clear

	// number of workers
	tab ym
	
	// number of direct movements (from one month to the next)
	gen mov = ((plant_id != L.plant_id) & (plant_id != .) & (L.plant_id != .))
	tab mov // 986,330
	
	// how many workers had a direct movement?
	egen mov_worker = max(mov), by(cpf)
	tab ym mov_worker // 3,458,453
	
	*/
	
// summary stats table

	// origin: variables
	
		use "output/data/cowork_panel_m_rs_dir", clear
		merge m:1 event_id using "output/data/sample_selection_dir", keep(match) nogen
	
		// identifying the poached individuals among the coworkers
	
		bysort event_id cpf: gen pc = ym_rel == 0 & (dir[_n-1] == 1) & (plant_id[_n-1] == o_plant) & (plant_id == d_plant)	
		egen pc_individual = max(pc), by(event_id cpf)
		
		// identifying the poached individuals who remain a manager and those who do not
		bysort event_id cpf: gen pc_dir = ym_rel == 0 & pc_individual == 1 & dir == 1
		egen pc_dir_individual = max(pc_dir), by(event_id cpf)
		
		
		// firm size in t=-12
		bysort event_id ym: gen emp_t = _N
		gen emp_temp_12 = emp_t if ym_rel == -12
		egen emp_12 = max(emp_temp_12), by(event_id)
		
		// number of non-directors in t=-12
		gen emp_nondir_temp_12 = (ym_rel == -12 & dir == 0)
		egen emp_nondir_12 = sum(emp_nondir_temp_12), by(event_id)
		
		// number of directors in t=-12
		gen emp_dir_temp_12 = (ym_rel == -12 & dir == 1)
		egen emp_dir_12 = sum(emp_dir_temp_12), by(event_id)
		
		// avg team size in t=-12
		gen teamsize_12 = emp_nondir_12 / emp_dir_12
		
		// wage at origin
		
				merge m:1 year using "input/Auxiliary/ipca_brazil"
				generate index_2008 = index if year == 2008
				egen index_base = max(index_2008)
				generate adj_index = index / index_base		
				generate wage_real = earn_avg_month_nom / adj_index
		
				// in logs
				gen wage_real_ln = ln(wage_real)
				
				drop if _merge == 2
				drop _merge
		
		gen wage_temp_12 =  wage_real if ym_rel == -12
		egen wage_12 = mean(wage_temp_12), by(event_id)
		
		gen wage_nondir_temp_12 = wage_real if ym_rel == -12 & dir == 0
		egen wage_nondir_12 = mean(wage_nondir_temp_12), by(event_id)
		
		gen wage_dir_temp_12 = wage_real if ym_rel == -12 & dir == 1
		egen wage_dir_12 = mean(wage_dir_temp_12), by(event_id)
		
		gen wage_dir_pc_temp_12 = wage_real if ym_rel == -12 & dir == 1 & pc_individual == 1
		egen wage_dir_pc_12 = mean(wage_dir_pc_temp_12), by(event_id)
		
		gen wage_dir_pc_dir0_temp_12 = wage_real if ym_rel == -12 & dir == 1 & pc_individual == 1 & pc_dir_individual == 0
		egen wage_dir_pc_dir0_12 = mean(wage_dir_pc_dir0_temp_12), by(event_id)
		
		gen wage_dir_pc_dir1_temp_12 = wage_real if ym_rel == -12 & dir == 1 & pc_individual == 1 & pc_dir_individual == 1
		egen wage_dir_pc_dir1_12 = mean(wage_dir_pc_dir1_temp_12), by(event_id)
		 
	

	egen unique = tag(event_id)
	keep if unique == 1
	keep event_id emp_12 teamsize_12 wage_12 wage_nondir_12 wage_dir_12 wage_dir_pc_12 wage_dir_pc_dir0_12 wage_dir_pc_dir1_12
	
	save "temp/sumstats_o", replace
		
	// destination firm size

		use "temp/temp_wage_dir", clear
			
		// firm size in t=0
		bysort event_id: gen emp_0 = _N
				
		// number of non-directors in t=0
		gen emp_nondir_temp_0 = (dir == 0)
		egen emp_nondir_0 = sum(emp_nondir_temp_0), by(event_id)
					
		// number of directors in t=0
		gen emp_dir_temp_0 = (dir == 1)
		egen emp_dir_0 = sum(emp_dir_temp_0), by(event_id)
					
		// avg team size in t=0		
		gen teamsize_0 = emp_nondir_0 / emp_dir_0
		
		// wage at destination
	
			merge m:1 year using "input/Auxiliary/ipca_brazil"
			generate index_2008 = index if year == 2008
			egen index_base = max(index_2008)
			generate adj_index = index / index_base		
			generate wage_real = earn_avg_month_nom / adj_index
			
			// in logs
			gen wage_real_ln = ln(wage_real)
			
			drop if _merge == 2
			drop _merge
		
		gen wage_temp_0 =  wage_real
		egen wage_0 = mean(wage_temp_0), by(event_id)
		
		gen wage_nondir_temp_0 = wage_real if dir == 0
		egen wage_nondir_0 = mean(wage_nondir_temp_0), by(event_id)
		
		gen wage_dir_temp_0 = wage_real if dir == 1
		egen wage_dir_0 = mean(wage_dir_temp_0), by(event_id)
		
		gen wage_dir_pc_temp_0 = wage_real if pc_individual == 1
		egen wage_dir_pc_0 = mean(wage_dir_pc_temp_0), by(event_id)
		
		gen wage_dir_pc_dir0_temp_0 = wage_real if pc_individual == 1 & pc_dirindestination_ind == 0
		egen wage_dir_pc_dir0_0 = mean(wage_dir_pc_dir0_temp_0), by(event_id)
		
		gen wage_dir_pc_dir1_temp_0 = wage_real if pc_individual == 1 & pc_dirindestination_ind == 1
		egen wage_dir_pc_dir1_0 = mean(wage_dir_pc_dir1_temp_0), by(event_id)

	egen unique = tag(event_id)
	keep if unique == 1
	keep event_id emp_0 teamsize_0 wage_0 wage_nondir_0 wage_dir_0 wage_dir_pc_0 wage_dir_pc_dir0_0 wage_dir_pc_dir1_0
	
	save "temp/sumstats_d", replace
	
	// merging and creating table
	
	use "temp/sumstats_o", clear
	merge 1:1 event_id using "temp/sumstats_d"
	drop _merge
	
	/*
	reshape long emp_ teamsize_ wage_ wage_nondir_ wage_dir_, i(event_id) j(period)
	gen group = (period == 0)
	sort event_id group
	order event_id group
	*/
	
	label var emp_12 "Origin"
	label var emp_0 "Destination"
	
	label var teamsize_12 "Origin"
	label var teamsize_0 "Destination"
	
	label var wage_nondir_12 "Origin (Non-Managers)"
	label var wage_dir_12 "Origin (Managers)"
	label var wage_nondir_0 "Destination (Non-Managers)"
	label var wage_dir_0 "Destination (Managers)"
	
	label var wage_dir_pc_12 "Origin"
	label var wage_dir_pc_dir0_12 "Origin (No Longer Manager)"
	label var wage_dir_pc_dir1_12 "Origin (Still Manager)"
	label var wage_dir_pc_0 "Destination"
	label var wage_dir_pc_dir0_0 "Destination (No Longer Manager)"
	label var wage_dir_pc_dir1_0 "Destination (Still Manager)"
	
	
	local vars emp_12 emp_0 teamsize_12 teamsize_0 wage_nondir_12 wage_dir_12 wage_nondir_0 wage_dir_0 ///
		wage_dir_pc_12 wage_dir_pc_dir0_12 wage_dir_pc_dir1_12 wage_dir_pc_0 wage_dir_pc_dir0_0 wage_dir_pc_dir1_0
	
	eststo clear
		
		eststo: estpost summarize `vars', detail
		
		esttab using "output/results/sumstats.tex", replace ///
			refcat(emp_12 "\textbf{Firm Size}" ///
				teamsize_12 "\\ \textbf{Team Size} (\# employees / \# managers)" ///
				wage_nondir_12 "\\ \textbf{All Workers: Average Wage} (R\\$)" ///
				wage_dir_pc_12 "\\ \textbf{Poached Managers: Average Wage} (R\\$)", nolabel) ///
			cells("p50(fmt(2)) mean(fmt(2)) sd(fmt(2))") nostar unstack nonumber ///
			compress nonote gap label booktabs frag nomtitle ///
			collabels("Median" "Mean" "SD")
			
		
	
		
	

	
	
