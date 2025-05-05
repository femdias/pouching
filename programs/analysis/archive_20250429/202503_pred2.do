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
	
	// we're only interested in spv-spv, spv-emp, emp-spv, and emp-emp
	keep if type == 1 | type == 2 | type == 3 | type == 4
				
	// keeping only the events we're interested in -- THIS PART HAS TO BE MODIFIED!!! USING TEMP FILE!!!
	// WHAT I SHOULD DO HERE: RUN THE COMPLETE REGRESSION (ONCE I'VE DEFINED IT) & KEEP E(SAMPLE) == 1
	// REVIEW THIS ONCE I GET TO PREDICTIONS 4, 5, AND 6
	rename type spv
	merge m:1 spv event_id using "${temp}/eventlist"
	keep if spv == 4 | _merge == 3 // this event list does not include the placebo emp-emp events
	drop _merge
	rename spv type
	
	// organizing some variables we need
	
		// generate unique id
		egen unique_id = group(event_id type)
	
		// hire variables: winsorize to remove outliers 
		*winsor d_h_emp_o, gen(d_h_emp_o_w) p(0.01) highonly
		*winsor d_h_emp, gen(d_h_emp_w) p(0.01) highonly
		*winsor d_h_emp_o_pc, gen(d_h_emp_o_pc_w) p(0.01) highonly
		
			// NOTE: NOW THAT I AM COMBINING IN THE SAME DATA SET ALL EVENTS TYPES, I HAVE TO THINK A BIT MORE HOW TO WINSORIZE
			// SHOULD IT BE BY EVENT TYPE?
			// WELL, IN FACT, PERHAPS WE SHOULD NOT WINSORIZE! WE SHOULD DIRECTLY REMOVE THE EVENTS THAT SEEM ODD
			// BUT THE CRITERIA SHOULD BE TRANSPARENT
		
		gen d_h_emp_o_w = d_h_emp_o
		gen d_h_emp_w = d_h_emp
		ge d_h_emp_o_pc_w = d_h_emp_o_pc
		
		// main outcome variable: share of raided hires relative to all hires
		
		g numraid = .
		replace numraid = d_h_emp_o_w 			if type == 1
		replace numraid = d_h_emp_o_w - d_h_emp_o_pc_w  if type == 2
		replace numraid = d_h_emp_o_w 			if type == 3
		replace numraid = d_h_emp_o_w - d_h_emp_o_pc_w	if type == 4
		
		g numhire = .
		replace numhire = d_h_emp_w 			if type == 1
		replace numhire = d_h_emp_w - d_h_emp_o_pc_w 	if type == 2
		replace numhire = d_h_emp_w 			if type == 3
		replace numhire = d_h_emp_w - d_h_emp_o_pc_w		if type == 4
		
		// number of employees -- use t=0 value
		gen d_emp_t0_temp = d_emp if ym_rel == 0
		egen d_emp_t0 = max(d_emp_t0_temp), by(unique_id)
		drop d_emp_t0_temp
		
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
			
			eststo main: reghdfe ratio $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
				& ym_rel >= -9 & (type == 1 | type == 2 | type == 3) , absorb(unique_id d_plant) vce(cluster unique_id)			
				
			eststo mainnum: reghdfe numraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
				& ym_rel >= -9 & (type == 1 | type == 2 | type == 3) , absorb(unique_id d_plant) vce(cluster unique_id)
			
			// control events
			
			eststo control: reghdfe ratio $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
				& ym_rel >= -9 & type == 4, absorb(event_id d_plant) vce(cluster event_id)
				
			eststo controlnum: reghdfe numraid $evt_vars if pc_ym >= ym(2010,1) & pc_ym <= ym(2016,12) ///
				& ym_rel >= -9 & type == 4, absorb(event_id d_plant) vce(cluster event_id)
			
	// analysis -- regression
				
		// collapsing at the event level
		keep if ym_rel >= 0
		collapse (sum) numraid numhire (mean) d_emp_t0, by(unique_id type)
		drop unique_id
		
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
		gen spv = (type == 1 | type == 2 | type == 3)
		label var spv "\hline \\ Manager-Manager"
		
		// firm size (in log)
		gen d_emp_ln = ln(d_emp_t0)
		
		// regressions
			
			eststo reg1: reg raid spv, rob
			
				summ raid, detail
				local lhs: display %4.3f r(mean)
				di "`lhs'"
				estadd local lhs `lhs'
			
			eststo reg2: reg raid spv d_emp_ln, rob
			
				summ raid, detail
				local lhs: display %4.3f r(mean)
				di "`lhs'"
				estadd local lhs `lhs'
			
			eststo reg3: reg numraid spv, rob
			
				summ numraid, detail
				local lhs: display %4.3f r(mean)
				di "`lhs'"
				estadd local lhs `lhs'
			
			eststo reg4: reg numraid spv d_emp_ln, rob
			
				summ numraid, detail
				local lhs: display %4.3f r(mean)
				di "`lhs'"
				estadd local lhs `lhs'
			
			eststo reg5: reg shareraid spv, rob
			
				summ shareraid, detail
				local lhs: display %4.3f r(mean)
				di "`lhs'"
				estadd local lhs `lhs'
			
			eststo reg6: reg shareraid spv d_emp_ln, rob
			
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
		indicate("\textbf{Destination firm controls} \\ Firm size = d_emp_ln" ///
		, labels("\cmark" ""))
		 
	// save table

	esttab reg1 reg2 reg3 reg4 reg5 reg6 using "${results}/202503_pred2_reg.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		refcat(d_size_w_ln "\midrule", nolabel) ///
		mgroups("At Least 1 Raid" "\# of Raided Workers" "Share of Raided Workers",  /// 
		pattern(1 0 1 0 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(spv) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		stats(lhs N r2 , fmt(3 0 3) label("\\ Mean LHS" "Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Destination firm controls} \\ Firm size = d_emp_ln", labels("\cmark" ""))
			
