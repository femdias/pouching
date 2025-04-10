// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Constructing the panel with coworkers

*--------------------------*
* BUILD
*--------------------------*

/*

// PART I: LIST ORIGIN AND DESTINATION PLANTS, ALONG WITH MONTHS OF INTEREST

	// this panel will be constructed separately for each cohort
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {	
			
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
			compress
			save "${temp}/202503_o_plant_`ym'", replace
	
		restore
	
		// destination plants
		
		preserve
		
			keep eventid d_plant pc_ym
			rename d_plant plant_id
			compress
			save "${temp}/202503_d_plant_`ym'", replace
			
		restore
		
	clear
	
	}
	
// PART II: LISTING COWORKERS AND FINDING THEM
	
	// this panel will be constructed separately for each cohort
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
	
	// origin coworkers
		
		local o_ym = `ym'-12 // origin coworkers are identified 12 months before the event
		
		use "${data}/rais_m/rais_m`o_ym'", clear
		
		merge m:1 plant_id using "${temp}/202503_o_plant_`ym'"
		keep if _merge == 3
		drop _merge
		
		keep cpf eventid pc_ym 
		
		compress
		save "${temp}/202503_o_cw_`ym'", replace
		
	// destination coworkers
	
		local d_ym = `ym' // destination coworkers are identified at the time of the event
		
		use "${data}/rais_m/rais_m`d_ym'", clear
		
		merge m:1 plant_id using "${temp}/202503_d_plant_`ym'"
		keep if _merge == 3
		drop _merge
		
		keep cpf eventid pc_ym
		
		compress
		save "${temp}/202503_d_cw_`ym'", replace
		
	// finding these workers in monthly RAIS files	

	local ym_l12 = `ym' - 12
	local ym_f12 = `ym' + 12

	// origin coworkers
	
	forvalues yymm=`ym_l12'/`ym_f12' {
		
		use "${data}/rais_m/rais_m`yymm'", clear
		
		drop year month firm_id hire_year hire_month hire_day occ_1d occ_3d ///
			sep_month contract_salary salary_type legal_nature cnae20_subclass
		
		merge 1:1 cpf using "${temp}/202503_o_cw_`ym'"
		keep if _merge == 3
		drop _merge
		
		compress
		save "${temp}/202503_o_cw_`ym'_`yymm'", replace
		
	}
	
	// destination coworkers
	
	forvalues yymm=`ym_l12'/`ym_f12' {
		
		use "${data}/rais_m/rais_m`yymm'", clear
		
		drop year month firm_id hire_year hire_month hire_day occ_1d occ_3d ///
			sep_month contract_salary salary_type legal_nature cnae20_subclass
		
		merge 1:1 cpf using "${temp}/202503_d_cw_`ym'"
		keep if _merge == 3
		drop _merge
		
		compress
		save "${temp}/202503_d_cw_`ym'_`yymm'", replace
		
	}
	
	// combining all months in a cohort planel
		
	// origin
	
	use "${temp}/202503_o_cw_`ym'", clear
			
		expand 25
		sort cpf
			
			by cpf: gen ym = pc_ym - 13 + _n
			format ym %tm
			
			gen ym_rel = ym - pc_ym
			
			local ym_l12 = `ym' - 12
			local ym_f12 = `ym' + 12
			
			forvalues yymm=`ym_l12'/`ym_f12' {
			
				merge 1:1 cpf ym using "${temp}/202503_o_cw_`ym'_`yymm'", nogen update

			}
	compress
	save "${temp}/202503_o_cw_`ym'_complete", replace
	
		// removing heavy temporary files
		
		clear
		forvalues yymm=`ym_l12'/`ym_f12' {
		rm "${temp}/202503_o_cw_`ym'_`yymm'.dta"
		}
	
	// destination
	
	use "${temp}/202503_d_cw_`ym'", clear
			
		expand 25
		sort cpf
			
			by cpf: gen ym = pc_ym - 13 + _n
			format ym %tm
			
			gen ym_rel = ym - pc_ym
			
			local ym_l12 = `ym' - 12
			local ym_f12 = `ym' + 12
			
			forvalues yymm=`ym_l12'/`ym_f12' {
			
				merge 1:1 cpf ym using "${temp}/202503_d_cw_`ym'_`yymm'", nogen update

			}
	compress
	save "${temp}/202503_d_cw_`ym'_complete", replace
	
		// removing heavy temporary files
		
		clear
		forvalues yymm=`ym_l12'/`ym_f12' {
		rm "${temp}/202503_d_cw_`ym'_`yymm'.dta"
		}
			
	}
	
// PART III: ORGANIZING AUXILIARY DATA SETS

	// keeping event level information we need

		use "${data}/202503_evt_m", clear
		
		keep eventid o_plant d_plant d_n_emp_lavg o_n_emp_lavg multiple
		
		// only 1 observation for each event id
		egen unique = tag(eventid)
		keep if unique == 1
		drop unique
		
		// saving
		save "${temp}/202503_evt_vars", replace
		
	// keeping list of poached individuals
	
		use "${data}/202503_evt_m", clear
		
		drop if eventid == . // THIS WILL BE CORRECTED SOON!! DELETE THIS LINE THEN!!!
		keep eventid pc_cpf pc_dir pc_spv pc_emp pc_d_dir pc_d_spv pc_d_emp
		rename pc_cpf cpf
		
		save "${temp}/202503_pc_ind", replace
		
*/
	
