// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Create data set with poached individuals only

*--------------------------*
* BUILD
*--------------------------*

/*
// AUXILIARY DATA SETS

	// information about raided coworkers
	
	foreach e in spv emp dir { // dir5 
	forvalues ym=528/683 {	
	
		use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
		
		if _N >= 1 {
	
			// identifying raided coworkers
			sort event_id cpf ym_rel
			by event_id cpf: gen rd_coworker = (pc_individual == 0) & (ym_rel>=0) & (plant_id[_n-1] != d_plant) & (plant_id == d_plant)
			
			// number of raided coworkers
			egen rd_coworker_n = sum(rd_coworker), by(event_id)
			
			// wage of raided coworkers in destination firm
			gen rd_coworker_wage_d = wage_real_ln if rd_coworker == 1
			
			// wage of raided coworkers in origin firm
			egen rd_coworker_max = max(rd_coworker), by(cpf event_id)
			gen rd_coworker_wage_o_l12 = wage_real_ln if ym_rel == -12 & rd_coworker_max == 1
			egen rd_coworker_wage_o = max(rd_coworker_wage_o_l12), by(cpf event_id)
			
			// quality of raided coworkers
			gen rd_coworker_fe = fe_worker if rd_coworker == 1
			
			// keeping relevant obs and collapsing to event level
			
			keep if rd_coworker == 1
			
			if _N >= 1 { // there might not be any raided coworkers
			
				collapse (mean) rd_coworker_n rd_coworker_wage_d rd_coworker_wage_o rd_coworker_fe, by(event_id)
		
				// saving temp file
				save "${temp}/rd_coworker_`e'_`ym'", replace
		
			}
		}
	}
	}
		
	// destination firm -- firm size and wage bill
	
	foreach e in spv dir emp { // dir5 
		
		// listing events in t=0

		use "${data}/evt_m_`e'", clear
		
		egen unique = tag(d_plant pc_ym)
		keep if unique == 1
		keep event_id d_plant pc_ym
		
		save "${temp}/events_t0", replace	
		
		// look for destination firms in t=0 and calculate the firm size and wage bill
		
		forvalues ym=528/683 {

			// in RAIS, keeping what we need for this data set	

			use "${data}/rais_m/rais_m`ym'", clear
	
			// keeping t=0 (ym == pc_ym) for the destination plants
			rename ym pc_ym
			rename plant_id d_plant
			merge m:1 d_plant pc_ym using "${temp}/events_t0", keep(match)
			
			if _N >= 1 {
			
				drop _merge
		
				// organizing
				order event_id d_plant pc_ym
				sort event_id cpf
		
				// adjusting wages
			
				merge m:1 year using "${input}/auxiliary/ipca_brazil"
				generate index_2017 = index if year == 2017
				egen index_base = max(index_2017)
				generate adj_index = index / index_base		
				generate wage_real = earn_avg_month_nom / adj_index
				
					// in logs
					gen wage_real_ln = ln(wage_real)
				
				drop if _merge == 2
				drop _merge
				sort event_id cpf
			
				// collapsing
				
				gen count = 1
				collapse (sum) d_size=count (mean) d_wage_real=wage_real d_wage_real_ln=wage_real_ln, by(event_id)	
				
				// saving
				save "${temp}/d_vars_`e'_`ym'", replace
			
			}			
		}
	}
	
	// information about team size -- spv only
	
	foreach e in spv {
	forvalues ym=528/683 {	
	
		use "${data}/cowork_panel_m_spv/cowork_panel_m_spv_`ym'", clear
	
		if _N >= 1 {

			// identify occupation group of the poached supervisor

				gen occup_pc = occup_cbo2002 if pc_individual == 1 & ym_rel == -1
				
				gen occup_pc_2d = substr(occup_pc, 1, 2)
				
				destring occup_pc_2d, force replace
				
				// note: there might be more than 1 poached supervisors
				// if they are not in the same team, this will be complicated
				// i will not compute team size in this case
					
				egen unique = tag(occup_pc_2d event_id)
				egen n_unique = sum(unique), by(event_id)
				replace occup_pc_2d = . if n_unique != 1
				
				// expanding 2-digit occupation of the supervisor for the entire event (including t=-12)
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
			
			// identify coworkers from the same team as the poached supervisors

				gen team_cw = (occup_pc_2d == occup_cw_2d) & spv == 0 & dir == 0 & ym_rel == -12
				
			// identify coworkers who are also supervisors from the same team as the poached supervisors

				gen team_spv = (occup_pc_2d == occup_cw_2d) & spv == 1 & dir == 0 & ym_rel == -12	
			
			// keep only t=-12
			keep if ym_rel == -12
	
			// collapsing at the event level
			collapse (sum) team_cw team_spv, by(event_id)

			// saving
			save "${temp}/spvteam_`e'_`ym'", replace
		
		}
	}
	}
	
	// destination firm variables
	
		foreach e in spv dir emp { // dir5 
		
		use "${data}/evt_panel_m_`e'", clear
		*use "${data}/evt_panel_m_spv", clear
		
			// destination firm growth
			
			gen d_emp_l12_temp = d_emp if ym_rel == -12
			egen d_emp_l12 = max(d_emp_l12_temp), by(event_id)
			drop d_emp_l12_temp
			
			gen d_emp_l1_temp = d_emp if ym_rel == -1
			egen d_emp_l1 = max(d_emp_l1_temp), by(event_id)
			drop d_emp_l1_temp
			
			gen d_growth = d_emp_l1 / d_emp_l12 - 1
			
			// keep 1 obs for each event_id
			
			egen unique = tag(event_id)
			keep if unique == 1
			keep event_id d_growth
			
		// saving
		* This should be 
		*save "${temp}/d_growth_`e'", replace
		save "${data}/d_growth_`e'", replace
		
		}
		
// MAIN DATA SET

*/

