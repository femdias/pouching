
// Poaching Project
// Created by: Heloísa de Paula
// (heloisap3@al.insper.edu.br)
// Date created: October 2024

// Purpose: Compare wage of raided workers to moveable workers in origin firm	

*--------------------------*
* ANALYSIS
*--------------------------*


// using all workers in origin plants in t=-12

	// combining all cohorts for this analysis
	
	
	
	foreach e in spv dir emp {
	
	cap rm "${temp}/wage_origin_`e'.dta"
	
	forvalues ym=612/683 { // PENDING: UPDATE THIS WITH ALL COHORTS!

		clear
		cap use "${data}/cowork_panel_m_`e'/cowork_panel_m_`e'_`ym'", clear
		
		if _N >= 1 {
			
			// sample restrictions
			merge m:1 event_id using "${data}/sample_selection_`e'", keep(match) nogen
			
			// adding event type variables
			merge m:1 event_id using "${data}/evt_type_m_`e'", keep(match) nogen
			
			// keep t=-12 only
			keep if ym_rel == -12
			
			cap append using "${temp}/wage_origin_`e'"
			save "${temp}/wage_origin_`e'", replace
		}
		}
	}
	
	clear
	
	use "${temp}/wage_origin_spv", clear
	append using "${temp}/wage_origin_dir"
	append using "${temp}/wage_origin_emp"
	
	save "${temp}/wage_origin", replace
	
	
	use "${temp}/wage_origin_spv", clear
	append using "${temp}/wage_origin_dir"
	
	save "${temp}/wage_origin_spv_dir", replace
	
	foreach e in spv dir emp spv_dir {
	
	
	
	use "${temp}/wage_origin_`e'", clear
	
	// distribution of AKM FE of origin firm non-raided "leftover people"

	// CDF: raided new hires vs non-raided leftover people
	
		// variables summarizing the two groups
		gen group = .
		replace group = 1 if raid_individual == 1 & (spv == 0 & dir == 0) & type_spv == 1
		//replace group = 2 if raid_individual == 0 & (spv == 0 & dir == 0) & type_spv == 1
		//replace group = 3 if raid_individual == 0 & (spv == 0 & dir == 0) & type_spv == 1 & moveable_worker == 1
		replace group = 4 if raid_individual == 0 & (spv == 0 & dir == 0) & type_spv == 1 & moveable_worker_changed_firm == 1
		label define group_l 1 "Raided New Hires" 4 "Moveable Stayers", replace // 2 "Non-Raided 'Leftover People'" 3 "Non-Raided Moveable Workers"///
			 
		label values group group_l
	
		distplot wage_real_ln, over(group) xtitle("Ln Wage - 2008 R$") ytitle("Cumulative Probability") ///
			plotregion(lcolor(white)) ///
			lcolor(emerald maroon) lpattern(solid dash) ///
			legend(region(lstyle(none)))
			

			
			graph export "${results}/wage_origin_`e'.pdf", as(pdf) replace
			graph export "${results}/wage_origin_`e'.png", as(png) replace
			
			// Now we will do the CDF of winsorized values


// Winsorize the wage data (top and bottom 1%)
winsor wage_real_ln, gen (wage_real_ln_winsor) p(0.01)

histogram wage_real_ln, frequency
histogram wage_real_ln_winsor, frequency

ksmirnov wage_real_ln_winsor, by(group)
	

distplot wage_real_ln_winsor, over(group) xtitle("Ln Wage - 2008 R$") ///
    ytitle("Cumulative Probability") plotregion(lcolor(white)) ///
    lcolor(emerald maroon) lpattern(solid dash) ///
    legend(region(lstyle(none)))
   
			
			graph export "${results}/wage_origin_winsor_`e'.pdf", as(pdf) replace
			graph export "${results}/wage_origin_winsor_`e'.png", as(png) replace
			
	}
	
