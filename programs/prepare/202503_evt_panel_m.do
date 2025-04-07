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
	save "${temp}/2025_plant_list", replace
	
	// looping over months and calculating variables of interest for these firms
	// our cohorts go from ym=600 through ym=683
	// data set goes from -12 through +12: ym=588 through ym=695

	forvalues ym=588/695 {
		
	use "${data}/rais_m/rais_m`ym'", clear
	
	// merging with list of firms of interest
	merge m:1 plant_id using "${temp}/2025_plant_list"
	keep if _merge == 3
	drop _merge
	
	// some variables we need for constructing the variables of interest
	
	gen hire_ym = ym(hire_year, hire_month)
	
	// organizing variables we want to keep
	
		// emp
		
		gen emp_temp = 1
		egen emp = sum(emp_temp), by(plant_id)
		
		drop emp_temp
		
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
	keep plant_id ym emp hire hire_dir hire_spv hire_emp
	
	// keeping one observation per firm
	egen unique = tag(plant_id ym)
	keep if unique == 1
	drop unique
	
	// save temporary file
	save "${temp}/from_rais_m_`ym'", replace
		
	}	
	
// variables from cowork_panel_m	
				
	//// PENDING: I FIRST NEED TO ORGANIZE COWORK_PANEL_M
	
	
	
