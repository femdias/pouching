// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2025

// Purpose: Identifying the event type

*--------------------------*
* BUILD
*--------------------------*

	use "${data}/202503_evt_m", clear
	
	drop if eventid == . // TEMPORARY! THIS SHOULD BE DELETED DURING THE DATA CONSTRUCTION OF 202503_EVT_M
	
	rename pc_cpf cpf
	
	merge 1:1 eventid cpf using "${data}/202503_mainpc"
	drop _merge
	
	// IF NOT IN 202503_MAINPC, IT'S NOT MAIN BY CONSTRUCTION
	// NOT THAT THIS WILL BE FIXED ONCE I RERUN 202503_MAINPC
	replace main = 0 if main == .
	
		// making sure that there is only 1 main poached individual in each event
		egen n_main = sum(main), by(eventid)
		tab n_main
		
	// keep only the main individual
	keep if main == 1
	
	// keep only the variables we need to identify event types
	keep eventid pc_dir pc_spv pc_emp pc_d_dir pc_d_spv pc_d_emp
	
		// making sure that all events only have 1 classification in origin and destination
		
		gen origin = pc_dir + pc_spv + pc_emp
		tab origin
		
		gen destination = pc_d_dir + pc_d_spv + pc_d_emp
		tab destination
		
		drop origin destination
	
	// creating eventy type variable
	
		gen type = .
		replace type = 1 if pc_dir == 1 & pc_d_dir == 1
		replace type = 2 if pc_dir == 1 & pc_d_spv == 1
		replace type = 3 if pc_dir == 1 & pc_d_emp == 1
		replace type = 4 if pc_spv == 1 & pc_d_dir == 1
		replace type = 5 if pc_spv == 1 & pc_d_spv == 1
		replace type = 6 if pc_spv == 1 & pc_d_emp == 1
		replace type = 7 if pc_emp == 1 & pc_d_dir == 1
		replace type = 8 if pc_emp == 1 & pc_d_spv == 1
		replace type = 9 if pc_emp == 1 & pc_d_emp == 1
		
		label var type "Poaching event type"
		label define type_l 1 "dir-dir" 2 "dir-spv" 3 "dir-emp" 4 "spv-dir" 5 "spv-spv" 6 "spv-emp" 7 "emp-dir" 8 "emp-spv" 9 "emp-emp" 
		label values type type_l
		
	// saving
	keep eventid type
	compress
	save "${data}/202503_evttype", replace	
