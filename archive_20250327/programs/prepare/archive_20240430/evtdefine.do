// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: Aprul 2024

// Purpose: Identifying poached managers (poaching events)

*--------------------------*
* BUILD
*--------------------------*

use plant_id cpf occ_gr_o occ_1d occ_3d mgr_top5 n_emp cause_of_sep sep_month year yq type_of_hire hire_month hire_year gov using "output/data/RAIS_Quarterly_RS", clear

	// list of criteria

		// 1. worker is a manager in t-1
		gen criteria1 = (L.occ_gr_o == 1) // 3.2M
		gen criteria1d = (L.occ_1d == 1) 
		gen criteria1d5 = (L.occ_1d == 0 | L.mgr_top5==1) 
		gen criteria1s = (L.occ_3d == 0) 
		
		// 2. worker is employed in a firm with at least 45 employees in t-1
		gen criteria2 = (L.n_emp >= 45 & L.n_emp < .) // 28.3M
		
		// 3. worker is employed in the same firm in t-4 and t-1
		gen criteria3 = ((L.plant_id == L4.plant_id) & (L.plant_id != .) & (L4.plant_id != .)) // 31.2M
		
		// 4. worker is employed in a different firm in t
		gen criteria4 = ((plant_id != L.plant_id) & (plant_id != .) & (L.plant_id != .)) // 1.2M
		
		// 5. worker is employed in a firm with at least 45 employees in t
		gen criteria5 = (n_emp >= 45 & n_emp < .) // 29.6M
		
		// 6. worker must be separated from the old firm in t
		
			gen sep = (cause_of_sep == 10 | cause_of_sep == 11 | cause_of_sep == 12 | ///
				cause_of_sep == 20 | cause_of_sep == 21)
					
			gen sep_quarter = floor(sep_month / 4) + 1
			
			gen sep_yq = yq(year, sep_quarter)
			
		gen criteria6 = ((yq == L.sep_yq) & (L.sep_yq != .) & (L.sep == 1)) // 3.1M

		// 7. worker must be hired by the new firm in t

			gen hire = (type_of_hire == 2)
			
			gen hire_quarter = floor(hire_month / 4) + 1
			
			gen hire_yq = yq(hire_year, hire_quarter)
			
		gen criteria7 = ((yq == hire_yq) & (hire_yq != .) & (hire == 1)) // 3.4M
		
		// 8. worker is employed in non-gov firms in t-1 and t
		gen criteria8 = ((L.gov == 0 & gov == 0) & (L.plant_id != .) & (plant_id != .)) // 29.5 M
	
	// variable identifying poached managers --> 1,487 events
	** Definition 1: any sort of manager (director (occ 1xx), supervisor (occ xx0))
	gen poached_mgr = (criteria1 == 1 & criteria2 == 1 & criteria3 == 1 & criteria4 == 1 & ///
		criteria5 == 1 & criteria6 == 1 & criteria7 == 1 & criteria8 == 1)
	
	** Definition 2: directors only (occ 1xx)
	gen poached_dir = (criteria1d == 1 & criteria2 == 1 & criteria3 == 1 & criteria4 == 1 & ///
		criteria5 == 1 & criteria6 == 1 & criteria7 == 1 & criteria8 == 1)
	
	** Definition 3: directors + top 5% of salaries (occ 1xx + top 5%)
	gen poached_dir5 = (criteria1d5 == 1 & criteria2 == 1 & criteria3 == 1 & criteria4 == 1 & ///
		criteria5 == 1 & criteria6 == 1 & criteria7 == 1 & criteria8 == 1)
	
	** Definition 4: supervisors only (occ xx0)
	gen poached_sup = (criteria1s == 1 & criteria2 == 1 & criteria3 == 1 & criteria4 == 1 & ///
		criteria5 == 1 & criteria6 == 1 & criteria7 == 1 & criteria8 == 1)
		
	** Determining hierarchy of poaching importance
	* As sometimes firms poach multiple workers, who do we count as first?
	* poached_dir > poached_dir5 > poached_mgr > poached_sup
	
	// heterogeneity: poaching a director vs. poaching a supervisor
	
	*gen director = (occ_gr_o == 1 & occ_1d == 1)
	*gen poached_director = (poached_mgr == 1 & L.director == 1)
	
	// organizing the data set and keeping the information that we need
	
	gen double plant_id_L1 = L.plant_id
	format plant_id_L1 %14.0f
	
	keep if poached_mgr == 1 | poached_dir5==1
	keep cpf yq plant_id plant_id_L1 poached_mgr poached_dir poached_dir5 poached_sup
		
	sort plant_id yq
	order plant_id yq
	
	// DEALING WITH MULTIPLE PERIODS
	
		// first event
		
			// identify the first event
			egen yq_first = min(yq), by(plant_id)
			
			// calculate distance to first event
			gen dist_first = yq - yq_first
			
			// keep only the event itself or events 9 or more quarters away
			// this way, a 4-quarter window on both sides of the event is clean from other events
			keep if dist_first == 0 | dist_first >= 9
			

		// second event
		
			// identify the second event
			egen yq_second = min(yq) if yq > yq_first, by(plant_id)
		
			// calculate distance to second event
			gen dist_second = yq - yq_second 
			
			// as before, keep only the previous events, the event itself or events 9 or more quarters away
			keep if dist_second == . | dist_second == 0 | dist_second >= 9
		
		// third event
		
			// identify the third event
			egen yq_third = min(yq) if yq > yq_second, by(plant_id)
		
			// no cases!
			
	// DEALING WITH MULTIPLE POACHES IN THE SAME QUARTER
	
		// it's OK if origin firm is the same; otherwise let's not consider
	
		egen unique = tag(plant_id yq plant_id_L1)
		egen n_origin = sum(unique), by(plant_id yq)
		drop if n_origin != 1 // 12.92% of the events
	
	drop yq_first dist_first yq_second dist_second yq_third unique n_origin
	
	// creating an event identifier
	
	egen event_id = group(plant_id yq)
	order event_id plant_id yq plant_id_L1 cpf 
	
	// organizing
	
	rename poached_mgr 	mgr
	rename poached_director director
	rename plant_id 	poaching_plant
	rename yq 		poaching_yq
	rename plant_id_L1 	poached_plant
	rename cpf		poached_mgr
	
	save "output/data/PoachingEvents_Quarterly_RS", replace
	
	
		
	
	
	
	
	
	
	
	
	
	
	
	
	
