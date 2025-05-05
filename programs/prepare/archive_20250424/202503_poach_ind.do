// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Create data set with poached individuals only

*--------------------------*
* BUILD
*--------------------------*

// variables from cowork_panel_m

	foreach e in spv dir emp {
	forvalues ym=600/683 {

	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
	
	if _N > 0 {
	
	// identifying raided coworkers -- MOVE THIS TO COWORK_PANEL_M_SPV, EVENTUALLY
	
	drop raid raid_individual
	
	sort event_id cpf ym_rel
	by event_id cpf: gen raid = (pc_individual == 0) & (ym_rel>=0) & (plant_id[_n-1] != d_plant) & (plant_id == d_plant)
	
	egen raid_individual = max(raid), by(event_id cpf)
		
	// organizing variables we want to keep
	
		// cnae_o, cnae_d
		
		tostring cnae20_class, gen(cnae20_class_str) format(%05.0f)
		gen cnae20_2d = substr(cnae20_class_str, 1, 2)
		destring cnae20_2d, force replace
		
		gen cnae_o_temp = cnae20_2d if ym_rel == -12
		egen cnae_o = max(cnae_o_temp), by(event_id)
		
		gen cnae_d_temp = cnae20_2d if ym_rel == 0
		egen cnae_d = max(cnae_d_temp), by(event_id)
		
		drop cnae20_class_str cnae20_2d cnae_o_temp cnae_d_temp
		
		// o_avg_fe_worker
		
		gen o_avg_fe_worker_temp = fe_worker if ym_rel == -12
		egen o_avg_fe_worker = mean(o_avg_fe_worker_temp), by(event_id)
		
		drop o_avg_fe_worker_temp
		
		// o_size
	
		gen o_size_temp = 1 if ym_rel == -12
		egen o_size = sum(o_size_temp), by(event_id)
		
		drop o_size_temp
		
		// pc_age
		
		gen pc_age_temp = age if ym_rel == -12 & pc_individual == 1
		egen pc_age = mean(pc_age_temp), by(event_id)
		
		drop pc_age_temp
		
		// pc_exp
		
		gen pc_exp_temp = age - educ_years - 6 if ym_rel == -12 & pc_individual == 1
		
			// note: in some cases, this is negative or zero
			// issue: young people with too many education years
			// in these cases, we assign pc_exp = 1 (they were employed, after all)
			replace pc_exp_temp = 1 if pc_exp <= 0
			
		egen pc_exp = mean(pc_exp_temp), by(event_id)
		
		drop pc_exp_temp
		
		// pc_fe
		
		gen pc_fe_temp = fe_worker if ym_rel == -12 & pc_individual == 1
		egen pc_fe = mean(pc_fe), by(event_id)
		
		drop pc_fe_temp
	
		// pc_wage_d
		
		gen pc_wage_d_temp = wage_real_ln if ym_rel == 0 & pc_individual == 1
		egen pc_wage_d = mean(pc_wage_d_temp), by(event_id)
		
		drop pc_wage_d_temp
		
		// pc_wage_d_lvl
		
		gen pc_wage_d_lvl_temp = wage_real if ym_rel == 0 & pc_individual == 1
		egen pc_wage_d_lvl = mean(pc_wage_d_lvl_temp), by(event_id)
		
		drop pc_wage_d_lvl_temp
		
		// pc_wage_o_l1
		
		gen pc_wage_o_l1_temp = wage_real_ln if ym_rel == -1 & pc_individual == 1
		egen pc_wage_o_l1 = mean(pc_wage_o_l1_temp), by(event_id)
		
		drop pc_wage_o_l1_temp
		
		// pc_wage_o_l1_lvl
		
		gen pc_wage_o_l1_lvl_temp = wage_real if ym_rel == -1 & pc_individual == 1
		egen pc_wage_o_l1_lvl = mean(pc_wage_o_l1_lvl_temp), by(event_id)
		
		drop pc_wage_o_l1_lvl_temp
		
		// rd_coworker_fe
		
		gen rd_coworker_fe_temp = fe_worker if ym_rel == -12 & raid_individual == 1
		egen rd_coworker_fe = mean(rd_coworker_fe_temp), by(event_id)
		
		drop rd_coworker_fe_temp
		
		// rd_coworker_n
		
		gen rd_coworker_n_temp = 1 if ym_rel == -12 & raid_individual == 1
		egen rd_coworker_n = sum(rd_coworker_n_temp), by(event_id)
		
		drop rd_coworker_n_temp
		
		// rd_coworker_wage_o_lvl
		
		gen rd_coworker_wage_o_lvl_temp = wage_real if ym_rel == -12 & raid_individual == 1
		egen rd_coworker_wage_o_lvl = mean(rd_coworker_wage_o_lvl_temp), by(event_id)
		
		drop rd_coworker_wage_o_lvl_temp
		
		// rd_coworker_wage_d_lvl
		
		gen rd_coworker_wage_d_lvl_temp = wage_real if raid == 1 & raid_individual == 1
		egen rd_coworker_wage_d_lvl = mean(rd_coworker_wage_d_lvl_temp), by(event_id)
		
		drop rd_coworker_wage_d_lvl_temp
	
	// keeping the variables we need
	keep event_id cnae_d cnae_o o_avg_fe_worker o_size pc_age pc_exp pc_fe pc_wage_d ///
		pc_wage_d_lvl pc_wage_o_l1 pc_wage_o_l1_lvl rd_coworker_fe rd_coworker_n ///
		rd_coworker_wage_d_lvl rd_coworker_wage_o_lvl
	
	// keeping one observation per event
	egen unique = tag(event_id)
	keep if unique == 1
	drop unique
	
	// save temporary file
	save "${temp}/from_cowork_panel_m_`e'_`ym'", replace
	
	}
	}
	}
	
	// appending monthly files
	
	foreach e in spv dir emp {
		
	clear	
		
	forvalues ym=600/683 {
		
		cap append using "${temp}/from_cowork_panel_m_`e'_`ym'"
	
	}
	
	save "${temp}/from_cowork_panel_m_`e'", replace
	
	}

