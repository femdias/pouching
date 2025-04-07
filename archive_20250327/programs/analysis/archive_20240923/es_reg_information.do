// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Wage analysis (poached workers only; correlation with "information")

*--------------------------*
* ANALYSIS
*--------------------------*

// MAIN ANALYSIS

	use "${data}/poach_ind_spv", clear
	
	// sample restrictions
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// adding event type variables
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen

	// outcome variable: salary of poached managers
	
	// organizing independent variables
	
		// a. team size in origin plant
	
			gen teamsize_cw_ln = ln(team_cw)
			replace teamsize_cw_ln = -99 if teamsize_cw_ln == .
			gen teamsize_cw_ln_m = (teamsize_cw_ln == -99) // dummy identifying the missing points
		
		// b. avg wage of raided employees at destination firm

			replace rd_coworker_wage_d = -99 if rd_coworker_wage_d == .
			gen rd_coworker_wage_d_m = (rd_coworker_wage_d == -99) // dummy identifying the missing points
		
		// c. avg AKM worker FE of raided employees
		
			replace rd_coworker_fe = -99 if rd_coworker_fe == .
			gen rd_coworker_fe_m = (rd_coworker_fe == -99) // dummy identifying the missing points
			
		// d. number of raided workers
		
			gen rd_coworker_n_ln = ln(rd_coworker_n) 
			replace rd_coworker_n_ln = -99 if rd_coworker_n_ln == .
			gen rd_coworker_n_ln_m = (rd_coworker_n_ln == -99) // dummy identifying the missing points
	
	// organizing control variables
		
		// firm size
		gen d_size_ln = ln(d_size)
		
		// AKM firm FE of origin firm
		replace fe_firm_o = -99 if fe_firm_o == .
		gen fe_firm_o_m = (fe_firm_o == -99)
		
		// AKM firm FE of destination firm
		replace fe_firm_d = -99 if fe_firm_d == .
		gen fe_firm_d_m = (fe_firm_d == -99)
	
	// regressions
	
	local basectrl "pc_exp d_wage_real_ln d_size_ln"
	local akmctrl  "fe_firm_o fe_firm_o_m fe_firm_d fe_firm_d_m"
	
	eststo clear
		
		eststo a1_base: reg pc_wage_d teamsize_cw_ln teamsize_cw_ln_m ///
				`basectrl' if type_spv == 1, rob
		
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	" "
			estadd local fe_o	" "
			estadd local period "2004-2016"
			
		eststo a1_base_2010: reg pc_wage_d teamsize_cw_ln teamsize_cw_ln_m ///
				`basectrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	" "
			estadd local fe_o	" "
			estadd local period "2010-2016"	
			
			
		eststo a1_all: reg pc_wage_d teamsize_cw_ln teamsize_cw_ln_m ///
				`basectrl' `akmctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	"\cmark"
			estadd local fe_o	"\cmark"
			estadd local period "2010-2016"
			
		
		
		eststo b1_base: reg pc_wage_d rd_coworker_wage_d rd_coworker_wage_d_m ///
				`basectrl' if type_spv == 1, rob
			
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	" "
			estadd local fe_o	" "
			estadd local period "2004-2016"
			
		eststo b1_base_2010: reg pc_wage_d rd_coworker_wage_d rd_coworker_wage_d_m ///
				`basectrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
			
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	" "
			estadd local fe_o	" "
			estadd local period "2010-2016"	
	
			
		eststo b1_all: reg pc_wage_d rd_coworker_wage_d rd_coworker_wage_d_m ///
				`basectrl' `akmctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
			
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	"\cmark"
			estadd local fe_o	"\cmark"
			estadd local period "2010-2016"
	
			
		eststo c1_base: reg pc_wage_d rd_coworker_fe rd_coworker_fe_m ///
				`basectrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob

			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	" "
			estadd local fe_o	" "
			estadd local period "2010-2016"	
			
			
			
		eststo c1_all: reg pc_wage_d rd_coworker_fe rd_coworker_fe_m ///
				`basectrl' `akmctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
	
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	"\cmark"
			estadd local fe_o	"\cmark"
			estadd local period "2010-2016"
			
			
		eststo d1_base: reg pc_wage_d rd_coworker_n_ln rd_coworker_n_ln_m ///
				`basectrl' if type_spv == 1, rob
		
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	" "
			estadd local fe_o	" "
			estadd local period "2004-2016"
			
		eststo d1_base_2010: reg pc_wage_d rd_coworker_n_ln rd_coworker_n_ln_m ///
				`basectrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	" "
			estadd local fe_o	" "
			estadd local period "2010-2016"	
			
			
		eststo d1_all: reg pc_wage_d rd_coworker_n_ln rd_coworker_n_ln_m ///
				`basectrl' `akmctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	"\cmark"
			estadd local fe_o	"\cmark"
			estadd local period "2010-2016"	
			
		
			
	// table

		esttab a1_base a1_base_2010 a1_all d1_base d1_base_2010 d1_all b1_base b1_base_2010 b1_all c1_base c1_all ///
			using "${results}/reg_wage_pc.tex", tex ///
			replace frag compress noconstant nomtitles nogap collabels(none) ///
			mgroups("\textbf{Outcome var:} ln(wage) of poached manager (at destination)", ///
			pattern(1 0 0 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span ///
			erepeat(\cmidrule(lr){@span})) ///
			keep(teamsize_cw_ln rd_coworker_n_ln rd_coworker_wage_d rd_coworker_fe) ///
			cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
			coeflabels(teamsize_cw_ln "\hline \\ Ln(occ group empl)" ///
			rd_coworker_n_ln "Ln(number raided coworkers)" ///
			rd_coworker_wage_d "Avg raided wage (destination)" ///
			rd_coworker_fe  "Avg raided FE" ) ///
			stats(N r2 experience firmsize wagebill fe_d fe_o period , ///
			fmt(0 3 0 0 0 0 0 0 0 0) ///
			label("\\ Obs" "R-Squared" "\\ \textbf{Controls:} \\ Poached manager \\ \textit{Experience (yrs)}" ///
			"\\ Destination firm \\ \textit{Firm size}" "\textit{Avg. wage bill}" ///
			"\\ AKM firm effects \\ \textit{Destination}" "\textit{Origin}" ///
			"\\ \textbf{Cohorts}")) ///
			obslast nolines ///
			starlevels(* 0.1 ** 0.05 *** 0.01)
			
