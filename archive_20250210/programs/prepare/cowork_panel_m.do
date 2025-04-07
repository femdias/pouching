// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Constructing the panel with coworkers

*--------------------------*
* BUILD
*--------------------------*

foreach e in spv dir emp dir5 {
forvalues ym=528/683 {
	
	// PART I: LIST EVENTS AND ORIGIN FIRMS
	
	// the month when the poaching took place is called pc_ym
	// but the coworkers are identified 12 months before pc_ym
	// let's add this variable to evt_xxx and keep only what we need to identify the coworkers in t=-1
		
	use "${data}/evt_m_`e'", clear
			
	keep if pc_ym == `ym'
			
	if _N >= 1 { // we only continue running if there are events
			
		keep event_id o_plant pc_ym d_plant
			
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
		save "${temp}/key_evts_m", replace  
			
		// listing firms and period where I will try to find the coworkers
		// i use this to save a simpler version of rais that only includes the workers I might be interested in
		keep plant_id ym
		duplicates drop
			
		// saving this list of origin firms and their t=-12
		save "${temp}/o_plants", replace
			
		// PART II: FINDING THE COWORKERS IN T=-12	
			
			local ym_l12=`ym'-12
			local ym_f12=`ym'+12
			
			use "${data}/rais_m/rais_m`ym_l12'", clear
			
			merge m:1 plant_id using "${temp}/o_plants", nogen keep(match)
			
			// saving list of coworkers
			keep cpf
			save "${temp}/cw", replace
			
		// PART III: FINDING THE T=-12 WORKERS IN T=-12 THROUGH T=+12	

			
			forvalues yymm=`ym_l12'/`ym_f12' {
				
				use "${data}/rais_m/rais_m`yymm'", clear
				
				merge m:1 cpf using "${temp}/cw", nogen keep(match)
				
				save "${temp}/cw_`yymm'", replace
				
			} 

		// PART IV: CREATING AND POPULATING THE EMPTY PANEL
		
			use "${temp}/cw", clear
			
			expand 25
			sort cpf
			
			by cpf: gen ym = `ym' - 13 + _n
			format ym %tm
			
			gen ym_rel = ym - `ym'
			
			forvalues yymm=`ym_l12'/`ym_f12' {
			
				merge 1:1 cpf ym using "${temp}/cw_`yymm'", nogen update

			}
			
			save "${temp}/cw", replace
		
		// PART V: ORGANIZING WITH EVENT INFORMATION
		
			use "${temp}/cw", clear
			
			merge m:1 plant_id ym using "${temp}/key_evts_m", nogen
			sort cpf ym_rel
			
			// expanding the event variables for the entire panel
				
			foreach var in event_id d_plant pc_ym o_plant {
				egen double `var'_n = max(`var'), by(cpf)
					replace `var' = `var'_n
					drop `var'_n
				}
				
			order event_id d_plant pc_ym o_plant cpf year month ym ym_rel
			sort event_id cpf ym_rel	

			// other variables
			
			gen coworker_l12 = (ym_rel == -12)
			gen coworker = 1
				
			save "${temp}/cw", replace
							
		// PART VI: adding more variables to the data set

			use "${temp}/cw", clear
		
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
				merge m:1 year using "${input}/auxiliary/ipca_brazil"
				generate index_2008 = index if year == 2008
				egen index_base = max(index_2008)
				generate adj_index = index / index_base
				drop if _merge == 2
				drop _merge
				
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
	
		if "`e'" == "dir" | "`e'" == "dir5" | "`e'" == "spv" {
		
			sort event_id cpf ym_rel
			by event_id cpf: gen pc = ym_rel == 0 & (`e'[_n-1] == 1) ///
				& (plant_id[_n-1] == o_plant) & (plant_id == d_plant) 
			egen pc_individual = max(pc), by(event_id cpf)
		
		}
		
		if "`e'" == "emp" {
			
			sort event_id cpf ym_rel
			by event_id cpf: gen pc = ym_rel == 0 & (dir[_n-1] == 0 | spv[_n-1] == 0) ///
				& (plant_id[_n-1] == o_plant) & (plant_id == d_plant) 
			egen pc_individual = max(pc), by(event_id cpf)
	
		}
		
		
		if "`e'" == "dir" | "`e'" == "dir5" {
		
			// identifying the poached directors who continued as directors
			gen pc_dirindestination = (pc ==1) & (`e' == 1)
			egen pc_dirindestination_ind = max(pc_dirindestination), by(event_id cpf)
			
		}	
		 
		 // organizing and saving
		 
		 drop gov emp o_emp_l12_temp o_emp_l12_nondir_temp ///
			o_emp_l12_dir_temp index index_2008 index_base adj_index wage_0_temp ///
			wage_real_0_temp wage_l12_temp wage_real_l12_temp
			
	} // closing "if _N >= 1"	
	
	save "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", replace	
		
} // closing loop through months	
} // closing loop through event type

*--------------------------*
* ADDITIONAL VARIABLES
*--------------------------*

// AKM FEs
	
foreach e in spv dir emp dir5 {
forvalues ym = 528/683 {	

	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
		
		if _N > 0 {
		
			// worker FEs (from "low-tech" AKM model)
			merge m:1 cpf using "${AKM}/AKM_2003_2008_Worker", keep(master match) nogen
		
			// saving
			save "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", replace
	
		}
}
}

// identifying raided individuals

foreach e in spv dir emp dir5 {
forvalues ym = 528/683 {	

	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
		
		if _N > 0 {
		
			// set hiring date
			gen hire_ym = ym(hire_year, hire_month) 
				
			// identify raidind events 
			gen raid = ((ym == hire_ym) & (hire_ym != .)) /// hired in the month
				   & (type_of_hire == 2) /// type was 'readmissão'
				   & (plant_id == d_plant) /// moving to destination plant
				   & (pc_individual == 0) /// not a poached invidual
				   & (dir == 0 & spv == 0) // is an employee
			
			// identify raided individuals
			egen raid_individual = max(raid), by(cpf)
		
			// saving
			save "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", replace
	
		}
}
}
// including variable that indicates moveable workers and tenure overlap of worker with pc mgr
foreach e in spv dir emp  { // dir5
forvalues ym = 528/683 {	

	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
		
		if _N > 0 {
		
			// Construct variables that indicate moveable workers
			// ie which workers left the origin firm within the next year following the poaching event
			sort event_id cpf ym_rel

			// 1. Who was at origin firm at t=-12?
			// everybody was at origin firm at t=-12 by construction

			// 2. who left after or at zero
			gen left = (ym_rel >= 0 & plant_id != o_plant)

			// 3. but were in t=-1
			gen was_at_l1_aux = (ym_rel == -1 & plant_id == o_plant)
			egen was_at_l1 = max(was_at_l1_aux), by(event_id cpf) 

			// identifies who was in t=-1, but not t=0 and on and expands to event id 
			gen left_after_zero = (left == 1 & was_at_l1 == 1)
			egen moveable_worker = max(left_after_zero), by(event_id cpf) 

			// still, this people could move out of firm and formal (plant id missing). let us create moveable that remained in formal sector
			gen left_to_other_firm = (ym_rel >= 0 & plant_id != o_plant & plant_id != .)

			// identifica quem estava em t = -1, mas não t = 0 em diante e expande para o event id
			gen left_after_zero_to_other_firm = (left_to_other_firm == 1 & was_at_l1 == 1)
			egen moveable_worker_changed_firm = max(left_after_zero_to_other_firm), by(event_id cpf) 
			
			drop left was_at_l1_aux was_at_l1 left_after_zero left_to_other_firm left_after_zero_to_other_firm
			
			// Construct variables that indicate tenure overlap
			// tenure in RAIS is reported in december or last month of person in the firm
			// let us compute a "running" tenure instead
			gen tenure_ym = ym - hire_ym

			// tenure of worker
			gen tenure_l12_aux = tenure_ym if ym_rel == -12
			egen tenure_l12 = max(tenure_l12_aux), by(event_id cpf)

			// tenure of pc individual
			gen tenure_l12_pc_aux = tenure_ym if (ym_rel == -12 & pc_individual == 1)
			egen tenure_l12_pc = max(tenure_l12_pc_aux), by(event_id)

			// tenure overlap
			gen tenure_overlap_aux = min(tenure_l12, tenure_l12_pc) if pc_individual == 0 // doesnt make sense for poached individual
			egen tenure_overlap = max(tenure_overlap_aux), by(event_id cpf)

			// this is more complicated if we have more than 1 pc individual, we won't calculate in this case
			egen n_pc = sum(pc_individual), by(event_id ym_rel)
			replace tenure_overlap = . if n_pc != 1

			drop tenure_l12_aux tenure_l12_pc_aux tenure_overlap_aux
		
			// saving
			save "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", replace
	
		}
}
}

	 		
*--------------------------*
* EXIT
*--------------------------*

cap rm "${temp}/key_evts_m.dta"
cap rm "${temp}/o_plants.dta"
cap rm "${temp}/cw.dta"

forvalues ym=516/695 {

	cap rm "${temp}/cw_`ym'.dta"

}

clear
