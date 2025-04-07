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
	
*--------------------------*
* PANEL B
*--------------------------*

	use "${data}/202503_evt_panel_m", clear
	
	// we're only interested in spv-spv, spv-emp, and emp-spv
	keep if type == 1 | type == 2 | type == 3
	
	// keeping only the events we're interested in -- THIS PART HAS TO BE MODIFIED!!! USING TEMP FILE!!!
	// WHAT I SHOULD DO HERE: RUN THE COMPLETE REGRESSION (ONCE I'VE DEFINED IT) & KEEP E(SAMPLE) == 1
	// REVIEW THIS ONCE I GET TO PREDICTIONS 4, 5, AND 6
	rename type spv
	merge m:1 spv event_id using "${temp}/eventlist"
	keep if _merge == 3
	drop _merge
	rename spv type
	
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
		
		graph export "${results}/202503_pred1_destgrowth.pdf", as(pdf) replace
			
