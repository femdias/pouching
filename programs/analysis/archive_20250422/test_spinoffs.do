// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: February 2025

// Purpose: Hypothesis testing: Managers are the owners of the destination firm (spinoffs)

*--------------------------*
* SET UP
*--------------------------*

// 1. Check that the owner of the destination firm is NOT the manager that was poached

	// organizing information from "Poaching" project

	// events from the spv type
	
		use "${temp}/eventlist", clear
		keep if spv == 1 | spv == 2 // spv-spv and spv-emp
		drop spv
		duplicates drop event_id, force
		save "${temp}/eventlist_spv", replace
		
		use "${data}/evt_m_spv", clear
		merge 1:1 event_id using "${temp}/eventlist_spv"
		keep if _merge == 3
		keep pc_cpf d_plant
		isid pc_cpf d_plant
		save "${temp}/potentialowners_spv", replace
	
	// events from the emp type
	
		use "${temp}/eventlist", clear
		keep if spv == 3 // emp-spv
		drop spv
		duplicates drop event_id, force
		save "${temp}/eventlist_emp", replace
		
		use "${data}/evt_m_emp", clear
		merge 1:1 event_id using "${temp}/eventlist_emp"
		keep if _merge == 3
		keep pc_cpf d_plant
		isid pc_cpf d_plant
		save "${temp}/potentialowners_emp", replace
		
	// combining these events
	
		clear
		
		append using "${temp}/potentialowners_spv"
		append using "${temp}/potentialowners_emp"
		
		// organizing this in the format we need to merge with firm ownership information
		
		rename pc_cpf cpf
		tostring cpf, replace format(%011.0f)
		
		rename d_plant plant_id
		tostring plant_id, replace format(%014.0f)
		
		gen firm_id = substr(plant_id, 1, 8)
		drop plant_id
		
		save "${temp}/potentialowners", replace
	
	// organizing information from "Job Market Paper" project

	use "${Owners}/Owners_Firms_List", clear
	keep cpf firm_id
	merge 1:1 cpf firm_id using "${temp}/potentialowners"
	tab _merge // this is what we need for this analysis
	
// 2. Look at the tenure of the firms (i.e. all the destination firms have foundation dates that far precede the poaching date)

	// organizing information from "Poaching" project

	// events from the spv type
	
		use "${temp}/eventlist", clear
		keep if spv == 1 | spv == 2 // spv-spv and spv-emp
		drop spv
		duplicates drop event_id, force
		save "${temp}/eventlist_spv", replace
		
		use "${data}/evt_m_spv", clear
		merge 1:1 event_id using "${temp}/eventlist_spv"
		keep if _merge == 3
		keep pc_ym d_plant
		isid pc_ym d_plant
		save "${temp}/potentialdates_spv", replace
	
	// events from the emp type
	
		use "${temp}/eventlist", clear
		keep if spv == 3 // emp-spv
		drop spv
		duplicates drop event_id, force
		save "${temp}/eventlist_emp", replace
		
		use "${data}/evt_m_emp", clear
		merge 1:1 event_id using "${temp}/eventlist_emp"
		keep if _merge == 3
		keep pc_ym d_plant
		isid pc_ym d_plant
		save "${temp}/potentialdates_emp", replace
		
	// combining these events
	
						clear
						
						append using "${temp}/potentialdates_spv"
						append using "${temp}/potentialdates_emp"
						
						// organizing this in the format we need to merge with firm ownership information
						
						rename d_plant plant_id
						tostring plant_id, replace format(%014.0f)
						
						gen firm_id = substr(plant_id, 1, 8)
						drop plant_id
						
						save "${temp}/potentialdates", replace
						
	// organizing information from "Job Market Paper" project

	use "${Firms_Panel}/Firms_Panel_q200", clear // any month will do
	keep firm_id open_date
	isid firm_id
	merge 1:m firm_id using "${temp}/potentialdates"
	keep if _merge == 3
	tab _merge // this is what we need for this analysis
	
	// variable of interest is the gap between open date and poaching date
	gen y = year(open_date)
	gen m = month(open_date)
	gen open_ym = ym(y,m)
	format open_ym %tm
	
	// organizing and running the analys we want
	keep firm_id pc_ym open_ym
	sort firm_id pc_ym
	
		// distance
		gen distance = pc_ym - open_ym
		label var distance "Distance (in months): Poaching Date - Open Date"
		summ distance, detail
	
	
