// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Create data set with poached individuals only

*--------------------------*
* BUILD
*--------------------------*

/*

// variables from cowork_panel_m

	// this panel will be constructed separately for each cohort
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {	

	use "${data}/202503_cowork_panel_m/202503_o_cw_`ym'", clear
	
	// creating alternative raided workers variable -- MOVE THIS TO COWORK_PANEL_M_SPV, EVENTUALLY
	// reassigning poached individuals who are not the main one as raided individuals
	
		gen raidpc = (raid == 1 | (ym_rel == 0 & pc_individual == 1 & main_individual == 0))
		
		gen raidpc_individual = (raid_individual == 1 | (pc_individual == 1 & main_individual == 0))
			
	// organizing variables we want to keep
	
		// cnae_o, cnae_d
		
		tostring cnae20_class, gen(cnae20_class_str) format(%05.0f)
		gen cnae20_2d = substr(cnae20_class_str, 1, 2)
		destring cnae20_2d, force replace
		
		gen cnae_o_temp = cnae20_2d if ym_rel == -12 & pc_individual == 1
		egen cnae_o = max(cnae_o_temp), by(eventid)
			
		gen cnae_d_temp = cnae20_2d if ym_rel == 0 & pc_individual == 1
		egen cnae_d = max(cnae_d_temp), by(eventid)
			
		drop cnae20_class_str cnae20_2d cnae_o_temp cnae_d_temp
		
		// o_avg_worker_naive_fe
		
		gen o_avg_worker_naive_fe_temp = worker_naive_fe if ym_rel == -12
		egen o_avg_worker_naive_fe = mean(o_avg_worker_naive_fe_temp), by(eventid)
		
		drop o_avg_worker_naive_fe_temp
		
		// o_avg_worker_akm_fe
		
		gen o_avg_worker_akm_fe_temp = worker_akm_fe if ym_rel == -12
		egen o_avg_worker_akm_fe = mean(o_avg_worker_akm_fe_temp), by(eventid)
		
		drop o_avg_worker_akm_fe_temp
		
		// o_size
	
		gen o_size_temp = 1 if ym_rel == -12
		egen o_size = sum(o_size_temp), by(eventid)
		
		drop o_size_temp
		
		// pc_age
		
		gen pc_age_temp = age if ym_rel == -12 & pc_individual == 1
		egen pc_age = mean(pc_age_temp), by(eventid)
		
		drop pc_age_temp
		
			// pc_age
		
			gen main_age_temp = age if ym_rel == -12 & main_individual == 1
			egen main_age = mean(main_age_temp), by(eventid)
		
			drop main_age_temp
		
		// pc_exp
		
		gen pc_exp_temp = age - educ_years - 6 if ym_rel == -12 & pc_individual == 1
		
			// note: in some cases, this is negative or zero
			// issue: young people with too many education years
			// in these cases, we assign pc_exp = 1 (they were employed, after all)
			replace pc_exp_temp = 1 if pc_exp <= 0
			
		egen pc_exp = mean(pc_exp_temp), by(eventid)
		
		drop pc_exp_temp
		
			// main_exp
		
			gen main_exp_temp = age - educ_years - 6 if ym_rel == -12 & main_individual == 1
		
				// note: in some cases, this is negative or zero
				// issue: young people with too many education years
				// in these cases, we assign main_exp = 1 (they were employed, after all)
				replace main_exp_temp = 1 if main_exp <= 0
				
			egen main_exp = mean(main_exp_temp), by(eventid)
			
			drop main_exp_temp
		
		// pc_worker_naive_fe
		
		gen pc_worker_naive_fe_temp = worker_naive_fe if ym_rel == -12 & pc_individual == 1
		egen pc_worker_naive_fe = mean(pc_worker_naive_fe_temp), by(eventid)
		
		drop pc_worker_naive_fe_temp
		
			// main_worker_naive_fe
		
			gen main_worker_naive_fe_temp = worker_naive_fe if ym_rel == -12 & main_individual == 1
			egen main_worker_naive_fe = mean(main_worker_naive_fe_temp), by(eventid)
		
			drop main_worker_naive_fe_temp
			
		// pc_worker_akm_fe
		
		gen pc_worker_akm_fe_temp = worker_akm_fe if ym_rel == -12 & pc_individual == 1
		egen pc_worker_akm_fe = mean(pc_worker_akm_fe_temp), by(eventid)
		
		drop pc_worker_akm_fe_temp
		
			// main_worker_akm_fe
		
			gen main_worker_akm_fe_temp = worker_akm_fe if ym_rel == -12 & main_individual == 1
			egen main_worker_akm_fe = mean(main_worker_akm_fe_temp), by(eventid)
		
			drop main_worker_akm_fe_temp	
	
		// pc_wage_d
		
		gen pc_wage_d_temp = wage_real_ln if ym_rel == 0 & pc_individual == 1
		egen pc_wage_d = mean(pc_wage_d_temp), by(eventid)
		
		drop pc_wage_d_temp
		
			// main_wage_d
		
			gen main_wage_d_temp = wage_real_ln if ym_rel == 0 & main_individual == 1
			egen main_wage_d = mean(main_wage_d_temp), by(eventid)
			
			drop main_wage_d_temp
		
		// pc_wage_d_lvl
		
		gen pc_wage_d_lvl_temp = wage_real if ym_rel == 0 & pc_individual == 1
		egen pc_wage_d_lvl = mean(pc_wage_d_lvl_temp), by(eventid)
		
		drop pc_wage_d_lvl_temp
		
			// main_wage_d_lvl
		
			gen main_wage_d_lvl_temp = wage_real if ym_rel == 0 & main_individual == 1
			egen main_wage_d_lvl = mean(main_wage_d_lvl_temp), by(eventid)
			
			drop main_wage_d_lvl_temp
			
		// pc_wage_o_l1
		
		gen pc_wage_o_l1_temp = wage_real_ln if ym_rel == -1 & pc_individual == 1
		egen pc_wage_o_l1 = mean(pc_wage_o_l1_temp), by(eventid)
		
		drop pc_wage_o_l1_temp
		
			// pc_wage_o_l1
		
			gen main_wage_o_l1_temp = wage_real_ln if ym_rel == -1 & main_individual == 1
			egen main_wage_o_l1 = mean(main_wage_o_l1_temp), by(eventid)
			
			drop main_wage_o_l1_temp
			
		// pc_wage_o_l1_lvl
		
		gen pc_wage_o_l1_lvl_temp = wage_real if ym_rel == -1 & pc_individual == 1
		egen pc_wage_o_l1_lvl = mean(pc_wage_o_l1_lvl_temp), by(eventid)
		
		drop pc_wage_o_l1_lvl_temp
		
			// main_wage_o_l1_lvl
		
			gen main_wage_o_l1_lvl_temp = wage_real if ym_rel == -1 & main_individual == 1
			egen main_wage_o_l1_lvl = mean(main_wage_o_l1_lvl_temp), by(eventid)
			
			drop main_wage_o_l1_lvl_temp
			
		// rd_coworker_naive_fe
		
		gen rd_coworker_naive_fe_temp = worker_naive_fe if ym_rel == -12 & raid_individual == 1
		egen rd_coworker_naive_fe = mean(rd_coworker_naive_fe_temp), by(eventid)
		
		drop rd_coworker_naive_fe_temp
		
			// rdpc_coworker_naive_fe
		
			gen rdpc_coworker_naive_fe_temp = worker_naive_fe if ym_rel == -12 & raidpc_individual == 1
			egen rdpc_coworker_naive_fe = mean(rdpc_coworker_naive_fe_temp), by(eventid)
			
			drop rdpc_coworker_naive_fe_temp

		// rd_coworker_akm_fe
		
		gen rd_coworker_akm_fe_temp = worker_akm_fe if ym_rel == -12 & raid_individual == 1
		egen rd_coworker_akm_fe = mean(rd_coworker_akm_fe_temp), by(eventid)
		
		drop rd_coworker_akm_fe_temp
		
			// rdpc_coworker_akm_fe
		
			gen rdpc_coworker_akm_fe_temp = worker_akm_fe if ym_rel == -12 & raidpc_individual == 1
			egen rdpc_coworker_akm_fe = mean(rdpc_coworker_akm_fe_temp), by(eventid)
			
			drop rdpc_coworker_akm_fe_temp	
			
		// rd_coworker_n
		
		gen rd_coworker_n_temp = 1 if ym_rel == -12 & raid_individual == 1
		egen rd_coworker_n = sum(rd_coworker_n_temp), by(eventid)
		
		drop rd_coworker_n_temp
		
			// rdpc_coworker_n
		
			gen rdpc_coworker_n_temp = 1 if ym_rel == -12 & raidpc_individual == 1
			egen rdpc_coworker_n = sum(rdpc_coworker_n_temp), by(eventid)
		
			drop rdpc_coworker_n_temp
		
		// rd_coworker_wage_o_lvl
		
		gen rd_coworker_wage_o_lvl_temp = wage_real if ym_rel == -12 & raid_individual == 1
		egen rd_coworker_wage_o_lvl = mean(rd_coworker_wage_o_lvl_temp), by(eventid)
		
		drop rd_coworker_wage_o_lvl_temp
		
			// rdpc_coworker_wage_o_lvl
			
			gen rdpc_coworker_wage_o_lvl_temp = wage_real if ym_rel == -12 & raidpc_individual == 1
			egen rdpc_coworker_wage_o_lvl = mean(rdpc_coworker_wage_o_lvl_temp), by(eventid)
			
			drop rdpc_coworker_wage_o_lvl_temp
		
		// rd_coworker_wage_d_lvl
		
		gen rd_coworker_wage_d_lvl_temp = wage_real if raid == 1 & raid_individual == 1
		egen rd_coworker_wage_d_lvl = mean(rd_coworker_wage_d_lvl_temp), by(eventid)
		
		drop rd_coworker_wage_d_lvl_temp
		
			// rdpc_coworker_wage_d_lvl
		
			gen rdpc_coworker_wage_d_lvl_temp = wage_real if raidpc == 1 & raidpc_individual == 1
			egen rdpc_coworker_wage_d_lvl = mean(rdpc_coworker_wage_d_lvl_temp), by(eventid)
			
			drop rdpc_coworker_wage_d_lvl_temp
			
	// keeping the variables we need
	keep eventid cnae_d cnae_o o_avg_worker_naive_fe o_avg_worker_akm_fe o_size pc_age main_age pc_exp main_exp ///
		pc_worker_naive_fe pc_worker_akm_fe main_worker_naive_fe main_worker_akm_fe ///
		pc_wage_d main_wage_d pc_wage_d_lvl main_wage_d_lvl pc_wage_o_l1 ///
		main_wage_o_l1 pc_wage_o_l1_lvl main_wage_o_l1_lvl rd_coworker_naive_fe rd_coworker_akm_fe ///
		rdpc_coworker_naive_fe rdpc_coworker_akm_fe ///
		rd_coworker_n rdpc_coworker_n rd_coworker_wage_d_lvl rdpc_coworker_wage_d_lvl ///
		rd_coworker_wage_o_lvl rdpc_coworker_wage_o_lvl
	
	// keeping one observation per event
	egen unique = tag(eventid)
	keep if unique == 1
	drop unique
	
	// save temporary file
	save "${temp}/from_cowork_panel_m_`ym'", replace
	
	}
	
	// appending monthly files

	clear 
		
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {	
		
		append using "${temp}/from_cowork_panel_m_`ym'"
	
	}
	
	save "${temp}/from_cowork_panel_m", replace

// variables from dest_panel_m
	
	// this panel will be constructed separately for each cohort
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {	

	use "${data}/202503_dest_panel_m/202503_dest_panel_m_`ym'", clear
	
	sort eventid ym cpf
	gen pc_ym = `ym'
	gen ym_rel = ym - pc_ym
	
	// organizing variables we want to keep
	
		// d_avg_worker_naive_fe
		
		gen d_avg_worker_naive_fe_temp = worker_naive_fe if ym_rel == 0
		egen d_avg_worker_naive_fe = mean(d_avg_worker_naive_fe_temp), by(eventid)
		
		drop d_avg_worker_naive_fe_temp
		
		// d_avg_worker_akm_fe
		
		gen d_avg_worker_akm_fe_temp = worker_akm_fe if ym_rel == 0
		egen d_avg_worker_akm_fe = mean(d_avg_worker_akm_fe_temp), by(eventid)
		
		drop d_avg_worker_akm_fe_temp
		
		// d_size
		
		gen d_size_temp = 1 if ym_rel == 0
		egen d_size = sum(d_size_temp), by(eventid)
	
		drop d_size_temp
		
	// keeping the variables we need
	keep eventid d_avg_worker_naive_fe d_avg_worker_akm_fe d_size
	
	// keeping one observation per event
	egen unique = tag(eventid)
	keep if unique == 1
	drop unique
	
	// save temporary file
	save "${temp}/from_dest_panel_m_`ym'", replace
		
	}
	
	// appending monthly files
	
	clear
		
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {	
		
		append using "${temp}/from_dest_panel_m_`ym'"
	
	}
	
	save "${temp}/from_dest_panel_m", replace
			
// variables from evt_panel_m
	
	use "${data}/202503_evt_panel_m", clear
	
	// organizing variables we want to keep
	
		// d_growth -- NOTE::: LATER, LET'S USE THE PLANT SIZE DATA SET
			
		gen d_wkr_l12_temp = d_wkr if ym_rel == -12
		egen d_wkr_l12 = max(d_wkr_l12_temp), by(eventid)
		drop d_wkr_l12_temp
			
		gen d_wkr_l1_temp = d_wkr if ym_rel == -1
		egen d_wkr_l1 = max(d_wkr_l1_temp), by(eventid)
		drop d_wkr_l1_temp
			
		gen d_growth = d_wkr_l1 / d_wkr_l12 - 1
		
		// d_hire_total
		
		gen d_hire_total_temp = d_hire if ym_rel >= 0
		egen d_hire_total = sum(d_hire_total_temp), by(eventid)
		
		drop d_hire_total_temp
		
	// keeping the variables we need
	keep eventid d_growth d_hire_total
	
	// keeping one observation per event
	egen unique = tag(eventid)
	keep if unique == 1
	drop unique
	
	// save temporary file
	save "${temp}/from_evt_panel_m", replace 
	
// constructing the panel directly

	use "${data}/202503_evt_m", clear 
	
	drop if eventid == . // REMOVE THIS ONCE CORRECTED IN THE DO-FILE THAT ORIGINATES THIS
	
	// moving to the event level
	
	drop pc_dir pc_spv pc_emp pc_d_dir pc_d_spv pc_d_emp pc_cpf
	
	egen unique = tag(eventid)
	keep if unique == 1
	drop unique

	// merging with the previous data sets
	merge 1:1 eventid using "${temp}/from_cowork_panel_m", nogen
	merge 1:1 eventid using "${temp}/from_dest_panel_m", nogen
	merge 1:1 eventid using "${temp}/from_evt_panel_m", nogen
	
	// merging with firm FE --- UPDATE THIS USING THE NEW AKM EFFECTS!
	
		// origin firm FE
		tostring o_plant, generate(o_plant_str) format(%014.0f)
		gen firm_id = substr(o_plant_str, 1, 8)
		destring firm_id, replace force
		merge m:1 firm_id using "${AKM}/AKM_2003_2008_both_firmFE", keep(master match) nogen
		rename naive_FE_firm o_firm_naive_fe
		rename akm_FE_firm o_firm_akm_fe
		drop o_plant_str firm_id
		
		// destination firm FE
		tostring d_plant, generate(d_plant_str) format(%014.0f)
		gen firm_id = substr(d_plant_str, 1, 8)
		destring firm_id, replace force
		merge m:1 firm_id using "${AKM}/AKM_2003_2008_both_firmFE", keep(master match) nogen
		rename naive_FE_firm d_firm_naive_fe
		rename akm_FE_firm d_firm_akm_fe
		drop d_plant_str firm_id
		
	// creating additional variables
	
		// d_size_ln
		gen d_size_ln = ln(d_size)
		
		// pc_exp_ln
		gen pc_exp_ln = ln(pc_exp)
		
		// rd_coworker_n_ln
		gen rd_coworker_n_ln = ln(rd_coworker_n)
		
		// ratio_cw_new_hire
		gen ratio_cw_new_hire = rd_coworker_n / d_hire
		
	// labeling variables
	
	la var cnae_d 			"CNAE of destination firm"
	la var cnae_o 			"CNAE of origin firm"
	la var d_avg_worker_naive_fe 	"Avg. worker naive FE at dest. firm at -0" 
	la var d_avg_worker_akm_fe 	"Avg. worker AKM FE at dest. firm at -0" 
	la var d_growth 		"Destination firm growth rate between -12 and -1"            
	la var d_hire 			"Number of hires at dest. firm after 0" 
	la var d_plant			"Destination plant ID"
	la var d_size 			"Size of destination firm"      
	la var d_size_ln 		"Ln of size of destination firm"  
	la var eventid 			"Event ID"
	la var d_firm_naive_fe		"Destination firm naive FE" 
	la var d_firm_akm_fe		"Destination firm AKM FE" 
   	la var o_firm_naive_fe		"Origin firm naive FE"
	la var o_firm_akm_fe		"Origin firm AKM FE"  
	la var o_avg_worker_naive_fe 	"Avg. worker naive FE at origin firm at -12"
	la var o_avg_worker_akm_fe	"Avg. worker AKM FE at origin firm at -12"
	la var o_plant			"Origin plant ID"
	la var o_size 			"Size of origin firm"       
	la var pc_age 			"Age of poached individual"       
	la var pc_exp 			"Poached individual experience"       
	la var pc_exp_ln 		"Ln of experience of poached individual" 
	la var pc_worker_naive_fe	"Naive FE of poached individual"
	la var pc_worker_akm_fe  	"AKM FE of poached individual"       
	la var pc_wage_d 		"Ln wage of poached individual at dest. firm"
	la var pc_wage_d_lvl 		"Wage of poached individual at dest. firm (level)"
	la var pc_wage_o_l1 		"Ln wage of poached individual at origin firm in -1"  
	la var pc_wage_o_l1_lvl 	"Wage of poached individual at origin firm in -1 (level)"
	la var pc_ym 			"Poaching cohort"
	la var ratio_cw_new_hire 	"Destination firm (# raided workers / # new hires)"
	la var rd_coworker_naive_fe 	"Avg. naive FE of raided coworkers"   
	la var rd_coworker_akm_fe 	"Avg. AKM FE of raided coworkers"   
	la var rd_coworker_n 		"Number of raided coworkers"
	la var rd_coworker_n_ln 	"Ln of number of raided coworkers"	
	la var rd_coworker_wage_d_lvl 	"Wage of raided coworker at dest. firm (level)" 
	la var rd_coworker_wage_o_lvl 	"Wage of raided coworker at origin firm (level)" 
	
	// saving
	save "${data}/202503_poach_ind", replace
	
// adding more variables

	use "${data}/202503_poach_ind", clear
	
	// event type variable
	merge 1:1 eventid using "${data}/202503_evttype", nogen
	
	// tagging top earners in spv-emp and emp-spv
	xtile waged_spvemp = pc_wage_d    if type==6, nq(10)
	xtile waged_empspv = pc_wage_o_l1 if type==8, nq(10)
	
	// saving
	save "${data}/202503_poach_ind", replace
	
*/	
	
