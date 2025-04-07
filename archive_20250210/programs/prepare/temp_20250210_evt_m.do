// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2024

// Purpose: Identifying poached managers (poaching events)

*--------------------------*
* BUILD
*--------------------------*			

// I. identifying all poaching events

forvalues ym=528/683 {
	
clear	

	// opening the main month (t=0) and appending the other required data sets (t=-12,-1,12)
	
	local ym_l12=`ym'-12
	local ym_l1 =`ym'-1
	local ym_f12=`ym'+12
	
	append using "${data}/rais_m/rais_m`ym_l12'"
	append using "${data}/rais_m/rais_m`ym_l1'"
	append using "${data}/rais_m/rais_m`ym'"
	append using "${data}/rais_m/rais_m`ym_f12'"

	// setting as a panel
	tsset cpf ym

	// list of criteria

		// 1. worker is employed in an establishment with at least 45 employees in t-1
		gen criteria1 = (L.n_emp >= 45 & L.n_emp < .) & ym==`ym'
		
		// 2. worker is employed in the same establishment in t-12 and t-1
		gen criteria2 = ((L.plant_id == L12.plant_id) & (L.plant_id != .) & (L12.plant_id != .))   & ym==`ym' 
		
		// 3. worker is employed in a different establishment in t
		gen criteria3 = ((plant_id != L.plant_id) & (plant_id != .) & (L.plant_id != .))  & ym==`ym' 
		
		// 4. worker is employed in a different firm in t
		gen criteria4 = ((firm_id != L.firm_id) & (firm_id != .) & (L.firm_id != .)) & ym==`ym'
		
		// 5. worker is employed in a establishment with at least 45 employees in t
		gen criteria5 = (n_emp >= 45 & n_emp < .)  & ym==`ym'
		
		// 6. worker must be separated from the old establishment in t
		
			gen sep = (cause_of_sep == 10 | cause_of_sep == 11 | cause_of_sep == 12 | ///
				cause_of_sep == 20 | cause_of_sep == 21) 

			gen sep_ym = ym(year, sep_month)					
			
		gen criteria6 = ((ym == L.sep_ym) & (L.sep_ym != .) & (L.sep == 1))  & ym==`ym'

		// 7. worker must be hired by the new establishment in t

			gen hire = (type_of_hire == 2)
			
			gen hire_ym = ym(hire_year, hire_month)
			
		gen criteria7 = ((ym == hire_ym) & (hire_ym != .) & (hire == 1))  & ym==`ym'
		
		// 8. worker is employed in non-gov establishment in t-1 and t
		gen criteria8 = ((L.gov == 0 & gov == 0) & (L.plant_id != .) & (plant_id != .))  & ym==`ym' 
		
		// 9. worker is still employed in the new establishment in t+12
		gen criteria9 = ((plant_id == F12.plant_id) & (plant_id != .) & (F12.plant_id != .))  & ym==`ym' 

	// event types:
	
	// director (1xx) is poached
	gen pc_dir = (L.dir == 1 & criteria1 == 1 & criteria2 == 1 & criteria3 == 1 & criteria4 == 1 & ///
		criteria5 == 1 & criteria6 == 1 & criteria7 == 1 & criteria8 == 1 & criteria9 == 1)
		
	// director (1xx | top 5%) is poached
	gen pc_dir5 = (L.dir5 == 1 & criteria1 == 1 & criteria2 == 1 & criteria3 == 1 & criteria4 == 1 & ///
		criteria5 == 1 & criteria6 == 1 & criteria7 == 1 & criteria8 == 1 & criteria9 == 1)
		
	// supervisor (xx0) is poached
	gen pc_spv = (L.spv == 1 & criteria1 == 1 & criteria2 == 1 & criteria3 == 1 & criteria4 == 1 & ///
		criteria5 == 1 & criteria6 == 1 & criteria7 == 1 & criteria8 == 1 & criteria9 == 1)
		
	// employee (L.dir == 0 & L.spv == 0) is poached	
	gen pc_emp = (L.dir == 0 & L.spv == 0 & criteria1 == 1 & criteria2 == 1 & criteria3 == 1 & ///
		criteria4 == 1 & criteria5 == 1 & criteria6 == 1 & criteria7 == 1 & criteria8 == 1 & criteria9 == 1)
	
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
	
	save "${data}/evt_m/evt_m_`ym'", replace
	
}

