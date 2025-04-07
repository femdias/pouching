// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: Aprul 2024

// Purpose: Identifying poached managers (poaching events)

*--------------------------*
* BUILD
*--------------------------*

use "output/data/RAIS_Quarterly_RS", clear

	// list of criteria

		// 1. worker is a manager in t-1
		gen criteria1 = (L.occ_gr_o == 1) // 3.2M
		
		// 2. worker is employed in a firm with at least 50 employees in t-1
		gen criteria2 = (L.n_emp >= 50 & L.n_emp < .) // 28.3M
		
		// 3. worker is employed in the same firm in t-4 and t-1
		gen criteria3 = ((L.plant_id == L4.plant_id) & (L.plant_id != .) & (L4.plant_id != .)) // 31.2M
		
		// 4. worker is employed in a different firm in t
		gen criteria4 = ((plant_id != L.plant_id) & (plant_id != .) & (L.plant_id != .)) // 1.2M
		
		// 5. worker is employed in a firm with at least 50 employees in t
		gen criteria5 = (n_emp >= 50 & n_emp < .) // 29.6M
		
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
	gen poached_mgr = (criteria1 == 1 & criteria2 == 1 & criteria3 == 1 & criteria4 == 1 & ///
		criteria5 == 1 & criteria6 == 1 & criteria7 == 1 & criteria8 == 1)
		
		/*
		
		// why so few events
		
		gen poached_mgr_test = criteria1
		*tab poached_mgr_test // 3.2M
		
		replace poached_mgr_test = 0 if criteria2 == 0
		*tab poached_mgr_test // 2.0M
		
		replace poached_mgr_test = 0 if criteria3 == 0
		*tab poached_mgr_test // 1.4M
		
		replace poached_mgr_test = 0 if criteria4 == 0
		*tab poached_mgr_test // 33.8K
		
		replace poached_mgr_test = 0 if criteria5 == 0
		*tab poached_mgr_test // 28.3K
		
		replace poached_mgr_test = 0 if criteria6 == 0
		*tab poached_mgr_test // 3.0K
		
		replace poached_mgr_test = 0 if criteria7 == 0
		*tab poached_mgr_test // 2.1K
		
		replace poached_mgr_test = 0 if criteria8 == 0
		*tab poached_mgr_test // 1.5K
		
		*/
	
	// heterogeneity: poaching a director vs. poaching a supervisor
	
		gen director = (occ_gr_o == 1 & occ_1d == 1)
		
		gen poached_director = (poached_mgr == 1 & L.director == 1)
	
	// organizing the data set and keeping the information that we need
	
	gen double plant_id_L1 = L.plant_id
	format plant_id_L1 %14.0f
	
	keep if poached_mgr == 1
	
	keep cpf yq plant_id plant_id_L1 poached_mgr poached_director criteria*	
	
	// how many workers are poached more than once?
	
	duplicates tag cpf, gen(dupli)
	tab dupli // 52, i.e., 3.5%
	
		// excluding these workers
		drop if dupli != 0
		drop dupli
		
	// saving
	order cpf yq plant_id plant_id_L1 poached_mgr poached_director
	save "output/data/PoachedManagers_Quarterly_RS", replace
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
