// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Create data set with poached individuals only

*--------------------------*
* BUILD
*--------------------------*

/*
// AUXILIARY DATA SETS

	// information about raided coworkers
	
	foreach e in spv emp dir { // dir5 
	forvalues ym=528/683 {	
	
		use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
		
		if _N >= 1 {
	
			// identifying raided coworkers
			sort event_id cpf ym_rel
			by event_id cpf: gen rd_coworker = (pc_individual == 0) & (ym_rel>=0) & (plant_id[_n-1] != d_plant) & (plant_id == d_plant)
			
			// number of raided coworkers
			egen rd_coworker_n = sum(rd_coworker), by(event_id)
			
			// wage of raided coworkers in destination firm
			gen rd_coworker_wage_d = wage_real_ln if rd_coworker == 1
			
			// wage of raided coworkers in origin firm
			egen rd_coworker_max = max(rd_coworker), by(cpf event_id)
			gen rd_coworker_wage_o_l12 = wage_real_ln if ym_rel == -12 & rd_coworker_max == 1
			egen rd_coworker_wage_o = max(rd_coworker_wage_o_l12), by(cpf event_id)
			
			// quality of raided coworkers
			gen rd_coworker_fe = fe_worker if rd_coworker == 1
			
			// keeping relevant obs and collapsing to event level
			
			keep if rd_coworker == 1
			
			if _N >= 1 { // there might not be any raided coworkers
			
				collapse (mean) rd_coworker_n rd_coworker_wage_d rd_coworker_wage_o rd_coworker_fe, by(event_id)
		
				// saving temp file
				save "${temp}/rd_coworker_`e'_`ym'", replace
		
			}
		}
	}
	}
		
	// destination firm -- firm size and wage bill
	
	foreach e in spv dir emp { // dir5 
		
		// listing events in t=0

		use "${data}/evt_m_`e'", clear
		
		egen unique = tag(d_plant pc_ym)
		keep if unique == 1
		keep event_id d_plant pc_ym
		
		save "${temp}/events_t0", replace	
		
		// look for destination firms in t=0 and calculate the firm size and wage bill
		
		forvalues ym=528/683 {

			// in RAIS, keeping what we need for this data set	

			use "${data}/rais_m/rais_m`ym'", clear
	
			// keeping t=0 (ym == pc_ym) for the destination plants
			rename ym pc_ym
			rename plant_id d_plant
			merge m:1 d_plant pc_ym using "${temp}/events_t0", keep(match)
			
			if _N >= 1 {
			
				drop _merge
		
				// organizing
				order event_id d_plant pc_ym
				sort event_id cpf
		
				// adjusting wages
			
				merge m:1 year using "${input}/auxiliary/ipca_brazil"
				generate index_2017 = index if year == 2017
				egen index_base = max(index_2017)
				generate adj_index = index / index_base		
				generate wage_real = earn_avg_month_nom / adj_index
				
					// in logs
					gen wage_real_ln = ln(wage_real)
				
				drop if _merge == 2
				drop _merge
				sort event_id cpf
			
				// collapsing
				
				gen count = 1
				collapse (sum) d_size=count (mean) d_wage_real=wage_real d_wage_real_ln=wage_real_ln, by(event_id)	
				
				// saving
				save "${temp}/d_vars_`e'_`ym'", replace
			
			}			
		}
	}
	

	// information about team size
	
	foreach e in emp  { //dir emp
	forvalues ym=612/683 {	
	
		use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
	
		if _N >= 1 {

			// identify occupation group of the poached individual

				gen occup_pc = occup_cbo2002 if pc_individual == 1 & ym_rel == -1
				
				gen occup_pc_2d = substr(occup_pc, 1, 2)
				
				destring occup_pc_2d, force replace
				
				// note: there might be more than 1 poached invidual
				// if they are not in the same team, this will be complicated
				// i will not compute team size in this case
					
				egen unique = tag(occup_pc_2d event_id)
				egen n_unique = sum(unique), by(event_id)
				replace occup_pc_2d = . if n_unique != 1
				
				// expanding 2-digit occupation of the poached individual for the entire event (including t=-12)
				egen occup_pc_2d_max = max(occup_pc_2d), by(event_id)
				replace occup_pc_2d = occup_pc_2d_max
				drop occup_pc_2d_max
		
			// identify occupation group of the coworkers

				gen occup_cw = occup_cbo2002 if pc_individual == 0 & ym_rel == -12
				
				gen occup_cw_2d = substr(occup_cw, 1, 2)
				
				destring occup_cw_2d, force replace
				
				egen occup_cw_2d_max = max(occup_cw_2d), by(event_id cpf)
				replace occup_cw_2d = occup_cw_2d_max
				drop occup_cw_2d_max
			
			// identify coworkers from the same team as the poached individual

				gen team_cw = (occup_pc_2d == occup_cw_2d) & spv == 0 & dir == 0 & ym_rel == -12
				
			// identify supervisors from the same team as the poached individual

				gen team_spv = (occup_pc_2d == occup_cw_2d) & spv == 1 & dir == 0 & ym_rel == -12
				
			// identify directors from the same team as the poached individual

				gen team_dir = (occup_pc_2d == occup_cw_2d) & spv == 0 & dir == 1 & ym_rel == -12
			
			// keep only t=-12
			keep if ym_rel == -12
	
			// collapsing at the event level
			collapse (sum) team_cw team_spv team_dir, by(event_id)

			// saving
			save "${temp}/team_`e'_`ym'", replace
		
		}
	}
	}
	
	
	
	// destination firm variables
	
		foreach e in spv dir emp { // dir5 
		
		use "${data}/evt_panel_m_`e'", clear
		*use "${data}/evt_panel_m_spv", clear
		
			// destination firm growth
			
			gen d_emp_l12_temp = d_emp if ym_rel == -12
			egen d_emp_l12 = max(d_emp_l12_temp), by(event_id)
			drop d_emp_l12_temp
			
			gen d_emp_l1_temp = d_emp if ym_rel == -1
			egen d_emp_l1 = max(d_emp_l1_temp), by(event_id)
			drop d_emp_l1_temp
			
			gen d_growth = d_emp_l1 / d_emp_l12 - 1
			
			// keep 1 obs for each event_id
			
			egen unique = tag(event_id)
			keep if unique == 1
			keep event_id d_growth
			
		// saving
		* This should be 
		*save "${temp}/d_growth_`e'", replace
		save "${data}/d_growth_`e'", replace
		
		}





// NEW HIRES
foreach e in emp { // dir5 spv dir emp 
		
		use "${data}/evt_panel_m_`e'", clear
		
			// destination firm new hires
		
			egen d_hire_temp = sum(d_hire_t) if ym_rel >= 0, by(event_id)
			egen d_hire = max(d_hire_temp), by(event_id)
			drop d_hire_temp
			
			// keep 1 obs for each event_id
			
			egen unique = tag(event_id)
			keep if unique == 1
			keep event_id d_hire
			
		// saving
		save "${temp}/d_hire_`e'", replace
}
		

// Adding var with number of current workers in the same occupational code as the poached individual in DESTINATION firm_id
foreach e in emp  { // dir5 spv dir emp
    forvalues ym=612/683 {
	
        // Define the file path
        local filepath "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'.dta"

        // Check if the file exists before using it
        if (fileexists("`filepath'")) {
		
            use "`filepath'", clear
		
		gen ym_rel = ym - pc_ym
			
			// identify occupation group of the poached individual

				gen occup_pc = occup_cbo2002 if pc_individual == 1 & ym_rel == 0
				
				gen occup_pc_2d = substr(occup_pc, 1, 2)
				
				destring occup_pc_2d, force replace
				
				// note: there might be more than 1 poached individual
				// if they are not in the same team, this will be complicated
				// i will not compute team size in this case
					
				egen unique = tag(occup_pc_2d event_id)
				egen n_unique = sum(unique), by(event_id)
				replace occup_pc_2d = . if n_unique != 1
				
				// expanding 2-digit occupation of the poached individual for the entire event
				egen occup_pc_2d_max = max(occup_pc_2d), by(event_id)
				replace occup_pc_2d = occup_pc_2d_max
				drop occup_pc_2d_max
		
			// identify occupation group of the coworkers

				gen occup_cw = occup_cbo2002 if pc_individual == 0 & ym_rel == 0
				
				gen occup_cw_2d = substr(occup_cw, 1, 2)
				
				destring occup_cw_2d, force replace
				
				egen occup_cw_2d_max = max(occup_cw_2d), by(event_id cpf)
				replace occup_cw_2d = occup_cw_2d_max
				drop occup_cw_2d_max
			
			// identify coworkers from the same team as the poached individual

				gen team_cw = (occup_pc_2d == occup_cw_2d) & spv == 0 & dir == 0 & ym_rel == 0
				
			// identify supervisors from the same team as the poached individual

				gen team_spv = (occup_pc_2d == occup_cw_2d) & spv == 1 & dir == 0 & ym_rel == 0
				
			// identify directors from the same team as the poached individual

				gen team_dir = (occup_pc_2d == occup_cw_2d) & spv == 0 & dir == 1 & ym_rel == 0
			
			// keep only t=0
			keep if ym_rel == 0
	
			// collapsing at the event level
			collapse (sum) team_cw team_spv team_dir, by(event_id)
			rename team_cw d_team_cw
			rename team_spv d_team_spv
			rename team_dir d_team_dir
			
			// saving
			save "${temp}/d_team_`e'_`ym'", replace
		} 
		else {
            di "File `filepath' not found."
        }
    }
}

// Adding turnover at the destination firm
foreach e in emp  { //dir emp
    forvalues ym=612/683 { 
    
        // Define the file path 
        local filepath "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'.dta"

        // Check if the file exists before using it
        if (fileexists("`filepath'")) {
		
		use "`filepath'", clear
	    
			gen ym_rel = ym - pc_ym
			
			sort event_id cpf ym_rel
				
			order cpf ym_rel
			
			// pessoas na empresa (média entre t=-12 e t=-1)
			
				// calcula pessoas em t=-12
			
					egen emp_L12_temp = count(cpf) if ym_rel == -12, by(event_id)
					egen emp_L12 = max(emp_L12_temp), by(event_id)
					drop emp_L12_temp
					
				// calcula pessoas em t=-1
				
					egen emp_L1_temp = count(cpf) if ym_rel == -1, by(event_id)	
					egen emp_L1 = max(emp_L1_temp), by(event_id)
					drop emp_L1_temp

			// pessoas who left (entre t=-12 e t=-1)
			
					// who was employed before zero
					
					gen emp_beforezero = (ym_rel < 0)
					egen worker_emp_beforezero = max(emp_beforezero), by(event_id cpf)
					
					// who is employed after zero
					
					gen emp_afterzero = (ym_rel >= 0)
					egen worker_emp_afterzero = max(emp_afterzero), by(event_id cpf)
					
					// workers who left
					gen left_temp = (worker_emp_beforezero == 1 & worker_emp_afterzero == 0)
					egen left = max(left_temp), by(event_id cpf)
					
			egen unique = tag(event_id cpf)
			
			egen n_left = sum(left) if unique == 1, by(event_id)
			
			drop unique
			
			// pessoas que foram recontratadas em ym_rel > 0 entram na nossa conta do turnover como se NÃO fossem left
			// logo, o "left" que a gente considera é um "left" permanente
					
			// collapse at the event_id level
			egen unique = tag(event_id)
			keep if unique == 1
			
			keep event_id n_left emp_L12 emp_L1
			
			// turnover
			gen turnover = n_left / ((emp_L12 + emp_L1)/2)
			
			// saving
			save "${temp}/turnover_`e'_`ym'", replace
		
		} 
		else {
            di "File `filepath' not found."
        }
    }
}

	
// calculating workers below 75th perc in dest. firm_id
foreach e in emp  { //dir emp
    forvalues ym=612/683 { 
    
        // Define the file path 
        local filepath "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'.dta"

        // Check if the file exists before using it
        if (fileexists("`filepath'")) {
		
		use "`filepath'", clear
	    
			gen ym_rel = ym - pc_ym
			
			sort event_id cpf ym_rel
				
			order cpf ym_rel
			
			egen d_size_temp = count(cpf) if ym_rel == 0, by(event_id)
			egen d_size = max(d_size_temp), by(event_id)
			drop d_size_temp
		
			// include information on quartile of worker fe
			merge m:1 cpf using "${AKM}/AKM_2003_2008_Worker_quartiles", keep(master match) nogen	
			gen below_75th_fe = 1 if quartile_worker == 1 | quartile_worker == 2 | quartile_worker == 3	
			replace below_75th_fe = 0 if quartile_worker == 4
		
			// number of above 75th at origin firm 
			egen d_size_below_75th_temp = sum(below_75th_fe) if ym_rel == -0, by(event_id)
			egen d_size_below_75th = max(d_size_below_75th_temp), by(event_id)
			drop d_size_below_75th_temp
		
			// ratio of above 75th at origin firm 
			gen d_ratio_below_75th = d_size_below_75th / d_size
			
			egen unique = tag(event_id)
			keep if unique == 1
			keep event_id d_ratio_below_75th
			
			save "${temp}/d_ratio_below_75th_`e'_`ym'", replace
			
	} 
		else {
            di "File `filepath' not found."
        }
    }
}



// calculating additional vars and putting everything together	
	
foreach e in spv  { //dir emp
	forvalues ym=612/683 { 

	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
	
	if _N >= 1 {
		
		sort event_id cpf ym_rel

		// poached individuals are identified by variable pc_individual (full panel)
		// when they are poached is identified by variable pc (ym_rel == 0)
		
		// size of the origin firm
		egen o_size_temp = count(cpf) if ym_rel == -12, by(event_id)
		egen o_size = max(o_size_temp), by(event_id)
		drop o_size_temp
	
		
		// include information on quartile of worker fe
		merge m:1 cpf using "${AKM}/AKM_2003_2008_Worker_quartiles", keep(master match) nogen
		gen below_median_fe = 1 if quartile_worker == 1 | quartile_worker == 2
		replace below_median_fe = 0 if quartile_worker == 3 | quartile_worker == 4	
		gen above_75th_fe = 1 if quartile_worker == 4 
		replace above_75th_fe = 0 if quartile_worker == 1 | quartile_worker == 2 | quartile_worker == 3	
		
		// number of above 75th at origin firm 
		egen o_size_above_75th_temp = sum(above_75th_fe) if ym_rel == -12, by(event_id)
		egen o_size_above_75th = max(o_size_above_75th_temp), by(event_id)
		drop o_size_above_75th_temp
		
		// ratio of above 75th at origin firm 
		gen ratio_above_75th = o_size_above_75th / o_size
		
		// number of mgrs at origin firm -- we need this to calculate # emp / # mgr
		egen o_size_mgr_temp = sum(spv) if ym_rel == -12, by(event_id)
		egen o_size_mgr = max(o_size_mgr_temp), by(event_id)
		drop o_size_mgr_temp
		
		// calculate # emp / # mgr
		gen o_size_ratio = o_size / o_size_mgr
		
		// origin firm avg AKM FE
		egen o_avg_fe_worker_temp = mean(fe_worker) if ym_rel == -12, by(event_id)
		egen o_avg_fe_worker = max(o_avg_fe_worker_temp), by(event_id)
		drop o_avg_fe_worker_temp
		
		// number of poached individuals
		egen pc_n = sum(pc), by(event_id)
		
		// wage of poached individual in destination firm
		gen pc_wage_d = wage_real_ln if pc == 1
		
		// wage of poached individual in origin firm (t=-12)
		gen pc_wage_o_l12_temp = wage_real_ln if ym_rel == -12 & pc_individual == 1
		egen pc_wage_o_l12 = max(pc_wage_o_l12_temp), by(cpf event_id)
		drop pc_wage_o_l12_temp
		
		// wage of poached individual in origin firm (t=-1)
		gen pc_wage_o_l1_temp = wage_real_ln if ym_rel == -1 & pc_individual == 1
		egen pc_wage_o_l1 = max(pc_wage_o_l1_temp), by(cpf event_id)
		drop pc_wage_o_l1_temp
		
		// quality of poached individual
		gen pc_fe = fe_worker if pc == 1
		
		// experience of the poached individual
		gen pc_exp = age - educ_years - 6
		
		// renaming some variables
		rename age 	  pc_age
		rename educ_years pc_educ_years
		
		// keeping relevant obs and collapsing to the event level
		keep if pc == 1
		collapse (mean) o_size o_size_mgr o_size_ratio o_avg_fe_worker  ///
			o_size_above_75th ratio_above_75th pc_wage_o_l12 pc_wage_o_l1 pc_wage_d ///
			pc_n pc_fe pc_exp pc_age pc_educ_years, ///
			by(event_id d_plant pc_ym o_plant)
	
		// merging with the auxiliary data sets
		
			// information about raided workers
			cap merge 1:1 event_id using "${temp}/rd_coworker_`e'_`ym'", nogen // "cap" because there might not be any raided coworker
			
			// destination firm -- firm size and wage bill
			cap merge 1:1 event_id using "${temp}/d_vars_`e'_`ym'", nogen
			
			// turnover
			cap merge 1:1 event_id using "${temp}/turnover_`e'_`ym'", nogen
			
			// information about team size: origin
			cap merge 1:1 event_id using "${temp}/team_`e'_`ym'", nogen
				
			// information about team size: destination	
			cap merge 1:1 event_id using "${temp}/d_team_`e'_`ym'", nogen
			
			// information about share of people below 75th perc in dest. firm_id
			cap merge 1:1 event_id using "${temp}/d_ratio_below_75th_`e'_`ym'", nogen
			
				
		// saving
		save "${temp}/poach_ind_`e'_`ym'", replace
		
	}
	
}	
}


// APPENDING
	
foreach e in spv dir emp { // dir5  spv dir emp spv
	
	clear
	
	forvalues ym=612/683 {	//683
		cap append using "${temp}/poach_ind_`e'_`ym'"
	}
	
	save "${data}/poach_ind_`e'", replace
	
}




// ADDING MORE VARIABLES

	// Firm AKM FE for destination and origin firms and info on growth rate and size of new hires
	
	foreach e in spv dir emp { // dir5 spv emp dir
	
		use "${data}/poach_ind_`e'", clear
		
			// destination
			
			tostring d_plant, generate(plant_id) format(%014.0f)
			gen firm_id = substr(plant_id, 1, 8)
			destring firm_id, force replace
			
			merge m:1 firm_id using "${AKM}/AKM_2003_2008_Firm", keep(master match) nogen
			rename fe_firm fe_firm_d
			
			drop firm_id plant_id
			
			// origin
			
			tostring o_plant, generate(plant_id) format(%014.0f)
			gen firm_id = substr(plant_id, 1, 8)
			destring firm_id, force replace
			
			merge m:1 firm_id using "${AKM}/AKM_2003_2008_Firm", keep(master match) nogen
			rename fe_firm fe_firm_o
			
			drop firm_id plant_id
			
			*cap merge 1:1 event_id using "${temp}/d_growth_`e'", nogen
			cap merge 1:1 event_id using "${data}/d_growth_`e'", keep(master match) nogen
			
			cap merge 1:1 event_id using "${temp}/d_hire_`e'", keep(master match) nogen
			
		save "${data}/poach_ind_`e'", replace
	
	}
	
	
	// Incluiding additional variables that will be necessary for the creation of tables in following steps
	
	foreach e in spv dir emp { // dir5 spv emp dir
	
		use "${data}/poach_ind_spv", clear
		
		// origin firm (# emp / # mgr) within same occ category as the poached mgr: o_ratio_team
		gen o_ratio_team = team_cw / team_spv
		
		// destination firm (# raided workers / # new hires): ratio_cw_new_hire and ratio_cw_new_hire_m
		gen ratio_cw_new_hire = rd_coworker_n / d_hire
		
		// destination firm log hires handling missing values, creating dummy for when this is zero and dealing with missing 
		// vars of this dummy
		gen d_hire_d0 = 1 if d_hire == 0
		replace d_hire_d0 = 0 if d_hire != 0
		
		
		// Taking log
		local logvars pc_exp o_size o_size_ratio team_cw o_ratio_team rd_coworker_n d_team_cw d_size
		foreach var of local logvars {
								
			gen `var'_ln = ln(`var')
									
		}
		
		
		// Winsorizing vars
		local winsorvars d_growth o_ratio_team o_size_ratio // dir não encontra obs. para o_ratio_team pq team_spv tudo zero
		
		foreach var of local winsorvars {
			winsor `var', gen (`var'_winsor) p(0.01)
		}
		
							


			
		save "${data}/poach_ind_`e'", replace
	
	}		
					

		
		
// information about department FE 
	
	foreach e in spv dir emp { //dir emp
	forvalues ym=612/683 {	
	
		use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
	
		if _N >= 1 {

			// identify occupation group of the poached individual

				gen occup_pc = occup_cbo2002 if pc_individual == 1 & ym_rel == -1
				
				gen occup_pc_2d = substr(occup_pc, 1, 2)
				
				destring occup_pc_2d, force replace
				
				// note: there might be more than 1 poached invidual
				// if they are not in the same team, this will be complicated
				// i will not compute team size in this case
					
				egen unique = tag(occup_pc_2d event_id)
				egen n_unique = sum(unique), by(event_id)
				replace occup_pc_2d = . if n_unique != 1
				
				// expanding 2-digit occupation of the poached individual for the entire event (including t=-12)
				egen occup_pc_2d_max = max(occup_pc_2d), by(event_id)
				replace occup_pc_2d = occup_pc_2d_max
				drop occup_pc_2d_max
		
			// identify occupation group of the coworkers

				gen occup_cw = occup_cbo2002 if pc_individual == 0 & ym_rel == -12
				
				gen occup_cw_2d = substr(occup_cw, 1, 2)
				
				destring occup_cw_2d, force replace
				
				egen occup_cw_2d_max = max(occup_cw_2d), by(event_id cpf)
				replace occup_cw_2d = occup_cw_2d_max
				drop occup_cw_2d_max
			
			// identify coworkers from the same team as the poached individual

				gen team_cw = (occup_pc_2d == occup_cw_2d) & spv == 0 & dir == 0 & ym_rel == -12
				
			// collapsing at the event level
			// this does not work if there are no obs where team_cw == 1
			// in these cases, we will set this to missing
			summarize team_cw if team_cw == 1
			if r(N) > 0 {
				collapse (mean) fe_worker if team_cw == 1, by(event_id)
			} 
			else {
				collapse (mean) fe_worker, by(event_id)
				replace fe_worker = .
			}
			
			rename fe_worker department_fe
			// saving
			save "${temp}/department_fe_`e'_`ym'", replace
		
		}
	}
	}


// this is smaller than 15,513	
foreach e in spv dir emp { // dir5  spv dir emp spv
	
	clear
	
	forvalues ym=612/683 {	//683
		cap append using "${temp}/department_fe_`e'_`ym'"
	}
	
	save "${data}/department_fe_`e'", replace
	
}

// information about CNAE

foreach e in emp  { //dir emp
 	forvalues ym=612/683 {	
	
	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
	
		if _N >= 1 {
	
	keep if pc_individual == 1
	keep if ym_rel == -12 | ym_rel == 0
	
	keep event_id ym ym_rel cnae20_class cnae20_subclass
	
	gen cnae = real(substr(string(cnae20_class), 1, 2))
	
	
	bysort event_id: gen cnae_d = cnae if ym_rel == 0
	bysort event_id: gen cnae_o = cnae if ym_rel == -12
	
	egen cnae_d_filled = max(cnae_d), by(event_id)
	egen cnae_o_filled = max(cnae_o), by(event_id)
	
	replace cnae_d = cnae_d_filled
	replace cnae_o = cnae_o_filled
	
	drop cnae_d_filled cnae_o_filled
	
	bysort event_id: keep if _n ==1
	
	keep event_id cnae_o cnae_d
	
	save "${temp}/cnae_`e'_`ym'", replace
	
		}
	}
}

	
foreach e in spv dir emp  { // dir5  spv dir emp spv
	
	clear
	
	forvalues ym=612/683 {	//683
		cap append using "${temp}/cnae_`e'_`ym'"
	}
	
	*duplicates drop event_id cnae_o cnae_d, force
	save "${data}/cnae_`e'", replace
	
}

			
// include this in poach_ind

foreach e in spv dir emp  { // dir5 spv emp dir
	
		use "${data}/poach_ind_`e'", clear
			
		merge m:1 event_id using "${data}/cnae_`e'", keep(master match) nogen
		merge m:1 event_id using "${data}/department_fe_`e'", keep(master match) nogen
			
		save "${data}/poach_ind_`e'", replace
}




	// including level of rd_coworker_wage_o and rd_coworker_wage_o
	
	foreach e in spv emp dir { // dir5 
	forvalues ym=528/683 {	
	
		use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
		
		if _N >= 1 {
	
			// identifying raided coworkers
			sort event_id cpf ym_rel
			by event_id cpf: gen rd_coworker = (pc_individual == 0) & (ym_rel>=0) & (plant_id[_n-1] != d_plant) & (plant_id == d_plant)
			
			// number of raided coworkers
			egen rd_coworker_n = sum(rd_coworker), by(event_id)
			
			// wage of raided coworkers in destination firm
			gen rd_coworker_wage_d_lvl = wage_real if rd_coworker == 1
			
			// wage of raided coworkers in origin firm
			egen rd_coworker_max = max(rd_coworker), by(cpf event_id)
			gen rd_coworker_wage_o_l12_lvl = wage_real if ym_rel == -12 & rd_coworker_max == 1
			egen rd_coworker_wage_o_lvl = max(rd_coworker_wage_o_l12_lvl), by(cpf event_id)
			
			
			keep if rd_coworker == 1
			
			if _N >= 1 { // there might not be any raided coworkers
			
				collapse (mean) rd_coworker_wage_d_lvl rd_coworker_wage_o_lvl, by(event_id)
		
				// saving temp file
				save "${temp}/rd_coworker_wage_lvl_`e'_`ym'", replace
		
			}
		}
	}
}

foreach e in spv dir emp  { // dir5  spv dir emp spv
	
	clear
	
	forvalues ym=612/683 {	//683
		cap append using "${temp}/rd_coworker_wage_lvl_`e'_`ym'"
	}
	
	*duplicates drop event_id cnae_o cnae_d, force
	save "${temp}/rd_coworker_wage_lvl_`e'", replace
	
}

	
foreach e in spv dir emp { //dir emp
	forvalues ym=612/683 { 

	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
	
	if _N >= 1 {
		
		sort event_id cpf ym_rel
		
		// wage of poached individual in origin firm (t=-12)
		gen pc_wage_o_l12_temp_lvl = wage_real if ym_rel == -12 & pc_individual == 1
		egen pc_wage_o_l12_lvl = max(pc_wage_o_l12_temp_lvl), by(cpf event_id)
		drop pc_wage_o_l12_temp_lvl
		
		// wage of poached individual in origin firm (t=-1)
		gen pc_wage_o_l1_temp_lvl = wage_real if ym_rel == -1 & pc_individual == 1
		egen pc_wage_o_l1_lvl = max(pc_wage_o_l1_temp_lvl), by(cpf event_id)
		drop pc_wage_o_l1_temp_lvl
		
		// wage of poached individual in destination firm
		gen pc_wage_d_lvl = wage_real if pc == 1
		
		// keeping relevant obs and collapsing to the event level
		keep if pc == 1
		collapse (mean) pc_wage_o_l12_lvl pc_wage_o_l1_lvl pc_wage_d_lvl, ///
			by(event_id d_plant pc_ym o_plant)
	
		// saving
		save "${temp}/pc_wage_lvl_`e'_`ym'", replace
		
	}
	
}	
}

foreach e in spv dir emp  { // dir5  spv dir emp spv
	
	clear
	
	forvalues ym=612/683 {	//683
		cap append using "${temp}/pc_wage_lvl_`e'_`ym'"
	}
	
	*duplicates drop event_id cnae_o cnae_d, force
	save "${temp}/pc_wage_lvl_`e'", replace
	
}

foreach e in emp spv dir  { //dir emp
    forvalues ym=612/683 { 
    
        // Define the file path 
        local filepath "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'.dta"

        // Check if the file exists before using it
        if (fileexists("`filepath'")) {
		
		use "`filepath'", clear
	    
			gen ym_rel = ym - pc_ym
			
			sort event_id cpf ym_rel
				
			order cpf ym_rel
			
			// destination firm avg AKM FE
			egen d_avg_fe_worker_temp = mean(fe_worker) if ym_rel == -12, by(event_id)
			egen d_avg_fe_worker = max(d_avg_fe_worker_temp), by(event_id)
			drop d_avg_fe_worker_temp
			
			egen unique = tag(event_id)
			keep if unique == 1
			keep event_id d_avg_fe_worker
			
			save "${temp}/d_avg_fe_worker_`e'_`ym'", replace
			
	} 
		else {
            di "File `filepath' not found."
        }
    }
}

foreach e in spv dir emp  { // dir5  spv dir emp spv
	
	clear
	
	forvalues ym=612/683 {	//683
		cap append using "${temp}/d_avg_fe_worker_`e'_`ym'"
	}
	
	*duplicates drop event_id cnae_o cnae_d, force
	save "${temp}/d_avg_fe_worker_`e'", replace
	
}

*/

