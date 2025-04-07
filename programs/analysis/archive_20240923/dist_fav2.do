// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Is it favoritism? [2]		
	
*--------------------------*
* ANALYSIS
*--------------------------*

// using all workers in destination plants in t=0

	// combining all cohorts for this analysis
	
	/*
	
	cap rm "${temp}/dir_fav2_d.dta"
	
	forvalues ym=612/635 { // PENDING: UPDATE THIS WITH ALL COHORTS!

		clear
		cap use "${data}/dest_panel_m_spv/dest_panel_m_spv_`ym'", clear
		
		if _N >= 1 {
		
			// sample restrictions
			merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
			
			// adding event type variables
			merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
			
			// keep t=0 only
			keep if ym == `ym'
			
			cap append using "${temp}/dir_fav2_d"
			save "${temp}/dir_fav2_d", replace
		
		}
	}
	
	*/
	
	use "${temp}/dir_fav2_d", clear
	
	// organizing more variables
	
		// set hiring date
		gen hire_ym = ym(hire_year, hire_month) 
				
			// identify hiring events 
			gen hire = ((ym == hire_ym) & (hire_ym != .)) /// hired in the month
				   & (type_of_hire == 2) /// type was 'readmissão'
				   & (pc_individual == 0 & raid_individual == 0) /// not a poached or raided individual
				   & (dir == 0 & spv == 0) // is an employee
				   
	// adding real wages variable to this data set
		
		// adjusting wages
				merge m:1 year using "${input}/auxiliary/ipca_brazil"
				generate index_2008 = index if year == 2008
				egen index_base = max(index_2008)
				generate adj_index = index / index_base
				drop if _merge == 2
				drop _merge
				
				generate wage_real = earn_avg_month_nom / adj_index
			
				// in logs
				gen wage_real_ln = ln(wage_real)
	
	// figures
	
	// distribution of AKM FE of new raided hires -- baseline events
	
	hist fe_worker if raid_individual == 1 & (spv == 0 & dir == 0) & type_spv == 1 ///
		& fe_worker >= -2 & fe_worker <= 2.5, ///
		xlabel(-2(.5)2.5) ylabel(0(.2)1.2) xtitle("Worker FE") ///
		plotregion(lcolor(white))
		
		graph export "${results}/dist_fav2_dist1.pdf", as(pdf) replace
		graph export "${results}/dist_fav2_dist1.png", as(png) replace
		
	summ fe_worker if raid_individual == 1 & (spv == 0 & dir == 0) & type_spv == 1, detail // -0.34
	
	// distribution of AKM FE of new raided hires -- if mgr to non-mgr poaching
	
	hist fe_worker if raid_individual == 1 & (spv == 0 & dir == 0) & type_emp == 1 ///
		& fe_worker >= -2 & fe_worker <= 2.5, ///
		xlabel(-2(.5)2.5) ylabel(0(.2)1.2) xtitle("Worker FE") ///
		plotregion(lcolor(white))
		
		graph export "${results}/dist_fav2_dist2.pdf", as(pdf) replace
		graph export "${results}/dist_fav2_dist2.png", as(png) replace
		
	summ fe_worker if raid_individual == 1 & (spv == 0 & dir == 0) & type_emp == 1, detail // -0.34

	// distribution of AKM FE of current non-mgrs -- baseline events
	
	hist fe_worker if raid_individual == 0 & (spv == 0 & dir == 0) & type_spv == 1 ///
		& fe_worker >= -2 & fe_worker <= 2.5, ///
		xlabel(-2(.5)2.5) ylabel(0(.2)1.2) xtitle("Worker FE") ///
		plotregion(lcolor(white)) 
		
		graph export "${results}/dist_fav2_dist3.pdf", as(pdf) replace
		graph export "${results}/dist_fav2_dist3.png", as(png) replace
		
	summ fe_worker if raid_individual == 0 & (spv == 0 & dir == 0) & type_spv == 1, detail // -0.32
	
	// distribution of AKM FE of new non-raided hires
	
		
				   
	hist fe_worker if hire == 1 & type_spv == 1 ///
		& fe_worker >= -2 & fe_worker <= 2.5, ///
		xlabel(-2(.5)2.5) ylabel(0(.2)1.2) xtitle("Worker FE") ///
		plotregion(lcolor(white)) 
	
		graph export "${results}/dist_fav2_dist4.pdf", as(pdf) replace
		graph export "${results}/dist_fav2_dist4.png", as(png) replace
	
	summ fe_worker if hire == 1 & type_spv == 1, detail  // -0.48
	
	// CDF: raided new hires vs non-raided new hires
	
		// variables summarizing the two groups
		gen group = .
		replace group = 1 if raid_individual == 1 & (spv == 0 & dir == 0) & type_spv == 1
		replace group = 2 if hire == 1 & type_spv == 1
		label define group_l 1 "Raided New Hires" 2 "Non-Raided New Hires", replace
		label values group group_l
	
		distplot fe_worker, over(group) xtitle("Worker FE") ytitle("Cumulative Probability") ///
			plotregion(lcolor(white))
			
			graph export "${results}/dist_fav2_cdf1.pdf", as(pdf) replace
			graph export "${results}/dist_fav2_cdf1.png", as(png) replace
			
	// CDF: raided new hires (mgr to mgr), raided new hires (mgr to non-mgr), non-raided new hires (mgr to mgr), non-raided new hires ( mgr to non-mgr)
	
		// variables summarizing the two groups
		gen group = .
		replace group = 1 if raid_individual == 1 & (spv == 0 & dir == 0) & type_spv == 1
		replace group = 2 if raid_individual == 1 & (spv == 0 & dir == 0) & type_emp == 1
		replace group = 3 if hire == 1 & type_spv == 1
		replace group = 4 if hire == 1 & type_emp == 1
		label define group_l 1 "Raided  (M-M)" 2 "Raided (M-NM)" 3 "Non-Raided (M-M)" 4 "Non-Raided (M-NM)", replace
		label values group group_l
	
		distplot fe_worker, over(group) xtitle("Worker FE") ytitle("Cumulative Probability") ///
			plotregion(lcolor(white))
			
			
		// variables summarizing the two groups
		drop group
		gen group = .
		replace group = 1 if raid_individual == 1 & (spv == 0 & dir == 0) & type_spv == 1
		replace group = 2 if raid_individual == 1 & (spv == 0 & dir == 0) & type_emp == 1
		replace group = 3 if hire == 1 & type_spv == 1
		replace group = 3 if hire == 1 & type_emp == 1
		label define group_l 1 "Raided  (M-M)" 2 "Raided (M-NM)" 3 "Non-Raided ", replace
		label values group group_l
	
		distplot fe_worker, over(group) xtitle("Worker FE") ytitle("Cumulative Probability") ///
			plotregion(lcolor(white))	
			
			graph export "${results}/dist_fav2_cdf3.pdf", as(pdf) replace
			graph export "${results}/dist_fav2_cdf3.png", as(png) replace
		
	// CDF: salary (wages) of raided new hires vs non-raided new hires
	
		
		// variables summarizing the two groups
		gen group = .
		replace group = 1 if raid_individual == 1 & (spv == 0 & dir == 0) & type_spv == 1
		replace group = 2 if hire == 1 & type_spv == 1
		label define group_l 1 "Raided New Hires" 2 "Non-Raided New Hires", replace
		label values group group_l
	
		distplot wage_real_ln, over(group) xtitle("Ln (Wage - 2008 R$)") ytitle("Cumulative Probability") ///
			plotregion(lcolor(white))
			
			graph export "${results}/dist_fav2_cdf4.pdf", as(pdf) replace
			graph export "${results}/dist_fav2_cdf4.png", as(png) replace
			
	