// COMECAR A RODAR AQUI
// ATENÇÃO: ESTOU RODANDO TUDO A PARTIR DO 612

// NEW HIRES
foreach e in dir emp { // dir5 spv
		
		use "${data}/evt_panel_m_`e'", clear
		
			/*
			// destination firm new hires
			
			gen d_hire_l12_temp = d_hire_t if ym_rel == -12
			egen d_hire_l12 = max(d_hire_l12_temp), by(event_id)
			drop d_hire_l12_temp
			*/
			
			egen d_hire_temp = sum(d_hire_t) if ym_rel >= 0
			egen d_hire = max(d_hire_temp), by(event_id)
			
			
			// keep 1 obs for each event_id
			
			egen unique = tag(event_id)
			keep if unique == 1
			*keep event_id d_hire_l12 // OLD VERSION
			KEE
			
			
		// saving
		* This should be 
		*save "${data}/d_growth_`e'", replace
		save "${temp}/size_hire_`e'", replace
}
		

// Adding current workers in the same occupational code as the poached manager in DESTINATION firm_id
// Should the code change apart from dataset used?
// Checar essa parte do código
foreach e in dir emp { // dir5 spv
    forvalues ym=600/683 { // 683
	
	
        // Define the file path -- ESSE CARA COMEÇA EM 613 NÃO SEI PORQUE, POR ISSO A CONDICAO PARA ACHAR O ARQUIVO
        local filepath "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'.dta"

        // Check if the file exists before using it
        if (fileexists("`filepath'")) {
		
            use "`filepath'", clear
	    
		merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
		* keep only people that became spv
		keep if type_spv == 1
		
		gen ym_rel = ym - pc_ym
			
			// identify occupation group of the poached supervisor

				gen occup_pc = occup_cbo2002 if pc_individual == 1 & ym_rel == -1
				
				gen occup_pc_2d = substr(occup_pc, 1, 2)
				
				destring occup_pc_2d, force replace
				
				// note: there might be more than 1 poached supervisors
				// if they are not in the same team, this will be complicated
				// i will not compute team size in this case
					
				egen unique = tag(occup_pc_2d event_id)
				egen n_unique = sum(unique), by(event_id)
				replace occup_pc_2d = . if n_unique != 1
				
				// expanding 2-digit occupation of the supervisor for the entire event (including t=-12)
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
			
			// identify coworkers from the same team as the poached supervisors

				gen team_cw = (occup_pc_2d == occup_cw_2d) & spv == 0 & dir == 0 & ym_rel == -12
				
			// identify coworkers who are also supervisors from the same team as the poached supervisors

				gen team_spv = (occup_pc_2d == occup_cw_2d) & spv == 1 & dir == 0 & ym_rel == -12	
			
			// keep only t=-12
			keep if ym_rel == -12
	
			// collapsing at the event level
			collapse (sum) team_cw team_spv, by(event_id)
			rename team_cw d_team_cw
			rename team_spv d_team_spv
			
			// saving
			save "${temp}/d_spvteam_`e'_`ym'", replace
		} 
		else {
            di "File `filepath' not found."
        }
    }
}


