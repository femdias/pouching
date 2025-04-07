// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: September 2024

// Purpose: Event study around poaching events -- raw avgs.		
	
*--------------------------*
* ANALYSIS
*--------------------------*

// main line
	
	* evt_panel_m_x is the event-level panel with dest. plants and x refers to type of worker (spv, dir, emp) in origin plant
	use "${data}/evt_panel_m_spv", clear
	* we need to bind to get some selections of sample, don't worry about it
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	* keep only people that became spv
	keep if type_spv == 1
	tempfile spv
	save `spv'

	use "${data}/evt_panel_m_dir", clear
	merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
	keep if type_spv == 1
	tempfile dir
	save `dir'
	
	use "${data}/evt_panel_m_emp", clear
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	keep if type_spv == 1
	tempfile emp
	save `emp'
	
	
	* Binding dataset of people that were spv, dir or emp and became mgr at destinantion firm 
	use `spv', clear
	append using `dir'
	append using `emp'
	
	// 1.
	// a) The previous outcome variable has too many zeros.
	// Let us do the following:
	// in ym_rel = -1 (poaching event was in previous month)
	// (*) Firms that hired at least one person: d_h_emp >= 1 - this is our total number of firms
	bysort d_plant: gen hired_min1 = (ym_rel == -1 & d_h_emp >= 1)
	// (**) How many of them (d_h_emp >= 1 and ym_rel = -1) raided zero workers i.e. d_h_emp_0 == 0 
	bysort d_plant: gen raided_0 = (ym_rel == -1 & d_h_emp >= 1 & d_h_emp_o == 0)

	// Count the number of unique d_plant for hired_min1 and raided_0
	egen unique_hired_min1 = tag(d_plant) if hired_min1
	egen unique_raided_0 = tag(d_plant) if raided_0

	// Compute the ratio by dividing the count of raided_0 by hired_min1
	sum unique_hired_min1 if unique_hired_min1
	scalar count_hired_min1 = r(N)

	sum unique_raided_0 if unique_raided_0
	scalar count_raided_0 = r(N)

	// // (**)/(*) = % of firms that raided 0 workers following poaching event, given they hired at least 1 person
	display count_raided_0/count_hired_min1
	
	// b) what is the average share of raided workers when there was at least one person hired? 
	// // outcome variable -- share of raided workers if there was at least one person hired (d_h_emp >= 1)
	gen ratio = d_h_emp_o / d_h_emp if d_h_emp >= 1
	// replace ratio = 0 if ratio == . -- we don't want to replace this with zero. we want to calculate mean only where this var exists
	// baseline values (in ym_rel == -1)
	summarize ratio if ym_rel == -1, detail
	
	// c) Now we want to see share of raided workers when there was at least one person RAIDED (not hired) i.e. d_h_emp_o >= 1
	gen ratio2 = d_h_emp_o / d_h_emp if d_h_emp_o >= 1
	// replace ratio = 0 if ratio == . -- we don't want to replace this with zero. we want to calculate mean only where this var exists
	// baseline values (in ym_rel == -1)
	summarize ratio2 if ym_rel == -1, detail
	
	// 2. Back to initial dataset
	* Binding dataset of people that were spv, dir or emp and became mgr at destinantion firm 
	use `spv', clear
	append using `dir'
	append using `emp'
	
	// outcome variable
	gen ratio = d_h_emp_o / d_h_emp 
	replace ratio = 0 if ratio == .
	// baseline values (in ym_rel == -1)
	summarize ratio if ym_rel == -1, detail
	
	// raw averages
	
	collapse (mean) ratio, by(ym_rel)
				
	gen id = 1
	order id
	tsset id ym_rel
	
	tempfile raw1
	save `raw1'
	
		
// control line
	
	use "${data}/evt_panel_m_emp", clear
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	keep if type_emp == 1
	
	// outcome variable
	gen ratio = (d_h_emp_o - d_h_emp_o_pc) / (d_h_emp - d_h_emp_o_pc)
	replace ratio = 0 if ratio == .
			
		
	// raw averages
	collapse (mean) ratio, by(ym_rel)
				
	gen id = 2
	order id
	tsset id ym_rel
	
	tempfile raw2
	save `raw2'
	
	
	use `raw1', clear
	append using `raw2'
		
		
// figure -- usar mesmo design do baseline
tsline ratio if id == 1 & ym_rel >= -9, recast(connected) msymbol(T) mcolor(emerald) mlcolor(emerald) msize(small) ///
        lcolor(emerald%60) lpattern(dash) || ///
       tsline ratio if id == 2 & ym_rel >= -9, recast(connected) msymbol(X) mcolor(maroon) mlcolor(maroon) msize(small) ///
        lcolor(maroon%60) lpattern(dash_dot) ///
       graphregion(lcolor(white)) plotregion(lcolor(white)) ///
       legend(order(1 "Mgr is Poached" 2 "Non-Mgr is Poached") rows(1) region(lcolor(white)) pos(6) ring(1)) ///
       xlabel(-9(3)12) ///
       xtitle("Months Relative to Poaching Event") ///
       ytitle("Share of New Hires (Monthly)" "from Same Firm as Poached Worker") ///
       ylabel(0(.03).15) ///
       xline(-3, lpattern(dash) lcolor(black))



		
		
