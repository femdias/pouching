// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: March 2025

// Purpose: Testing Prediction 1
// "Managers are poached by more productive firms"

*--------------------------*
* PANEL A
*--------------------------*

	use "${data}/poaching_evt", clear
	
	// we're only interested in spv-spv, spv-emp, and emp-spv
	keep if type == 1 | type == 2 | type == 3
	
	// keeping only the events we're interested in -- THIS PART HAS TO BE MODIFIED!!! USING TEMP FILE!!!
	// WHAT I SHOULD DO HERE: RUN THE COMPLETE REGRESSION (ONCE I'VE DEFINED IT) & KEEP E(SAMPLE) == 1
	// REVIEW THIS ONCE I GET TO PREDICTIONS 4, 5, AND 6
	rename type spv
	merge m:1 spv event_id using "${temp}/eventlist", keep(match)
	rename spv type
	
	// for this analysis, we need long format
	// variable of interest: fe_firm
	// note: origin = 1, destination = 2
	
	rename fe_firm_o fe_firm1
	rename fe_firm_d fe_firm2
	
	egen unique_id = group(event_id type)
	reshape long fe_firm, i(unique_id) j(or_dest)
	
	la var or_dest "Origin or destination"
	la def or_dest 1 "Origin" 2 "Destination", replace
	la val or_dest or_dest
	
	la var fe_firm "Wage premium"
		
	// winsorize top and bottom .1% (for graphing purposes) 
	winsor fe_firm, gen(fe_firm_w) p(0.001)
	la var fe_firm_w "Wage premium (winsorized)"
	
	// analysis

		// testing differences in means and distributions
		
		ksmirnov fe_firm_w, by(or_dest)
		local ks: display %4.3f r(p)
		di "`ks'"
		
		ttest fe_firm_w, by(or_dest)
		local ttest: display %4.3f r(p)
		di "`ttest'"
		
		// first figure: CDF
		
		distplot fe_firm_w, over(or_dest) xtitle("Firm productivity proxy (wage premium)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(solid dash) lwidth(medthick medthick) ///
		legend(order(1 2) region(lstyle(none))) ///
		note("P-values: T-test = `ttest' ; K-S = `ks'", size(small))
		
		graph export "${results}/202503_pred1_cdf.pdf", as(pdf) replace
		
		// second figure: PDF
		
		// note: bwidth = .06 is ~1.5 times the default bandwidth
		twoway kdensity fe_firm_w if or_dest == 1, n(50) bwidth(.06) lcolor(black) lpattern(solid) lwidth(medthick) || ///
		kdensity fe_firm_w if or_dest == 2, n(50)  bwidth(.06) lcolor(black) lpattern(dash) lwidth(medthick) ///
		xtitle("Firm productivity proxy (wage premium)") ///
		ytitle("Density") plotregion(lcolor(white)) ///
		legend(order(1 "Origin" 2 "Destination") region(lstyle(none))) ///
		note("P-values: T-test = `ttest' ; K-S = `ks'", size(small))
		
		graph export "${results}/202503_pred1_pdf.pdf", as(pdf) replace
		

		
		
		
/*
				
		
*--------------------------*
* PANEL A - REGRESSION
*--------------------------*

/*

set seed 6543

// events "spv --> spv"
		
	use "${data}/poach_ind_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 1
	
	// saving
	save "${temp}/pred1_spv_spv", replace

// events "spv --> emp"
		
	use "${data}/poach_ind_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became emp
	keep if type_emp == 1
	
	// generating identifier
	gen spv = 2
		
	save "${temp}/pred1_spv_emp", replace
	
// events "emp --> spv"
		
	use "${data}/poach_ind_emp", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 3
	
	// saving	
	save "${temp}/pred1_emp_spv", replace	

// combining events and keeping what we need

	use "${temp}/pred1_spv_spv", clear
	append using "${temp}/pred1_spv_emp" 
	append using "${temp}/pred1_emp_spv" 
	
	merge m:1 spv event_id using "${temp}/eventlist", keep(match)

	// labeling event typs		
	la def spv 1 "spv-spv" 2 "spv-emp" 3 "emp-spv", replace
	la val spv spv
	
	// organizing some variables
	// note: Destination = 1, Origin = 2 
	
	// fe_firm_d
	replace fe_firm_d = -99 if fe_firm_d==.
	g fe_firm_d_m = (fe_firm_d==-99)
			
	// wage premium: productivity proxy
	rename fe_firm_o fe_firm2
	rename fe_firm_d fe_firm1
				
	replace fe_firm1 = . if fe_firm1==-99
	replace fe_firm2 = . if fe_firm2==-99

	// reshaping data set
	egen unique_id = group(event_id spv)
	reshape long fe_firm, i(unique_id) j(or_dest)
	
	la def or_dest 1 "Destination" 2 "Origin"
	la val or_dest or_dest
	
		// for this regression, let's invert origin/destination
		gen destination = (or_dest == 1)
		
		label var destination "Destination firm"
		
	// pc_fe
	replace pc_fe = -99 if pc_fe==.
	g pc_fe_m = (pc_fe==-99)
	
	// pc_exp_ln -- NOTE: WE SHOULD NOT HAVE MISSING VALUES HERE
	replace pc_exp_ln = -99 if pc_exp_ln==.
	g pc_exp_m =(pc_exp_ln==-99)
	
	// regression
	
	eststo col1: reg fe_firm destination, rob
	
	eststo col2: reg fe_firm destination pc_wage_o_l1, rob
	
	eststo col3: reg fe_firm destination pc_wage_o_l1 pc_exp_ln pc_exp_m, rob
	
	eststo col4: reg fe_firm destination pc_wage_o_l1 pc_exp_ln pc_exp_m pc_fe pc_fe_m, rob
	
	// display table
	
	esttab  col1 col2 col3 col4,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		keep(destination) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  ///
		, labels("\cmark" ""))
	
	// save table

	esttab col1 col2 col3 col4 using "${results}/pred1_reg.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(destination "\midrule", nolabel) ///
		mgroups("Outcome: Firm productivity proxy (wage premium)",  /// 
		pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(destination) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Manager salary at origin = pc_wage_o_l1" ///
		"Manager experience = pc_exp_ln" "Manager ability = pc_fe"  /// 
		, labels("\cmark" ""))	
	
*--------------------------*
* PANEL B
*--------------------------*

/*

set seed 6543

// "spv --> spv" events
			
	use "${data}/evt_panel_m_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 1

	save "${temp}/destgrowth_spv", replace
	
// "spv --> emp" events
			
	use "${data}/evt_panel_m_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became spv
	keep if type_emp == 1
	
	// generating identifier
	gen spv = 2

	save "${temp}/destgrowth_spv_emp", replace	
		
// "emp --> spv" events	

	use "${data}/evt_panel_m_emp", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 3

	save "${temp}/destgrowth_emp", replace
			
// combining everything and keeping main events 

	use "${temp}/destgrowth_spv", clear
	append using "${temp}/destgrowth_spv_emp"
	append using "${temp}/destgrowth_emp"
	
	merge m:1 spv event_id using "${temp}/eventlist", keep(match)
	
	// outcome variables
	
		// total number of hires in destination plant
		gen d_h = d_h_dir + d_h_spv + d_h_emp
		
			// hire variables: winsorize to remove outliers 
			winsor d_h, gen(d_h_w) p(0.01) highonly
	
		// total number of employees in destination plant
		* d_emp: already in the data set
						
	// collapsing by ym_rel & setting up a panel
	
	collapse (median) d_h_w d_emp, by(ym_rel) // we report the median
				
	gen id = 1
	order id
	tsset id ym_rel
	
	// graphing
	
	tsline d_emp, recast(connect) mcolor(gs1) m(Oh) lcolor(gs1) ///
		ytitle("Number of employees (monthly)") ylabel(150(25)275, grid glpattern(dot) glcolor(gs13*.3) gmax) ||  ///
		tsline d_h_w, recast(bar) yaxis(2) color(gs8%60) ///
		ytitle("Number of hires (monthly)", axis(2)) ylabel(4(4)16, grid glpattern(dot) glcolor(gs13*.3) gmax axis(2)) ///
			graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(3)12) xline(-0.5, lpattern(dot) lcolor(gs13) lwidth(5)) ///
		legend(order(1 "Firm size (left axis)" 2 "New hires (right axis)") region(lcolor(white)) pos(6) col(2)) ///
		text(275 3.3 "Poaching event", size(medsmall) color(gs8))
		
		graph export "${results}/destgrowth.pdf", as(pdf) replace
		
*/		