foreach e in emp dir { // dir5 spv
    forvalues ym=600/683 { // 683
	
	
        // Define the file path -- ESSE CARA COMEÇA EM 613 NÃO SEI PORQUE, POR ISSO A CONDICAO PARA ACHAR O ARQUIVO
        local filepath "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'.dta"

        // Check if the file exists before using it
        if (fileexists("`filepath'")) {
		
            use "`filepath'", clear
	    
		merge m:1 event_id using "${data}/evt_type_m_`e'", keep(match) nogen
		
		gen ym_rel = ym - pc_ym
			
			// identify occupation group of the poached supervisor

				gen occup_pc = occup_cbo2002 if ym_rel == -1
				gen occup_pc_2d = substr(occup_pc, 1, 2)
				
				egen unique = tag(occup_pc_2d event_id)
				egen n_unique = sum(unique), by(event_id)
				replace occup_pc_2d = . if n_unique != 1
				
				// expanding 2-digit occupation of the supervisor for the entire event (including t=-12)
				egen occup_pc_2d_max = max(occup_pc_2d), by(event_id)
				replace occup_pc_2d = occup_pc_2d_max
				drop occup_pc_2d_max
				
			// identify coworkers who are also supervisors from the same team as the poached supervisors

				gen team_spv = (occup_pc_2d == occup_cw_2d) & spv == 1 & dir == 0 & ym_rel == -12	
			
			// keep only t=-12
			keep if ym_rel == -12
	
			// collapsing at the event level
			collapse (sum) team_cw team_spv, by(event_id)
			rename team_cw d_team_cw
			rename team_spv d_team_spv
			
			// saving
			save "${temp}/d_spvteam_`e'_`ym'", replace
		} 
		else {
            di "File `filepath' not found."
        }
    }
}



// Adding turnover
foreach e in dir emp { // dir5 spv
    forvalues ym=600/683 { // 683

        // Define the file path -- ESSE CARA COMEÇA EM 613 NÃO SEI PORQUE, POR ISSO A CONDICAO PARA ACHAR O ARQUIVO
        local filepath "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'.dta"

        // Check if the file exists before using it
        if (fileexists("`filepath'")) {
		
            use "`filepath'", clear
	    
	    
            // Your code for processing the file goes here
			
			gen ym_rel = ym - pc_ym
			
			sort event_id cpf ym_rel
				
			order cpf ym_rel
			
			// pessoas na empresa (média entre t=-12 e t=-1)
			
				// calcula pessoas em t=-12
			
					egen emp_L12_temp = count(cpf) if ym_rel == -12, by(event_id)
					egen emp_L12 = max(emp_L12_temp), by(event_id)
					drop emp_L12_temp
					
				// calcula pessoas em t=-1
				
					egen emp_L1_temp = count(cpf) if ym_rel == -1, by(event_id)	
					egen emp_L1 = max(emp_L1_temp), by(event_id)
					drop emp_L1_temp

			// pessoas who left (entre t=-12 e t=-1)
			
				
					// who was employed before zero
					
					gen emp_beforezero = (ym_rel < 0)
					egen worker_emp_beforezero = max(emp_beforezero), by(event_id cpf)
					
					// among these workers, who is not employed after zero
					
					gen emp_afterzero = (ym_rel >= 0)
					egen worker_emp_afterzero = max(emp_afterzero), by(event_id cpf)
					
					// workers who left
					gen left_temp = (worker_emp_beforezero == 1 & worker_emp_afterzero == 0)
					egen left = max(left_temp), by(event_id cpf)
					
			egen unique = tag(cpf)
			
			egen n_left = sum(left) if unique == 1, by(event_id)
			
			drop unique
			
			// pessoas que foram recontratadas em ym_rel > 0 entram na nossa conta do turnover como se fossem left (acho ok)
					
			// collapse at the event_id level
			egen unique = tag(event_id)
			keep if unique == 1
			
			keep event_id n_left emp_L12 emp_L1
			
			// turnover
			
			gen turnover = n_left / ((emp_L12 + emp_L1)/2)
			
			
			
			save "${temp}/turnover_`e'_`ym'", replace
		
		} 
		else {
            di "File `filepath' not found."
        }
    }
}
	

