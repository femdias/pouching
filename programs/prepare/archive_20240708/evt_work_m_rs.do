// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Constructing worker-level data set with poaching events in t=0

*--------------------------*
* BUILD
*--------------------------*

// listing events in t=0

	use "output/data/evt_m_rs_dir", clear
	
	egen unique = tag(d_plant pc_ym)
	keep if unique == 1
	keep event_id d_plant pc_ym o_plant
	
	save "temp/events", replace
	
// listing poached individuals in t=0

	use "output/data/evt_m_rs_dir", clear
	
	egen unique = tag(pc_cpf pc_ym)
	keep if unique == 1
	keep pc_cpf pc_ym
	
	save "temp/poached", replace
	
// in RAIS, keeping what we need for this data set	

	use "output/data/rais_m_rs", clear
	
	// keeping t=0 (ym == pc_ym) for the destination plants
	rename ym pc_ym
	rename plant_id d_plant
	merge m:1 d_plant pc_ym using "temp/events", keep(match)
	drop _merge
	
	// identifying poached individuals
	rename cpf pc_cpf
	merge 1:1 pc_cpf pc_ym using "temp/poached"
	rename pc_cpf cpf
	gen pc_individual = (_merge == 3)
	gen pc_dirindestination_ind = (pc_individual == 1 & dir == 1)
	drop _merge
	
	// organizing
	
	order event_id d_plant pc_ym o_plant
	sort event_id cpf
	
	// adding / generating more variables
	
		// adjusting wages
		
			merge m:1 year using "input/Auxiliary/ipca_brazil"
			generate index_2008 = index if year == 2008
			egen index_base = max(index_2008)
			generate adj_index = index / index_base		
			generate wage_real = earn_avg_month_nom / adj_index
			
			// in logs
			gen wage_real_ln = ln(wage_real)
			
			drop if _merge == 2
			drop _merge
			sort event_id cpf
		
		// calculating experience
		
			gen experience = age - educ_years - 6
			
		// samples based on similarity to poached individuals
		
			gen occup_1digit = substr(occup_cbo2002,1,1)
			gen occup_2digit = substr(occup_cbo2002,1,2)
			gen occup_3digit = substr(occup_cbo2002,1,3)
			
			egen sample_1digit = max(pc_individual), by(event_id occup_1digit)
			egen sample_2digit = max(pc_individual), by(event_id occup_2digit)
			egen sample_3digit = max(pc_individual), by(event_id occup_3digit)
	
		// calculate average wage
					
			egen avg_wage_1digit_t = mean(wage_real_ln) if sample_1digit == 1 & pc_individual == 0, by(event_id)
			egen avg_wage_1digit = max(avg_wage_1digit_t), by(event_id)
			drop avg_wage_1digit_t
				
			egen avg_wage_plant_t = mean(wage_real_ln) if pc_individual == 0, by(event_id)
			egen avg_wage_plant = mean(avg_wage_plant_t) , by(event_id)
			drop avg_wage_plant_t
			
			egen avg_wage_real_plant_t = mean(wage_real) if pc_individual == 0, by(event_id)
			egen avg_wage_real_plant = mean(avg_wage_real_plant_t) , by(event_id)
			drop avg_wage_real_plant_t
			
			
		// include team size variables
					
			// number of employees in t=0
	
			bysort event_id: gen d_emp_0 = _N
				
			// number of non-directors in t=0
					
			gen d_emp_0_nondir_temp = (dir == 0)
			egen d_emp_0_nondir = sum(d_emp_0_nondir_temp), by(event_id)
					
			// number of directors in t=0
					
			gen d_emp_0_dir_temp = (dir == 1)
			egen d_emp_0_dir = sum(d_emp_0_dir_temp), by(event_id)
					
			// avg team size
					
			gen d_teamsize_0 = d_emp_0_nondir / d_emp_0_dir
	
	
	// organizing
	drop emp_on_m* dir_temp n_emp_plant_year n_mgr_plant_year n_dir_plant_year p95 dirinc_temp ///
		n_dirinc_plant_year dirinc dir5 spv_temp gov emp index index_2008 index_base ///
		adj_index 
	
	// saving
	save "output/data/evt_work_m_rs_dir", replace
