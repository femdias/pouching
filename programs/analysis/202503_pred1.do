// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: March 2025

// Purpose: Testing Prediction 1
// "Managers are poached by more productive firms"

*--------------------------*
* PANEL A
*--------------------------*

	use "${data}/202503_poach_ind", clear
	
	// which are the events we are interested in?
	gen keep = .
				
		// identify the main events events we're interested in 
		merge m:1 eventid using "${temp}/202503_eventlist"
		replace keep = 1 if _merge == 3
		drop _merge
	
	keep if keep == 1
	
	// for this analysis, we need long format
	// variable of interest: fe_firm
	// note: origin = 1, destination = 2
	
	rename o_firm_akm_fe fe_firm1
	rename d_firm_akm_fe fe_firm2
	
	reshape long fe_firm, i(eventid) j(or_dest)
	
	la var or_dest "Origin or destination"
	la def or_dest 1 "Origin" 2 "Destination", replace
	la val or_dest or_dest
	
	la var fe_firm "Wage premium"
		
	// winsorize top and bottom .1% (for graphing purposes) 
	winsor fe_firm, gen(fe_firm_w) p(0.001)
	la var fe_firm_w "Wage premium (winsorized)"
	
	// analysis

		// winsorize top and bottom .1%
	
		winsor fe_firm, gen(fe_firm_w) p(0.001)

		ksmirnov fe_firm_w, by(or_dest)
		local ks: display %4.3f r(p)
		di "`ks'"
		
		ttest fe_firm_w, by(or_dest)
		local ttest: display %4.3f r(p)
		di "`ttest'"
		local diff = r(mu_2) - r(mu_1)
		local diff: display %4.3f `diff'
		di "`diff'"

		// CDF
		
		distplot fe_firm_w, over(or_dest) xtitle("Firm productivity proxy (wage premium)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(dash solid) lwidth(medthick medthick) ///
		legend(order(1 2) region(lstyle(none))) ///
		text(.2 .65 "{bf:Equality of distributions test:}" ///
		" K-S p-value < `ks'" " " "{bf: Equality of means:}" "{&beta}{subscript:D} - {&beta}{subscript:O} = `diff'" ///
		"p-value < `ttest'" , justification(right))
		
		graph export "${results}/202503_prod_od_w_cdf.pdf", as(pdf) replace
		
		// PDF
		
		// note: bwidth = .06 is 1.5 times the default bandwidth
		twoway kdensity fe_firm_w if or_dest == 1, n(50) bwidth(.06) lcolor(black) lpattern(dash) lwidth(medthick) || ///
		kdensity fe_firm_w if or_dest == 2, n(50)  bwidth(.06) lcolor(black) lpattern(solid) lwidth(medthick) ///
		xtitle("Firm productivity proxy (wage premium)") ///
		ytitle("Density") plotregion(lcolor(white)) ///
		legend(order(1 "Origin" 2 "Destination") region(lstyle(none))) ///
		text(1.3 .65 "{bf:Equality of distributions test:}" ///
		" K-S p-value < `ks'" " " "{bf: Equality of means:}" "{&beta}{subscript:D} - {&beta}{subscript:O} = `diff'" ///
		"p-value < `ttest'" , justification(right))
		
		graph export "${results}/202503_prod_od_w_pdf.pdf", as(pdf) replace
	
*--------------------------*
* PANEL B
*--------------------------*

	use "${data}/202503_evt_panel_m", clear
	
	// which are the events we are interested in?
	gen keep = .
				
		// identify the main events events we're interested in 
		merge m:1 eventid using "${temp}/202503_eventlist"
		replace keep = 1 if _merge == 3
		drop _merge
	
	keep if keep == 1
	
	// outcome variables
	
		// total number of hires in destination plant
		* d_hire: already in the data set
	
		// total number of workers in destination plant
		* d_wkr: already in the data set
						
	// collapsing by ym_rel & setting up a panel
	
	collapse (median) d_hire d_wkr, by(ym_rel) // we report the median
				
	gen id = 1
	order id
	tsset id ym_rel
	
	// graphing
	
	tsline d_wkr, recast(connect) mcolor(gs1) m(Oh) lcolor(gs1) ///
		ytitle("Number of employees (monthly)") ylabel(275(25)400, grid glpattern(dot) glcolor(gs13*.3) gmax) ||  ///
		tsline d_hire, recast(bar) yaxis(2) color(gs8%60) ///
		ytitle("Number of hires (monthly)", axis(2)) ylabel(8(4)20, grid glpattern(dot) glcolor(gs13*.3) gmax axis(2)) ///
			graphregion(lcolor(white)) plotregion(lcolor(white)) ///
		xtitle("Relative month (manager poached at t=-1, starts at t=0)") xlabel(-12(3)12) xline(-0.5, lpattern(dot) lcolor(gs13) lwidth(5)) ///
		legend(order(1 "Firm size (left axis)" 2 "New hires (right axis)") region(lcolor(white)) pos(6) col(2)) ///
		text(400 3.3 "Poaching event", size(medsmall) color(gs8))
		
		graph export "${results}/202503_destgrowth.pdf", as(pdf) replace
			
