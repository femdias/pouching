// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: May 2024

// Purpose: Wage analysis (poached workers only; correlation with "information")

*--------------------------*
* ANALYSIS
*--------------------------*

// MAIN ANALYSIS

	use "${data}/poach_ind_dir", clear
	merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
	gen type = "dir"
	tempfile dir
	save `dir'
	
	use "${data}/poach_ind_spv", clear
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	gen type = "spv"
	tempfile spv
	save `spv'
	
	use `dir', clear
	append using `spv'

	// organizing independent variables
	
	// team size in origin plant	
	gen teamsize_o = ln(o_teamsize_l12)
	replace teamsize_o = -99 if teamsize_o == .
	gen m_teamsize_o = (teamsize_o == -99) // dummy identifying the missing points
	
	// raided co-workers wage in destination plant
	gen rd_coworker_wage_d_0 = rd_coworker_wage_d
	replace rd_coworker_wage_d_0 = 0 if rd_coworker_wage_d == .
	gen rd_coworker_wage_d_miss = (rd_coworker_wage_d_0 == 0) // dummy identifying the missing points
	
	// raided co-workers wage in origin plant
	gen rd_coworker_wage_o_0 = rd_coworker_wage_o
	replace rd_coworker_wage_o_0 = 0 if rd_coworker_wage_o == .
	gen rd_coworker_wage_o_miss = (rd_coworker_wage_o_0 == 0) // dummy identifying the missing points
	
	// raided co-workers fe
	gen rd_coworker_fe_99 = rd_coworker_fe
	replace rd_coworker_fe_99 = 99 if rd_coworker_fe == .
	gen rd_coworker_fe_miss = (rd_coworker_fe_99 == 99) // dummy identifying the missing points
	

	// hypothesis testing:
	
	// a. the salary of a manager increases in the number of employees she oversaw
	
	// b. the salary of the poached manager is correlated with the quality of the subsequent poached coworkers
	//    quality = proxied by realized wages (destination firm)
	
	// c. the salary of the poached manager is correlated with the quality of the subsequent poached coworkers
	//    quality = proxied by pre-raid wages (origin firm)
	
	// d. the salary of the poached manager is correlated with the quality of the subsequent poached coworkers
	//    quality = proxied by worker FE from low-tech AKM model 
	
	// regressions
	
	eststo clear
		
		eststo a1_all: reg pc_wage_d teamsize_o  m_teamsize_o             pc_exp 			 , rob
		
			estadd local experience "\cmark"
			estadd local period "2004-2016"
		
		eststo b1_all: reg pc_wage_d rd_coworker_wage_d_0 rd_coworker_wage_d_miss  pc_exp 			 , rob
		
			estadd local experience "\cmark"
			estadd local period "2004-2016"
		
		eststo c1_all: reg pc_wage_d rd_coworker_wage_o_0 rd_coworker_wage_o_miss  pc_exp 			 , rob
			
			estadd local experience "\cmark"
			estadd local period "2004-2016"
		
		eststo d1_all: reg pc_wage_d rd_coworker_fe_99    rd_coworker_fe_miss      pc_exp if pc_ym >= ym(2010,1) , rob
		
			estadd local experience "\cmark"
			estadd local period "2010-2016"
		
	foreach e in spv dir {
		
		eststo a1_`e': reg pc_wage_d teamsize_o           m_teamsize_o             pc_exp ///
			if type == "`e'", rob
			
			estadd local experience "\cmark"
			estadd local period "2004-2016"
		
		eststo b1_`e': reg pc_wage_d rd_coworker_wage_d_0 rd_coworker_wage_d_miss  pc_exp ///
			if type == "`e'", rob
			
			estadd local experience "\cmark"
			estadd local period "2004-2016"
		
		eststo c1_`e': reg pc_wage_d rd_coworker_wage_o_0 rd_coworker_wage_o_miss  pc_exp ///
			if type == "`e'", rob
			
			estadd local experience "\cmark"
			estadd local period "2004-2016"
		
		eststo d1_`e': reg pc_wage_d rd_coworker_fe_99    rd_coworker_fe_miss      pc_exp ///
			if type == "`e'" & pc_ym >= ym(2010,1) , rob
			
			estadd local experience "\cmark"
			estadd local period "2010-2016"
			
	}	
		

		
	
	
	// tables
	
	foreach e in all spv dir {
			
		esttab a1_`e' b1_`e' c1_`e' d1_`e' using "${results}/reg_wage_info_`e'.tex", tex ///
			replace frag compress noconstant nomtitles nogap collabels(none) ///
			mgroups("\textbf{Outcome var:} ln(wage) of poached manager (dest)", ///
			pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span ///
			erepeat(\cmidrule(lr){@span})) ///
			keep(teamsize_o rd_coworker_wage_d_0 rd_coworker_wage_o_0 rd_coworker_fe_99) ///
			cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
			coeflabels(teamsize_o "\hline \\ Team size (ln)" ///
			rd_coworker_wage_d_0 "Avg wage raided (ln) - dest" ///
			rd_coworker_wage_o_0 "Avg wage raided (ln) - orig" ///
			rd_coworker_fe_99  "Avg FE raided" ) ///
			stats(N r2 experience period , fmt(0 3 0 0) ///
			label("\\ Obs" "R-Squared" "\\ \textbf{Controls:} \\ Poached manager \\ \textit{Experience (yrs)}" ///
			"\\ Cohorts")) ///
			obslast nolines ///
			starlevels(* 0.1 ** 0.05 *** 0.01)
			
	} 	
		
		
	
		
/* ARCHIVE	


/*

// organizing some additional variables we need for this analysis

	use "output/data/evt_work_m_rs_dir", clear
	egen unique = tag(event_id)
	keep if unique == 1
	keep event_id d_emp_0 avg_wage_1digit avg_wage_real_plant avg_wage_plant d_emp_0_nondir d_emp_0_dir d_teamsize_0 
	save "temp/merging", replace
	
*/



// old regressions

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
		
		/*
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
			
			*/
		
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
