// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 3
// "Poached managers earn higher salaries"

*--------------------------*
* PREPARE
*--------------------------*

// using all workers in destination plants in t=0

	// combining all cohorts for this analysis
		
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
		
	// append each ym to this dataset
	// this is a worker level dataset
	use "${data}/202503_dest_panel_m/202503_dest_panel_m_`ym'", clear
			
		// keep t=0 only
		keep if ym == `ym'
		
		// which individuals are we interested in?
		gen keep = .
		
			// spv-spv events
			replace keep = 1 if (type == 5 & main_individual == 1) | (type == 5 & spv == 1)
			
			// spv-emp events
			replace keep = 1 if (type == 6 & main_individual == 1) | (type == 6 & spv == 1)
			
			// emp-spv events
			replace keep = 1 if (type == 8 & main_individual == 1) | (type == 8 & spv == 1)
			
		keep if keep == 1	
		
		// keep if hired in the month
		
			// set hiring year-month
			gen hire_ym = ym(hire_year, hire_month)
			
			// indicator for hires in that month
			gen hire = ((ym == hire_ym) & (hire_ym != .))
				
		keep if hire == 1
		
		// saving
		save "${temp}/202503_pred3_`ym'", replace
		
	}
	
	clear
	
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
	
		append using "${temp}/202503_pred3_`ym'"
		
	}	
	
	save "${temp}/202503_pred3", replace

// proceeding to the analysis	
	
	use "${temp}/202503_pred3", clear
	
	// merging with event list
	merge m:1 eventid using "${temp}/202503_eventlist", keep(match)
				  
	// variables summarizing the two groups
	
	gen group = .
	replace group = 1 if main_individual == 1
	replace group = 2 if main_individual == 0
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
		
		distplot wage_real_ln_winsor, over(group) xtitle("Ln salary (2017 R$)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(solid dash) lwidth(medthick medthick) ///
		legend(order(2 1) region(lstyle(none))) ///
		text(.2 10 "{bf:Equality of distributions test:}" ///
		" K-S p-value < `ks'" " " "{bf: Equality of means:}" "{&beta}{subscript:P} - {&beta}{subscript:NP} = `diff'" ///
		"p-value < `ttest'" , justification(right))
   
			graph export "${results}/202503_wage_dest_hire_mgr_w_cdf.pdf", as(pdf) replace
		
		// note: bwidth = .16 is 1.5 times the default bandwidth
		twoway kdensity wage_real_ln_winsor if group == 1, lcolor(black) bwidth(.16) lpattern(solid) lwidth(medthick) || ///
		kdensity wage_real_ln_winsor if group == 2, lcolor(black) bwidth(.16) lpattern(dash) lwidth(medthick) ///
		xtitle("Ln salary (2017 R$)") ///
		ytitle("Density") plotregion(lcolor(white)) ylabel(0(.2).7) ///
		legend(order(2 "Non-poached new managers" 1 "Poached managers") region(lstyle(none))) ///
		text(.55 10 "{bf:Equality of distributions test:}" ///
		" K-S p-value < `ks'" " " "{bf: Equality of means:}" "{&beta}{subscript:P} - {&beta}{subscript:NP} = `diff'" ///
		"p-value < `ttest'" , justification(right))
   
			graph export "${results}/202503_wage_dest_hire_mgr_w_pdf.pdf", as(pdf) replace
			
	// regression: wage
	
		// exp_ln
		gen exp = age - educ_years - 6
		replace exp = 1 if exp <= 0
		gen exp_ln = ln(exp) 
			
		// worker_akm_fe
		replace worker_akm_fe = -99 if worker_akm_fe ==.
		
		// worker_akm_fe_m
		gen worker_akm_fe_m = (worker_akm_fe==-99)
		
		// poached
		gen poached = (group == 1)
		label var poached "Poached manager = 1"

	eststo col1: reg wage_real_ln poached, rob
	
	eststo col2: reg wage_real_ln poached exp_ln, rob
	
	eststo col3: reg wage_real_ln poached exp_ln worker_akm_fe worker_akm_fe_m, rob
	
	// display table
	
	esttab  col1 col2 col3,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		keep(poached) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Manager experience = exp_ln" "Manager ability = worker_akm_fe"  ///
		, labels("\cmark" ""))
	
	// save table

	esttab col1 col2 col3 using "${results}/202503_pred3_reg.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(poached "\midrule", nolabel) ///
		mgroups("Outcome: ln(salary) at destination",  /// 
		pattern(1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(poached) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager experience = exp_ln" ///
		"Manager ability = worker_akm_fe"  /// 
		, labels("\cmark" ""))			
			
