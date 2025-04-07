// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: Aprul 2024

// Purpose: Identifying poached managers (poaching events)

*--------------------------*
* BUILD
*--------------------------*

/*  // need to check var list since data set is different now
use plant_id cpf occ_gr_o occ_1d occ_3d mgr_top5 n_emp cause_of_sep sep_month year yq type_of_hire hire_month hire_year gov using "output/data/rais_monthly_rs", clear
*/

use "output/data/rais_m_rs", clear	

	// list of criteria

		// 1. worker is employed in a firm with at least 45 employees in t-1
		gen criteria1 = (L.n_emp >= 45 & L.n_emp < .) // 89.5M
		
		// 2. worker is employed in the same firm in t-12 and t-1
		gen criteria2 = ((L.plant_id == L12.plant_id) & (L.plant_id != .) & (L12.plant_id != .)) // 87.0M
		
		// 3. worker is employed in a different firm in t
		gen criteria3 = ((plant_id != L.plant_id) & (plant_id != .) & (L.plant_id != .)) // 986K
		
		// 4. worker is employed in a firm with at least 45 employees in t
		gen criteria4 = (n_emp >= 45 & n_emp < .) // 90.8M
		
		// 5. worker must be separated from the old firm in t
		
			gen sep = (cause_of_sep == 10 | cause_of_sep == 11 | cause_of_sep == 12 | ///
				cause_of_sep == 20 | cause_of_sep == 21)

			gen sep_ym = ym(year, sep_month)
			
		gen criteria5 = ((ym == L.sep_ym) & (L.sep_ym != .) & (L.sep == 1)) // 4.8M

		// 6. worker must be hired by the new firm in t

			gen hire = (type_of_hire == 2)
			
			gen hire_ym = ym(hire_year, hire_month)
			
		gen criteria6 = ((ym == hire_ym) & (hire_ym != .) & (hire == 1)) // 5.0M
		
		// 7. worker is employed in non-gov firms in t-1 and t
		gen criteria7 = ((L.gov == 0 & gov == 0) & (L.plant_id != .) & (plant_id != .)) // 32.3M
		
	// event types:
	
	// director (1xx) is poached --> 793 events
	gen pc_dir = (L.dir == 1 & criteria1 == 1 & criteria2 == 1 & criteria3 == 1 & criteria4 == 1 & ///
		criteria5 == 1 & criteria6 == 1 & criteria7 == 1)
		
	// director (1xx | top 5%) is poached --> 2,407 events
	gen pc_dir5 = (L.dir5 == 1 & criteria1 == 1 & criteria2 == 1 & criteria3 == 1 & criteria4 == 1 & ///
		criteria5 == 1 & criteria6 == 1 & criteria7 == 1)
		
	// supervisor (xx0) is poached --> 1,251 events
	gen pc_spv = (L.spv == 1 & criteria1 == 1 & criteria2 == 1 & criteria3 == 1 & criteria4 == 1 & ///
		criteria5 == 1 & criteria6 == 1 & criteria7 == 1)
		
	// employee (L.dir == 0 & L.spv == 0) is poached --> 35,054 events	
	gen pc_emp = (L.dir == 0 & L.spv == 0 & criteria1 == 1 & criteria2 == 1 & criteria3 == 1 & ///
		criteria4 == 1 & criteria5 == 1 & criteria6 == 1 & criteria7 == 1)
	
	
			/*
			tab pc_dir
			tab pc_dir5
			tab pc_spv
			tab pc_emp
			
			tab pc_dir pc_spv
			tab pc_dir pc_emp
			tab pc_spv pc_emp
			
			tab pc_dir5 pc_spv
			tab pc_dir5 pc_emp
			*/
	

	// organizing the data set and keeping the information that we need
	
	gen double o_plant = L.plant_id
	format o_plant %14.0f
	
	rename plant_id d_plant
	rename ym pc_ym
	rename cpf pc_cpf
	
	keep if pc_dir == 1 | pc_dir5 == 1 | pc_spv == 1 | pc_emp == 1
	keep pc_cpf pc_ym d_plant o_plant pc_dir pc_dir5 pc_spv pc_emp
		
	sort d_plant pc_ym
	order d_plant pc_ym
	
	save "temp/evt_m_rs_all", replace
	
	// dir, dir5, spv, and emp will be treated independently
	
	foreach e in dir dir5 spv {
	
	use "temp/evt_m_rs_all", clear
	
	keep if pc_`e' == 1
	
	// DEALING WITH MULTIPLE PERIODS
	
		// first event
		
			// identify the first event
			egen pc_ym_first = min(pc_ym), by(d_plant)
			
			// calculate distance to first event
			gen dist_first = pc_ym - pc_ym_first
			
			// keep only the event itself or events 25 or more months away
			// this way, a 12-month window on both sides of the event is clean from other events
			keep if dist_first == 0 | dist_first >= 25
		
		// second event
		
			// identify the second event
			egen pc_ym_second = min(pc_ym) if pc_ym > pc_ym_first, by(d_plant)
		
			// calculate distance to second event
			gen dist_second = pc_ym - pc_ym_second 
			
			// as before, keep only the previous events, the event itself or events 25 or more months away
			keep if dist_second == . | dist_second == 0 | dist_second >= 25
		
		// third event
		
			// identify the third event
			egen pc_ym_third = min(pc_ym) if pc_ym > pc_ym_second, by(d_plant)
		
			// calculate distance to third event
			gen dist_third = pc_ym - pc_ym_third 
			
			// as before, keep only the previous events, the event itself or events 25 or more months away
			keep if dist_third == . | dist_third == 0 | dist_third >= 25
			
		// since the monthly panel goes from 2003 to 2008 and we require 25 months between events,
		// it's not possible to have more than three event	
			
	// DEALING WITH MULTIPLE POACHES IN THE SAME month
	
		// it's OK if origin firm is the same; otherwise let's not consider
	
		egen unique = tag(d_plant pc_ym o_plant)
		egen n_origin = sum(unique), by(d_plant pc_ym)
		drop if n_origin != 1 // 8.14% of the events
	
	drop pc_ym_first dist_first pc_ym_second dist_second pc_ym_third dist_third unique n_origin
	
	// creating an event identifier
	
	egen event_id = group(d_plant pc_ym)
	order event_id d_plant pc_ym o_plant pc_cpf
	
	// organizing
		
	keep event_id d_plant pc_ym o_plant pc_cpf pc_`e'
	
	save "output/data/evt_m_rs_`e'", replace
	
	}
	
	use "output/data/evt_m_rs_dir", clear // 443 events
	use "output/data/evt_m_rs_dir5", clear // 1407 events
	use "output/data/evt_m_rs_spv", clear // 795 events
	
	// for the emp events, we have too many
	// let's focus on those that have the d_plant from the events with dir, dir5, and spv
	
	clear
	
	foreach e in dir dir5 spv {
		
		append using "output/data/evt_m_rs_`e'"
		keep d_plant
		duplicates drop
		
	}
	
	save "temp/evt_plants", replace
	
	// now organizing events where employees are poached
	
	use "temp/evt_m_rs_all", clear
	
	keep if pc_emp == 1

	merge m:1 d_plant using "temp/evt_plants"
	keep if _merge == 3 // 25,395 out of 35,340 events
	drop _merge
	
	// DEALING WITH MULTIPLE PERIODS
	
		// first event
		
			// identify the first event
			
			egen pc_ym_first = min(pc_ym), by(d_plant)
			
			// calculate distance to first event
			gen dist_first = pc_ym - pc_ym_first
			
			// keep only the event itself! (we won't look at the other events here)
			// this way, a 12-month window on both sides of the event is clean from other events
			keep if dist_first == 0
	
	// DEALING WITH MULTIPLE POACHES IN THE SAME MONTH
	
		egen unique = tag(d_plant pc_ym o_plant)
		egen n_origin = sum(unique), by(d_plant pc_ym)
		tab n_origin // would drop too many events
		
		// hence, randomly select 1 event
		
		sort d_plant pc_ym pc_cpf
		by d_plant pc_ym: keep if _n == 1
	
	drop pc_ym_first dist_first unique n_origin
	
	// creating an event identifier
	
	egen event_id = group(d_plant pc_ym)
	order event_id d_plant pc_ym o_plant pc_cpf 
	
	// organizing
	
	keep event_id d_plant pc_ym o_plant pc_cpf pc_emp
	
	save "output/data/evt_m_rs_emp", replace
	
	
	
	
	
	
	
	
	
	
	
	
	
	
