// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2025

// Purpose: Creating data set listing all workers in destination firms in all months

*--------------------------*
* BUILD
*--------------------------*

	// this panel will be constructed separately for each cohort
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
		
	// defining locals for this analysis
	local ym_l12 = `ym' - 12
	local ym_f12 = `ym' + 12
		
	// first: listing plants and months i'm interested in
		
		use "${data}/202503_evt_panel_m", clear
			
		keep if pc_ym == `ym'
					
		keep d_plant eventid
		duplicates drop
		
		save "${temp}/202503_d_firmlist_m_`ym'", replace
		
	// second: using the complete RAIS panel, identify all workers in d_plants
		
		forvalues yymm=`ym_l12'/`ym_f12' {

			use "${data}/rais_m/rais_m`yymm'", clear
				
			// keeping only d_plants in the the months around the poaching events
			rename plant_id d_plant
			merge m:1 d_plant using "${temp}/202503_d_firmlist_m_`ym'", keep(match) nogen 
				
			save "${temp}/202503_dest_panel_m_`ym'_`yymm'", replace
				
		}
	
		// appending the temporary files
		
		clear
		
		forvalues yymm=`ym_l12'/`ym_f12' {
			
			append using "${temp}/202503_dest_panel_m_`ym'_`yymm'"
			
		}
		
		save "${data}/202503_dest_panel_m/202503_dest_panel_m_`ym'", replace
	
		// removing temporary files
		
		forvalues yymm=`ym_l12'/`ym_f12' {
			
			rm "${temp}/202503_dest_panel_m_`ym'_`yymm'.dta"
		
		}
		
		rm "${temp}/202503_d_firmlist_m_`ym'.dta"
	
}

// adding more variables

	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
		
		// organizing data set with list of raided and poached individuals
		
		use "${data}/202503_cowork_panel_m/202503_o_cw_`ym'", clear
                  
			collapse (max) pc_individual raid_individual main_individual, by(cpf eventid)
                          
                        keep if pc_individual == 1 | raid_individual == 1 | main_individual == 1
 
                        save "${temp}/cw_`ym'", replace
			
	// back to the main data set		
	
	use "${data}/202503_dest_panel_m/202503_dest_panel_m_`ym'", clear
	
		// raided and poached individuals
		merge m:1 eventid cpf using "${temp}/cw_`ym'", nogen
		replace pc_individual = 0 if pc_individual == .
                replace raid_individual = 0 if raid_individual == .
		replace main_individual = 0 if main_individual == .
	
		// worker FE
		merge m:1 cpf using "${AKM}/AKM_2003_2008_both_workerFE", keep(master match) nogen
		rename naive_FE_worker worker_naive_fe
		rename akm_FE_worker worker_akm_fe
		
		// destination firm FE
		merge m:1 firm_id using "${AKM}/AKM_2003_2008_both_firmFE", keep(master match) nogen
		rename naive_FE_firm d_firm_naive_fe
		rename akm_FE_firm d_firm_akm_fe
		
		// adjusting wages ---- THIS IS TEMPORARY --- WILL EVENTUALLY BE DONE WHEN CONSTRUCTING THE MONTHLY DS
		
		merge m:1 year using "${input}/auxiliary/ipca_brazil"
		generate index_2017 = index if year == 2017
		egen index_base = max(index_2017)
		generate adj_index = index / index_base
		drop if _merge == 2
				
			// in level
			generate wage_real = earn_avg_month_nom / adj_index
		
			// in logs
			gen wage_real_ln = ln(wage_real)
			
		drop year index _merge index_2017 index_base adj_index
			
	// saving
	compress
	save "${data}/202503_dest_panel_m/202503_dest_panel_m_`ym'", replace
						
	}
	
// adding event type to this data set
	
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
		
	use "${data}/202503_dest_panel_m/202503_dest_panel_m_`ym'", clear
	
	merge m:1 eventid using "${data}/202503_evttype", keep(master match) nogen
	
	// saving
	compress
	save "${data}/202503_dest_panel_m/202503_dest_panel_m_`ym'", replace	
	
	}