/*

// including necessary vars and labeling 
foreach e in spv dir emp  { // dir5 spv emp dir
	
		use "${data}/poach_ind_`e'", clear
		
		merge m:1 event_id using "${temp}/rd_coworker_wage_lvl_`e'", keep(master match) nogen
		merge m:1 event_id using "${temp}/pc_wage_lvl_`e'", keep(master match) nogen
		merge m:1 event_id using "${temp}/d_avg_fe_worker_`e'", keep(master match) nogen
		
		
		cap la var pc_wage_o_l1 "Ln wage of poached individual at origin firm in -1"
		cap la var pc_wage_o_l12 "Ln wage of poached individual at origin firm in -12"
		cap la var rd_coworker_wage_o "Ln wage of raided coworker at origin firm" 
		cap la var team_spv "Number of spv in same team as poached individual at origin firm"     
		cap la var o_ratio_team "Origin firm (# emp / # mgr) within same occ category as the poached mgr"
		cap la var d_size_ln "Ln of size of destination firm"        
		cap la var rd_coworker_fe "Avg. AKM FE of raided coworkers"
		cap la var team_dir "Number of dir in same team as poached individual at origin firm"     
		cap la var ratio_cw_new_hire "Destination firm (# raided workers / # new hires)"		
		cap la var d_growth_winsor "Winsor of destination firm growth rate between -12 and -1"         
		cap la var pc_wage_d "Ln wage of poached individual at dest. firm"
		cap la var d_size "Size of destination firm"      
		cap la var d_team_cw "Number of coworkers from the same team as the poached individual at destination firm"	    
		cap la var d_hire_d0 "Dummy = 1 when zero new hires at dest. firm" 
		cap la var o_ratio_team_winsor "Winsor origin firm (# emp / # mgr) within same occ category as the poached mgr"      
		cap la var pc_n "Number of poached individuals"         
		cap la var d_wage_real "Real wage at dest. firm"
		cap la var d_team_spv "Number of spv in same team as poached individual at dest. firm"   
		cap la var pc_exp_ln "Ln of experience of poached individual"   
		cap la var o_size_ratio_winsor "Winsor # emp / # mgr at origin firm"
		cap la var o_size "Size of origin firm"       
		cap la var pc_fe  "AKM FE of poached individual"       
		cap la var d_wage_real_ln  "Ln real wage at dest. firm"
		cap la var d_team_dir "Number of dir in same team as poached individual at dest. firm" 
		cap la var o_size_ln "Ln of size of origin firm"     
		cap la var cnae_d "CNAE of destination firm"
		cap la var o_size_mgr "Number of managers at origin firm at -12"  
		cap la var pc_exp "Poached individual experience"       
		cap la var emp_L12 "Size of dest. firm in -12"     
		cap la var d_ratio_below_75th "Share of workers below 75th AKM FE at dest. firm"
		cap la var o_size_ratio_ln "Ln # emp / # mgr at origin firm"
		cap la var cnae_o "CNAE of origin firm"
		cap la var o_size_ratio "# emp / # mgr at origin firm"
		cap la var pc_age "Age of poached individual"       
		cap la var emp_L1 "Size of dest. firm in -1"        
		cap la var fe_firm_d "Destination firm AKM FE"    
		cap la var team_cw_ln "Ln of number of coworkers from the same team as the poached individual at origin firm"	  
		cap la var department_fe "Avg. AKM FE of workers in same team/department (3d CBO)"
		cap la var o_avg_fe_worker "Avg. worker AKM FE at origin firm at -12" 
		cap la var pc_educ_years "Years of education of poached individual"
		cap la var n_left "Number of people that were employed before zero, but left after zero at dest. firm"       
		cap la var fe_firm_o "Origin firm AKM FE"     
		cap la var o_ratio_team_ln "Ln origin firm (# emp / # mgr) within same occ category as the poached mgr"
		cap la var o_size_above_75th "Number of workers above 75th AKM FE at origin firm"
		cap la var rd_coworker_n "Number of raided coworkers"
		cap la var turnover "Ratio between n_left and avg. emp_L1 and emp_L12"    
		cap la var d_growth "Destination firm growth rate between -12 and -1"     
		cap la var rd_coworker_n_ln "Ln of number of raided coworkers"
		cap la var ratio_above_75th "Share of workers above 75th AKM FE at origin firm"
		cap la var rd_coworker_wage_d "Ln wage of raided coworkers at dest. firm"
		cap la var team_cw "Number of coworkers from the same team as the poached individual at origin firm"		     
		cap la var d_hire "Number of hires at dest. firm after 0"       
		cap la var d_team_cw_ln "Ln of number of coworkers from the same team as the poached individual at dest. firm"
		cap la var rd_coworker_wage_d_lvl "Wage of raided coworker at dest. firm (level)" 
		cap la var rd_coworker_wage_o_lvl "Wage of raided coworker at origin firm (level)" 
		cap la var pc_wage_o_l1_lvl "Wage of poached individual at origin firm in -1 (level)"
		cap la var pc_wage_o_l12_lvl "Wage of poached individual at origin firm in -12 (level)"
		cap la var pc_wage_d_lvl "Wage of poached individual at dest. firm (level)"
		cap la var d_avg_fe_worker "Avg. worker AKM FE at dest. firm at -0" 
		
		
		
		save "${data}/poach_ind_`e'", replace
}

*/

