// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2024

// Purpose: Identifying poached managers (poaching events)

*--------------------------*
* BUILD
*--------------------------*			

// I. identifying all poaching events 

foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 { // note: we can't identify m1 poaching events yet
	
	local ym_l12=`ym'-12
	local ym_l1 =`ym'-1
	local ym_f12=`ym'+12
	
	// appending plant size data sets, which we will use below
	
	clear
	
	append using "${data}/plantsize_m/plantsize_m`ym_l12'"
	append using "${data}/plantsize_m/plantsize_m`ym_l1'"
	append using "${data}/plantsize_m/plantsize_m`ym'"
	append using "${data}/plantsize_m/plantsize_m`ym_f12'"
	
	save "${temp}/plantsize_m", replace
	
	// opening the main month (t=0) and appending the other required data sets (t=-12,-1,12)
	
	clear
	
	append using "${data}/rais_m/rais_m`ym_l12'"
	append using "${data}/rais_m/rais_m`ym_l1'"
	append using "${data}/rais_m/rais_m`ym'"
	append using "${data}/rais_m/rais_m`ym_f12'"
	
	// merging with lagged plant size variable
	merge m:1 plant_id ym using "${temp}/plantsize_m", keepusing(n_emp_lavg)
	drop _merge
	
	// setting as a panel
	tsset cpf ym
	
	// list of criteria

		// 1. worker is employed in an establishment with, on average, at least 20 employees before the poaching event
		gen criteria1 = (L.n_emp_lavg >= 20 & L.n_emp_lavg < .) & ym==`ym'
		egen criteria1_cpf = max(criteria1), by(cpf)
		keep if criteria1_cpf == 1
		drop criteria1_cpf
		
		// 2. worker is employed in the same establishment in t-12 and t-1
		gen criteria2 = ((L.plant_id == L12.plant_id) & (L.plant_id != .) & (L12.plant_id != .))   & ym==`ym'
		egen criteria2_cpf = max(criteria2), by(cpf)
		keep if criteria2_cpf == 1
		drop criteria2_cpf
		
		// 3. worker is employed in a different establishment in t
		gen criteria3 = ((plant_id != L.plant_id) & (plant_id != .) & (L.plant_id != .))  & ym==`ym'
		egen criteria3_cpf = max(criteria3), by(cpf)
		keep if criteria3_cpf == 1
		drop criteria3_cpf
		
		// 4. worker is employed in a different firm in t
		gen criteria4 = ((firm_id != L.firm_id) & (firm_id != .) & (L.firm_id != .)) & ym==`ym'
		egen criteria4_cpf = max(criteria4), by(cpf)
		keep if criteria4_cpf == 1
		drop criteria4_cpf
		
		// 5. worker is employed in a establishment with, on average, at least 20 employees before the poaching event
		gen criteria5 = (n_emp_lavg >= 20 & n_emp_lavg < .)  & ym==`ym'
		egen criteria5_cpf = max(criteria5), by(cpf)
		keep if criteria5_cpf == 1
		drop criteria5_cpf
		
		// 6. worker must be separated from the old establishment in t
		
			// identifying separations of interest
			gen sep = (cause_of_sep == 10 | /// 10: Rescisão com justa causa por iniciativa do empregador ou servidor demitido
				   cause_of_sep == 11 | /// 11: Rescisão sem justa causa por iniciativa do empregador
				   cause_of_sep == 12 | /// 12: Término do contrato de trabalho
				   cause_of_sep == 20 | /// 20: Rescisão com justa causa por iniciativa do empregado (rescisão indireta)
				   cause_of_sep == 21)  //  21: Rescisão sem justa causa por iniciativa do empregado ou exoneração a pedido
			
			// identifying separation month 
			gen sep_ym = ym(year, sep_month)					
			
		gen criteria6 = ((ym == L.sep_ym) & (L.sep_ym != .) & (L.sep == 1))  & ym==`ym'
		egen criteria6_cpf = max(criteria6), by(cpf)
		keep if criteria6_cpf == 1
		drop criteria6_cpf

		// 7. worker must be hired by the new establishment in t

			// identifying hirings of interest
			gen hire = (type_of_hire == 2) // 2: Reemprego
			
			// identifying hiring month
			gen hire_ym = ym(hire_year, hire_month)
			
		gen criteria7 = ((ym == hire_ym) & (hire_ym != .) & (hire == 1))  & ym==`ym'
		egen criteria7_cpf = max(criteria7), by(cpf)
		keep if criteria7_cpf == 1
		drop criteria7_cpf
		
		// 8. worker is employed in non-gov establishment in t-1 and t
		gen criteria8 = ((L.gov == 0 & gov == 0) & (L.plant_id != .) & (plant_id != .))  & ym==`ym'
		egen criteria8_cpf = max(criteria8), by(cpf)
		keep if criteria8_cpf == 1
		drop criteria8_cpf
		
		// 9. worker is still employed in the new establishment in t+12
		gen criteria9 = ((plant_id == F12.plant_id) & (plant_id != .) & (F12.plant_id != .))  & ym==`ym'
		egen criteria9_cpf = max(criteria9), by(cpf)
		keep if criteria9_cpf == 1
		drop criteria9_cpf		
	
		// 10. origin firm is not going through a "joint movement" event
		
			// merge with joint movements data set
			merge m:1 plant_id year using "${data}/jointmvt"
			drop if _merge == 2
			drop _merge
			replace joint_acrossfirm = 0 if joint_acrossfirm == .
			
			// reset the data set as a panel
			tsset cpf ym
			
		gen criteria10 = (L.joint_acrossfirm == 0) & ym==`ym'
		egen criteria10_cpf = max(criteria10), by(cpf)
		keep if criteria10_cpf == 1
		drop criteria10_cpf
	
		// 11. destination plant has positve employment in all months between t-12 and t+12	
		
			// merge with positive employment dummy
			merge m:1 plant_id ym using "${data}/posemp_m/posemp_m`ym'", keepusing(posemp)
			drop if _merge == 2
			drop _merge
			
			// reset the data set as a panel
			tsset cpf ym
			
		gen criteria11 = (posemp == 1) & ym==`ym'
		egen criteria11_cpf = max(criteria11), by(cpf)
		keep if criteria11_cpf == 1
		drop criteria11_cpf
		
		// this identifies the poaching events in `ym'
	
	// event types:
	
	// origin:
	
		// director (1xx) is poached
		gen pc_dir = (L.dir == 1) & ym==`ym'
			
		// director (1xx | top 5%) is poached
		gen pc_dir5 = (L.dir5 == 1) & ym==`ym'
			
		// supervisor (xx0) is poached
		gen pc_spv = (L.spv == 1) & ym==`ym'
			
		// employee (L.dir == 0 & L.spv == 0) is poached	
		gen pc_emp = (L.dir == 0 & L.spv == 0) & ym==`ym'
		
	// destination	
		
		// director (1xx) is poached
		gen pc_d_dir = (dir == 1) & ym==`ym'
			
		// director (1xx | top 5%) is poached
		gen pc_d_dir5 = (dir5 == 1) & ym==`ym'
			
		// supervisor (xx0) is poached
		gen pc_d_spv = (spv == 1) & ym==`ym'
			
		// employee (L.dir == 0 & L.spv == 0) is poached	
		gen pc_d_emp = (dir == 0 & spv == 0) & ym==`ym'
		
	// organizing the data set and keeping the information that we need
	
	gen double o_plant = L.plant_id
	format o_plant %14.0f
	
	gen d_n_emp_lavg = n_emp_lavg
	gen o_n_emp_lavg = L.n_emp_lavg
	
	keep if ym==`ym'
	
	rename plant_id d_plant
	rename ym pc_ym
	rename cpf pc_cpf

	keep pc_cpf pc_ym d_plant o_plant pc_dir pc_dir5 pc_spv pc_emp pc_d_dir ///
		pc_d_dir5 pc_d_spv pc_d_emp ///
		d_n_emp_lavg o_n_emp_lavg
		
	sort d_plant pc_ym
	order d_plant o_plant pc_ym
		
	save "${temp}/202503_evt_m_`ym'", replace
	
}

	// combining all cohorts
	
	clear

	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
	
		append using "${temp}/202503_evt_m_`ym'"
	
	}
	
	save "${data}/202503_evt_m", replace
	
	
