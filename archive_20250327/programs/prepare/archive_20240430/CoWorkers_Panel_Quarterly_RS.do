// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: Aprul 2024

// Purpose: Constructing the panel with coworkers

*--------------------------*
* BUILD
*--------------------------*

	// identifying poached firms and their t=-4

		use "output/data/PoachingEvents_Quarterly_RS", clear
		
		drop poached_mgr mgr director
		
		duplicates drop event_id poaching_plant poaching_yq poaching_plant, force
		isid event_id
		
		// creating variables to find the coworkers
		gen double plant_id = poached_plant
		format plant_id %14.0f
		gen yq = poaching_yq - 4 // i will use this to identify the coworkers
		format yq %tq
		
			// listing the events
			save "temp/Events", replace
		
		// listing firms and period where I will try to find the coworkers
		keep plant_id yq
		duplicates drop
		
			// only the poached firms and the t=-4 information
			save "temp/PoachedFirms_L4", replace
		
	// the main data set is too heavy -- keep only the potential coworkers
			
		use "output/data/RAIS_Quarterly_RS", clear
		
		merge m:1 plant_id yq using "temp/PoachedFirms_L4"
		
		gen coworker_L4 = (_merge == 3)
		egen coworker = max(coworker_L4), by(cpf)
		keep if coworker == 1
		
		drop _merge
		drop coworker_L4 coworker
		
		save "temp/CoWorkers", replace
	
	// now, construct the panel for each event	
			
	forvalues ev=1/867 {	
		
		// selecting the event of interest
		
		use "temp/Events", clear
		keep if event_id == `ev'
		save "temp/EventInterest", replace
		
		// selecting its coworkers
		
		use "temp/CoWorkers", clear
		
		merge m:1 plant_id yq using "temp/EventInterest"
		
		gen coworker_L4 = (_merge == 3)
		egen coworker = max(coworker_L4), by(cpf)
		keep if coworker == 1
		drop _merge
		
		order event_id poaching_plant poaching_yq poached_plant
		
		egen event_id_n = max(event_id)
		egen double poaching_plant_n = max(poaching_plant)
		egen poaching_yq_n = max(poaching_yq)
		egen double poached_plant_n = max(poached_plant)
		
		replace event_id = event_id_n
		replace poaching_plant = poaching_plant_n
		replace poaching_yq = poaching_yq_n
		replace poached_plant = poached_plant_n
		
		drop event_id_n poaching_plant_n poaching_yq_n poached_plant_n
		
		gen yq_rel = yq - poaching_yq
		keep if yq_rel >= -6 & yq_rel <= 6
		
		order event_id poaching_plant poaching_yq poached_plant cpf year quarter yq yq_rel
		sort event_id cpf yq_rel
		
		save "temp/CoWorkers_`ev'", replace
		
	}
	
	clear
	
	forvalues ev=1/867 {
		
		qui append using "temp/CoWorkers_`ev'"
			
	}
	
	save "output/data/CoWorkers_Panel_Quarterly_RS", replace
	
// adding more variables

	// who are the poached managers?
	
	use "output/data/PoachingEvents_Quarterly_RS", clear
	
	keep event_id poached_mgr mgr director
	rename poached_mgr cpf
	rename mgr tag_mgr
	rename director tag_director
	isid event_id cpf
	
	save "temp/PoachedManagers", replace
	
		// merging into the main data set
		
		use "output/data/CoWorkers_Panel_Quarterly_RS", clear
		
		merge m:1 event_id cpf using "temp/PoachedManagers", keepusing(tag_mgr tag_director)
		drop _merge
		
		egen tag_mgr_new = max(tag_mgr), by(event_id cpf)
		egen tag_director_new = max(tag_director), by(event_id cpf)
		
		replace tag_mgr_new = 0 if tag_mgr_new == .
		replace tag_director_new = 0 if tag_director_new == .
		
		drop tag_mgr tag_director
		rename tag_mgr_new tag_mgr
		rename tag_director_new tag_director
		
		save "output/data/CoWorkers_Panel_Quarterly_RS", replace
	
	
			
			// FIRST PASS
			
			use "output/data/CoWorkers_Panel_Quarterly_RS", clear
			
			gen samefirm = (plant_id == poaching_plant)
			
			collapse (mean) samefirm if tag_mgr == 0, by(event_id yq_rel)
			
			collapse (mean) samefirm, by(yq_rel)
			
			gen id = 1
			tsset id yq_rel
			order id yq_rel
	
			tsline samefirm
			
	
	
	
	

	
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
				
				
		
		
		
		
		
		
		
		
		
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
		