// December 23: adding more variables to these data sets

	// delta wages
	
	foreach e in spv emp dir { // dir5 
	forvalues ym=528/683 {	
	
		// this is from the coworker data set
		
		use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
		
		if _N >= 1 {
		
			// identifying raided coworkers
			sort event_id cpf ym_rel
			by event_id cpf: gen rd_coworker = (pc_individual == 0) & (ym_rel>=0) & (plant_id[_n-1] != d_plant) & (plant_id == d_plant)
			
			// log: wage of raided coworkers in destination firm
			gen rd_coworker_wage_d = wage_real_ln if rd_coworker == 1
			
			// log: wage of raided coworkers in origin firm
			egen rd_coworker_max = max(rd_coworker), by(cpf event_id)
			gen rd_coworker_wage_o_l12 = wage_real_ln if ym_rel == -12 & rd_coworker_max == 1
			egen rd_coworker_wage_o = max(rd_coworker_wage_o_l12), by(cpf event_id)
			
				// delta log:
				gen delta_rd_coworker_wage = rd_coworker_wage_d - rd_coworker_wage_o
			
			// level: wage of raided coworkers in destination firm
			gen rd_coworker_wage_d_lvl = wage_real if rd_coworker == 1
			
			// level: wage of raided coworkers in origin firm
			gen rd_coworker_wage_o_l12_lvl = wage_real if ym_rel == -12 & rd_coworker_max == 1
			egen rd_coworker_wage_o_lvl = max(rd_coworker_wage_o_l12_lvl), by(cpf event_id)
			
				// delta log:
				gen delta_rd_coworker_wage_lvl = rd_coworker_wage_d_lvl - rd_coworker_wage_o_lvl
			
			// keeping relevant obs and collapsing to event level
			
			keep if rd_coworker == 1
			
			if _N >= 1 { // there might not be any raided coworkers
			
				collapse (mean) delta_rd_avg=delta_rd_coworker_wage ///
						delta_rd_avg_lvl=delta_rd_coworker_wage_lvl ///
					 (sum)  delta_rd_sum=delta_rd_coworker_wage ///
						delta_rd_sum_lvl=delta_rd_coworker_wage_lvl, ///
						by(event_id)
		
				// saving temp file
				save "${temp}/delta_`e'_`ym'", replace
		
			}
		}
	}
	}
	
	foreach e in spv dir emp  { // dir5
	
		clear
	
		forvalues ym=528/683 {
		cap append using "${temp}/delta_`e'_`ym'"
		}
	
		save "${temp}/delta_`e'", replace
	
	}	

	foreach e in spv dir emp  { // dir5
	
		use "${data}/poach_ind_`e'", clear
		
		merge 1:1 event_id using "${temp}/delta_`e'", keep(master match) nogen
		
		save "${data}/poach_ind_`e'_NEW", replace
		
	}
			
	

*--------------------------*
* EXIT
*--------------------------*

/*

// REMOVE TEMP FILES! (AFTER GUARANTEEING EVERYTHING IS OK!)
	
clear

cap rm "${temp}/events_t0.dta"

foreach e in spv dir emp dir5 {
forvalues ym=528/683 {
	
	cap rm "${temp}/rd_coworker_`e'_`ym'.dta"
	cap rm "${temp}/d_vars_`e'_`ym'.dta"
	cap rm "${temp}/spvteam_`e'_`ym'.dta"
	cap rm "${temp}/poach_ind_`e'_`ym'.dta"
		
}		
}
	

