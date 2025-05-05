// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Testing Prediction 2
// "When a firm poaches a manager from another firm, the poaching firm is more likely to also raid their workers"

*--------------------------*
* ANALYSIS
*--------------------------*
	
	use "${data}/202503_evt_panel_m", clear
	
	// which are the events we are interested in?
	gen keep = .
				
		// identify the main events events we're interested in 
		merge m:1 eventid using "${temp}/202503_eventlist"
		replace keep = 1 if _merge == 3
		drop _merge
	
		// identify the placebo events emp-emp (9) with at least 50 employees
		replace keep = 1 if type == 9 & d_n_emp_lavg >= 50 & o_n_emp_lavg >= 50
	
	keep if keep == 1
	
	// organizing some variables we need
		
		// number of raided hires
		g numraid = .
		
			// spv-spv events: all emp hires count
			replace numraid = d_hire_emp_o		if type == 5
			
			// spv-emp events: discount 1 hire in t=0 (it's the main individual)
			replace numraid = d_hire_emp_o 		if type == 6
			replace numraid = numraid - 1		if type == 6 & ym_rel == 0
			
			// emp-spv events: all emp hires count
			replace numraid = d_hire_emp_o 		if type == 8
			
			// emp-emp events: discount 1 hire in t=0 (it's the main individual)
			replace numraid = d_hire_emp_o		if type == 9
			replace numraid = numraid - 1		if type == 9 & ym_rel == 0
		
		// number of hires
		g numhire = .
		
			// spv-spv events: all emp hires count
			replace numhire = d_hire_emp 		if type == 5
			
			// spv-emp events: discount 1 hire in t=0 (it's the main individual)
			replace numhire = d_hire_emp		if type == 6
			replace numhire = numhire - 1		if type == 6 & ym_rel == 0
			
			// emp-spv events: all emp hires count
			replace numhire = d_hire_emp		if type == 8
			
			// emp-emp events: discount 1 hire in t=0 (it's the main individual)
			replace numhire = d_hire_emp 		if type == 9
			replace numhire = numhire - 1		if type == 9 & ym_rel == 0

	// analysis -- event study
	
		// main outcome variable: share of raided hires relative to all hires
			
		gen ratio = (numraid) / (numhire)
		replace ratio = 0 if ratio == .
	
		// event time dummies		
						
			forvalues i = -12/12 {
				if (`i' < 0) {
					local j = abs(`i')
					gen evt_l`j' = (ym_rel == `i')
				}
				else if `i' >= 0 {
					gen evt_f`i' = (ym_rel == `i') 
				}
			}
			
		// event zero for graphing purposes
		gen evt_zero = 1
		
		// running the regressions
	
			// main events
			
			eststo main: reghdfe ratio $evt_vars ///
				if ym_rel >= -9 & (type == 5 | type == 6 | type == 8) , absorb(eventid) vce(cluster eventid)			
				
			eststo mainnum: reghdfe numraid $evt_vars ///
				if ym_rel >= -9 & (type == 5 | type == 6 | type == 8) , absorb(eventid) vce(cluster eventid)
			
			// control events
			
			eststo control: reghdfe ratio $evt_vars ///
				if ym_rel >= -9 & type == 9, absorb(eventid) vce(cluster eventid)
				
			eststo controlnum: reghdfe numraid $evt_vars ///
				if ym_rel >= -9 & type == 9, absorb(eventid) vce(cluster eventid)
				
	// analysis -- regression
				
		// collapsing at the event level
		keep if ym_rel >= 0
		collapse (sum) numraid numhire (mean) d_n_emp_lavg, by(eventid type)
		
		// outcome variables:
	
		// raid 1 or more workers
		gen raid = (numraid >= 1 & numraid != .)
		
		// number of raided workers
		* already in data set: numraid
		
		// share of raided workers
		gen shareraid = (numraid / numhire)
		replace shareraid = 0 if shareraid ==.
		
		// right-hand size:
		
		// dummy for event type
		gen spv = (type == 5 | type == 6 | type == 8)
		label var spv "\hline \\ Poached manager event = 1"
		
		// firm size (in log)
		gen d_n_emp_lavg_ln = ln(d_n_emp_lavg)
		
		// regressions
			
			eststo reg1: reg raid spv, rob
			
				summ raid, detail
				local lhs: display %4.3f r(mean)
				di "`lhs'"
				estadd local lhs `lhs'
			
			eststo reg2: reg raid spv d_n_emp_lavg_ln, rob
			
				summ raid, detail
				local lhs: display %4.3f r(mean)
				di "`lhs'"
				estadd local lhs `lhs'
			
			eststo reg3: reg numraid spv, rob
			
				summ numraid, detail
				local lhs: display %4.3f r(mean)
				di "`lhs'"
				estadd local lhs `lhs'
			
			eststo reg4: reg numraid spv d_n_emp_lavg_ln, rob
			
				summ numraid, detail
				local lhs: display %4.3f r(mean)
				di "`lhs'"
				estadd local lhs `lhs'
			
			eststo reg5: reg shareraid spv, rob
			
				summ shareraid, detail
				local lhs: display %4.3f r(mean)
				di "`lhs'"
				estadd local lhs `lhs'
			
			eststo reg6: reg shareraid spv d_n_emp_lavg_ln, rob
			
				summ shareraid, detail
				local lhs: display %4.3f r(mean)
				di "`lhs'"
				estadd local lhs `lhs'		
	
	// generating figures
	
	clear
			
	coefplot (main, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
		 (control, recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months relative to poaching event") ///
		 ytitle("Share of new hires" "from the same firm as poached worker") ///
		 ylabel(-.02(.02).08) name(spv, replace)
		 
		 graph export "${results}/202503_pred2_ratio.pdf", as(pdf) replace
		
	coefplot (mainnum, recast(connected) keep(${evt_vars}) msymbol(T) mcolor(black%60) mlcolor(black%80) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash)) ///
		 (controlnum, recast(connected) keep(${evt_vars}) msymbol(X) mcolor(black) mlcolor(black) msize(medium) ///
		  levels(95) lcolor(black%60) ciopts(lcolor(black%60)) lpattern(dash_dot)) ///
		 , ///
		 omitted keep(${evt_vars}) vertical yline(0, lcolor(black)) xline(7, lcolor(black) lpattern(dash)) ///
		 plotregion(lcolor(white)) ///
		 legend(order(2 "Manager poached" 4 "Non-manager poached" ) rows(1) region(lcolor(white)) pos(6) ring(1)) ///
		 xlabel(1 "-9" 4 "-6" 7 "-3" 10 "0" 13 "3" 16 "6" 19 "9" 22 "12") ///
		 xtitle("Months relative to poaching event") ///
		 ytitle("Average number of raided hires" ) ///
		 ylabel(0(1)2) name(spv_num, replace)
		 
		 graph export "${results}/202503_pred2_numraid.pdf", as(pdf) replace	 
	
	// generating tables
	
	clear
		 
	// display table
		
	esttab reg1 reg2 reg3 reg4 reg5 reg6,  /// 	
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("Raid > 1" "Raid > 1"  "# Raid" "# Raid" "Share Raid" "Share Raid") ///
		keep(spv) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(lhs N r2 , fmt(3 0 3) label("\\ Mean LHS" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Destination firm controls} \\ Firm size = d_n_emp_lavg_ln" ///
		, labels("\cmark" ""))
		 
	// save table

	esttab reg1 reg2 reg3 reg4 reg5 reg6 using "${results}/202503_pred2_reg.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		mgroups(">1 raided worker" "\# of raided worker" "\% raided new hires",  /// 
		pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(spv) coeflabels(spv "\hline \\ Poached manager event = 1") ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(lhs N r2 , fmt(3 0 3) label("\\ Mean LHS" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Destination firm controls} \\ Firm size = d_n_emp_lavg_ln", labels("\cmark" ""))
	