// using all workers in origin plants in t=-12

	// combining all cohorts for this analysis
	
	/*
	
	cap rm "${temp}/dir_fav2_o.dta"
	
	forvalues ym=612/635 { // PENDING: UPDATE THIS WITH ALL COHORTS!

		clear
		cap use "${data}/cowork_panel_m_spv/cowork_panel_m_spv_`ym'", clear
		
		if _N >= 1 {
		
			// sample restrictions
			merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
			
			// adding event type variables
			merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
			
			// keep t=-12 only
			keep if ym_rel == -12
			
			cap append using "${temp}/dir_fav2_o"
			save "${temp}/dir_fav2_o", replace
		
		}
	}
	
	*/
	
	use "${temp}/dir_fav2_o", clear
	
	// distribution of AKM FE of origin firm non-raided "leftover people"
	
	hist fe_worker if raid_individual == 0 & (dir == 0 & spv == 0) & type_spv == 1 ///
		& fe_worker >= -2 & fe_worker <= 2.5, ///
		xlabel(-2(.5)2.5) ylabel(0(.2)1.2) xtitle("Worker FE") ///
		plotregion(lcolor(white))
		
		graph export "${results}/dist_fav2_dist5.pdf", as(pdf) replace
		graph export "${results}/dist_fav2_dist5.png", as(png) replace
		
	summ fe_worker if raid_individual == 0 & (dir == 0 & spv == 0) & type_spv == 1, detail // -0.30
	
	// CDF: raided new hires vs non-raided leftover people
	
		// variables summarizing the two groups
		gen group = .
		replace group = 1 if raid_individual == 1 & (spv == 0 & dir == 0) & type_spv == 1
		replace group = 2 if raid_individual == 0 & (dir == 0 & spv == 0) & type_spv == 1
		label define group_l 1 "Raided New Hires" 2 "Non-Raided 'Leftover People'", replace
		label values group group_l
	
		distplot fe_worker, over(group) xtitle("Worker FE") ytitle("Cumulative Probability") ///
			plotregion(lcolor(white))
			
			graph export "${results}/dist_fav2_cdf2.pdf", as(pdf) replace
			graph export "${results}/dist_fav2_cdf2.png", as(png) replace
	
