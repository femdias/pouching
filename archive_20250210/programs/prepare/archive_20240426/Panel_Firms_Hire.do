// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: Aprul 2024

// Purpose: Firm-level panel with hiring outcomes

*--------------------------*
* BUILD
*--------------------------*

					// identifying poaching of directors

					use "output/data/PoachedManagers_Quarterly_RS", clear
					
					keep plant_id yq poached_director
					
					collapse (max) poached_direct, by(plant_id yq)
					
					save "temp/poached_director", replace

// calculating hiring measures

// number of employed workers

	// plants-quarters of interest
	
		use "output/data/Panel_PoachingFirms_Quarterly_RS", clear
		
		keep plant_id yq
		egen unique = tag(plant_id yq)
		keep if unique == 1
		drop unique
		
		save "temp/FirmList", replace
	
	// full panel
	
		use "output/data/RAIS_Quarterly_RS", clear
		
		// keeping only the observations we need
		
		merge m:1 plant_id yq using "temp/FirmList"
		keep if _merge == 3
		drop _merge
		
		// identifying employed workers
		
		cap drop emp
		gen emp = (plant_id != .)
		
		// collapsing at the plant-quarter level
		
		collapse (sum) emp, by(plant_id yq)
		
		order plant_id yq
		sort plant_id yq
		
		save "temp/emp", replace
	
// total number of hires
	
	// plants-quarters of interest
	
		use "output/data/Panel_PoachingFirms_Quarterly_RS", clear
		
		keep plant_id yq
		egen unique = tag(plant_id yq)
		keep if unique == 1
		drop unique
		
		save "temp/FirmList", replace
	
	// full panel
	
		use "output/data/RAIS_Quarterly_RS", clear
		
		// keeping only the observations we need
		merge m:1 plant_id yq using "temp/FirmList"
		keep if _merge == 3
		drop _merge
		
		// identifying hires

		gen type_of_hire_hire = (type_of_hire == 2)
		gen hire_quarter = floor(hire_month / 4) + 1
		gen hire_yq = yq(hire_year, hire_quarter)
		gen hire = ((yq == hire_yq) & (hire_yq != .) & (type_of_hire_hire == 1)) 
	
		// collapsing at the plant-quarter level
		
		collapse (sum) hire, by(plant_id yq)
		
		order plant_id yq
		sort plant_id yq
		
		save "temp/hire", replace
	
// hires from coworkers
		
	// listing coworkers of interest
	
		use "temp/Panel_CoWorkers_Quarterly_RS", clear // stop using a tempfile here!!!
		
		keep if yq_rel == -4
		keep cpf firm_dest
		
		rename firm_dest plant_id
		order plant_id
		sort plant_id
		
		isid plant_id cpf
		
		save "temp/CoWorkers_List", replace
		
	// full panel
	
		use "output/data/RAIS_Quarterly_RS", clear
		
		
					keep if plant_id == 97755177000300
		
		// keeping only the observations we need
		merge m:1 plant_id yq using "temp/FirmList"
		keep if _merge == 3
		drop _merge
		
		// identifying hires

		gen type_of_hire_hire = (type_of_hire == 2)
		gen hire_quarter = floor(hire_month / 4) + 1
		gen hire_yq = yq(hire_year, hire_quarter)
		gen hire = ((yq == hire_yq) & (hire_yq != .) & (type_of_hire_hire == 1))
		
		// are these hires coworkers?
		
		merge m:1 plant_id cpf using "temp/CoWorkers_List"
		drop if _merge == 2
		gen coworker = (_merge == 3)
		drop _merge
		
		gen hire_coworker = (hire == 1 & coworker == 1)
	
		// collapsing at the plant-quarter level
		
		collapse (sum) hire_coworker, by(plant_id yq)
		
		order plant_id yq
		sort plant_id yq
	
		save "temp/hire_coworker", replace
		
