// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 7
// "Raided workers are, on average, of higher ability than non-raided workers" 

*--------------------------*
* PREPARE
*--------------------------*

/*

// using all workers in destination plants in t=0

	// combining all cohorts for this analysis
	
	foreach e in spv emp dir { // emp dir
					
	cap rm "${temp}/quality_dest_hire_`e'.dta"
		
	forvalues ym=612/683 { // events from 2011m1 through 2016m12

		clear
		
		// append each ym to this dataset
		// this is a worker level dataset
		cap use "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", clear
		
		// use if there are poaching events in that date
		if _N >= 1 {
		
			// sample restrictions
			merge m:1 event_id using "${data}/sample_selection_`e'", keep(match) nogen
			
			// adding event type variables
			// evt_type_m: identifying event types (using destination occupation)
			merge m:1 event_id using "${data}/evt_type_m_`e'", keep(match) nogen
			
			// keep t=0 only
			keep if ym == `ym'
			
			// save appended dataset
			cap append using "${temp}/quality_dest_hire_`e'"
			save "${temp}/quality_dest_hire_`e'", replace
		
		}
	}
	}
	
	clear
	
*/	
	
// "spv --> spv" events
		
	use "${temp}/quality_dest_hire_spv", clear
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	rename spv supervisor
	gen spv = 1

	save "${temp}/pred7_spv_spv", replace
	
// "spv --> emp" events
		
	use "${temp}/quality_dest_hire_spv", clear
	
	// keep only people that became spv
	keep if type_emp == 1
	
	// generating identifier
	rename spv supervisor
	gen spv = 2

	save "${temp}/pred7_spv_emp", replace	
	
// "emp --> spv" events	

	use "${temp}/quality_dest_hire_emp", clear
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	rename spv supervisor
	gen spv = 3

	save "${temp}/pred7_emp_spv", replace
		
// combining events and keeping what we need

	use "${temp}/pred7_spv_spv", clear
	append using "${temp}/pred7_spv_emp"
	append using "${temp}/pred7_emp_spv"
	
	merge m:1 spv event_id using "${temp}/eventlist_noreclass", keep(match)
	
	// identifying who was hired as an employee
	
		// set hiring date
		gen hire_ym = ym(hire_year, hire_month) 
				
		// identify hiring events (non-raided)
		gen hire = ((ym == hire_ym) & (hire_ym != .)) /// hired in the month
			& (type_of_hire == 2) /// type was 'readmissão'
			& (pc_individual == 0 & raid_individual == 0) /// not a poached or raided individual
			& (dir == 0 & supervisor == 0) // is an employee
				  
	// variables summarizing the two groups
	
	gen group = .
	replace group = 1 if raid_individual == 1 & (supervisor == 0 & dir == 0)
	replace group = 2 if hire == 1
	label define group_l 1 "Raided new hires" 2 "Non-raided new hires", replace
	label values group group_l
	
	tab group
			
	// figure: worker quality (winsorize top and bottom .1%)
	
		winsor fe_worker, gen(fe_worker_winsor) p(0.001)

		distplot fe_worker_winsor, over(group) xtitle("Worker ability") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(solid dash) lwidth(medthick medthick)  ///
		legend(order(2 1) region(lstyle(none)))
			
			graph export "${results}/quality_dest_hire_winsor_noreclass.pdf", as(pdf) replace
		
		// note: bwidth = .09 is ~1.5 times the default bandwidth
		twoway kdensity fe_worker_winsor if group == 1, lcolor(black) bwidth(.09) lpattern(solid) lwidth(medthick)  || ///
		kdensity fe_worker_winsor if group == 2, lcolor(black) lpattern(dash) bwidth(.09) lwidth(medthick) ///
		xtitle("Worker ability") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		legend(order(2 "Raided new hires" 1 "Non-raided new hires") region(lstyle(none)))
			
			graph export "${results}/quality_dest_hire_winsor_pdf_noreclass.pdf", as(pdf) replace
	
	
	
	
	
	
	
	
	
	
	
