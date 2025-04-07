// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: Aprul 2024

// Purpose: Constructing the panel with coworkers

*--------------------------*
* BUILD
*--------------------------*

// list of poaching events we are interested in

	use "output/data/Panel_PoachingFirms_Quarterly_RS", clear
	keep if yq_rel == 0
	keep plant_id yq_poach
	save "temp/List_EventsInterest", replace
	
// identifying the managers who were poached in these events

	use "output/data/PoachedManagers_Quarterly_RS", clear
	keep cpf yq plant_id plant_id_L1
	rename yq yq_poach
	merge m:1 plant_id yq_poach using "temp/List_EventsInterest"
	keep if _merge == 3
	drop _merge
	
		// we are interested in where they were for this analysis
		
		replace yq_poach = yq_poach - 1
		rename yq_poach yq
		
		rename plant_id plant_id_F1
		rename plant_id_L1 plant_id
		drop plant_id // we already have this
		
		save "temp/List_PoachedManagersInterest", replace

// now, in the main panel

	use "output/data/RAIS_Quarterly_RS", clear
	
		merge 1:1 cpf yq using "temp/List_PoachedManagersInterest"

	// identifying poached managers immediately before they are poached
	gen poached_mgr_L1 = (_merge == 3)
	drop _merge
	
		// tagging the entire employment history of these managers
		egen poached_mgr = max(poached_mgr_L1), by(cpf)
	
	// identify these managers 4 quarters before the poach
	gen poached_mgr_L4 = F3.poached_mgr_L1
	
	// tag the entire firm where the poached manager was employed in t=-4
	// this wicoworkers of the poached managers 4 quarters before the poach
	egen firm_poached_L4 = max(poached_mgr_L4), by(plant_id yq)
	
	// tag the entire history of the coworkers of a poached manager -- including the poached manager
	egen poached_coworker = max(firm_poached_L4), by(cpf)
	
	// these are the workers we are interested in
	keep if poached_coworker == 1
	
	save "output/data/Panel_CoWorkers_Quarterly_RS", replace
	
	use "output/data/Panel_CoWorkers_Quarterly_RS", clear
	
	// dealing with the complications...
	
		// an individual can be a coworker of more than 1 poached manager
		// when is this a problem?
		
		// a. when there is more than 1 poaching period (mais de um t=0)
		egen firm_poached_L4_totalcpf = sum(firm_poached_L4) if poached_mgr == 0, by(cpf)
		tab firm_poached_L4_totalcpf // 24% das pessoas tem mais de um poaching period (mais de um t=0)
		
			// dropping this for now -- will have to think more about this
			drop if firm_poached_L4_totalcpf >= 2 & poached_mgr == 0
			
		// b. when there is only 1 poaching period, but two coworkers were poached
		egen firm_poached_L4_totalplantyq = sum(poached_mgr_L4), by(plant_id yq)
		tab firm_poached_L4_totalplantyq // this identifies when this happens
		
			// in this case, I'll drop this poaching event (and its coworkers) altogether
			egen co_mul_mgr_poach = max(firm_poached_L4_totalplantyq), by(cpf)
			tab co_mul_mgr_poach // 7.14% apenas -- drop tbm
			drop if co_mul_mgr_poach > 1
			
			// note that this will also drop some poached managers 
			// let me identify when this happened and drop the coworkers (drop the entire event)

			egen firm_poached_L4_test = max(poached_mgr_L4), by(plant_id yq)
			egen poached_coworker_test = max(firm_poached_L4_test), by(cpf)
			
			drop if poached_coworker_test != 1
	
		// this should be much simpler now
		
		sort cpf yq
		
	// identify period t-4
	gen yq_l4 = .
	replace yq_l4 = yq if poached_mgr == 0 & firm_poached_L4 == 1
	replace yq_l4 = yq if poached_mgr == 1 & poached_mgr_L4 == 1
	
		// everybody should have this period and just once
		egen ok = count(yq_l4), by(cpf)
		tab ok // OK!
		drop ok
		
		// expand this for the entire cpf
		egen yq_l4_exp = max(yq_l4), by(cpf)
		
		// and so we know what t=0 is
		gen yq_zero = yq_l4_exp + 4
		
		// relative variable
		gen yq_rel = yq - yq_zero
		
	// where did the poached manager go to?
	
	gen double firm_mgr_dest_L4 = F4.plant_id if yq_rel == -4 & poached_mgr == 1
	format firm_mgr_dest_L4 %14.0f
	
	// expanding this for the entire panel
	
		// for poached managers
	
		egen double firm_mgr_dest = max(firm_mgr_dest_L4) if poached_mgr == 1, by(cpf)
		format firm_mgr_dest %14.0f
		
		// for coworkers
		
		egen double firm_cw_dest_temp = max(firm_mgr_dest_L4), by(plant_id yq)
		egen double firm_cw_dest = max(firm_cw_dest_temp) if poached_mgr == 0, by(cpf)
		drop firm_cw_dest_temp
		format firm_cw_dest %14.0f
		
		// combining
		gen double firm_dest = .
		replace firm_dest = firm_mgr_dest if poached_mgr == 1
		replace firm_dest = firm_cw_dest if poached_mgr == 0
		format firm_dest %14.0f
				
	save "temp/Panel_CoWorkers_Quarterly_RS", replace
	