// putting everything together	

	use "output/data/Panel_PoachingFirms_Quarterly_RS", clear

	merge 1:1 plant_id yq using "temp/emp"
	drop _merge
	replace emp = 0 if emp == .
	
	merge 1:1 plant_id yq using "temp/hire"
	drop _merge
	replace hire = 0 if hire == .
	
	merge 1:1 plant_id yq using "temp/hire_coworker"
	drop _merge
	replace hire_coworker = 0 if hire_coworker == .
	
		// note that hire e hire_coworker includes the poached mgr
		// create new variables without them
		
		gen hire_sansmgr = hire
		replace hire_sansmgr = hire_sansmgr - 1 if yq_rel == 0
		
		gen hire_coworker_sansmgr = hire_coworker
		replace hire_coworker_sansmgr = hire_coworker_sansmgr - 1 if yq_rel == 0
		
	save "temp/Panel_Hiring", replace


			// FIRST PASS
			
			// number of hires
			
			use "temp/Panel_Hiring", clear
			
			collapse (mean) hire, by(yq_rel)
			
			gen id = 1
			tsset id yq_rel
			
			tsline hire
			
			// number of hires from manager origin firm (including the manager)
			
			use "temp/Panel_Hiring", clear
			
			collapse (mean) hire_coworker, by(yq_rel)
			
			gen id = 1
			tsset id yq_rel
			
			tsline hire_coworker
			
			// number of hires from manager origin firm (excluding the manager)
			
			use "temp/Panel_Hiring", clear
			
			collapse (mean) hire_coworker_sansmgr, by(yq_rel)
			
			gen id = 1
			tsset id yq_rel
			
			tsline hire_coworker_sansmgr
			
			// percentage of hires (including the manager)
			
			use "temp/Panel_Hiring", clear
			
			gen hire_coworker_rel = hire_coworker / hire
			replace hire_coworker_rel = 0 if hire_coworker_rel == .
			
			collapse (mean) hire_coworker_rel, by(yq_rel)
			
			gen id = 1
			tsset id yq_rel
			
			tsline hire_coworker_rel
			
					// by type of poach
					
					use "temp/Panel_Hiring", clear
			
					merge 1:1 plant_id yq using "temp/poached_director", keepusing(poached_director)
			
					drop if _merge == 2
					drop _merge
			
					egen poached_dir = max(poached_director), by(id)
					
					// now to the analysis we had before, but with a heterogeneity analysis
				
					gen hire_coworker_rel = hire_coworker / hire
					replace hire_coworker_rel = 0 if hire_coworker_rel == .
				
					collapse (mean) hire_coworker_rel, by(poached_dir yq_rel)
				
					tsset poached_dir yq_rel
				
					tsline hire_coworker_rel if poached_dir == 0 || ///
					tsline hire_coworker_rel if poached_dir == 1, ///
					xlabel(-6(1)6) xtitle("Quarters Since Hiring Poached Manager") ///
					ytitle("Share of Co-Worker Hires") ///
					legend(order(1 "Supervisors" 2 "Directors") lcolor(white))
			
			// percentage of hires (excluding the manager)
			
			use "temp/Panel_Hiring", clear
			
			gen hire_coworker_sansmgr_rel = hire_coworker_sansmgr / hire_sansmgr
			replace hire_coworker_sansmgr_rel = 0 if hire_coworker_sansmgr_rel == .
			
			collapse (mean) hire_coworker_sansmgr_rel, by(yq_rel)
			
			gen id = 1
			tsset id yq_rel
			
			tsline hire_coworker_sansmgr_rel
			
					// by type of poach
			
					use "temp/Panel_Hiring", clear
			
					merge 1:1 plant_id yq using "temp/poached_director", keepusing(poached_director)
			
					drop if _merge == 2
					drop _merge
			
					egen poached_dir = max(poached_director), by(id)
					
					// now to the analysis we had before, but with a heterogeneity analysis
				
					gen hire_coworker_sansmgr_rel = hire_coworker_sansmgr / hire_sansmgr
					replace hire_coworker_sansmgr_rel = 0 if hire_coworker_sansmgr_rel == .
				
					collapse (mean) hire_coworker_sansmgr_rel, by(poached_dir yq_rel)
				
					tsset poached_dir yq_rel
				
					tsline hire_coworker_sansmgr_rel if poached_dir == 0 || ///
					tsline hire_coworker_sansmgr_rel if poached_dir == 1, ///
					xlabel(-6(1)6) xtitle("Quarters Since Hiring Poached Manager") ///
					ytitle("Share of Co-Worker Hires") ///
					legend(order(1 "Supervisors" 2 "Directors") lcolor(white))
			
			
				
			
			
			
			
			
			
			


















