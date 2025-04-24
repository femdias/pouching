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

	/*
	
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
	
	*/
		
// combining events and keeping what we need

	use "${temp}/pred7_spv_spv", clear
	append using "${temp}/pred7_spv_emp"
	append using "${temp}/pred7_emp_spv"
	
	merge m:1 spv event_id using "${temp}/eventlist", keep(match)
	
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
	
		// keeping list of these workers -- I will use this to construct another data set
		
		preserve
		
			keep if group != .
			keep d_plant pc_ym cpf
			
			// NOTE: THERE ARE SOME DUPLICATES HERE, BECAUSE I TREATED EMP, SPV, AND DIR EVENTS INDEPENDENTLY
			// THIS WILL NO LONGER BE A PROBLEM WITH THE NEW CODE
			duplicates drop
			
			// 1 year later
			gen ym = pc_ym + 12
			format ym %tm
			save "${temp}/workers_1y", replace
			
			// 2 years later
			replace ym = ym + 12
			save "${temp}/workers_2y", replace
			
			// 3 years later
			replace ym = ym + 12
			save "${temp}/workers_3y", replace	
		
		restore	
	
	tab group
			
	// ANALYSIS I. figure: worker quality (winsorize top and bottom .1%)
	
		winsor fe_worker, gen(fe_worker_winsor) p(0.001)

		ksmirnov fe_worker_winsor, by(group)
		local ks: display %4.3f r(p)
		di "`ks'"
		
		ttest fe_worker_winsor, by(group)
		local ttest: display %4.3f r(p)
		di "`ttest'"
		local diff = r(mu_1) - r(mu_2)
		local diff: display %4.3f `diff'
		di "`diff'"
	
		distplot fe_worker_winsor, over(group) xtitle("Worker ability") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(solid dash) lwidth(medthick medthick)  ///
		legend(order(2 1) region(lstyle(none))) ///
		text(.2 2 "{bf:Equality of distributions test:}" ///
		" K-S p-value < `ks'" " " "{bf: Equality of means:}" "{&beta}{subscript:R} - {&beta}{subscript:NR} = `diff'" ///
		"p-value < `ttest'" , justification(right))
		
			graph export "${results}/quality_dest_hire_w_cdf.pdf", as(pdf) replace
		
		// note: bwidth = .09 is ~1.5 times the default bandwidth
		twoway kdensity fe_worker_winsor if group == 1, lcolor(black) bwidth(.09) lpattern(solid) lwidth(medthick)  || ///
		kdensity fe_worker_winsor if group == 2, lcolor(black) lpattern(dash) bwidth(.09) lwidth(medthick) ///
		xtitle("Worker ability") ///
		ytitle("Density") plotregion(lcolor(white)) ///
		legend(order(2 "Non-raided new hires" 1 "Raided new hires") region(lstyle(none))) ///
		text(.85 2 "{bf:Equality of distributions test:}" ///
		" K-S p-value < `ks'" " " "{bf: Equality of means:}" "{&beta}{subscript:R} - {&beta}{subscript:NR} = `diff'" ///
		"p-value < `ttest'" , justification(right))
			
			graph export "${results}/quality_dest_hire_w_pdf.pdf", as(pdf) replace
				
			
	// ANALYSIS II. regression 
	
	drop if group == .
	
		// exp_ln
			
		gen exp = age - educ_years - 6
		replace exp = 0 if exp <= 0
		
		gen exp_ln = ln(exp) 
		replace exp_ln = -99 if exp_ln==.
		g exp_m =(exp_ln==-99)
			
		// raided
		gen raided = (group == 1)
		label var raided "Raided new hire"

	
	eststo col1: reg fe_worker raided, rob
	summ fe_worker, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
	
	eststo col2: reg fe_worker raided exp_ln exp_m, rob
	summ fe_worker, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
		estadd local exp "\cmark"
		
	eststo col2alt: areg fe_worker raided, rob absorb(d_plant)
	summ fe_worker, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'	
		
		estadd local firmfe "\cmark"
	
	eststo col3: areg fe_worker raided exp_ln exp_m, rob absorb(d_plant)
	summ fe_worker, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
		
		estadd local firmfe "\cmark"
		estadd local exp "\cmark"
	
	// display table
	
	esttab  col1 col2,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		keep(raided) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Worker controls} \\ Worker experience = exp_ln"  ///
		, labels("\cmark" ""))
	
	// save table

	esttab col1 col2 using "${results}/pred7_reg.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(raided "\midrule", nolabel) ///
		mgroups("Outcome: worker ability",  /// 
		pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(raided) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Worker controls} \\ Worker experience = exp_ln" /// 
		, labels("\cmark" ""))	
		
	save "${temp}/pred7_dataset", replace
	
	// ANALYSIS III. how long did they last
	
	// finding new hires in the future

		// looping over windows
		foreach w in 1 2 3 {

		use "${temp}/workers_`w'y", clear
		
		drop if ym > ym(2017,12)
		
		levelsof ym, local(months)
		
		/*
		
		foreach ym of local months {
		
			use "${data}/rais_m/rais_m`ym'", clear
			
			keep cpf ym plant_id 
			
			merge 1:1 cpf ym using "${temp}/workers_`w'y"
			keep if _merge == 3
			drop _merge
			
			save "${temp}/`w'y_`ym'", replace
		
		}
		
		*/
		
		clear
		
		foreach ym of local months {
			append using "${temp}/`w'y_`ym'"
		}
		
		rename plant_id y`w'_plant
		
		save "${temp}/`w'y", replace
		
		}
		
	// back to the main data set after this detour
	
	use "${temp}/pred7_dataset", clear
	drop _merge // CHECK WHY THIS WAS NOT DROPPED BEFORE
	drop if group == .
	
	merge m:1 cpf pc_ym using "${temp}/1y"
	drop _merge
	
	merge m:1 cpf pc_ym using "${temp}/2y"
	drop _merge
	
	merge m:1 cpf pc_ym using "${temp}/3y"
	drop _merge
	
	gen emp1y = (d_plant == y1_plant)
	replace emp1y = . if (pc_ym + 12 > ym(2017,12))
	label var emp1y "In destination firm after 1 year"
	
	gen emp2y = (d_plant == y2_plant)
	replace emp2y = . if (pc_ym + 24 > ym(2017,12))
	label var emp2y "In destination firm after 2 years"
	
	gen emp3y = (d_plant == y3_plant)
	replace emp3y = . if (pc_ym + 36 > ym(2017,12))
	label var emp3y "In destination firm after 3 years"
	
	// first pass analysis
	
		tab group emp1y, row nokey
		tab group emp2y, row nokey
		tab group emp3y, row nokey
	
	foreach w in 1 2 3 {
	
	eststo col1_`w'y: reg emp`w'y raided, rob
	summ emp`w'y, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
	
	eststo col2_`w'y: reg emp`w'y raided exp_ln exp_m, rob	
	summ emp`w'y, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
		estadd local exp "\cmark"
		
		
	eststo col2alt_`w'y: areg emp`w'y raided, rob absorb(d_plant)	
	summ emp`w'y, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
		
		estadd local firmfe "\cmark"
	
	eststo col3_`w'y: areg emp`w'y raided exp_ln exp_m, rob	absorb(d_plant)
	summ emp`w'y, detail
		local lhs: display %4.3f r(mean)
		di "`lhs'"
		estadd local lhs `lhs'
		
		estadd local firmfe "\cmark"
		estadd local exp "\cmark"
	
	}
	
	esttab col1 col3 col1_1y col3_1y col1_2y col3_2y col1_3y col3_3y,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		keep(raided) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(firmfe lhs N r2 , fmt(0 0 0 3) label("\\ Destination firm FE" "\\ Mean LHS" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Worker controls} \\ Worker experience = exp_ln"  ///
		, labels("\cmark" ""))
	
	esttab col1 col3 col1_1y col3_1y col1_2y col3_2y col1_3y col3_3y using "${results}/pred7_reg_extra.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(raided "\midrule", nolabel) ///
		mgroups("Worker ability" "Retained 1 yr" "Retained 2 yrs" "Retained 3 yrs",  /// 
		pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(raided) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(firmfe lhs N r2 , fmt(0 0 0 3) label("Dest firm FE" "\\ Mean LHS" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Controls} \\ Worker experience = exp_ln" /// 
		, labels("\cmark" ""))
		
	esttab col2 col3 col2_1y col3_1y col2_2y col3_2y col2_3y col3_3y using "${results}/pred7_reg_extra_v2.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(raided "\midrule", nolabel) ///
		mgroups("Worker ability" "Retained 1 yr" "Retained 2 yrs" "Retained 3 yrs",  /// 
		pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(raided) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(firmfe lhs N r2 , fmt(0 0 0 3) label("Dest firm FE" "\\ Mean LHS" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Controls} \\ Worker experience = exp_ln" /// 
		, labels("\cmark" ""))	
		
	esttab col2alt col3 col2alt_1y col3_1y col2alt_2y col3_2y col2alt_3y col3_3y using "${results}/pred7_reg_extra_v3.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(raided "\midrule", nolabel) ///
		mgroups("Worker ability" "Retained 1 yr" "Retained 2 yrs" "Retained 3 yrs",  /// 
		pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(raided) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(firmfe exp lhs N r2 , fmt(0 0 3 0 3) label("\\ \textbf{Controls} \\ Dest firm FE" "Worker Experience" "\\ Mean LHS" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01)

		
			
	
	
	
	
	
	
	
	
	
	