*******************************************************************************	
/* ARCHIVE	
	
	
	use "temp/Panel_CoWorkers_Quarterly_RS", clear
	
	
			// FIRST PASS
			
				order cpf year quarter yq yq_rel poached_mgr
				
				
						// how much were these poached managers earning?
						summ earn_avg_month_nom if poached_mgr == 1 & yq_rel == -4, detail
						summ earn_avg_month_nom if poached_mgr == 0 & yq_rel == -4, detail
				
						/*
						// let's look for the highly paid managers & their coworkers
						gen sample_mgr_5000_temp = (poa_mgr == 1 & earn_avg_month_nom >= 5000 & yq_rel == -4)
							tab poa_mgr if yq_rel == -4
							tab sample_mgr_5000_temp if yq_rel == -4
						egen sample_mgr_5000_temp2 = max(sample_mgr_5000_temp), by(plant_id yq)
							tab sample_mgr_5000_temp2
						egen sample_mgr_5000 = max(sample_mgr_5000_temp2), by(cpf)
							tab sample_mgr_5000
							
							keep if sample_mgr_5000 == 1
						*/
						
						/*
						// let's look for the highly paid managers & their coworkers
						gen sample_mgr_7500_temp = (poa_mgr == 1 & earn_avg_month_nom >= 7500 & yq_rel == -4)
							tab poa_mgr if yq_rel == -4
							tab sample_mgr_7500_temp if yq_rel == -4
						egen sample_mgr_7500_temp2 = max(sample_mgr_7500_temp), by(plant_id yq)
							tab sample_mgr_7500_temp2
						egen sample_mgr_7500 = max(sample_mgr_7500_temp2), by(cpf)
							tab sample_mgr_7500
							
							keep if sample_mgr_7500 == 1
						*/
				
				// variable identifying employment in destination firm
				drop samefirm
				gen samefirm = (plant_id == firm_dest)
				
				
				// keep workers with a full panel (-6 to 6)
				egen min_yq_rel = min(yq_rel), by(cpf)
				egen max_yq_rel = max(yq_rel), by(cpf)
				tab min_yq_rel
				tab max_yq_rel
				keep if min_yq_rel <= -6 & max_yq_rel >= 6
				
					/*
					// heterogeneity: workers who were and were not managers before
					gen mgr_before_temp = mgr if yq_rel == -4
					egen mgr_before = max(mgr_before_temp), by(cpf)
				
						tab mgr_before 
						tab mgr_before poa_mgr
						
					*/	
				
				
				
				// collapse
				
				collapse (mean) samefirm, by(poached_mgr yq_rel)
				
				tsset poached_mgr yq_rel
				
				tsline samefirm if poached_mgr == 1 & yq_rel >= -6 & yq_rel <= 6 || ///
				
				tsline samefirm if poached_mgr == 0 & yq_rel >= -6 & yq_rel <= 6, ///
					xtitle("Quarters Since Manager Was Poached") ///
					ytitle("Share Coworkers Employed in Poaching Firm")
				
				
		
		
		
		
		
		
		
		
		
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
		

