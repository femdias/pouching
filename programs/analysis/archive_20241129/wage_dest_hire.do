// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024


// Purpose: Generate plot of cumulative probability of wages of raided and non-raided new hires	
	
*--------------------------*
* ANALYSIS
*--------------------------*

// using all workers in destination plants in t=0

	// combining all cohorts for this analysis
	
	foreach e in spv dir emp {	
			
	cap rm "${temp}/wage_dest_hire_`e'", replace
		
	forvalues ym=612/683 { // events from 2011m1 through 2016m12

		clear
		
		* Append each ym to this dataset
		cap use "${data}/dest_panel_m_`e'/dest_panel_m_`e'_`ym'", clear
		
		* Use if there are poaching events in that date
		if _N >= 1 {
		
			// sample restrictions
			merge m:1 event_id using "${data}/sample_selection_`e'", keep(match) nogen
			
			// adding event type variables
			* evt_type_m: identifying event types (using destination occupation) -- keep only people that become mgr
			merge m:1 event_id using "${data}/evt_type_m_`e'", keep(match) nogen
			keep if type_spv == 1
			
			// keep t=0 only
			keep if ym == `ym'
			
			* Save appended dataset
			cap append using "${temp}/wage_dest_hire_`e'"
			save "${temp}/wage_dest_hire_`e'", replace
		
		}
	}
	}
	
	clear
	
	use "${temp}/wage_dest_hire_spv", clear
	append using "${temp}/wage_dest_hire_dir"
	append using "${temp}/wage_dest_hire_emp"
	
	save "${temp}/wage_dest_hire", replace
	
	// identifying who was hired as an employee
	
		// set hiring date
		gen hire_ym = ym(hire_year, hire_month) 
				
			// identify hiring events (non-raided)
			gen hire = ((ym == hire_ym) & (hire_ym != .)) /// hired in the month
				   & (type_of_hire == 2) /// type was 'readmissão'
				   & (pc_individual == 0 & raid_individual == 0) /// not a poached or raided individual
				   & (dir == 0 & spv == 0) // is an employee
	
	// CDF: raided new hires vs non-raided new hires
	
		// variables summarizing the two groups
		gen group = .
		replace group = 1 if raid_individual == 1 & (spv == 0 & dir == 0)
		replace group = 2 if hire == 1
		label define group_l 1 "Raided New Hires" 2 "Non-Raided New Hires", replace
		label values group group_l
		
		ksmirnov wage_real_ln, by(group)
	

			distplot wage_real_ln, over(group) xtitle("Ln Wage - 2008 R$") ///
    ytitle("Cumulative Probability") plotregion(lcolor(white)) ///
    lcolor(emerald maroon) lpattern(solid dash) ///
    legend(region(lstyle(none)))
   
			
			graph export "${results}/wage_dest_hire.pdf", as(pdf) replace
			graph export "${results}/wage_dest_hire.png", as(png) replace
			
			
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
   
			
			graph export "${results}/wage_dest_hire_winsor.pdf", as(pdf) replace
			graph export "${results}/wage_dest_hire_winsor.png", as(png) replace
			

			
