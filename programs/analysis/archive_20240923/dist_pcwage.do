// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Salary of poached managers at destination		
	
*--------------------------*
* ANALYSIS
*--------------------------*

// using all workers in destination plants in t=0

	// combining all cohorts for this analysis
	
	/*
	
	cap rm "${temp}/dist_pcwage.dta"
	
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
			
			cap append using "${temp}/dist_pcwage"
			save "${temp}/dist_pcwage", replace
		
		}
	}
	
	*/
	
	use "${temp}/dist_pcwage", clear
	
	// distribution of: wage of existing managers at destination
	
	hist wage_real_ln if spv == 1 & pc_individual == 0 & type_spv == 1 ///
		& wage_real_ln >= 5 & wage_real_ln <= 11, ///
		xlabel(5(2)11) ylabel(0(.2)1) xtitle("Ln (Wage - 2008 R$)") ///
		plotregion(lcolor(white))
		
		graph export "${results}/dist_pcwage_dist1.pdf", as(pdf) replace
		graph export "${results}/dist_pcwage_dist1.png", as(png) replace
 		
	summ wage_real_ln if spv == 1 & pc_individual == 0 & type_spv == 1, detail // 7.67
	
	// distribution of: wage of poached managers at destination
	
	hist wage_real_ln if spv == 1 & pc_individual == 1 & type_spv == 1 ///
		& wage_real_ln >= 5 & wage_real_ln <= 11, ///
		xlabel(5(2)11) ylabel(0(.2)1) xtitle("Ln (Wage - 2008 R$)") ///
		plotregion(lcolor(white))
		
		graph export "${results}/dist_pcwage_dist2.pdf", as(pdf) replace
		graph export "${results}/dist_pcwage_dist2.png", as(png) replace
		
	summ wage_real_ln if spv == 1 & pc_individual == 1 & type_spv == 1, detail // 7.77
	
		// CDF: wage of poached mgrs at destination vs. wage of existing mgrs at destination
		
		gen group = .
		replace group = 1 if spv == 1 & pc_individual == 1 & type_spv == 1
		replace group = 2 if spv == 1 & pc_individual == 0 & type_spv == 1
		label define group_l 1 "Poached Managers" 2 "Existing Managers", replace
		label values group group_l
		
		distplot wage_real_ln, over(group) xtitle("Ln (Wage - 2008 R$)") ytitle("Cumulative Probability") ///
			plotregion(lcolor(white))
			
			graph export "${results}/dist_pcwage_cdf1.pdf", as(pdf) replace
			graph export "${results}/dist_pcwage_cdf1.png", as(png) replace
			
		drop group	
			
	// distribution of: wage of existing non-mgr at destination
	
	hist wage_real_ln if spv == 0 & dir == 0 & raid_individual == 0 & type_spv == 1 ///
		& wage_real_ln >= 5 & wage_real_ln <= 11, ///
		xlabel(5(2)11) ylabel(0(.2)1) xtitle("Ln (Wage - 2008 R$)") ///
		plotregion(lcolor(white))
		
		graph export "${results}/dist_pcwage_dist3.pdf", as(pdf) replace
		graph export "${results}/dist_pcwage_dist3.png", as(png) replace
		
	summ wage_real_ln if spv == 0 & dir == 0 & raid_individual == 0 & type_spv == 1, detail // 6.90
	
	// distribution of: wage of raided workers at destination
	
	hist wage_real_ln if spv == 0 & dir == 0 & raid_individual == 1 & type_spv == 1 ///
		& wage_real_ln >= 5 & wage_real_ln <= 11, ///
		xlabel(5(2)11) ylabel(0(.2)1) xtitle("Ln (Wage - 2008 R$)") ///
		plotregion(lcolor(white))
		
		graph export "${results}/dist_pcwage_dist4.pdf", as(pdf) replace
		graph export "${results}/dist_pcwage_dist4.png", as(png) replace
		
	summ wage_real_ln if spv == 0 & dir == 0 & raid_individual == 1 & type_spv == 1, detail // 6.87
	
		// CDF: wage of raided workers at destination vs. wage of existing non-mgrs at destination
		
		gen group = .
		replace group = 1 if spv == 0 & dir == 0 & raid_individual == 1 & type_spv == 1
		replace group = 2 if spv == 0 & dir == 0 & raid_individual == 0 & type_spv == 1
		label define group_l 1 "Raided Non-Mgrs" 2 "Existing Non-Managers", replace
		label values group group_l
		
		distplot wage_real_ln, over(group) xtitle("Ln (Wage - 2008 R$)") ytitle("Cumulative Probability") ///
			plotregion(lcolor(white))
			
			graph export "${results}/dist_pcwage_cdf2.pdf", as(pdf) replace
			graph export "${results}/dist_pcwage_cdf2.png", as(png) replace
			
		drop group	
	