// II. dealing with overlapping events	
	
	// dir, dir5, spv, and emp will be treated independently
	
	foreach e in dir dir5 spv emp {
		
		clear
	
		forvalues ym=528/683 {
			
			append using "${data}/evt_m/evt_m_`ym'"
		
		}
	
		keep if pc_`e' == 1
	
		// DEALING WITH MULTIPLE PERIODS
		
		// monthly panel goes from 2003 to 2017
		// and we can identify events from 2004m1 (528) to 2016m12 (683)
		// since we require 25 months between events, we can identify at most 7 events
		// e.g., in months 528, 553, 578, 603, 628, 653, 678			
	
		forvalues evtn=1/7 {
			
			if `evtn' == 1 {
			
				// identify the event number `evtn'
				egen pc_ym_`evtn' = min(pc_ym), by(d_plant)
				
				// calculate distance to event number `evtn'
				gen dist_`evtn' = pc_ym - pc_ym_`evtn'
				
				// keep only the event itself or events 25 or more months away
				// this way, a 12-month window on both sides of the event is clean from other events
				keep if dist_`evtn' == 0 | dist_`evtn' >= 25
			
			}
			
			else {
				
				local evtprev = `evtn' - 1
				
				// identify the event number `evtn'
				egen pc_ym_`evtn' = min(pc_ym) if pc_ym > pc_ym_`evtprev', by(d_plant)
				
				// calculate distance to event number `evtn'
				gen dist_`evtn' = pc_ym - pc_ym_`evtn'
				
				// keep only the previous events, the event itself ot events 25 or more months away
				// this way, a 12-month window on both side of the event is clean from other events
				keep if dist_`evtn' == . | dist_`evtn' == 0 | dist_`evtn' > = 25
				
				
			} 		
		} 
			
	// DEALING WITH MULTIPLE POACHES IN THE SAME MONTH
	
		// from the perspective of the destination firm:
		// if a destination firm is poaching more than 1 worker: select just one
	
		egen unique = tag(d_plant pc_ym o_plant)
		egen n_origin = sum(unique), by(d_plant pc_ym)
		tab n_origin
		
		sort d_plant pc_ym o_plant
		by d_plant pc_ym: keep if _n == 1
		
		drop unique n_origin
		
		// from the perspective of the origin firm:
		// if workers are poached by more than one destination firm: select just one
		
		egen unique = tag(o_plant pc_ym d_plant)
		egen n_destination = sum(unique), by(o_plant pc_ym)
		tab n_destination
		
		sort o_plant pc_ym d_plant
		by o_plant pc_ym: keep if _n == 1
		
		drop unique n_destination
	
	drop pc_ym_* dist_*
	
	// creating an event identifier
	
	egen event_id = group(d_plant pc_ym)
	order event_id d_plant pc_ym o_plant pc_cpf
	
	// organizing
		
	keep event_id d_plant pc_ym o_plant pc_cpf pc_`e'
	
	save "${data}/evt_m_`e'", replace
	
	}
	
	use "${data}/evt_m_dir", clear // 22,123 events
	use "${data}/evt_m_dir5", clear // 52,799 events
	use "${data}/evt_m_spv", clear // 28,193 events
	use "${data}/evt_m_emp", clear // 181,177 events
	
// III. additional criteria: no joint movements

	// current criteria requires that individuals have moved to another establishment and another firm
	
	forvalues y=2004/2016 {
	
		use "${JointMovements}/JointMovements_`y'", clear
		
		// we might be capturing some movements across firms
		keep if joint_acrossfirm == 1
		
		// keepinh what we need
		keep plant_id joint_acrossfirm
		gen year = `y'
		destring plant_id, force replace
		format plant_id %14.0f
		
		save "${temp}/JointMovements_`y'", replace
		
	}
	
	clear
	
	forvalues y=2004/2016 {
		
		append using "${temp}/JointMovements_`y'"
		
	}
	
	save "${temp}/JointMovements", replace
	
	// merging with the data sets we currently have
	
	foreach evt in dir dir5 spv emp {	
		
		use "${data}/evt_m_`evt'", clear
	
		rename o_plant plant_id
		gen year = year(dofm(pc_ym))
		
		merge m:1 plant_id year using "${temp}/JointMovements"
		drop if _merge == 2
		drop _merge
		
		replace joint_acrossfirm = 0 if joint_acrossfirm == .
	
		rename plant_id o_plant
		
		// saving the list of events that we want to keep here
		
		keep if joint_acrossfirm == 0
		keep event_id
		
		// create new event id, incorporating event type_of_hire
		tostring event_id, replace format(%09.0f)
		gen evtid = "`evt'" + "_" + event_id
		
		save "${temp}/evt_m_`evt'_nojoint", replace
		
	}
	
	clear
	
	foreach evt in dir dir5 spv emp {
		
		append using "${temp}/evt_m_`evt'_nojoint"
		
	}
	
	drop event_id
	save "${temp}/evt_m_nojoint", replace
	
		

*--------------------------*
* EXIT
*--------------------------*	

clear	

	
