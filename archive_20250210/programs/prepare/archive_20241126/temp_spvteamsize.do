// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: July 2024

// Purpose: Identifying supervisors teams

*--------------------------*
* BUILD
*--------------------------*

forvalues ym=528/575 { // looping through cohorts  

	use "output/data/cowork_panel_m_spv_`ym'", clear
	
	if _N >= 1 {

		// identify occupation group of the poached supervisor

			gen occup_pc = occup_cbo2002 if pc_individual == 1 & ym_rel == -1
			
			gen occup_pc_2d = substr(occup_pc, 1, 2)
			
			destring occup_pc_2d, force replace
							// note: there might be more than 1 poached supervisors
				// if they are not in the same team, this will be complicated
				// i will drop these events for this analysis
				
				egen unique = tag(occup_pc_2d event_id)
				egen n_unique = sum(unique), by(event_id)
				
				preserve
				
					keep if n_unique > 1
					
					if _N > 1 {
					
					keep event_id
					duplicates drop
					
					save "temp/list_morethan1spv_`ym'", replace
					
					}
				
				restore	
							
				drop if n_unique != 1
				
			egen occup_pc_2d_max = max(occup_pc_2d), by(event_id)
			replace occup_pc_2d = occup_pc_2d_max
			drop occup_pc_2d_max
	
		// identify occupation group of the coworkers

			gen occup_cw = occup_cbo2002 if pc_individual == 0 & ym_rel == -12
			
			gen occup_cw_2d = substr(occup_cw, 1, 2)
			
			destring occup_cw_2d, force replace
			
			egen occup_cw_2d_max = max(occup_cw_2d), by(event_id cpf)
			replace occup_cw_2d = occup_cw_2d_max
			drop occup_cw_2d_max
		
		// identify coworkers from the same team

			gen team = (occup_pc_2d == occup_cw_2d)
			gen notteam = (team == 0)
			
	// creating plant-level variables

		// set hiring date
		g hire_ym = ym(hire_year, hire_month) 
			
		// hire = 1 if hired in the month and type was 'readmissao' AND MOVING TO DESTINATION PLANT
		g d_hire_t_o = ((ym == hire_ym) & (hire_ym != .) & (type_of_hire == 2)) & plant_id == d_plant

		// variables for hires FROM ORIGIN PLANT & IN TEAM/NOT IN TEAM

		g d_h_o_team = 1 if d_hire_t_o == 1 & pc_individual == 0 & team == 1
		g d_h_o_notteam = 1 if d_hire_t_o == 1 & pc_individual == 0 & team == 0
		
	// collapsing at the plant-month level
	
	collapse (sum) d_h_o_team d_h_o_notteam team notteam, by(event_id d_plant ym)

	order event_id d_plant ym
	sort event_id d_plant ym
	
	// label variables
		
	label var d_h_o_team 		"From orig. plant: Hired workers from supervisor team"
	label var d_h_o_notteam		"From orig. plant: Hired workers NOT from supervisor team"
		
	save "temp/spvteam_`ym'", replace
		
	}	
} 
	
// combining all cohorts

	// firm-level variables
	
	clear
	
	forvalues ym=528/575 {
		
		cap append using "temp/spvteam_`ym'"
		cap rm "temp/spvteam_`ym'.dta"
		
	}
	
	save "temp/spvteam", replace
	
	// list of events we are excluding from the analysis
	
	clear
	
	forvalues ym=528/575 {
		
		cap append using "temp/list_morethan1spv_`ym'"
		cap rm "temp/list_morethan1spv_`ym'.dta" 
		
	}
	
	save "temp/list_morethan1spv", replace
	
