// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: Aprul 2024

// Purpose: Constructing the panel with coworkers

*--------------------------*
* BUILD
*--------------------------*

/*

foreach e in dir dir5 spv emp { // NOTE: STILL NEED TO RUN FOR DIR5 EM
	
	// the poaching events are listed in evt_xxx
	// the month when the poaching took place is called pc_ym
	// but the coworkers are identified 12 months before pc_ym
	// let's add this variable to evt_xxx and keep only what we need to identify the coworkers in t=-1
	
		use "output/data/evt_m_rs_`e'", clear
		
		keep event_id o_plant pc_ym d_plant
		
		duplicates drop 
		isid event_id
		
		// when is t=-12?
		gen ym = pc_ym - 12 // i'm calling this ym because this is the time variable in the monthly panel
		
		// duplicating the o_plant variable
		// and name if plant_id for merginf with rais
		gen double plant_id = o_plant
		format plant_id %14.0f
		 
		la var d_plant 	 "Destination plant"
		la var pc_ym 	 "Poaching event month"
		la var o_plant   "Origin plant ID"
		la var plant_id  "Origin plant ID"
			
		// listing the events
		// this is used later to construct the panel for each event
		save "temp/key_evts_m", replace  
		
		// listing firms and period where I will try to find the coworkers
		// i use this to save a simpler version of rais that only includes the workers I might be interested in
		keep plant_id ym
		duplicates drop
		
			// saving this list of origin firms and their t=-12
			save "temp/o_plants", replace
			
	// the main data set is too heavy -- keep only the potential coworkers
			
		use "output/data/rais_m_rs", clear
	
		merge m:1 plant_id ym using "temp/o_plants"
		
		gen coworker_l12 = (_merge == 3) // identifying coworkers in t=-12
		egen coworker = max(coworker_l12), by(cpf) // tagging their entire employment history
		keep if coworker == 1
		
		drop _merge
		drop coworker_l12 coworker
		
			// let's also drop some variables we won't use
			drop emp_on_m1 emp_on_m2 emp_on_m3 emp_on_m4 emp_on_m5 emp_on_m6 emp_on_m7 ///
			emp_on_m8 emp_on_m9 emp_on_m10 emp_on_m11 emp_on_m12 occ_1d occ_3d dir_temp ////
			n_emp_plant_year n_mgr_plant_year n_dir_plant_year p95 ///
			dirinc_temp n_dirinc_plant_year dirinc spv_temp n_spv_plant_year
		
		save "temp/coworkers_m", replace // much lighter data set!
	
	// now, construct the panel for each event
	// note the ID variable in event_id is meant to be unique
	
	use "temp/key_evts_m", clear

	su event_id
	local evtcount = `r(N)'
	di "Event count: `evtcount'"
	
	clear // need to clear the dataset to start appending from scratch
	
	forvalues ev=1/`evtcount' {
	di "Current event: `ev'"
		// selecting the event of interest
		preserve
			use "temp/key_evts_m", clear

			keep if event_id == `ev'

			// selecting its coworkers
			merge 1:m plant_id ym using "temp/coworkers_m"
			
			gen coworker_l12 = (_merge == 3)
			egen coworker = max(coworker_l12), by(cpf)
			keep if coworker == 1
			drop _merge
	
			order event_id d_plant pc_ym o_plant
			
			foreach var in event_id d_plant pc_ym o_plant {
				egen double `var'_n = max(`var')
				replace `var' = `var'_n
				drop `var'_n
			}
			
			gen ym_rel = ym - pc_ym
			keep if ym_rel >= -12 & ym_rel <= 12
			
			order event_id d_plant pc_ym o_plant cpf year month ym ym_rel
			sort event_id cpf ym_rel
			
			tempfile cowork_`ev'
			save "`cowork_`ev''"
		restore 
		
		append using "`cowork_`ev''" // ev=1 appends to a clear dataset, every ev after appends to the cumulative dataset
	}
	
	save "output/data/cowork_panel_m_rs_`e'", replace

}

*/

// adding more variables to the data set

	use "output/data/cowork_panel_m_rs_dir", clear
	
	// team size variables
	
		// number of employees in t=-12
		
		bysort event_id ym: gen o_emp = _N
		gen o_emp_l12_temp = o_emp if ym_rel == -12
		egen o_emp_l12 = max(o_emp_l12_temp), by(event_id)
		
		// number of non-directors in t=-12
		
		gen o_emp_l12_nondir_temp = (ym_rel == -12 & dir == 0)
		egen o_emp_l12_nondir = sum(o_emp_l12_nondir_temp), by(event_id)
		
		// number of directors in t=-12
		
		gen o_emp_l12_dir_temp = (ym_rel == -12 & dir == 1)
		egen o_emp_l12_dir = sum(o_emp_l12_dir_temp), by(event_id)
		
		// avg team size
		
		gen o_teamsize_l12 = o_emp_l12_nondir / o_emp_l12_dir
	
	// wages variables
	
			// adjusting wages
			merge m:1 year using "input/Auxiliary/ipca_brazil"
			drop if _merge == 2
			drop _merge
			generate index_2008 = index if year == 2008
			egen index_base = max(index_2008)
			generate adj_index = index / index_base
			
			generate wage_real = earn_avg_month_nom / adj_index
		
			// in logs
			gen wage_real_ln = ln(wage_real)
		
		gen wage_0_temp = wage_real_ln if ym_rel == 0
		egen wage_0 = max(wage_0_temp), by(event_id cpf)
		
			// same variable, but not in logs
			gen wage_real_0_temp = wage_real if ym_rel == 0
			egen wage_real_0 = max(wage_real_0_temp), by(event_id cpf)
		
		gen wage_l12_temp = wage_real_ln if ym_rel == -12
		egen wage_l12 = max(wage_l12_temp), by(event_id cpf)
		
			// same variable, but no in logs
			gen wage_real_l12_temp = wage_real if ym_rel == -12
			egen wage_real_l12 = max(wage_real_l12_temp), by(event_id cpf)
			
	// identifying the poached individuals among the coworkers
	
	sort event_id cpf ym_rel
	by event_id cpf: gen pc = ym_rel == 0 & (dir[_n-1] == 1) & (plant_id[_n-1] == o_plant) & (plant_id == d_plant) // 187
	egen pc_individual = max(pc), by(event_id cpf)
	
		// identifying the poached directors who continued as directors
		gen pc_dirindestination = (pc ==1) & (dir == 1) // 94
		egen pc_dirindestination_ind = max(pc_dirindestination), by(event_id cpf)
	 
	 // organizing and saving
	 
	 drop dir5 gov emp cnae20_subclass o_emp_l12_temp o_emp_l12_nondir_temp ///
		o_emp_l12_dir_temp index index_2008 index_base adj_index wage_0_temp ///
		wage_real_0_temp wage_l12_temp wage_real_l12_temp
		
	save "output/data/cowork_panel_m_rs_dir", replace	
	 