foreach e in spv { // dir5  dir emp spv
	forvalues ym=600/683 { //683
		*display(ym)

	use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
	*use "${data}/cowork_panel_m_spv/cowork_panel_m_spv_620", clear
	
	*sort event_id cpf ym_rel
	
	if _N >= 1 {

		// poached individuals are identified by variable pc_individual (full panel)
		// when they are poached is identified by variable pc (ym_rel == 0)
		
		// size of the origin firm
		egen o_size_temp = count(cpf) if ym_rel == -12, by(event_id)
		egen o_size = max(o_size_temp), by(event_id)
		drop o_size_temp
		
		// include information on quartile of worker fe
		merge m:1 cpf using "${AKM}/AKM_2003_2008_Worker_quartiles", keep(master match) nogen
		gen below_median_fe = 1 if quartile_worker == 1 | quartile_worker == 2
		replace below_median_fe = 0 if quartile_worker == 3 | quartile_worker == 4	
		gen above_75th_fe = 1 if quartile_worker == 4 
		replace above_75th_fe = 0 if quartile_worker == 1 | quartile_worker == 2 | quartile_worker == 3	
		
		// number of above 75th at origin firm 
		egen o_size_above_75th_temp = sum(above_75th_fe) if ym_rel == -12, by(event_id)
		egen o_size_above_75th = max(o_size_above_75th_temp), by(event_id)
		drop o_size_above_75th_temp
		
		// ratio of above 75th at origin firm 
		gen ratio_above_75th = o_size_above_75th / o_size
		
		// number of mgrs at origin firm -- we need this to calculate # emp / # mgr
		egen o_size_mgr_temp = sum(spv) if ym_rel == -12, by(event_id)
		egen o_size_mgr = max(o_size_mgr_temp), by(event_id)
		drop o_size_mgr_temp
		
		// calculate # emp / # mgr
		gen o_size_ratio = o_size / o_size_mgr
		
		// origin firm avg AKM FE
		egen o_avg_fe_worker_temp = mean(fe_worker) if ym_rel == -12, by(event_id)
		egen o_avg_fe_worker = max(o_avg_fe_worker_temp), by(event_id)
		drop o_avg_fe_worker_temp
		
		// number of poached individuals
		egen pc_n = sum(pc), by(event_id)
		
		// wage of poached individual in destination firm
		gen pc_wage_d = wage_real_ln if pc == 1
		
		// wage of poached individual in origin firm (t=-12)
		gen pc_wage_o_l12_temp = wage_real_ln if ym_rel == -12 & pc_individual == 1
		egen pc_wage_o_l12 = max(pc_wage_o_l12_temp), by(cpf event_id)
		drop pc_wage_o_l12_temp
		
		// wage of poached individual in origin firm (t=-1)
		gen pc_wage_o_l1_temp = wage_real_ln if ym_rel == -1 & pc_individual == 1
		egen pc_wage_o_l1 = max(pc_wage_o_l1_temp), by(cpf event_id)
		drop pc_wage_o_l1_temp
		
		// quality of poached individual
		gen pc_fe = fe_worker if pc == 1
		
		// experience of the poached individual
		gen pc_exp = age - educ_years - 6
		
		// renaming some variables
		rename age 	  pc_age
		rename educ_years pc_educ_years
		
		// keeping relevant obs and collapsing to the event level
		keep if pc == 1
		collapse (mean) o_size o_size_mgr o_size_ratio o_avg_fe_worker  ///
			o_size_above_75th ratio_above_75th ///
			pc_n pc_wage_d pc_wage_o_l12 pc_wage_o_l1 pc_fe pc_exp pc_age pc_educ_years, ///
			by(event_id d_plant pc_ym o_plant)
	
		// merging with the auxiliary data sets
		
			// information about raided workers
			cap merge 1:1 event_id using "${temp}/rd_coworker_`e'_`ym'", nogen // "cap" because there might not be any raided coworker
			
			// destination firm -- firm size and wage bill
			cap merge 1:1 event_id using "${temp}/d_vars_`e'_`ym'", nogen
			
			// turnover
			cap merge 1:1 event_id using "${temp}/turnover_`e'_`ym'", nogen
			
			// information about team size -- spv only
			
			if "`e'" == "spv" {
				
				cap merge 1:1 event_id using "${temp}/spvteam_`e'_`ym'", nogen
				
				
			}
			
			if "`e'" == "spv" {
				
				cap merge 1:1 event_id using "${temp}/d_spvteam_`e'_`ym'", nogen
				
				
			}
			
			// CHECAR SE ESSAS SÃO IGUAIS (NÃO DEVERIAM SER! UMA É ORIGEM, OUTRA DESTINO)
			
			
			
		// saving
		save "${temp}/poach_ind_`e'_`ym'", replace
		
	}
	
}	
}