/*

// I. create an empty panel around the t=0 (when poaching takes place)
	
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
	
	// saving
	compress
	save "${data}/202503_evt_panel_m", replace
	
	/*
	
// second: plant-month variables for the destination plant

	// example: how many workers the d_plant is hiring each month 
	
	// listing plants and months i'm interested in
	
		use "${data}/evt_panel_m_`e'", clear	
			
		keep d_plant ym
		egen unique = tag(d_plant ym)
		keep if unique == 1
		drop unique
			
		save "${temp}/d_firmlist_m", replace
	
	// using the complete RAIS panel, calcule the variables we need for the plants and months we're interested in
	
	// looping through the months of interest
	forvalues ym=516/695 {
		
		use "${data}/rais_m/rais_m`ym'", clear
	
		// keeping only the plants that poached workers in a period -- d_plant
		rename plant_id d_plant
		merge m:1 d_plant ym using "${temp}/d_firmlist_m", keep(match)  

	if _N >= 1 {	
		
	// creating the plant-level variables

		// variable full-time contracts
		g d_emp_ft = emp if num_hours>=35
		
		// all contracts: existing variable -- just renaming it
		rename emp d_emp
		
		// employment
		g d_emp_dir = (dir == 1)
		g d_emp_dir5 = (dir5 == 1)
		g d_emp_spv = (spv == 1)
		g d_emp_emp = (dir == 0 & spv == 0)
		
			// set hiring date
			g hire_ym = ym(hire_year, hire_month) 
		
			// hire = 1 if they were hired in the month and type was 'readmissao'
			g d_hire_t = ((ym == hire_ym) & (hire_ym != .) & (type_of_hire == 2))
		
		// variables for hires
		g d_h_wages = earn_avg_month_nom if d_hire_t==1
		g d_h_tenure = tenure_months if d_hire_t==1
		g d_h_dir = 1 if d_hire_t==1 & dir==1
		g d_h_dir5 = 1 if d_hire_t==1 & dir5==1
		g d_h_spv = 1 if d_hire_t==1 & spv==1
		g d_h_emp = 1 if d_hire_t==1 & dir==0 & spv==0
	
		// variables for retained workers
		g d_r_wages = earn_avg_month_nom if d_hire_t==0
		g d_r_tenure = tenure_months if d_hire_t==0
		g d_r_dir = 1 if d_hire_t==0 & dir==1
		g d_r_dir5 = 1 if d_hire_t==0 & dir5==1
		g d_r_spv = 1 if d_hire_t==0 & spv==1
		g d_r_emp = 1 if d_hire_t==0 & dir==0 & spv==0
		
		// collapsing at the plant-month level
		
		collapse (sum) d_emp_ft d_emp d_emp_dir d_emp_dir5 d_emp_spv d_emp_emp ///
			d_hire_t d_h_dir d_h_dir5 d_h_spv d_h_emp ///
			d_r_dir d_r_dir5 d_r_spv d_r_emp ///
			(mean) d_h_wages d_h_tenure d_r_wages d_r_tenure , by(d_plant ym)
		
		order d_plant ym
		sort d_plant ym
		
		// label variables
		
		label var d_emp_ft     	"Employment (total, FT) in destination plant"
		label var d_emp	       	"Employment (total) in destination plant"
		label var d_emp_dir	"Employment (director) in destination plant"
		label var d_emp_dir5	"Employment (director + 5%) in destination plant"
		label var d_emp_spv	"Employment (supervisor) in destination plant"
		label var d_emp_emp	"Employment (employeed) in destination plant"
		label var d_hire_t	"Hired workers (total) in destination plant"	
		label var d_h_dir	"Hired workers (director) in destination plant"
		label var d_h_dir5	"Hired workers (director + 5%) in destination plant"
		label var d_h_spv 	"Hired workers (supervisor) in destination plant"
		label var d_h_emp	"Hired workers (employee) in destination plant"
		label var d_r_dir	"Retained workers (director) in destination plant"
		label var d_r_dir5	"Retained workers (director + 5%) in destination plant"
		label var d_r_spv	"Retained workers (supervisor) in destination plant"
		label var d_r_emp 	"Retained workers (employee) in destination plant" 
		label var d_h_wages	"Wages (hired workers) in destination plant"
		label var d_h_tenure    "Tenure (hired workers) in destination plant"
		label var d_r_wages     "Wages (retained workers) in destination plant"
		label var d_r_tenure	"Tenure (retained workers) in destination plant"	
		
		// saving
		
		save "${temp}/d_firmvars_m_`ym'", replace
	
	} // closing the "if _N >= 1"
	} // closing the loop through months 
	
	clear
	
	forvalues ym=516/695 {
			
		cap append using "${temp}/d_firmvars_m_`ym'"	
			
	} 
	
	sort d_plant ym
	
	save "${temp}/d_firmvars_m", replace
	
// third: plant-month variables in the destination plant FROM ORIGIN PLAN
	
	forvalues ym=528/683 { // looping through the COHORTS
	
	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
	
	if _N >= 1 {

	// creating plant-level variables
	
		gen emp = 1 if plant_id != .	
	
		// variable full-time contracts FROM ORIGIN PLANT
		g d_emp_ft_o = emp if num_hours>=35 & plant_id == d_plant
		
		// all contracts FROM ORIGIN PLANT: 
		g  d_emp_o = emp if plant_id == d_plant
	
		// employment from ORIGIN PLANT
		g d_emp_dir_o = (plant_id == d_plant & dir == 1)
		g d_emp_dir5_o = (plant_id == d_plant & dir5 == 1)
		g d_emp_spv_o = (plant_id == d_plant & spv == 1)
		g d_emp_emp_o = (plant_id == d_plant & dir == 0 & spv == 0)

			// set hiring date
			*g hire_ym = ym(hire_year, hire_month) 
			
			// hire = 1 if hired in the month and type was 'readmissao' AND MOVING TO DESTINATION PLANT
			g d_hire_t_o = ((ym == hire_ym) & (hire_ym != .) & (type_of_hire == 2)) & plant_id == d_plant

		// variables for hires FROM ORIGIN PLANT
		g d_h_wages_o = earn_avg_month_nom if d_hire_t_o==1
		g d_h_tenure_o = tenure_months if d_hire_t_o==1
		g d_h_dir_o = 1 if d_hire_t_o==1 & dir==1
		g d_h_dir5_o = 1 if d_hire_t_o==1 & dir5==1
		g d_h_spv_o = 1 if d_hire_t_o==1 & spv==1
		g d_h_emp_o = 1 if d_hire_t_o==1 & dir==0 & spv==0
		
		// collapsing at the plant-month level
		
		collapse (sum) d_emp_ft_o d_emp_o d_emp_dir_o d_emp_dir5_o d_emp_spv_o d_emp_emp_o ///	
			d_hire_t_o d_h_dir_o d_h_dir5_o d_h_spv_o d_h_emp_o ///
			(mean) d_h_wages_o d_h_tenure_o, by(ev d_plant ym)

		order ev d_plant ym
		sort ev d_plant ym
	
		// label variables
		
		label var d_emp_ft_o     	"From orig. plant: Employment (total, FT) in destination plant"
		label var d_emp_o	       	"From orig. plant: Employment (total) in destination plant"
		label var d_emp_dir_o		"From orig. plant: Employment (director) in destination plant"
		label var d_emp_dir5_o		"From orig. plant: Employment (director + 5%) in destination plant"
		label var d_emp_spv_o		"From orig. plant: Employment (supervisor) in destination plant"
		label var d_emp_emp_o		"From orig. plant: Employment (employee) in destination plant"
		label var d_hire_t_o		"From orig. plant: Hired workers (total) in destination plant"	
		label var d_h_dir_o		"From orig. plant: Hired workers (director) in destination plant"
		label var d_h_dir5_o		"From orig. plant: Hired workers (director + 5%) in destination plant"
		label var d_h_spv_o 		"From orig. plant: Hired workers (supervisor) in destination plant"
		label var d_h_emp_o		"From orig. plant: Hired workers (employee) in destination plant"
		label var d_h_wages_o		"From orig. plant: Wages (hired workers) in destination plant"
		label var d_h_tenure_o    	"From orig. plant: Tenure (hired workers) in destination plant"
	
		save "${temp}/d_evtvars_m_`ym'", replace
		
	}	
	}
	
	clear
	
	forvalues ym=528/683 {
		
		cap append using "${temp}/d_evtvars_m_`ym'"
		
	}
	
	save "${temp}/d_evtvars_m", replace
		
	// fourth: similar to third, but just for the poached individuals
	
	forvalues ym=528/683 {
	
	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
	
	if _N >= 1 {
		
	// keeping just the poached individuals
	
	keep if pc_individual == 1
	
	// creating plant-level variables
	
		gen emp = 1 if plant_id != .
	
		// variable full-time contracts FROM ORIGIN PLANT
		g d_emp_ft_o_pc = emp if num_hours>=35 & plant_id == d_plant
		
		// all contracts FROM ORIGIN PLANT: 
		g  d_emp_o_pc = emp if plant_id == d_plant
	
		// employment from ORIGIN PLANT
		g d_emp_dir_o_pc = (plant_id == d_plant & dir == 1)
		g d_emp_dir5_o_pc = (plant_id == d_plant & dir5 == 1)
		g d_emp_spv_o_pc = (plant_id == d_plant & spv == 1)
		g d_emp_emp_o_pc = (plant_id == d_plant & dir == 0 & spv == 0)

			// set hiring date
			*g hire_ym = ym(hire_year, hire_month) 
			
			// hire = 1 if hired in the quarter and type was 'readmissao' AND MOVING TO DESTINATION PLANT
			g d_hire_t_o_pc = ((ym == hire_ym) & (hire_ym != .) & (type_of_hire == 2)) & plant_id == d_plant

		// variables for hires FROM ORIGIN PLANT
		g d_h_wages_o_pc = earn_avg_month_nom if d_hire_t_o_pc==1
		g d_h_tenure_o_pc = tenure_months if d_hire_t_o_pc==1
		g d_h_dir_o_pc = 1 if d_hire_t_o_pc==1 & dir==1
		g d_h_dir5_o_pc = 1 if d_hire_t_o_pc==1 & dir5==1
		g d_h_spv_o_pc = 1 if d_hire_t_o_pc==1 & spv==1
		g d_h_emp_o_pc = 1 if d_hire_t_o_pc==1 & dir==0 & spv==0
		
		// collapsing at the plant-month level
		
		collapse (sum) d_emp_ft_o_pc d_emp_o_pc d_emp_dir_o_pc d_emp_dir5_o_pc d_emp_spv_o_pc d_emp_emp_o_pc ///	
			d_hire_t_o_pc d_h_dir_o_pc d_h_dir5_o_pc d_h_spv_o_pc d_h_emp_o_pc ///
			(mean) d_h_wages_o_pc d_h_tenure_o_pc, by(ev d_plant ym)

		order ev d_plant ym
		sort ev d_plant ym
	
		// label variables
		
		label var d_emp_ft_o_pc     	"Poched from orig. plant: Employment (total, FT) in destination plant"
		label var d_emp_o_pc	       	"Poched from orig. plant: Employment (total) in destination plant"
		label var d_emp_dir_o_pc	"Poched from orig. plant: Employment (director) in destination plant"
		label var d_emp_dir5_o_pc	"Poched from orig. plant: Employment (director + 5%) in destination plant"
		label var d_emp_spv_o_pc	"Poched from orig. plant: Employment (supervisor) in destination plant"
		label var d_emp_emp_o_pc	"Poched from orig. plant: Employment (employee) in destination plant"
		label var d_hire_t_o_pc		"Poched from orig. plant: Hired workers (total) in destination plant"	
		label var d_h_dir_o_pc		"Poched from orig. plant: Hired workers (director) in destination plant"
		label var d_h_dir5_o_pc		"Poched from orig. plant: Hired workers (director + 5%) in destination plant"
		label var d_h_spv_o_pc 		"Poched from orig. plant: Hired workers (supervisor) in destination plant"
		label var d_h_emp_o_pc		"Poched from orig. plant: Hired workers (employee) in destination plant"
		label var d_h_wages_o_pc	"Poched from orig. plant: Wages (hired workers) in destination plant"
		label var d_h_tenure_o_pc   	"Poched from orig. plant: Tenure (hired workers) in destination plant"
	
		save "${temp}/d_evtvars_m_pc_`ym'", replace
		
	} // closing the first "if _N >= 1"
		
	} // closing the loop through cohorts
	
	clear
	
	forvalues ym = 528/683 {
		
		cap append using "${temp}/d_evtvars_m_pc_`ym'"
		
	}
	
	save "${temp}/d_evtvars_m_pc", replace
	
// fourth: merging everything with the main data set
		
	use "${data}/evt_panel_m_`e'", clear
		
	// merging into the main data set: firm vars
	merge m:1 d_plant ym using "${temp}/d_firmvars_m", nogen keep(master match)
		
	// merging into the main data set: evt vars
	merge 1:1 ev d_plant ym using "${temp}/d_evtvars_m", nogen
	
	// merging into the main data set: evt vars (only with the poached individuals)
	merge 1:1 ev d_plant ym using "${temp}/d_evtvars_m_pc", nogen
		
	// organizing and saving
		
	tsset event_id ym_rel
	sort event_id ym_rel
	
	// saving
	save "${data}/evt_panel_m_`e'.dta", replace
			
}


	*/

	// THIS IS WHERE I WILL COMBINE ALL THEREE IN ONE SINGLE PANEL
	
	
	// adding sample restrinction and event types

	foreach e in dir spv emp {
	
		use "${data}/evt_panel_m_`e'", clear
		
		// keep only events with positive employment in all months
		merge m:1 event_id using "${data}/sample_selection_`e'", keep(match) nogen
		
		// identify event types using origin occupation
		
		gen o_pc_dir = 0
		gen o_pc_spv = 0
		gen o_pc_emp = 0
		
		label var o_pc_dir "Poached individual is a director at origin firm"
		label var o_pc_spv "Poached individual is a supervisor at origin firm"
		label var o_pc_emp "Poached individual is a worker at origin firm"
		
		replace o_pc_`e' = 1 // in looping over `e', origin type must be `e'
		
		// identifying event types using destination occupation --- I'M DROPPING EVENTS WITH MULTIPLE TYPES. REVIEW THIS.
		
		merge m:1 event_id using "${data}/evt_type_m_`e'", keep(match) nogen
		
		// saving
		save "${temp}/202503_evt_panel_m_`e'", replace
	
}

	// combining the three previous data set
 
	use "${temp}/202503_evt_panel_m_dir", clear
	append using "${temp}/202503_evt_panel_m_spv" 
	append using "${temp}/202503_evt_panel_m_emp"
	
	// event type variable
	
	gen type = .
	replace type = 1 if o_pc_spv == 1 & d_pc_spv == 1
	replace type = 2 if o_pc_spv == 1 & d_pc_emp == 1
	replace type = 3 if o_pc_emp == 1 & d_pc_spv == 1
	replace type = 4 if o_pc_emp == 1 & d_pc_emp == 1
	
	la def type 1 "spv-spv" 2 "spv-emp" 3 "emp-spv" 4 "emp-emp", replace
	la val type type

	// saving
	save "${data}/202503_evt_panel_m", replace





*--------------------------*
* EXIT
*--------------------------*

cap rm "${temp}/d_firmlist_m.dta"
cap rm "${temp}/d_firmvars_m.dta"
cap rm "${temp}/d_evtvars_m.dta"
cap rm "${temp}/d_evtvars_m_pc.dta"

forvalues ym=516/695{
	
	cap rm "${temp}/d_firmvars_m_`ym'.dta"
	cap rm "${temp}/d_evtvars_m_`ym'.dta"
	cap rm "${temp}/d_evtvars_m_pc_`ym'.dta"
	
}

clear








