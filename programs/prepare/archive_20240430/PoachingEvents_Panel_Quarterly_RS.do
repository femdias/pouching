// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2024

// Purpose: Constructing panel around the poaching events

*--------------------------*
* BUILD
*--------------------------*
	
	use "output/data/PoachingEvents_Quarterly_RS", clear
	
	collapse (sum) mgr director, by(event_id poaching_plant poaching_yq poached_plant) 
	isid event_id
	
		expand 13
		sort event_id
		
		by event_id: gen yq = poaching_yq - 7 + _n	
		format yq %tq
		
		gen yq_rel = yq - poaching_yq
		
		// restring to 2003-2008
		keep if yq >= yq(2003,1) & yq <= yq(2008,4)
		
	save "output/data/PoachingEvents_Panel_Quarterly_RS", replace
	
// adding more variables

// number of employees
		
	// plants-quarters of interest
	
	use "output/data/PoachingEvents_Panel_Quarterly_RS", clear
		
	keep poaching_plant yq
	egen unique = tag(poaching_plant yq)
	keep if unique == 1
	drop unique
		
	rename poaching_plant plant_id // for merging
		
	save "temp/FirmList", replace
	
	// calculating number of employees using the full panel
	
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
	
		// merging into the main data set
		
		use "output/data/PoachingEvents_Panel_Quarterly_RS", clear
		
		rename poaching_plant plant_id // for merging
		merge m:1 plant_id yq using "temp/emp"
		drop _merge
		replace emp = 0 if emp == .
		rename plant_id poaching_plant
		
		save "output/data/PoachingEvents_Panel_Quarterly_RS", replace
		
// number of hires

	// plants-quarters of interest
	
	use "output/data/PoachingEvents_Panel_Quarterly_RS", clear
		
	keep poaching_plant yq
	egen unique = tag(poaching_plant yq)
	keep if unique == 1
	drop unique
		
	rename poaching_plant plant_id // fr merging
		
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
		
	collapse (sum) hire if hire == 1, by(plant_id yq) // THIS IS WHERE YOU'D ADD WAGES, TENURE, AND SO
								// WITH HIRE == 1, WE'RE ONLY GETTING THE NEW WORKERS (NEW HIRE)
								// IF WE WANT THE WAGES FOR THOSE WHO ARE ALREADY EMPLOYED, USE HIRE == 0
								
		
	order plant_id yq
	sort plant_id yq
		
	save "temp/hire", replace		
		
	// merging into the main data set
		
		use "output/data/PoachingEvents_Panel_Quarterly_RS", clear
		
		rename poaching_plant plant_id // for merging
		merge m:1 plant_id yq using "temp/hire"
		drop _merge
		replace hire = 0 if hire == .
		rename plant_id poaching_plant
		
		save "output/data/PoachingEvents_Panel_Quarterly_RS", replace	
		
// number of coworker / director / mgr hires and employees

	use "output/data/CoWorkers_Panel_Quarterly_RS", clear
	
	// employment
	
	gen emp_coworker = (plant_id == poaching_plant)
	gen emp_mgr = ((plant_id == poaching_plant) & (tag_mgr == 1))
	gen emp_director = ((plant_id == poaching_plant) & (tag_director == 1))
	
	// hires
	
	gen type_of_hire_hire = (type_of_hire == 2)
	gen hire_quarter = floor(hire_month / 4) + 1
	gen hire_yq = yq(hire_year, hire_quarter)
	gen hire = ((yq == hire_yq) & (hire_yq != .) & (type_of_hire_hire == 1)) 
	
	gen hire_coworker = ((hire == 1) & (plant_id == poaching_plant))
	gen hire_mgr = ((hire == 1) & (plant_id == poaching_plant) & (tag_mgr == 1))
	gen hire_director = ((hire == 1) & (plant_id == poaching_plant) & (tag_director == 1))
		
	// collapsing at the ev - poaching_plant - yq
	
	collapse (sum) emp_coworker emp_mgr emp_director hire_coworker hire_mgr hire_director, by(ev poaching_plant yq)  // THIS IS WHERE YOU COULD ADD MORE VARIABLES TOO
	
	order ev poaching_plant yq
	sort ev poaching_plant yq
	
	save "temp/emphire_coworkers", replace
	
		// merging into the main data set
		
		use "output/data/PoachingEvents_Panel_Quarterly_RS", clear
		
		merge 1:1 ev poaching_plant yq using "temp/emphire_coworkers"
		drop _merge
		
		save "output/data/PoachingEvents_Panel_Quarterly_RS", replace	
		
		
				// FIRST PASS
				
				use "output/data/PoachingEvents_Panel_Quarterly_RS", clear
				
				collapse (mean) hire hire_coworker hire_mgr hire_director, by(yq_rel)
				
				gen id = 1
				order id
				tsset id yq_rel
				
					tsline hire
					
					tsline hire_mgr
					
					gen hire_coworker_sansmgr = hire_coworker - hire_mgr
					tsline hire_coworker_sansmgr
					
					gen hire_mgr_rel = hire_mgr / hire
					tsline hire_mgr_rel
					
					gen hire_sansmgr = hire - hire_mgr
					gen hire_coworker_sansmgr_rel = hire_coworker_sansmgr / hire_sansmgr
					tsline hire_coworker_sansmgr_rel
					
					
					gen hire_coworker_sansdir = hire_coworker - hire_director
					tsline hire_coworker_sansdir
					
					gen hire_sansdir = hire - hire_dir
					gen hire_coworker_sansdir_rel = hire_coworker_sansdir / hire_sansdir
					tsline hire_coworker_sansdir_rel
		
		
		
		
	
	
	
		
		
	
	
	
