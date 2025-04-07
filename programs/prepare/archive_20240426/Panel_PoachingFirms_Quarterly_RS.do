// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2024

// Purpose: Constructing panel around the poaching events

*--------------------------*
* BUILD
*--------------------------*

	// when are firms poaching managers?
	
	use "output/data/PoachedManagers_Quarterly_RS", clear
	
	egen unique = tag(plant_id yq)
	keep if unique == 1
	
	keep plant_id yq
	order plant_id yq
	sort plant_id yq
	
	save "temp/PoachingEvents_Firms", replace
	
		// creating an empty panel
		
		keep plant_id
		duplicates drop
		
		expand 6
		sort plant_id
		by plant_id: gen year = 2002 + _n
		
		expand 4
		sort plant_id year
		by plant_id year: gen quarter = _n
		
		gen yq = yq(year, quarter)
		
		// fill in with poaching events
		
		merge 1:1 plant_id yq using "temp/PoachingEvents_Firms"
		gen poach = (_merge == 3)
		drop _merge
		
		// saving
		
		save "output/data/Panel_PoachingFirms_Quarterly_RS", replace
	
	// identify poaching events when firms poach managers from different firms
	
	use "output/data/PoachedManagers_Quarterly_RS", clear
	
	drop cpf
	order plant_id yq plant_id_L1
	sort plant_id yq
	
		// identifying unique combinations
		egen unique = tag(plant_id yq plant_id_L1)
		keep if unique == 1
	
		// how many different poached firms?
		egen n_poached_firms = sum(poached_mgr), by(plant_id yq)
		tab n_poached_firms
			// in 86% of the poaching events, firms poach managers from a single origin firm 
		
		// identify the bad cases -- managers poached from more than 1 firm
		gen poach_diff_firm = (n_poached_firms > 1)
		
		// organizing and saving
		
		keep plant_id yq poach_diff_firm
		egen unique = tag(plant_id yq)
		keep if unique == 1
		drop unique
		
		save "temp/PoachingEvents_Firms_DiffOrigin", replace
		
		// adding this back into the main panel
		
		use "output/data/Panel_PoachingFirms_Quarterly_RS", clear
		
		merge 1:1 plant_id yq using "temp/PoachingEvents_Firms_DiffOrigin"
		drop _merge
		
		save "output/data/Panel_PoachingFirms_Quarterly_RS", replace
		
	// identifying poaching events when firms poach managers from the same firm
	
	use "output/data/PoachedManagers_Quarterly_RS", clear
	
	drop cpf
	order plant_id yq plant_id_L1
	sort plant_id yq
	
		// count number of workers poached from the same firm
		egen n_poached_same_firm = sum(poached_mgr), by(plant_id yq plant_id_L1)
		
		// identify these cases
		gen poach_same_firm_temp = (n_poached_same_firm > 1)
		egen poach_same_firm = max(poach_same_firm_temp), by(plant_id yq)
		drop poach_same_firm_temp
		
		// organizing and saving
		
		keep plant_id yq poach_same_firm
		egen unique = tag(plant_id yq)
		keep if unique == 1
		drop unique
		
		save "temp/PoachingEvents_Firms_SameOrigin", replace
		
		// adding this back into the main panel
		
		use "output/data/Panel_PoachingFirms_Quarterly_RS", clear
		
		merge 1:1 plant_id yq using "temp/PoachingEvents_Firms_SameOrigin"
		drop _merge
		
		save "output/data/Panel_PoachingFirms_Quarterly_RS", replace
		
	// dealing with firms with multiple poaching events and whether they overlap
	
	use "output/data/Panel_PoachingFirms_Quarterly_RS", clear
	
	egen poach_n = sum(poach), by(plant_id) // in this sample, 76% of firms have more than 1 poaching event
	
		// identify first poaching event
		gen poach_first_yq = yq if poach == 1
		egen poach_yq_first = min(poach_first_yq), by(plant_id)
		
		// time relative to first poaching event
		gen yq_rel_first = yq - poach_yq_first
		
		// identify second poaching event (IF OUTSIDE 12-PERIOD WINDOW)
		gen poach_second = (poach == 1 & yq_rel_first > 12)
		tab poach_second // only 44 cases
		gen poach_second_yq = yq if poach_second == 1
		egen poach_yq_second = min(poach_second_yq), by(plant_id)
		
		// time relative to second poaching event
		gen yq_rel_second = yq - poach_yq_second
		
		// identify third poaching event (IF OUTSIDE 12-PERIOD WINDOW)
		gen poach_third = (poach == 1 & yq_rel_second > 12 & yq_rel_second < .)
		tab poach_third // no cases!
		drop poach_third
		
			// unique yq_rel variable
			gen yq_rel = .
			replace yq_rel = yq_rel_first if yq_rel_first >= -6 & yq_rel_first <= 6
			replace yq_rel = yq_rel_second if yq_rel_second >= -6 & yq_rel_second <= 6
			drop yq_rel_first yq_rel_second
			
			// keep the windows around the first and second poaching events
			keep if yq_rel >= -6 & yq_rel <= 6

			// organizing
			drop poach_first_yq poach_second_yq poach_yq_first poach_yq_second poach_second
			order plant_id year quarter yq poach yq_rel

		// identifying plants with non-overlapping windows
		gen event0 = (yq_rel == 0)
		egen poach_n_nonoverlap = sum(event0), by(plant_id)
		drop event0
		
		// creating a variable that identifies poaching events
		gen yq_poach = yq - yq_rel
		egen id = group(plant_id yq_poach)
		order id
		
		// drop the events where the managers were poached from different companies
		gen poach_diff_firm_temp = poach_diff_firm if yq_rel == 0
		egen drop = max(poach_diff_firm_temp), by(id)
		tab drop // 5% of the events
		drop if drop == 1
		drop drop poach_diff_firm_temp
		
		// saving
		save "output/data/Panel_PoachingFirms_Quarterly_RS", replace
		
			// listing the poaching events we are interested in
			use "output/data/Panel_PoachingFirms_Quarterly_RS", clear
			keep if yq_rel == 0
			keep plant_id yq
			save "temp/ListPoachingEvents_Firms", replace
		
	// adding poach origin
	
	use "output/data/PoachedManagers_Quarterly_RS", clear
	
		merge m:1 plant_id yq using "temp/ListPoachingEvents_Firms"
		drop if _merge != 3
		
		order plant_id yq plant_id_L1
		sort plant_id yq plant_id_L1
		
		// I should only have events where plant_id_L1 is the same
		
		egen unique = tag(plant_id yq plant_id_L1)
		keep if unique == 1
		drop unique
		
		egen n_origin_firms = count(plant_id_L1), by(plant_id yq)
		tab n_origin_firms // all good!
		
		// organizing
		
		keep plant_id yq plant_id_L1
		rename yq yq_poach
		
		// saving
		
		save "temp/OriginFirms", replace
		
		// merging with the main data set
		
		use "output/data/Panel_PoachingFirms_Quarterly_RS", clear
		
		merge m:1 plant_id yq_poach using "temp/OriginFirms"
		drop _merge
		
		save "output/data/Panel_PoachingFirms_Quarterly_RS", replace
	
			
		
		
		
	
	
	
