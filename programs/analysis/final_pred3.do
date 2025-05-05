// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 3
// "Poached managers earn higher salaries"

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

	save "${temp}/pred3_spv_spv", replace
	
// "spv --> emp" events
		
	use "${temp}/quality_dest_hire_spv", clear
	
	// keep only people that became spv
	keep if type_emp == 1
	
	// generating identifier
	rename spv supervisor
	gen spv = 2

	save "${temp}/pred3_spv_emp", replace	
	
// "emp --> spv" events	

	use "${temp}/quality_dest_hire_emp", clear
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	rename spv supervisor
	gen spv = 3

	save "${temp}/pred3_emp_spv", replace
		
// combining events and keeping what we need

	use "${temp}/pred3_spv_spv", clear
	append using "${temp}/pred3_spv_emp"
	append using "${temp}/pred3_emp_spv"
	
	merge m:1 spv event_id using "${temp}/eventlist", keep(match)
	 
	// identifying who was hired as a manager
	
		// set hiring date
		gen hire_ym = ym(hire_year, hire_month) 
				
		// identify hiring events (non-raided)
		gen hire = ((ym == hire_ym) & (hire_ym != .)) /// hired in the month
			& (type_of_hire == 2) /// type was 'readmissão'
			& (pc_individual == 0 & raid_individual == 0) /// not a poached or raided individual
			& (supervisor == 1) // is a manager
				  
	// variables summarizing the two groups
	
	gen group = .
	replace group = 1 if pc_individual == 1
	replace group = 2 if hire == 1
	label define group_l 1 "Poached managers" 2 "Non-poached new managers", replace
	label values group group_l
	
	tab group
	
	// figure: wage (winsorize top and bottom .1%)
	
		winsor wage_real_ln, gen(wage_real_ln_winsor) p(0.001)

		ksmirnov wage_real_ln_winsor, by(group)
		local ks: display %4.3f r(p)
		di "`ks'"
		
		ttest wage_real_ln_winsor, by(group)
		local ttest: display %4.3f r(p)
		di "`ttest'"
		local diff= r(mu_1) - r(mu_2)
		local diff: display %4.3f `diff'
		di "`diff'"
		
		distplot wage_real_ln_winsor, over(group) xtitle("Ln salary (2008 R$)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(solid dash) lwidth(medthick medthick) ///
		legend(order(2 1) region(lstyle(none))) ///
		text(.2 9 "{bf:Equality of distributions test:}" ///
		" K-S p-value < `ks'" " " "{bf: Equality of means:}" "{&beta}{subscript:P} - {&beta}{subscript:NP} = `diff'" ///
		"p-value < `ttest'" , justification(right))
   
			graph export "${results}/wage_dest_hire_mgr_w_cdf.pdf", as(pdf) replace
		
		// note: bwidth = .16 is 1.5 times the default bandwidth
		twoway kdensity wage_real_ln_winsor if group == 1, lcolor(black) bwidth(.16) lpattern(solid) lwidth(medthick) || ///
		kdensity wage_real_ln_winsor if group == 2, lcolor(black) bwidth(.16) lpattern(dash) lwidth(medthick) ///
		xtitle("Ln salary (2008 R$)") ///
		ytitle("Density") plotregion(lcolor(white)) ///
		legend(order(2 "Non-poached new managers" 1 "Poached managers") region(lstyle(none))) ///
		text(.42 9.2 "{bf:Equality of distributions test:}" ///
		" K-S p-value < `ks'" " " "{bf: Equality of means:}" "{&beta}{subscript:P} - {&beta}{subscript:NP} = `diff'" ///
		"p-value < `ttest'" , justification(right))
   
			graph export "${results}/wage_dest_hire_mgr_w_pdf.pdf", as(pdf) replace
			
	
		
	// regression
	
	keep if group != .
	
		gen exp = age - educ_years - 6
		replace exp = 0 if exp <= 0
	
		// exp_ln
		gen exp_ln = ln(exp) 
		replace exp_ln = -99 if exp_ln==.
		g exp_m =(exp_ln==-99)
			
		// fe_worker
		replace fe_worker = -99 if fe_worker==.
		g fe_worker_m = (fe_worker==-99)
		
		// poached
		gen poached = (group == 1)
		label var poached "Poached manager"

	eststo col1: reg wage_real_ln poached, rob
	
	eststo col2: reg wage_real_ln poached exp_ln exp_m, rob
	
	eststo col3: reg wage_real_ln poached exp_ln exp_m fe_worker fe_worker_m, rob
	
	// display table
	
	esttab  col1 col2 col3,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		keep(poached) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Manager experience = exp_ln" "Manager quality = fe_worker"  ///
		, labels("\cmark" ""))
	
	// save table

	esttab col1 col2 col3 using "${results}/pred3_reg.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(poached "\midrule", nolabel) ///
		mgroups("Outcome: ln(salary) at destination",  /// 
		pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(poached) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager experience = exp_ln" ///
		"Manager ability = fe_worker"  /// 
		, labels("\cmark" ""))	
		
	// save this final data set	
	
	save "${temp}/pred3_end", replace
	
	
	
	
	
	
