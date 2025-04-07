// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Constructing the panel with coworkers

*--------------------------*
* BUILD
*--------------------------*

// PART I: LIST ORIGIN AND DESTINATION PLANTS, ALONG WITH MONTHS OF INTEREST

	// this panel will be constructed separately for each cohort
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {	
	*forvalues ym=620/620 {	
			
	use "${data}/202503_evt_m", clear
	
	// let's only keep the unique event identifiers
	keep eventid d_plant o_plant pc_ym
	egen unique = tag(eventid)
	keep if unique == 1

	// keep the cohort we're looping over		
	keep if pc_ym == `ym'
	
		// origin plants
		
		preserve
		
			keep eventid o_plant pc_ym
			rename o_plant plant_id
			save "${temp}/o_plant_`ym'", replace
	
		restore
	
		// destination plants
		
		preserve
		
			keep eventid d_plant pc_ym
			rename d_plant plant_id
			save "${temp}/d_plant_`ym'", replace
			
		restore
		
	clear
	
	}
	
// PART II: LISTING COWORKERS
	
	// this panel will be constructed separately for each cohort
	*foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
	forvalues ym=620/620 {
	
	// origin coworkers
		
		local o_ym = `ym'-12 // origin coworkers are identified 12 months before the event
		
		use "${data}/rais_m/rais_m`o_ym'", clear
		
		merge m:1 plant_id using "${temp}/o_plant_`ym'"
		keep if _merge == 3
		drop _merge
		
		keep cpf eventid pc_ym 
		
		save "${temp}/o_cw_`ym'", replace
		
	// destination coworkers
	
		local d_ym = `ym' // destination coworkers are identified at the time of the event
		
		use "${data}/rais_m/rais_m`d_ym'", clear
		
		merge m:1 plant_id using "${temp}/d_plant_`ym'"
		keep if _merge == 3
		drop _merge
		
		keep cpf eventid pc_ym
		
		save "${temp}/d_cw_`ym'", replace
		
	}	
		
			
// PART III: FINDING COWORKERS FROM T=-12 THROUGH T=12

	// this panel will be constructed separately for each cohort
	*foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
	forvalues ym=620/620 {

	local ym_l12 = `ym' - 12
	local ym_f12 = `ym' + 12

	// origin coworkers
	
	forvalues yymm=`ym_l12'/`ym_f12' {
		
		use "${data}/rais_m/rais_m`yymm'", clear
		
		merge 1:1 cpf using "${temp}/o_cw_`ym'"
		keep if _merge == 3
		drop _merge
		
		save "${temp}/o_cw_`ym'_`yymm'", replace
		
	}
	
	// destination coworkers
	
	forvalues yymm=`ym_l12'/`ym_f12' {
		
		use "${data}/rais_m/rais_m`yymm'", clear
		
		merge 1:1 cpf using "${temp}/d_cw_`ym'"
		keep if _merge == 3
		drop _merge
		
		save "${temp}/d_cw_`ym'_`yymm'", replace
		
	}
	}
	
// PART IV: CREATING AND POPULATING THE EMPTY PANEL
		
	// origin
	
	use "${temp}/o_cw_620", clear
			
		expand 25
		sort cpf
			
			by cpf: gen ym = pc_ym - 13 + _n
			format ym %tm
			
			gen ym_rel = ym - pc_ym
			
						local ym 620
			
			local ym_l12 = `ym' - 12
			local ym_f12 = `ym' + 12
			
			forvalues yymm=`ym_l12'/`ym_f12' {
			
				merge 1:1 cpf ym using "${temp}/o_cw_620_`yymm'", nogen update

			}
			
	save "${temp}/o_cw_620_complete", replace	
			
			
			
			
			
			
			
			
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

// including variable that indicates tenure overlap of worker with pc individual

	foreach e in spv emp dir { // dir5
	forvalues ym=528/683 {
		
	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear	
		
		if _N > 0 {

		// construct variables that indicate tenure overlap
		// tenure in RAIS is reported in december or last month of person in the firm
		// let us compute a "running" tenure instead
		gen tenure_ym = ym - hire_ym
		
		// identify cases we have more than 1 pc individual -- we won't calculate overlap in this case
		egen n_pc = sum(pc_individual), by(event_id ym_rel)

		// tenure of pc individual expanded to the event
		gen tenure_ym_pc_aux = tenure_ym if (ym_rel <= -1 & pc_individual == 1)
		egen tenure_ym_pc = max(tenure_ym_pc_aux), by(event_id ym_rel)
		drop tenure_ym_pc_aux
		replace tenure_ym_pc = . if n_pc != 1
		
			// if tenure_ym_pc is smaller than 12 in t=-1, do not calculate this
			gen tenure_ym_pc_l1_aux = tenure_ym_pc if ym_rel == -1
			egen tenure_ym_pc_l1 = max(tenure_ym_pc_l1_aux), by(event_id)
			replace tenure_ym_pc = . if tenure_ym_pc_l1 < 12
			drop tenure_ym_pc_l1_aux tenure_ym_pc_l1
			
		// tenure overlap in each month
		gen tenure_overlap_ym = .
		replace tenure_overlap_ym = min(tenure_ym, tenure_ym_pc) ///
			if plant_id == o_plant /// worker still employed in origin plant
			& ym_rel <= -1 /// before the poaching event
			& pc_individual == 0 // doesn't make sense for poached individuals
		replace tenure_overlap_ym = . if n_pc != 1
		
		// tenure overlap when co-employment terminates
		egen tenure_overlap = max(tenure_overlap_ym), by(event_id cpf)
		
		// labeling new variables
		label var tenure_ym          "Tenure (in Months)"
		label var n_pc               "Number of Poached Individuals in the Event"
		label var tenure_ym_pc       "Tenure (in Months) of the Poached Individual"
		label var tenure_overlap_ym  "Cumulative Tenure Overlap (in Months)"
		label var tenure_overlap     "Total Tenure Overlap"
		
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
