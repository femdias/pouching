// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2025

// Purpose: Define the main poached individual

*--------------------------*
* BUILD
*--------------------------*	

	use "${data}/202503_evt_m", clear
	
	drop if eventid == .
	
	// adding tenure information
	
	gen ym = pc_ym - 1
	rename pc_cpf cpf
	
	gen tenure = .
	
		// merging with RAIS to extract tenure information
		
		levelsof ym, local(yymm)
		
		foreach ym of local yymm {
			
			merge 1:1 cpf ym using "${data}/rais_m/rais_m`ym'", keep(master match) keepusing(tenure_months)
			replace tenure = tenure_months if _merge == 3
			drop tenure_months _merge
			
		}
						
	// rank events by their type
	gen rank = .
	replace rank = 1 if (pc_dir == 1 & pc_d_dir == 1)
	replace rank = 2 if (pc_dir == 1 & pc_d_spv == 1) | (pc_spv == 1 & pc_d_dir == 1)
	replace rank = 3 if (pc_dir == 1 & pc_d_emp == 1) | (pc_emp == 1 & pc_d_dir == 1)
	replace rank = 4 if (pc_spv == 1 & pc_d_spv == 1)
	replace rank = 5 if (pc_spv == 1 & pc_d_emp == 1) | (pc_emp == 1 & pc_d_spv == 1)
	replace rank = 6 if (pc_emp == 1 & pc_d_emp == 1)
	
	// min ranking poached individual in the event
	egen evt_rankmin = min(rank), by(eventid)
	gen pc_rankmin = (rank == evt_rankmin)
	
	// case 1: events with only 1 min ranked individual
	
		preserve
		
			// keep only the min ranked individuals
			keep if pc_rankmin == 1
	
			// identifying these events and keeping them only
			egen n_pc_rankmin = sum(pc_rankmin), by(eventid)
			keep if n_pc_rankmin == 1
			
			// this is the main poached individual
			gen main = 1
			
			// saving this list
			keep eventid cpf main
			save "${temp}/202503_mainpc_case1", replace
			
		restore
		
	// case 2: events with more than 1 min ranked individual 
	
		preserve
		
			// keep only the min ranked individuals
			keep if pc_rankmin == 1
		
			// identifying these events and keeping them only
			egen n_pc_rankmin = sum(pc_rankmin), by(eventid)
			keep if n_pc_rankmin > 1
			
			// max tenured individual among these
			egen evt_tenuremax = max(tenure), by(eventid)
			gen pc_tenuremax = (tenure == evt_tenuremax)
			
			// keep only the max tenure individuals
			keep if pc_tenuremax == 1
		
			// in case an event has more than 1 max tenure individual, I randomly select one of them
			sort eventid cpf
			duplicates drop eventid, force // this will keep only one of the max tenure indivuals if there is more than 1
			
			// this is the main poached individual
			gen main = 1
			
			// saving this list
			keep eventid cpf main
			save "${temp}/202503_mainpc_case2", replace
			
		restore
		
	// merging these lists of main poached individual with our main data set
	
		merge 1:1 eventid cpf using "${temp}/202503_mainpc_case1", nogen
		merge 1:1 eventid cpf using "${temp}/202503_mainpc_case2", nogen update
		
		replace main = 0 if main == .
		
		// do all events have one and only one main poached individual now?
		egen main_n = sum(main), by(eventid)
		tab main_n
	
	// organizing data set
	keep eventid cpf main rank tenure
	order eventid cpf main rank tenure
	
	// saving
	compress
	save "${data}/202503_mainpc", replace
	
*--------------------------*
* EXIT
*--------------------------*	

clear

rm "${temp}/202503_mainpc_case1.dta"
rm "${temp}/202503_mainpc_case2.dta"		
	
	
	
	
	
	
