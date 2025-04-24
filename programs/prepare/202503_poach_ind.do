// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Create data set with poached individuals only

*--------------------------*
* BUILD
*--------------------------*

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
		
		gen cnae_o_temp = cnae20_2d if ym_rel == -12
		egen cnae_o = max(cnae_o_temp), by(eventid)
		
		gen cnae_d_temp = cnae20_2d if ym_rel == 0
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
	
	/*
	
	// appending monthly files

	clear 
		
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {	
		
		append using "${temp}/from_cowork_panel_m_`ym'"
	
	}
	
	save "${temp}/from_cowork_panel_m", replace
	
	*/

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
	
	/*
	
	clear
		
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {	
		
		append using "${temp}/from_dest_panel_m_`ym'"
	
	}
	
	save "${temp}/from_dest_panel_m", replace
	
	*/
			
// variables from evt_panel_m

	/* // ISSO AQUI JÁ FOI RODADO!!!!!!!!!!!
	
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
	
	*/
	
// constructing the panel directly

	// LATER -- THIS SHOULD BE PRETTY STRAIGHTFORWARD WHEN THE ABOVE IS COMPLETE
	
	/*

	foreach e in spv dir emp {

	use "${data}/evt_m_`e'", clear 
	
	// dropping unnecessary variable
	drop pc_`e'
	
	// period restriction
	keep if pc_ym >= ym(2010,1)
	
	// merging with the previous data sets
	merge 1:1 event_id using "${temp}/from_cowork_panel_m_`e'", nogen
	merge 1:1 event_id using "${temp}/from_dest_panel_m_`e'", nogen
	merge 1:1 event_id using "${temp}/from_evt_panel_m_`e'", nogen
	
	// merging with firm FE --- UPDATE THIS USING THE NEW AKM EFFECTS!
	
		// origin
			
		tostring o_plant, generate(plant_id) format(%014.0f)
		gen firm_id = substr(plant_id, 1, 8)
		destring firm_id, force replace
			
		merge m:1 firm_id using "${AKM}/AKM_2003_2008_Firm", keep(master match) nogen
		rename fe_firm fe_firm_o
			
		drop firm_id plant_id
		
		// destination
		
		tostring d_plant, generate(plant_id) format(%014.0f)
		gen firm_id = substr(plant_id, 1, 8)
		destring firm_id, force replace
			
		merge m:1 firm_id using "${AKM}/AKM_2003_2008_Firm", keep(master match) nogen
		rename fe_firm fe_firm_d
			
		drop firm_id plant_id
		
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
	
	cap la var cnae_d 			"CNAE of destination firm"
	cap la var cnae_o 			"CNAE of origin firm"
	cap la var d_avg_fe_worker 		"Avg. worker AKM FE at dest. firm at -0" 
	cap la var d_growth 			"Destination firm growth rate between -12 and -1"            
	cap la var d_hire 			"Number of hires at dest. firm after 0" 
	cap la var d_plant			"Destination plant ID"
	cap la var d_size 			"Size of destination firm"      
	cap la var d_size_ln 			"Ln of size of destination firm"  
	cap la var event_id 			"Event ID"
	cap la var fe_firm_d 			"Destination firm AKM FE"    
	cap la var fe_firm_o 			"Origin firm AKM FE"     
	cap la var o_avg_fe_worker 		"Avg. worker AKM FE at origin firm at -12"
	cap la var o_plant			"Origin plant ID"
	cap la var o_size 			"Size of origin firm"       
	cap la var pc_age 			"Age of poached individual"       
	cap la var pc_exp 			"Poached individual experience"       
	cap la var pc_exp_ln 			"Ln of experience of poached individual"   
	cap la var pc_fe  			"AKM FE of poached individual"       
	cap la var pc_wage_d 			"Ln wage of poached individual at dest. firm"
	cap la var pc_wage_d_lvl 		"Wage of poached individual at dest. firm (level)"
	cap la var pc_wage_o_l1 		"Ln wage of poached individual at origin firm in -1"  
	cap la var pc_wage_o_l1_lvl 		"Wage of poached individual at origin firm in -1 (level)"
	cap la var pc_ym 			"Poaching cohort"
	cap la var ratio_cw_new_hire 		"Destination firm (# raided workers / # new hires)"		
	cap la var rd_coworker_fe 		"Avg. AKM FE of raided coworkers"   
	cap la var rd_coworker_n 		"Number of raided coworkers"
	cap la var rd_coworker_n_ln 		"Ln of number of raided coworkers"	
	cap la var rd_coworker_wage_d_lvl 	"Wage of raided coworker at dest. firm (level)" 
	cap la var rd_coworker_wage_o_lvl 	"Wage of raided coworker at origin firm (level)" 
	
	// saving
	save "${data}/202503_poach_ind_`e'", replace
	
	}
		
*--------------------------*
* EXIT
*--------------------------*

// REMOVE TEMP FILES!!!! 
	
