// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Generate plot of cumulative probability of quality of raided and non-raided new hires	
	
*--------------------------*
* BUILD
*--------------------------*

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
	
	// creating an identifier for the event combinations
	
		use "${temp}/quality_dest_hire_spv", clear
		gen evtcomb = .
		replace evtcomb = 1 if type_spv == 1
		replace evtcomb = 2 if type_dir == 1
		replace evtcomb = 3 if type_emp == 1
		gen type_n = type_spv + type_dir + type_emp 
		replace evtcomb = . if type_n > 1
		save "${temp}/quality_dest_hire_spv", replace
		
		use "${temp}/quality_dest_hire_dir", clear
		gen evtcomb = .
		replace evtcomb = 4 if type_spv == 1
		replace evtcomb = 5 if type_dir == 1
		replace evtcomb = 6 if type_emp == 1
		gen type_n = type_spv + type_dir + type_emp 
		replace evtcomb = . if type_n > 1
		save "${temp}/quality_dest_hire_dir", replace
		
		use "${temp}/quality_dest_hire_emp", clear
		gen evtcomb = .
		replace evtcomb = 7 if type_spv == 1
		replace evtcomb = 8 if type_dir == 1
		replace evtcomb = 9 if type_emp == 1
		gen type_n = type_spv + type_dir + type_emp 
		replace evtcomb = . if type_n > 1
		save "${temp}/quality_dest_hire_emp", replace
		
	// appending everything	
		
	use "${temp}/quality_dest_hire_spv", clear // this  is all we need for the set of baseline events
	append using "${temp}/quality_dest_hire_dir"
	append using "${temp}/quality_dest_hire_emp"
	
		// labeling the variable identifying event combinations
		label define evtcomb_l 1 "spv-spv" 2 "spv-dir" 3 "spv-emp" 4 "dir-spv" 5 "dir-dir" 6 "dir-emp" 7 "emp-spv" 8 "emp-dir" 9 "emp-emp"
		label values evtcomb evtcomb_l
	
	save "${temp}/quality_dest_hire", replace
	

*--------------------------*
* ANALYSIS (FOCUSING ON SPV-SPV EVENTS) !!!!!!!!!!!!!!
*--------------------------*