// II. dealing with multiple poaching events in the same month and same origin/destination	
	
	use "${data}/202503_evt_m", clear
	
	// keeping the data set at the level where we will evaluate duplicates
	keep o_plant d_plant pc_ym
	egen unique = tag(o_plant d_plant pc_ym)
	keep if unique == 1
	drop unique
	
	// from the perspective of the origin firm:
	// if an origin firm is having its workers poached by more than 1 destination firm, select just one destination
	
		egen unique = tag(o_plant pc_ym d_plant)
		egen n_dest = sum(unique), by(o_plant pc_ym)
		tab n_dest
		
			// listing cases with n_dest > 1 so that I can identify these later
			
			preserve
			
				keep if n_dest > 1
				duplicates drop o_plant pc_ym, force
				keep o_plant pc_ym
				
				save "${temp}/o_plant_multiple", replace
				
			restore
		
		bysort o_plant pc_ym: keep if _n == 1
		
		drop unique n_dest
		
	// from the perspective of the destination firm:
	// if a destination firm is poaching workers from more than 1 origin firm, select just one origin
	
		egen unique = tag(d_plant pc_ym o_plant)
		egen n_orig = sum(unique), by(d_plant pc_ym)
		tab n_orig
		
			// listing cases with n_orig > 1 so that I can identify these later
			
			preserve
			
				keep if n_orig > 1
				duplicates drop d_plant pc_ym, force
				keep d_plant pc_ym
				
				save "${temp}/d_plant_multiple", replace
				
			restore				
		
		sort d_plant pc_ym o_plant
		by d_plant pc_ym: keep if _n == 1
		
		drop unique n_orig

	// creating event IDs
	// note1: an event is characterized by an origin-destination-cohort combination
	// note2: both o_plant-pc_ym and d_plant-pc_ym pairs also identify events
	egen eventid = group(o_plant d_plant pc_ym)
	order eventid o_plant d_plant pc_ym
	sort eventid
	isid o_plant pc_ym 
	isid d_plant pc_ym
	
	// this is the list of events and their ids
	save "${temp}/eventid", replace
		
	// now, merging this back with the complete list of poaching events
	
	use "${data}/202503_evt_m", clear
	merge m:1 o_plant d_plant pc_ym using "${temp}/eventid"
	keep if _merge == 3
	drop _merge
	
		// identifying the cases where some multiple origin/destination was identified
		
		gen multiple = 0
		
		merge m:1 o_plant pc_ym using "${temp}/o_plant_multiple"
		replace multiple = 1 if _merge == 3
		drop _merge
		
		merge m:1 d_plant pc_ym using "${temp}/d_plant_multiple"
		replace multiple = 1 if _merge == 3
		drop _merge
		
	order eventid o_plant d_plant pc_ym
	sort eventid
		
	save "${data}/202503_evt_m", replace	
	
*--------------------------*
* EXIT
*--------------------------*	

clear

foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
	
	rm "${temp}/2503_evt_m_`ym'.dta"
	
}









********************************************************************************
/* ARCHIVE

			// how many unique events do we have?
			
				// method 1: max of eventid
				summ eventid, detail // 577,797 events
			
				// method 2: unique eventids
				egen unique = tag(eventid)
				tab unique // 577,797
				drop unique
				
				// method 3: unique origin-destination
				egen unique = tag(o_plant d_plant pc_ym)
				tab unique // 577,797
				drop unique
		
			// what if we only focus on events with more than 50 employees?
			
				egen unique = tag(eventid)
				tab unique if o_n_emp_lavg >= 50 & d_n_emp_lavg >= 50 // 405,866 events
				drop unique
		

	
	use "${data}/evt_m/new_evt_m_620", clear
		
		// are there duplicates in d_plant o_plant pairs?
		
		duplicates tag d_plant o_plant, gen(dupli)
		tab dupli //  A LOT OF DUPLICATES!	
