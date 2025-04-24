// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2024

// Purpose: Constructing panel around the poaching events

*--------------------------*
* BUILD
*--------------------------*

// variables from rais_m

	// firms and months we are interested in
	
		// origin firms
		
		use "${data}/202503_evt_m", clear
		keep o_plant
		duplicates drop
		rename o_plant plant_id
		save "${temp}/202503_o_plant_list", replace
		
		// destination firms
		
		use "${data}/202503_evt_m", clear
		keep d_plant
		duplicates drop
		rename d_plant plant_id
		save "${temp}/202503_d_plant_list", replace
		
	clear
	append using "${temp}/202503_o_plant_list"
	append using "${temp}/202503_d_plant_list"
	duplicates drop
	save "${temp}/202503_plant_list", replace
	
	// looping over months and calculating variables of interest for these firms
	// our cohorts go from ym=600 through ym=683
	// data set goes from -12 through +12: ym=588 through ym=695

	forvalues ym=588/695 {
		
	use "${data}/rais_m/rais_m`ym'", clear
	
	// merging with list of firms of interest
	merge m:1 plant_id using "${temp}/202503_plant_list"
	keep if _merge == 3
	drop _merge
	
	// some variables we need for constructing the variables of interest
	
	gen hire_ym = ym(hire_year, hire_month)
	
	// organizing variables we want to keep
	
		// wkr
		
		gen wkr_temp = 1
		egen wkr = sum(wkr_temp), by(plant_id)
		
		drop wkr_temp
		
		// hire
		
		gen hire_temp = ((ym == hire_ym) & (hire_ym != .))
		egen hire = sum(hire_temp), by(plant_id)
		
		drop hire_temp
		
		// hire_dir
		
		gen hire_dir_temp = ((ym == hire_ym) & (hire_ym != .) & dir == 1)
		egen hire_dir = sum(hire_dir_temp), by(plant_id)
		
		drop hire_dir_temp
		
		// hire_spv
		
		gen hire_spv_temp = ((ym == hire_ym) & (hire_ym != .) & spv == 1)
		egen hire_spv = sum(hire_spv_temp), by(plant_id)
		
		drop hire_spv_temp
		
		// hire_emp
		
		gen hire_emp_temp = ((ym == hire_ym) & (hire_ym != .) & dir == 0 & spv == 0)
		egen hire_emp = sum(hire_emp_temp), by(plant_id)
		
		drop hire_emp_temp
		
	// keeping the variables we need
	keep plant_id ym wkr hire hire_dir hire_spv hire_emp
	
	// keeping one observation per firm
	egen unique = tag(plant_id ym)
	keep if unique == 1
	drop unique
	
	// save temporary file
	save "${temp}/from_rais_m_`ym'", replace
		
	}
	
// variables from cowork_panel_m

	// this part will be constructed separately for each cohort
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {

	use "${data}/202503_cowork_panel_m/202503_o_cw_`ym'", clear
	
	// organizing variables we want to keep
	
		// wkr_o
		
		gen wkr_o_temp = (plant_id == d_plant)
		egen wkr_o = sum(wkr_o_temp), by(eventid ym)
		
		drop wkr_o_temp
		
		// hire_o
		
		gen hire_o_temp = ((ym == hire_ym) & (hire_ym != .) & (plant_id == d_plant))
		egen hire_o = sum(hire_o_temp), by(eventid ym)
		
		drop hire_o_temp
		
		// hire_dir_o
		
		gen hire_dir_o_temp = ((ym == hire_ym) & (hire_ym != .) & dir == 1 & (plant_id == d_plant))
		egen hire_dir_o = sum(hire_dir_o_temp), by(eventid ym)
		
		drop hire_dir_o_temp
		
		// hire_spv_o
		
		gen hire_spv_o_temp = ((ym == hire_ym) & (hire_ym != .) & spv == 1 & (plant_id == d_plant))
		egen hire_spv_o = sum(hire_spv_o_temp), by(eventid ym)
		
		drop hire_spv_o_temp
		
		// hire_emp_o
		
		gen hire_emp_o_temp = ((ym == hire_ym) & (hire_ym != .) & dir == 0 & spv == 0 & (plant_id == d_plant))
		egen hire_emp_o = sum(hire_emp_o_temp), by(eventid ym)
		
		drop hire_emp_o_temp	
		
	// keeping the variables we need
	keep eventid ym wkr_o hire_o hire_dir_o hire_spv_o hire_emp_o
	
	// keeping one observation per event per month
	egen unique = tag(eventid ym)
	keep if unique == 1
	drop unique
	
	// save temporary file
	save "${temp}/from_cowork_panel_m_`ym'", replace
	
	}	