// variables from dest_panel_m
	
	foreach e in spv dir emp {
	forvalues ym=612/683 {      // FALTA RODAR PARA OS OUTROS PERIODOS! 600-611

	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear // THIS RESTRICTION MUST GO!!!
	
	if _N > 0 {

	use "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", clear
	
	sort event_id ym cpf
	gen ym_rel = ym - pc_ym
	
	// organizing variables we want to keep
	
		// d_avg_fe_worker
		
		gen d_avg_fe_worker_temp = fe_worker if ym_rel == 0
		egen d_avg_fe_worker = mean(d_avg_fe_worker), by(event_id)
		
		drop d_avg_fe_worker_temp
		
		// d_size
		
		gen d_size_temp = 1 if ym_rel == 0
		egen d_size = sum(d_size_temp), by(event_id)
	
		drop d_size_temp
		
	// keeping the variables we need
	keep event_id d_avg_fe_worker d_size
	
	// keeping one observation per event
	egen unique = tag(event_id)
	keep if unique == 1
	drop unique
	
	// save temporary file
	save "${temp}/from_dest_panel_m_`e'_`ym'", replace 	
		
	}
	}
	}
	
	// appending monthly files
	
	foreach e in spv dir emp {
		
	clear	
		
	forvalues ym=600/683 {
		
		cap append using "${temp}/from_dest_panel_m_`e'_`ym'"
	
	}
	
	save "${temp}/from_dest_panel_m_`e'", replace
	
	}
		
// variables from evt_panel_m

	foreach e in spv dir emp {
	
	use "${data}/evt_panel_m_`e'", clear
	
	// organizing variables we want to keep
	
		// d_growth -- NOTE::: LATER, LET'S USE THE PLANT SIZE DATA SET
			
		gen d_emp_l12_temp = d_emp if ym_rel == -12
		egen d_emp_l12 = max(d_emp_l12_temp), by(event_id)
		drop d_emp_l12_temp
			
		gen d_emp_l1_temp = d_emp if ym_rel == -1
		egen d_emp_l1 = max(d_emp_l1_temp), by(event_id)
		drop d_emp_l1_temp
			
		gen d_growth = d_emp_l1 / d_emp_l12 - 1
		
		// d_hire
		
		gen d_hire_temp = d_hire_t if ym_rel >= 0
		egen d_hire = sum(d_hire_temp), by(event_id)
		
		drop d_hire_temp
		
	// keeping the variables we need
	keep event_id d_growth d_hire
	
	// keeping one observation per event
	egen unique = tag(event_id)
	keep if unique == 1
	drop unique
	
	// save temporary file
	save "${temp}/from_evt_panel_m_`e'", replace 	
			
	}
	
// constructing the panel directly

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
	
