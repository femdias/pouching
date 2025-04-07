// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Wage analysis (poached workers only; correlation with "information")

*--------------------------*
* ANALYSIS
*--------------------------*

// MAIN ANALYSIS

	
	
	* evt_panel_m_x is the event-level panel with dest. plants and x refers to type of worker (spv, dir, emp) in origin plant
	use "${data}/poach_ind_spv", clear
	* we need to bind to get some selections of sample, don't worry about it
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	* keep only people that became spv
	keep if type_spv == 1
	tempfile spv
	save `spv'
	
	
	
	use "${data}/poach_ind_dir", clear
	merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
	keep if type_spv == 1
	tempfile dir
	save `dir'
	
	use "${data}/poach_ind_emp", clear
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	keep if type_spv == 1
	tempfile emp
	save `emp'
	
	
	
	use `spv', clear
	append using `dir'
	append using `emp'
	
	

	// outcome variable: salary of poached managers
	* I think it's pc_wage_d
	
	// control variables: 
		// poached mgr experience (in log years)
		// Why is the min of pc_exp -1
		gen pc_exp_ln = ln(pc_exp)
		replace pc_exp_ln = -99 if pc_exp_ln == .
		gen pc_exp_ln_m = (pc_exp_ln == -99) // dummy for missing variables
		
		
		// poached mgr AKM FE
		* pc_fe
		replace pc_fe = -99 if pc_fe == .
		gen pc_fe_m = (pc_fe == -99) // dummy for missing variables
		
	
	// destinantion firm controls
		
		// log of firm size
		gen d_size_ln = ln(d_size)
		
		// AKM firm FE of destination firm -- fe_firm_d
		replace fe_firm_d = -99 if fe_firm_d == .
		gen fe_firm_d_m = (fe_firm_d == -99)
		
		// log of destination firm wage bill -- wage_real_ln
		replace d_wage_real_ln = -99 if d_wage_real_ln == .
		gen d_wage_real_ln_m = (d_wage_real_ln == -99)
		
	// organizing independent variables
	
		// col 1: destination firm log # emp
		gen d_size_ln = ln(d_size)
		
		// col 2: essa já existe!
		

		// col 3: we need to define turnover rate
		
		// col 4: Fabi and Luiza need to create AKM FEs below median

		
	
	// regressions
	
	local pcctrl "pc_exp_ln pc_exp_ln_m pc_fe pc_fe_m"
	local dctrl  "d_size_ln d_wage_real_ln d_wage_real_ln_m fe_firm_d fe_firm_d_m"
	
	// Check with Fabi the dates
	eststo clear
	
		eststo c1: reg pc_wage_d o_size_ln ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local pc_fe "\cmark"
			estadd local firmsize	" "
			estadd local wagebill	" "
			estadd local fe_d	" "
			estadd local period "2010-2016"	
			
			
		* Terminar reg
		
			
		
			
	// table

		esttab c1 c2 c3 c4 c5 c7 c8 ///
    using "${results}/reg_wage_information.tex", tex ///
    replace frag compress noconstant nomtitles nogap collabels(none) ///
    mgroups("\textbf{Outcome var:} ln(wage) of poached manager (at destination)", ///
        pattern(1 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    keep(o_size_ln o_size_ratio team_cw_ln ///
        o_ratio_team o_avg_fe_worker) ///
    cells(b(star fmt(3)) se(par fmt(3)) p(par([ ]) fmt(3))) ///
    coeflabels(o_size_ln "\hline \\ Ln(origin firm size)" ///
        o_size_ratio "Firm size / Number of mgrs." ///
        team_cw_ln "Ln(size same category mgr.)" ///
        o_ratio_team  "Size same category mgr. / Mgr. in category" ///
        o_avg_fe_worker "Avg. AKM effect of workers in origin firm") ///
    stats(N r2 experience pc_fe firmsize wagebill fe_d , ///
        fmt(0 3 0 0 0 0 0 0) ///
        label("\\ Obs" "R-Squared" ///
        "\\ \textbf{Controls:} \\ Poached manager \\ \textit{Experience (yrs)} \\ \textit{AKM ind. effects} \\" ///  % Experience on a new line
        "Destination firm \\ \textit{Firm size} \\ \textit{Avg. wage bill} \\ \textit{AKM firm effects} \\")) ///  % AKM ind. effects before Destination firm
    obslast nolines ///
    starlevels(* 0.1 ** 0.05 *** 0.01)
