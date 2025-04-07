// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024
 
// Purpose: Wage analysis (poached workers only; correlation with "information")

*--------------------------*
* ANALYSIS
*--------------------------*

// MAIN ANALYSIS

			// SPV:
			
				// how many events we should start with:
				use "${data}/evt_m_spv", clear
				keep if pc_ym >= ym(2010,1) // 18,007 events
				
				// how many events we are actually starting with
				use "${data}/poach_ind_spv", clear
				keep if pc_ym != . // 15,513 events
				
				// after imposing sample selection:
				merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen // 13,907
				
				// after identifying event types
				merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen // 13,907
				keep if type_spv // 4,619 events --> 33% of the events
				
					// how many events are spv type?
					use "${data}/evt_type_m_spv", clear
					tab type_spv // 34% --> so this is consistent!
					
					// conclusion: problem is at the very beginning. we should start with 18,007 vs. 15,513
					
			// DIR:
			
				// how many events we should start with:
				use "${data}/evt_m_dir", clear
				keep if pc_ym >= ym(2010,1) // 14,455 events
				
				// how many events we are actually starting with
				use "${data}/poach_ind_dir", clear
				keep if pc_ym != . // 12,269 events
				
				// after imposing sample selection:
				merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen // 11,638 events
				
				// after identifying event types
				merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen // 11,638
				tab type_spv // 1,156 events --> 10% of the events
				
					// how many events are spv type?
					use "${data}/evt_type_m_dir", clear
					tab type_spv // 10% --> so this is consistent!
					
					// conclusion: problem is at the very beginning. we should start with 14,455 vs. 12,269
					
			// EMP:
			
				// how many events we should start with:
				use "${data}/evt_m_emp", clear
				keep if pc_ym >= ym(2010,1) // 112,660 events
				
				// how many events we are actually starting with
				use "${data}/poach_ind_emp", clear
				keep if pc_ym != . // 95,613 events
				
				// after imposing sample selection:
				merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen // 86,078 events
				
				// after identifying event types
				merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen // 19,315 events (WE LOSE A LOT)
				tab type_spv // 921 events --> 5% of the events --> MAIN ANALYSIS
				tab type_dir // 627 events --> 3% of the events
				tab type_emp // 18,210 events --> 94% of the events --> "PLACEBO" ANALYSIS
				
					// how many events are each type?
					use "${data}/evt_type_m_emp", clear // this only has 42,622 events (SHOULD HAVE 112,660)
					tab type_spv // 5% --> so this is consistent!
					tab type_dir // 3% --> so this is consistent!
					tab type_emp // 94% --> so this is consistent!
					
					// conclusion [1]: first problem is at the very beginning. we should start with 112,660 vs. 95,613
					// conclusion [2]: ${data}/evt_type_m_emp is incomplete / was not correctly constructed
					
					
					
				
				

	
	
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
	
	*histogram o_size_ratio, frequency

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
	
		// col 1: origin firm log # emp
		gen o_size_ln = ln(o_size)
		
		// col 2: origin firm (# emp / # mgr)
		* o_size_ratio
		
		// a. Create log version of this var.
		gen o_size_ratio_ln = ln(o_size_ratio)
		
		// b. Create winsorized version of this var.
		winsor o_size_ratio, gen (o_size_ratio_winsor) p(0.01)

		// c. Dealing with missing values
		replace o_size_ratio = -99 if o_size_ratio == .
		gen o_size_ratio_m = (o_size_ratio == -99) // dummy identifying the missing points
		
		replace o_size_ratio_ln = -99 if o_size_ratio_ln == .
		gen o_size_ratio_ln_m = (o_size_ratio_ln == -99) // dummy identifying the missing points
		
		replace o_size_ratio_winsor = -99 if o_size_ratio_winsor == .
		gen o_size_ratio_winsor_m = (o_size_ratio_winsor == -99) // dummy identifying the missing points
		
		
		// col 3: origin firm log # empl within same occ category as the poached mgr
		gen team_cw_ln = ln(team_cw)
		
		replace team_cw_ln = -99 if team_cw_ln == .
		gen team_cw_ln_m = (team_cw_ln == -99) // dummy identifying the missing points
		
		
		// col 4: origin firm (# emp / # mgr) within same occ category as the poached mgr
		gen o_ratio_team = team_cw / team_spv
		
		// a. Create log version of this var.
		gen o_ratio_team_ln = ln(o_ratio_team)
		
		// b. Create winsorized version of this var.
		winsor o_ratio_team, gen (o_ratio_team_winsor) p(0.01)

		// c. Dealing with missing values
		
		histogram o_ratio_team, frequency
		
		replace o_ratio_team = -99 if o_ratio_team == .
		gen o_ratio_team_m = (o_ratio_team == -99) // dummy identifying the missing points
		
		replace o_ratio_team_ln = -99 if o_ratio_team_ln == .
		gen o_ratio_team_ln_m = (o_ratio_team_ln == -99) // dummy identifying the missing points
		
		replace o_ratio_team_winsor = -99 if o_ratio_team_winsor == .
		gen o_ratio_team_winsor_m = (o_ratio_team_winsor == -99) // dummy identifying the missing points
		

		// col 5: origin firm avg AKM FE (avg. akm FE of workers in origin firm)
		* o_avg_fe_worker
		replace o_avg_fe_worker = -99 if o_avg_fe_worker == .
		gen o_avg_fe_worker_m = (o_avg_fe_worker == -99) // dummy identifying the missing points
		
		
		// col 6: origin firm share of workers with above-75pctile AKM FE (this takes calculating the 75th pctile of AKM FE in the full sample, and building a dummy that identifies those workers with AKM FE >= 75th pctile) 
		// We are still waiting for those, will come from Fabi + Luiza

		
	
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
			
			
		eststo c2: reg pc_wage_d o_size_ratio o_size_ratio_m ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local pc_fe "\cmark"
			estadd local firmsize	" "
			estadd local wagebill	" "
			estadd local fe_d	" "
			estadd local period "2010-2016"	
			
		eststo c2_a: reg pc_wage_d o_size_ratio_ln o_size_ratio_ln_m ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local pc_fe "\cmark"
			estadd local firmsize	" "
			estadd local wagebill	" "
			estadd local fe_d	" "
			estadd local period "2010-2016"	
			
		eststo c2_b: reg pc_wage_d o_size_ratio_winsor o_size_ratio_winsor_m ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local pc_fe "\cmark"
			estadd local firmsize	" "
			estadd local wagebill	" "
			estadd local fe_d	" "
			estadd local period "2010-2016"	
			
			
			
		eststo c3: reg pc_wage_d team_cw_ln team_cw_ln_m ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local pc_fe "\cmark"
			estadd local firmsize	" "
			estadd local wagebill	" "
			estadd local fe_d	" "
			estadd local period "2010-2016"	
		
		eststo c4: reg pc_wage_d o_ratio_team o_ratio_team_m ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local pc_fe "\cmark"
			estadd local firmsize	" "
			estadd local wagebill	" "
			estadd local fe_d	" "
			estadd local period "2010-2016"	
			
		eststo c4_a: reg pc_wage_d o_ratio_team_ln o_ratio_team_ln_m ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local pc_fe "\cmark"
			estadd local firmsize	" "
			estadd local wagebill	" "
			estadd local fe_d	" "
			estadd local period "2010-2016"	
			
		eststo c4_b: reg pc_wage_d o_ratio_team_winsor o_ratio_team_winsor_m ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local pc_fe "\cmark"
			estadd local firmsize	" "
			estadd local wagebill	" "
			estadd local fe_d	" "
			estadd local period "2010-2016"	
			
		eststo c5: reg pc_wage_d o_avg_fe_worker o_avg_fe_worker_m ///
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local pc_fe "\cmark"
			estadd local firmsize	" "
			estadd local wagebill	" "
			estadd local fe_d	" "
			estadd local period "2010-2016"	
		
		* 6 missing
		
		eststo c7: reg pc_wage_d o_size_ln o_size_ratio o_size_ratio_m team_cw_ln ///
				team_cw_ln_m o_ratio_team o_ratio_team_m o_avg_fe_worker o_avg_fe_worker_m /// *6 missing
				`pcctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local pc_fe "\cmark"
			estadd local firmsize	" "
			estadd local wagebill	" "
			estadd local fe_d	" "
			estadd local period "2010-2016"	
			
		eststo c8: reg pc_wage_d o_size_ln o_size_ratio o_size_ratio_m team_cw_ln ///
				team_cw_ln_m o_ratio_team o_ratio_team_m o_avg_fe_worker o_avg_fe_worker_m ///
				`pcctrl' `dctrl' if type_spv == 1 & pc_ym >= ym(2010,1), rob
		
			estadd local experience "\cmark"
			estadd local pc_fe "\cmark"
			estadd local firmsize	"\cmark"
			estadd local wagebill	"\cmark"
			estadd local fe_d	"\cmark"
			estadd local period "2010-2016"	
		
			
		
			
	// table

		esttab c1 c2 c2_a c2_b c3 c4 c4_a c4_b c5 c7 c8 ///
    using "${results}/reg_wage_information.tex", tex ///
    replace frag compress noconstant nomtitles nogap collabels(none) ///
    mgroups("\textbf{Outcome var:} ln(wage) of poached manager (at destination)", ///
        pattern(1 0 0 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span ///
        erepeat(\cmidrule(lr){@span})) ///
    keep(o_size_ln o_size_ratio o_size_ratio_ln o_size_ratio_winsor team_cw_ln ///
        o_ratio_team o_ratio_team_ln o_ratio_team_winsor o_avg_fe_worker) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(o_size_ln "\hline \\ Ln(origin firm size)" ///
        o_size_ratio "Firm size / Number of mgrs." ///
	o_size_ratio_ln "Ln(Firm size / Number of mgrs.)" /// * including this var
	o_size_ratio_winsor "Firm size / Number of mgrs. -- Excl. top and bottom 1%" /// * including this var
        team_cw_ln "Ln(size same category mgr.)" ///
        o_ratio_team  "Size same category mgr. / Mgr. in category" ///
        o_ratio_team_ln  "Ln(size same category mgr. / Mgr. in category)" /// * including this var
        o_ratio_team_winsor  "Size same category mgr. / Mgr. in category -- Excl. top and bottom 1%" /// * including this var
	o_avg_fe_worker "Avg. AKM worker FE in origin firm") ///
    stats(N r2 experience pc_fe firmsize wagebill fe_d , ///
        fmt(0 3 0 0 0 0 0 0) ///
        label("\\ Obs" "R-Squared" ///
        "\\ \textbf{Controls:} \\ Poached manager \\ \textit{Experience (yrs)} \\ \textit{AKM worker FE} \\" ///
        "Destination firm \\ \textit{Firm size} \\ \textit{Avg. wage bill} \\ \textit{AKM firm FE} \\")) ///
    obslast nolines ///
    starlevels(* 0.1 ** 0.05 *** 0.01)