// PART IV: ADDING MORE INFORMATION AND VARIABLES WE MIGHT NEED

	// this panel will be constructed separately for each cohort
	*foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 { // COMPLETE LIST
	*forvalues ym=620/620 {								 // O QUE JÁ RODOU	
	*foreach ym of numlist 601/611 { 						 // LOOP 1
	*foreach ym of numlist 613/619 621/623 { 					 // LOOP 2
	*foreach ym of numlist 625/635 { 						 // LOOP 3
	*foreach ym of numlist 637/647 { 						 // LOOP 4
	*foreach ym of numlist 649/659 { 						 // LOOP 5
	*foreach ym of numlist 661/671 { 						 // LOOP 6
	*foreach ym of numlist 673/683 { 						 // LOOP 7
	
	
	use "${temp}/202503_o_cw_`ym'_complete", clear
	
	// event-level information
	merge m:1 eventid using "${temp}/202503_evt_vars"
	drop if _merge == 2
	drop _merge
		
	// wages variables
		
		// adjusting wages ---- THIS IS ALSO TEMPORARY --- WILL EVENTUALLY BE DONE WHEN CONSTRUCTING THE MONTHLY DS
		
		gen year = year(dofm(ym))
		merge m:1 year using "${input}/auxiliary/ipca_brazil"
		generate index_2017 = index if year == 2017
		egen index_base = max(index_2017)
		generate adj_index = index / index_base
		drop if _merge == 2
				
			// in level
			generate wage_real = earn_avg_month_nom / adj_index
		
			// in logs
			gen wage_real_ln = ln(wage_real)
			
		drop year index _merge index_2017 index_base adj_index
		
		// other wage variables
		
		// wage in t=-12, level
		
		gen wage_real_l12_temp = wage_real if ym_rel == -12
		egen wage_real_l12 = max(wage_real_l12_temp), by(cpf)
		
		drop wage_real_l12_temp
		
		// wage in t=-12, log
		
		gen wage_real_ln_l12_temp = wage_real_ln if ym_rel == -12
		egen wage_real_ln_l12 = max(wage_real_ln_l12_temp), by(cpf)
		
		drop wage_real_ln_l12_temp
			
		// wage in t=0, level
		
		gen wage_real_0_temp = wage_real if ym_rel == 0
		egen wage_real_0 = max(wage_real_0_temp), by(cpf)
		
		drop wage_real_0_temp
		
		// wage in t=0, log
		
		gen wage_real_ln_0_temp = wage_real_ln if ym_rel == 0
		egen wage_real_ln_0 = max(wage_real_ln_0_temp), by(cpf)
		
		drop wage_real_ln_0_temp		
				
	// identifying the poached individuals among the coworkers
	
	merge m:1 eventid cpf using "${temp}/202503_pc_ind"
	drop if _merge == 2
	drop _merge
	
		// organzing the newly added variables
		replace pc_dir = 0 if pc_dir == .
		replace pc_spv = 0 if pc_spv == .
		replace pc_emp = 0 if pc_emp == .
		replace pc_d_dir = 0 if pc_d_dir == .
		replace pc_d_spv = 0 if pc_d_spv == .
		replace pc_d_emp = 0 if pc_d_emp == .
		
		// unique variable identifying the poached individuals
		gen pc_individual = (pc_dir == 1 | pc_spv == 1 | pc_emp == 1)
		
	// identify the raided individuals among the coworkers	
	
		// set hiring year-month
		gen hire_ym = ym(year(hire_date), month(hire_date))
		format hire_ym %tm
				
			// identify raiding events
			
			gen raid = ((ym == hire_ym) & (hire_ym != .)) /// hired in the month
				   & (plant_id == d_plant) /// moving to destination plant
				   & (pc_individual == 0) // not a poached individual 
				 
				// let's identify who was raided more than once
				egen raid_n = sum(raid), by(cpf)
				gen raid_multiple = (raid_n > 1)
				drop raid_n
				 
				// if an individual is raided more than once, use only the first raiding
				gen ym_raid = ym if raid == 1
				egen ym_raid_min = min(ym_raid), by(cpf)
				replace raid = 0 if ym_raid != ym_raid_min
				drop ym_raid ym_raid_min
				
			// raid types according to occupations
			
				// spv in origin
				
				gen spv_l12_temp = spv if ym_rel == -12
				egen spv_l12 = max(spv_l12_temp), by(cpf)
				
				gen raid_spv_temp = (raid == 1 & spv_l12 == 1)
				egen raid_spv = max(raid_spv_temp), by(cpf)
				
				drop spv_l12_temp raid_spv_temp
				
				// dir in origin
				
				gen dir_l12_temp = dir if ym_rel == -12
				egen dir_l12 = max(dir_l12_temp), by(cpf)
				
				gen raid_dir_temp = (raid == 1 & dir_l12 == 1)
				egen raid_dir = max(raid_dir_temp), by(cpf)
				
				drop dir_l12_temp raid_dir_temp
				
				// emp in origin
				
				gen emp = (dir == 0 & spv == 0) // THIS SHOULD BE CREATED WAY BEFORE!!!!!!!
				
				gen emp_l12_temp = emp if ym_rel == -12
				egen emp_l12 = max(emp_l12_temp), by(cpf)
				
				gen raid_emp_temp = (raid == 1 & emp_l12 == 1)
				egen raid_emp = max(raid_emp_temp), by(cpf)
				
				drop emp_l12_temp raid_emp_temp
				
				// spv in destination
				
				gen raid_d_spv_temp = (raid == 1 & spv == 1)
				egen raid_d_spv = max(raid_d_spv_temp), by(cpf)
				
				drop raid_d_spv_temp
				
				// dir in destination
				
				gen raid_d_dir_temp = (raid == 1 & dir == 1)
				egen raid_d_dir = max(raid_d_dir_temp), by(cpf)
				
				drop raid_d_dir_temp
				
				// emp in destination
				
				gen raid_d_emp_temp = (raid == 1 & emp == 1)
				egen raid_d_emp = max(raid_d_emp_temp), by(cpf)
				
				drop raid_d_emp_temp
				
			// identify raided individuals
			egen raid_individual = max(raid), by(cpf)
			
	// saving
	compress
	save "${temp}/202503_o_cw_`ym'_complete", replace
	
	} 	
	
	
	
	/*
				
	// adding worker FEs --- CHECK WITH FELIIPE WHICH DATA SETS I SHOULD USE!

		
			// worker FEs (from "low-tech" AKM model)
			merge m:1 cpf using "${AKM}/AKM_2003_2008_Worker", keep(master match) nogen
		
	


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