// APPENDING
	
foreach e in spv { // dir5  spv dir emp spv
	
	clear
	
	forvalues ym=600/683 {	//683
		cap append using "${temp}/poach_ind_`e'_`ym'"
	}
	
	save "${data}/poach_ind_`e'", replace
	
}


//* 

// ADDING MORE VARIABLES

	// Firm AKM FE for destination and origin firms and info on growth rate and size of new hires
	
	foreach e in spv { // dir5 spv emp dir
	
		use "${data}/poach_ind_`e'", clear
		
			// destination
			
			tostring d_plant, generate(plant_id) format(%014.0f)
			gen firm_id = substr(plant_id, 1, 8)
			destring firm_id, force replace
			
			merge m:1 firm_id using "${AKM}/AKM_2003_2008_Firm", keep(master match) nogen
			rename fe_firm fe_firm_d
			
			drop firm_id plant_id
			
			// origin
			
			tostring o_plant, generate(plant_id) format(%014.0f)
			gen firm_id = substr(plant_id, 1, 8)
			destring firm_id, force replace
			
			merge m:1 firm_id using "${AKM}/AKM_2003_2008_Firm", keep(master match) nogen
			rename fe_firm fe_firm_o
			
			drop firm_id plant_id
			
			*cap merge 1:1 event_id using "${temp}/d_growth_`e'", nogen
			cap merge 1:1 event_id using "${data}/d_growth_`e'", keep(master match) nogen
			
			cap merge 1:1 event_id using "${temp}/size_hire_`e'", keep(master match) nogen
			
		save "${data}/poach_ind_`e'", replace
	
	}
	
	
	// Incluiding additional variables that will be necessary for the creation of tables in following steps
	
	foreach e in spv { // dir5 spv emp dir
	
		use "${data}/poach_ind_`e'", clear
		
		// origin firm (# emp / # mgr) within same occ category as the poached mgr: o_ratio_team
		gen o_ratio_team = team_cw / team_spv
		
		// destination firm (# raided workers / # new hires): ratio_cw_new_hire and ratio_cw_new_hire_m
		gen ratio_cw_new_hire = rd_coworker_n / d_hire_l12
		
		// destination firm log hires handling missing values, creating dummy for when this is zero and dealing with missing 
		// vars of this dummy
		gen d_hire_l12_d0 = 1 if d_hire_l12 == 0
		replace d_hire_l12_d0 = 0 if d_hire_l12 != 0
		
		
		// Taking log
		local logvars pc_exp o_size o_size_ratio team_cw o_ratio_team rd_coworker_n d_team_cw d_size
		foreach var of local logvars {
								
			gen `var'_ln = ln(`var')
									
		}
		
		
		// Winsorizing vars
		local winsorvars o_ratio_team d_growth o_size_ratio
		
		foreach var of local winsorvars {
			winsor `var', gen (`var'_winsor) p(0.01)
		}
		
		// Handling missing values:
		local missingvars pc_exp_ln pc_fe d_size d_size_ln fe_firm_d d_wage_real_ln o_size_ln o_size_ratio o_size_ratio_ln ///
		o_size_ratio_winsor team_cw_ln o_ratio_team o_ratio_team_ln o_ratio_team_winsor o_avg_fe_worker d_growth  ///
		d_growth_winsor turnover rd_coworker_n_ln ratio_cw_new_hire d_hire_l12 d_team_cw_ln
							 
		foreach var of local missingvars {
								
			misstable summ `var'
								
			if `r(N_eq_dot)' > 0 & `r(N_eq_dot)' < . {
									
				replace `var' = -99 if `var' == .
				gen `var'_m = (`var' == -99 )
									
			}
		}
							


			
		save "${data}/poach_ind_`e'", replace
	
	}		
					

		
		


	
*--------------------------*
* EXIT
*--------------------------*

/*

// REMOVE TEMP FILES! (AFTER GUARANTEEING EVERYTHING IS OK!)
	
clear

cap rm "${temp}/events_t0.dta"

foreach e in spv dir emp dir5 {
forvalues ym=528/683 {
	
	cap rm "${temp}/rd_coworker_`e'_`ym'.dta"
	cap rm "${temp}/d_vars_`e'_`ym'.dta"
	cap rm "${temp}/spvteam_`e'_`ym'.dta"
	cap rm "${temp}/poach_ind_`e'_`ym'.dta"
		
}		
}
	

