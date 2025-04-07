// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Wage analysis (poached workers only; correlation with "information")

*--------------------------*
* ANALYSIS
*--------------------------*

// organizing some additional variables we need for this analysis

	use "output/data/evt_work_m_rs_dir", clear
	egen unique = tag(event_id)
	keep if unique == 1
	keep event_id d_emp_0 avg_wage_1digit avg_wage_real_plant avg_wage_plant d_emp_0_nondir d_emp_0_dir d_teamsize_0 
	save "temp/merging", replace			

// main analysis
	
use "output/data/cowork_panel_m_rs_dir", clear
	
	// sample selection
	
	merge m:1 event_id using "output/data/sample_selection_dir", keep(match) nogen

	// only one observation per poached individual
	
	keep if pc_individual == 1
	egen unique = tag(event_id cpf)
	keep if unique == 1
	
	// adding the variables we created above
		
	merge m:1 event_id using "temp/merging", keep(match) nogen
	
	// adding more variables: number of poached coworkers and their wages
	
	merge m:1 event_id using "output/data/wage_real_ln_cw", keep(master match) nogen

	
	
	gen wage_real_ln_cw_0 = wage_real_ln_cw
	replace wage_real_ln_cw_0 = 0 if wage_real_ln_cw_0 == .
	gen dummy = (wage_real_ln_cw_0 == 0)
		
	replace total_pc_coworkers = 0 if total_pc_coworkers == .

	gen total_pc_coworkers_ln = ln(total_pc_coworkers)
	replace total_pc_coworkers_ln = -99 if total_pc_coworkers_ln == .
	
	// modifying / creating variables
	
		// controlling for experience
		gen exp = age - educ_years - 6
			
		// controlling for log firm size	
		gen d_emp_ln = ln(d_emp_0)
			
		// team size in log	
		gen o_teamsize_l12_ln = ln(o_teamsize_l12)
		replace o_teamsize_l12_ln = -99 if o_teamsize_l12_ln == . // missing for two events (no director in t=-12)
		gen m_teamsize = (o_teamsize_l12_ln == -99) // dummy identifying the missing points
	
	// hypothesis testing:
	
	// a. the salary of a manager increases in the number of employees she oversaw
	// b. the salary of the poached manager is correlated with the quality of the subsequent poached coworkers
	// c. the salary of the poached manager increases in the number of poached workers
	
	// regressions
		
	eststo clear
		
		// hypothesis a. --> indep variable: team size
		
		eststo a1: reg wage_0 o_teamsize_l12_ln m_teamsize exp 				, rob
			
			estadd local experience "\cmark"
			estadd local firmsize	""
			estadd local wagebill	""
			
			summ wage_real_0 
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_real_plant 
			estadd scalar avg_wage_plant_avg = `r(mean)'
		
		eststo a2: reg wage_0 o_teamsize_l12_ln m_teamsize exp avg_wage_plant 		, rob
		
			estadd local experience "\cmark"
			estadd local firmsize	""
			estadd local wagebill	"\cmark"
			
			summ wage_real_0 
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_real_plant 
			estadd scalar avg_wage_plant_avg = `r(mean)'	
		

		eststo a3: reg wage_0 o_teamsize_l12_ln m_teamsize exp avg_wage_plant d_emp_ln 	, rob
		
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			
			summ wage_real_0
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_real_plant 
			estadd scalar avg_wage_plant_avg = `r(mean)'
		
		// hypothesis b. --> indep variable: raided coworkers' wage
		
		eststo b1: reg wage_0 wage_real_ln_cw_0 dummy exp 				, rob
			
			estadd local experience "\cmark"
			estadd local firmsize	""
			estadd local wagebill	""
			
			summ wage_real_0 
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_real_plant 
			estadd scalar avg_wage_plant_avg = `r(mean)'
	
		eststo b2: reg wage_0 wage_real_ln_cw_0 dummy exp avg_wage_plant 		, rob
		
			estadd local experience "\cmark"
			estadd local firmsize	""
			estadd local wagebill	"\cmark"
			
			summ wage_real_0 
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_real_plant 
			estadd scalar avg_wage_plant_avg = `r(mean)'
		

		eststo b3: reg wage_0 wage_real_ln_cw_0 dummy exp avg_wage_plant d_emp_ln 	, rob
		
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			
			summ wage_real_0 
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_real_plant 
			estadd scalar avg_wage_plant_avg = `r(mean)'
			
		// hypothesis c. --> indep variable: number of raided coworker	
		
		eststo c1: reg wage_0 total_pc_coworkers_ln dummy exp 				, rob
			
			estadd local experience "\cmark"
			estadd local firmsize	""
			estadd local wagebill	""
			
			summ wage_real_0 
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_real_plant 
			estadd scalar avg_wage_plant_avg = `r(mean)'
	
		eststo c2: reg wage_0 total_pc_coworkers_ln dummy exp avg_wage_plant 		, rob
		
			estadd local experience "\cmark"
			estadd local firmsize	""
			estadd local wagebill	"\cmark"
			
			summ wage_real_0 
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_real_plant
			estadd scalar avg_wage_plant_avg = `r(mean)'		

		eststo c3: reg wage_0 total_pc_coworkers_ln dummy exp avg_wage_plant d_emp_ln 	, rob
		
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			
			summ wage_real_0
			estadd scalar wage_0_avg = `r(mean)'
			
			summ avg_wage_real_plant
			estadd scalar avg_wage_plant_avg = `r(mean)'	
	
	// tables
			
		esttab a1 a2 a3 b1 b2 b3 using "output/results/tab_wage_corrinfo_dir.tex", tex ///
			replace frag compress noconstant nomtitles nogap collabels(none) ///
			mgroups("\textbf{Outcome var:} ln(wage) of poached manager (at destination)", ///
			pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span ///
			erepeat(\cmidrule(lr){@span})) ///
			keep(o_teamsize_l12_ln wage_real_ln_cw_0) ///
			cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
			coeflabels(o_teamsize_l12_ln "\hline \\ Team size (ln)" ///
			wage_real_ln_cw_0 "Avg of poached") ///
			stats(N r2 experience wagebill firmsize wage_0_avg avg_wage_plant_avg , fmt(0 3 0 0 0 0 0) ///
			label("\\ Obs" "R-Squared" "\\ \textbf{Controls:} \\ Poached manager \\ \textit{Experience (yrs)}" ///
			"\\ Destination firm \\ \textit{Avg. wage bill}"  "\textit{Firm Size}" ///
			"\\ \textbf{Level means:} \\ Poached mgr wage (R\\$)" "Avg. plant wage bill (R\\$)")) ///
			obslast nolines ///
			starlevels(* 0.1 ** 0.05 *** 0.01)
		
		esttab a1 a3 b1 b3 c1 c3 using "output/results/tab_wage_corrinfo_dir_alt.tex", tex ///
			replace frag compress noconstant nomtitles nogap collabels(none) ///
			mgroups("\textbf{Outcome var:} ln(wage) of poached manager (at destination)", ///
			pattern(1 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span ///
			erepeat(\cmidrule(lr){@span})) ///
			keep(o_teamsize_l12_ln wage_real_ln_cw_0 total_pc_coworkers_ln) ///
			cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
			coeflabels(o_teamsize_l12_ln "\hline \\ Team size (ln)" ///
			wage_real_ln_cw_0 "Avg of poached" ////
			total_pc_coworkers_ln "\# poached co-workers") ///
			stats(N r2 experience wagebill firmsize wage_0_avg avg_wage_plant_avg , fmt(0 3 0 0 0 0 0) ///
			label("\\ Obs" "R-Squared" "\\ \textbf{Controls:} \\ Poached manager \\ \textit{Experience (yrs)}" ///
			"\\ Destination firm \\ \textit{Avg. wage bill}"  "\textit{Firm Size}" ///
			"\\ \textbf{Level means:} \\ Poached mgr wage (R\\$)" "Avg. plant wage bill (R\\$)")) ///
			obslast nolines ///
			starlevels(* 0.1 ** 0.05 *** 0.01)
		
	// binscatter using the complete specification
		
	
		binscatter wage_0 o_teamsize_l12_ln 	if o_teamsize_l12_ln != -99, 		control(m_teamsize exp avg_wage_plant d_emp_ln) ///
			ytitle("Ln(wage) of poached manager (at destination)") xtitle("Team size (ln) at origin firm")
		
		binscatter wage_0 wage_real_ln_cw_0 	if wage_real_ln_cw_0 != 0, 	    	control(dummy exp avg_wage_plant d_emp_ln)  ///
			ytitle("Ln(wage) of poached manager (at destination)") xtitle("Avg of poached co-worker wage (ln) at destination firm")  
		
		binscatter wage_0 total_pc_coworkers_ln if  total_pc_coworkers_ln != -99, 	control(dummy exp avg_wage_plant d_emp_ln)  ///
			ytitle("Ln(wage) of poached manager (at destination)") xtitle("# of poached co-workers")
		
		
	// bar graph: number of poached coworkers and wages
	
		gen tookany = (dummy == 0)
	
		graph bar (mean) wage_real_0, over(tookany, relabel(1 "No co-poaching"  2 "At least one co-poaching")) ///
			bar(1, fcolor(gs13) lcolor(black))  blabel(bar) ///
			ytitle("Mean of real wage (R$)") graphregion(lcolor(white)) plotregion(lcolor(white))
			
			graph export "output/results/fig_wage_copoaching_dir.pdf", as(pdf) replace
		
	