// EXHIBIT: RAIDED NEW HIRES VS. NON-RAIDED NEW HIRES (CDF)

	use "${temp}/quality_dest_hire", clear
	keep if evtcomb == 1 // baseline event: spv-spv
	
	// identifying who was hired as an employee
	
		// set hiring date
		gen hire_ym = ym(hire_year, hire_month) 
				
		// identify hiring events (non-raided)
		gen hire = ((ym == hire_ym) & (hire_ym != .)) /// hired in the month
			& (type_of_hire == 2) /// type was 'readmissão'
			& (pc_individual == 0 & raid_individual == 0) /// not a poached or raided individual
			& (dir == 0 & spv == 0) // is an employee
				  
	// variables summarizing the two groups
	
	gen group = .
	replace group = 1 if raid_individual == 1 & (spv == 0 & dir == 0)
	replace group = 2 if hire == 1
	label define group_l 1 "Raided new hires" 2 "Non-raided new hires", replace
	label values group group_l
	
	// figure: worker quality
	
		ksmirnov fe_worker, by(group)
		
		distplot fe_worker, over(group) xtitle("Worker ability") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(emerald maroon) lpattern(solid dash) ///
		legend(region(lstyle(none)))
				
			graph export "${results}/quality_dest_hire.pdf", as(pdf) replace
			graph export "${results}/quality_dest_hire.png", as(png) replace
			
	// figure: worker quality (winsorize top and bottom 1%)
	
		winsor fe_worker, gen(fe_worker_winsor) p(0.01)

		ksmirnov fe_worker_winsor, by(group)

		distplot fe_worker_winsor, over(group) xtitle("Worker ability") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(solid dash) lwidth(medthick medthick)  ///
		legend(order(2 1) region(lstyle(none)))
			
			graph export "${results}/quality_dest_hire_winsor.pdf", as(pdf) replace
			graph export "${results}/quality_dest_hire_winsor.png", as(png) replace

			
	// figure: wage (winsorize top and bottom 1%)
	
		winsor wage_real_ln, gen(wage_real_ln_winsor) p(0.01)

		histogram wage_real_ln, frequency
		histogram wage_real_ln_winsor, frequency

		ksmirnov wage_real_ln_winsor, by(group)
	
		distplot wage_real_ln_winsor, over(group) xtitle("Ln wage (2008 R$)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(emerald maroon) lpattern(solid dash) ///
		legend(region(lstyle(none)))
   
			graph export "${results}/wage_dest_hire_winsor.pdf", as(pdf) replace
			graph export "${results}/wage_dest_hire_winsor.png", as(png) replace
				
	// figures residualizing experience
	
		gen exp = age - educ_years - 6
		
		// residualizing wages
		reg wage_real_ln_winsor exp
		predict wage_pred, residuals
		summ wage_real_ln if e(sample) == 1
		replace wage_pred = wage_pred + `r(mean)'
		
		
		distplot wage_pred, over(group) xtitle("Ln wage (2008 R$)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(emerald maroon) lpattern(solid dash) ///
		legend(region(lstyle(none)))
   
			graph export "${results}/wagepred_dest_hire_winsor.pdf", as(pdf) replace
			graph export "${results}/wagepred_dest_hire_winsor.png", as(png) replace	

// EXHIBIT: POACHED MANAGERS VS. EXISTING MANAGERS (CDF)

	use "${temp}/quality_dest_hire", clear
	keep if evtcomb == 1 // baseline event: spv-spv

	// variable summarizing the two groups
		
	gen group = .
	replace group = 1 if spv == 1 & pc_individual == 1
	replace group = 2 if spv == 1 & pc_individual == 0
	label define group_l 1 "Poached Managers" 2 "Existing Managers", replace
	label values group group_l
	
	tab group

	// figure: worker quality (winsorize top and bottom 1%)
		
		winsor fe_worker, gen(fe_worker_winsor) p(0.01)

		ksmirnov fe_worker_winsor, by(group)

		distplot fe_worker_winsor, over(group) xtitle("Worker ability") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(emerald maroon) lpattern(solid dash) ///
		legend(region(lstyle(none)))
			
			graph export "${results}/quality_dest_mgr_winsor.pdf", as(pdf) replace
			graph export "${results}/quality_dest_mgr_winsor.png", as(png) replace

	// figure: wage (winsorize top and bottom 1%)
	
		winsor wage_real_ln, gen(wage_real_ln_winsor) p(0.01)

		ksmirnov wage_real_ln_winsor, by(group)
	
		distplot wage_real_ln_winsor, over(group) xtitle("Ln salary (2008 R$)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(solid dash) lwidth(medthick medthick) ///
		legend(order(2 1) region(lstyle(none)))
		
			graph export "${results}/wage_dest_mgr_winsor.pdf", as(pdf) replace
			graph export "${results}/wage_dest_mgr_winsor.png", as(png) replace
					
	// figures residualizing experience
	
		gen exp = age - educ_years - 6
		
		// residualizing wages
		reg wage_real_ln_winsor exp
		predict wage_pred, residuals
		summ wage_real_ln if e(sample) == 1
		replace wage_pred = wage_pred + `r(mean)'
	
		distplot wage_pred, over(group) xtitle("Ln salary (2008 R$)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(emerald maroon) lpattern(solid dash) ///
		legend(region(lstyle(none)))
   
			graph export "${results}/wagepred_dest_mgr_winsor.pdf", as(pdf) replace
			graph export "${results}/wagepred_dest_mgr_winsor.png", as(png) replace	

// EXHIBIT: POACHED MANAGERS VS. NEW MANAGERS HIRES (CDF)

	use "${temp}/quality_dest_hire", clear
	keep if evtcomb == 1 // baseline event: spv-spv
	
	// identifying who was hired as a manager
	
		// set hiring date
		gen hire_ym = ym(hire_year, hire_month) 
				
		// identify hiring events (non-raided)
		gen hire = ((ym == hire_ym) & (hire_ym != .)) /// hired in the month
			& (type_of_hire == 2) /// type was 'readmissão'
			& (pc_individual == 0 & raid_individual == 0) /// not a poached or raided individual
			& (spv == 1) // is a manager
				  
	// variables summarizing the two groups
	
	gen group = .
	replace group = 1 if spv == 1 & pc_individual == 1
	replace group = 2 if hire == 1
	label define group_l 1 "Poached managers" 2 "Non-poached new managers", replace
	label values group group_l
	
	tab group

	// figure: worker quality (winsorize top and bottom 1%)
		
		winsor fe_worker, gen(fe_worker_winsor) p(0.01)

		ksmirnov fe_worker_winsor, by(group)

		distplot fe_worker_winsor, over(group) xtitle("Worker ability") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(emerald maroon) lpattern(solid dash) ///
		legend(region(lstyle(none)))
			
			graph export "${results}/quality_dest_hire_mgr_winsor.pdf", as(pdf) replace
			graph export "${results}/quality_dest_hire_mgr_winsor.png", as(png) replace

	// figure: wage (winsorize top and bottom 1%)
	
		winsor wage_real_ln, gen(wage_real_ln_winsor) p(0.01)

		ksmirnov wage_real_ln_winsor, by(group)
	
		distplot wage_real_ln_winsor, over(group) xtitle("Ln salary (2008 R$)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(solid dash) lwidth(medthick medthick) ///
		legend(order(2 1) region(lstyle(none)))
   
			graph export "${results}/wage_dest_hire_mgr_w.pdf", as(pdf) replace
			graph export "${results}/wage_dest_hire_mgr_w.png", as(png) replace
			
	// figures residualizing experience
	
		gen exp = age - educ_years - 6
		
		// residualizing wages
		reg wage_real_ln_winsor exp
		predict wage_pred, residuals
		summ wage_real_ln if e(sample) == 1
		replace wage_pred = wage_pred + `r(mean)'
		
		
		distplot wage_pred, over(group) xtitle("Ln salary (2008 R$)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(emerald maroon) lpattern(solid dash) ///
		legend(region(lstyle(none)))
   
			graph export "${results}/wagepred_dest_hire_mgr_winsor.pdf", as(pdf) replace
			graph export "${results}/wagepred_dest_hire_mgr_winsor.png", as(png) replace		
			
	
