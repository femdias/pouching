// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 7
// "Raided workers are, on average, of higher ability than non-raided workers" 

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
			replace keep = 1 if (type == 5 & spv == 0 & dir == 0)
			
			// spv-emp events
			// 1 emp is considered poached individual here
			replace keep = 1 if (type == 6 & main_individual == 0 & spv == 0 & dir == 0) 
			
			// emp-spv events
			replace keep = 1 if (type == 8 & spv == 0 & dir == 0)
			
		keep if keep == 1	
		
		// keep if hired in the month
		
			// set hiring year-month
			gen hire_ym = ym(hire_year, hire_month)
			
			// indicator for hires in that month
			gen hire = ((ym == hire_ym) & (hire_ym != .))
				
		keep if hire == 1
		
		// saving
		save "${temp}/202503_pred7_`ym'", replace
		
	}
	
	clear
	
	foreach ym of numlist 601/611 613/623 625/635 637/647 649/659 661/671 673/683 {
	
		append using "${temp}/202503_pred7_`ym'"
		
	}	
	
	save "${temp}/202503_pred7", replace
	
	clear

// proceeding to the analysis	
	
	use "${temp}/202503_pred7", clear
	
	// merging with event list
	merge m:1 eventid using "${temp}/202503_eventlist", keep(match)
				  
	// variables summarizing the two groups
	
	gen group = .
	replace group = 1 if raid_individual == 1 | (pc_individual == 1 & main_individual == 0)  // this is raidpc_individual == 1
	replace group = 2 if raid_individual == 0
	label define group_l 1 "Raided new hires" 2 "Non-raided new hires", replace
	label values group group_l
	
	tab group
	
		// keeping list of these workers -- I will use this to construct another data set
		
		preserve
		
			// all these observations are in t=0
			// thus, pc_ym == ym
			gen pc_ym = ym
		
			// keeping what we need
			keep d_plant pc_ym cpf
			
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
			
	// ANALYSIS I. figure: worker quality (winsorize top and bottom .1%)
	
		winsor worker_akm_fe, gen(worker_akm_fe_winsor) p(0.001)

		ksmirnov worker_akm_fe_winsor, by(group)
		local ks: display %4.3f r(p)
		di "`ks'"
		
		ttest worker_akm_fe_winsor, by(group)
		local ttest: display %4.3f r(p)
		di "`ttest'"
		local diff = r(mu_1) - r(mu_2)
		local diff: display %4.3f `diff'
		di "`diff'"
	
		distplot worker_akm_fe_winsor, over(group) xtitle("Worker ability") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(solid dash) lwidth(medthick medthick)  ///
		legend(order(2 1) region(lstyle(none))) ///
		text(.2 1.5 "{bf:Equality of distributions test:}" ///
		" K-S p-value < `ks'" " " "{bf: Equality of means:}" "{&beta}{subscript:R} - {&beta}{subscript:NR} = `diff'" ///
		"p-value < `ttest'" , justification(right))
		
			graph export "${results}/202503_quality_dest_hire_w_cdf.pdf", as(pdf) replace
		
		// note: bwidth = .09 is ~1.5 times the default bandwidth
		twoway kdensity worker_akm_fe_winsor if group == 1, lcolor(black) bwidth(.09) lpattern(solid) lwidth(medthick)  || ///
		kdensity worker_akm_fe_winsor if group == 2, lcolor(black) lpattern(dash) bwidth(.09) lwidth(medthick) ///
		xtitle("Worker ability") ///
		ytitle("Density") plotregion(lcolor(white)) ///
		legend(order(2 "Non-raided new hires" 1 "Raided new hires") region(lstyle(none))) ///
		text(1.25 1.5 "{bf:Equality of distributions test:}" ///
		" K-S p-value < `ks'" " " "{bf: Equality of means:}" "{&beta}{subscript:R} - {&beta}{subscript:NR} = `diff'" ///
		"p-value < `ttest'" , justification(right))
			
			graph export "${results}/202503_quality_dest_hire_w_pdf.pdf", as(pdf) replace
				
	save "${temp}/pred7_dataset", replace
	
	// ANALYSIS III. how long did they last
	
	// finding new hires in the future

		// looping over windows
		foreach w in 1 2 3 {

		use "${temp}/workers_`w'y", clear
		
		drop if ym > ym(2017,12)
		
		levelsof ym, local(months)
		
		foreach ym of local months {
		
			use "${data}/rais_m/rais_m`ym'", clear
			
			keep cpf ym plant_id // ADICIONAR PARA KEEP WAGE TAMBÉM
			
			merge 1:1 cpf ym using "${temp}/workers_`w'y"
			keep if _merge == 3
			drop _merge
			
			save "${temp}/`w'y_`ym'", replace
		
		}
		
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
	
	
		// TBM CRIAR VARIABLS COM WAGE GROWTH
		* gen wagegrowth1y = wage1y - wageathiring if emp1y == 1
	
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
	
	esttab col2alt col3 col2alt_1y col3_1y col2alt_2y col3_2y col2alt_3y col3_3y using "${results}/pred7_reg_extra_v3.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(raided "\midrule", nolabel) ///
		mgroups("Worker ability" "Retained 1 yr" "Retained 2 yrs" "Retained 3 yrs",  /// 
		pattern(1 0 1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(raided) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(firmfe exp lhs N r2 , fmt(0 0 3 0 3) label("\\ \textbf{Controls} \\ Dest firm FE" "Worker Experience" "\\ Mean LHS" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01)

		
			
	
	
	
	
	
	
	
	
	
	