// create an empty panel around the t=0 (when poaching takes place)
	
	use "${data}/202503_evt_m", clear
	
	// panel is expanded around the eventid
	// note: 202503_evt_m is NOT at the event level. instead, it's at the poached individual level
	egen unique = tag(eventid)
	keep if unique == 1
	drop unique
	
	// drop pc_cpf because events can have more than 1 poached individual
	drop pc_cpf
	
	// creating the empty panel
	
	expand 25 // 12 months before, t=0, 12 months after
	sort eventid
		
	by eventid: gen ym= pc_ym - 13 + _n	
	format ym %tm	
	gen ym_rel = ym - pc_ym
	
	// organizing
	order eventid ym_rel ym
	sort eventid ym
	
	// saving
	compress
	save "${data}/202503_evt_panel_m", replace
	
// merging information with the empty panel
		
	use "${data}/202503_evt_panel_m", clear
		
	// merging into the main data set: information from rais_m --> origin plant
	
	rename o_plant plant_id
	
	levelsof ym, local(months)
	
	foreach ym of local months {
	
		merge m:1 plant_id ym using "${temp}/from_rais_m_`ym'", update
		drop if _merge == 2
		drop _merge
	
	}
	
	rename plant_id o_plant
	
		// renaming variables to indicate that these are origin variables
		rename wkr 	o_wkr
		rename hire 	o_hire
		rename hire_dir o_hire_dir
		rename hire_spv o_hire_spv
		rename hire_emp o_hire_emp
		
	// merging into the main data set: information from rais_m --> destination plant
	
	rename d_plant plant_id
	
	levelsof ym, local(months)
	
	foreach ym of local months {
	
		merge m:1 plant_id ym using "${temp}/from_rais_m_`ym'", update
		drop if _merge == 2
		drop _merge
	
	}
	
	rename plant_id d_plant
	
		// renaming variables to indicate that these are destination variables
		rename wkr 	d_wkr
		rename hire 	d_hire
		rename hire_dir d_hire_dir
		rename hire_spv d_hire_spv
		rename hire_emp d_hire_emp
	
	// merging into the main data set: information from cowork_panel_m 
	
	levelsof pc_ym, local(cohorts)
	
	foreach ym of local cohorts {
	
		merge 1:1 eventid ym using "${temp}/from_cowork_panel_m_`ym'", update
		drop _merge
	
	}
	
		// renaming variables to indicate that these are destination variables
		rename wkr_o 		d_wkr_o
		rename hire_o 		d_hire_o
		rename hire_dir_o 	d_hire_dir_o
		rename hire_spv_o 	d_hire_spv_o
		rename hire_emp_o 	d_hire_emp_o
	
	// organizing and saving
	order eventid ym_rel ym
	sort eventid ym
	
	// saving
	compress
	save "${data}/202503_evt_panel_m.dta", replace
			
// continue to build the data set

	use "${data}/202503_evt_panel_m.dta", clear
	
	// merging with event type information
	merge m:1 eventid using "${data}/202503_evttype", nogen
	
	// saving
	save "${data}/202503_evt_panel_m", replace

*--------------------------*
* EXIT
*--------------------------*

/*

clear

rm "${temp}/202503_o_plant_list.dta"
rm "${temp}/202503_d_plant_list.dta"
rm "${temp}/202503_plant_list.dta"

forvalues ym=588/695 {
	
	rm "${temp}/from_rais_m_`ym'.dta"
	
}

foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
	
	rm "${temp}/from_cowork_panel_m_`ym'.dta"
	
}