// tenure overlap: creating measure

	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {	
		
	use "${data}/202503_cowork_panel_m_`e'/202503_o_cw_`ym'", clear	
	
		// stat 1: number of employees they overlap with for the full tenure
			
			// poached manager tenure when poached
			gen tenure_pc_temp = tenure_ym_pc if ym_rel == -1
			egen tenure_pc = max(tenure_pc_temp), by(event_id)
			replace tenure_pc = . if n_pc != 1 
			drop tenure_pc_temp
			
			// who they've overlap with the entire time
			gen full_overlap = (tenure_pc == tenure_overlap) 
			replace full_overlap = . if tenure_pc == . | tenure_overlap == .
		
		// stat 2: average tenure overlap
		* we already have a variable for this: tenure_overlap
		
		// stat 3: average tenure overlap with individuals who were raided
		gen tenure_overlap_raided = tenure_overlap if raid_individual == 1
		
		// stat 4: number of employees they overlap with for at least 1 year
		gen tenure_overlap_1y = ((tenure_overlap >= 12) & (tenure_overlap != .))
		replace tenure_overlap_1y = . if tenure_pc == . | tenure_overlap == .
		
		// collapse
		
		drop if pc_individual == 1
		egen unique = tag(event_id cpf)
		keep if unique == 1
		
		collapse (mean) full_overlap tenure_overlap tenure_overlap_raided tenure_overlap_1y ///
			(sum) full_overlap_sum=full_overlap tenure_overlap_sum=tenure_overlap ///
			tenure_overlap_raided_sum=tenure_overlap_raided ///
			tenure_overlap_1y_sum=tenure_overlap_1y, by(event_id)
			
		// the sum should be missing if the average was not computed
		replace full_overlap_sum = . if full_overlap == .
		replace tenure_overlap_sum = . if tenure_overlap == .
		replace tenure_overlap_raided_sum = . if tenure_overlap_raided == .
		replace tenure_overlap_1y_sum = . if tenure_overlap_1y == .
		
		
		save "${temp}/tenureoverlap_`e'_`ym'", replace
		
		}

	
	// appending by event type
	
	foreach e in spv emp dir {
	
	clear
	
	forvalues ym=528/683 {
	
		cap append using "${temp}/tenureoverlap_`e'_`ym'"
	
	}
	
	save "${temp}/tenureoverlap_`e'", replace
	
	}

// tenure overlap: merging with poach_ind
	
*--------------------------*
* EXIT
*--------------------------*

// REMOVE TEMP FILES!!!! 
	
