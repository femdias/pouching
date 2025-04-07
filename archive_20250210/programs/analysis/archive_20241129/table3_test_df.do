// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Table 3

*--------------------------*
* ANALYSIS
*--------------------------*

// MAIN ANALYSIS

set seed 12345 

// spv --> spv
use "${data}/poach_ind_spv", clear
* we need to bind to get some selections of sample, don't worry about it
merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
* keep only people that became spv
keep if type_spv == 1
save "${temp}/table3_spv", replace
	
// dir --> spv
use "${data}/poach_ind_dir", clear
merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
keep if type_spv == 1
// I am running this here because for some reason these vars were  not created for dir, should be in poach_ind
gen d_size_ln = ln(d_size)
gen pc_exp_ln = ln(pc_exp)
gen o_size_ln = ln(o_size)
gen team_cw_ln = ln(team_cw)
winsor d_growth, gen (d_growth_winsor) p(0.01)
gen d_hire_d0 = .
gen ratio_cw_new_hire = rd_coworker_n / d_hire
save "${temp}/table3_dir", replace

// emp --> spv
use "${data}/poach_ind_emp", clear
merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
keep if type_spv == 1
save "${temp}/table3_emp", replace

// emp --> emp (placebo)
use "${data}/poach_ind_emp", clear
merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
keep if type_emp == 1
save "${temp}/table3_emp_placebo", replace

// subsample of placebo with 5775 obs. (same number as spv --> spv and dir --> spv)
sample 5775, count
save "${temp}/table3_emp_placebo_sample", replace

// spv --> spv + dir --> spv
use "${temp}/table3_spv", clear
append using "${temp}/table3_dir"
save "${temp}/table3_spv_dir", replace

// spv --> emp
use "${data}/poach_ind_spv", clear
* we need to bind to get some selections of sample, don't worry about it
merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
* keep only people that became spv
keep if type_emp == 1
save "${temp}/table3_spv_emp", replace


// DANI'S VERSION: Includes number of raided hires and adds control for number of total hires
// TABLE SPV --> SPV + DIR --> SPV
	
	use "${temp}/table3_spv", clear
	
	* Winsorize firm size
	winsor d_size, gen(d_size_w) p(0.005) highonly
	g d_size_w_ln = ln(d_size_w)
	winsor d_growth, gen(d_growth_w) p(0.05) 
	
	g raidw = rd_coworker_n 
	replace raidw = 0 if raidw==.
	
	winsor raidw, gen(raidw_w) p(0.05) highonly
	g lnraid_w = ln(raidw_w+1)
	
	replace rd_coworker_n=0 if rd_coworker_n==.
	
	g lnraid = ln(rd_coworker_n)
	
	g raidratio = rd_coworker_n / d_hire
	
	* Drop if raidratio doesn't make sense
	drop if raidratio>1
	
	g atleastraid = (rd_coworker_n>=1)

replace pc_exp_ln = -99 if pc_exp_ln==.
g pc_exp_m =(pc_exp_ln==-99)
replace pc_fe = -99 if pc_fe==.
g pc_fe_m = (pc_fe==-99)
replace fe_firm_d = -99 if fe_firm_d==.
g fe_firm_d_m = (fe_firm_d==-99)
replace rd_coworker_fe = -99 if rd_coworker_fe==.
g rd_coworker_fe_m = (rd_coworker_fe==-99)

	// 
	
	eststo c1: reg pc_wage_d d_size_w_ln  ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
	
	eststo c2: reg pc_wage_d d_size_w_ln d_growth_w   ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
	
	eststo c3: reg pc_wage_d d_size_w_ln d_growth_w  rd_coworker_fe  rd_coworker_fe_m ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c4: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c5: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m ///
			if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c6: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m pc_fe pc_fe_m ///
			if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c7: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m pc_fe pc_fe_m fe_firm_d fe_firm_d_m ///
			if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
				 	 
				 	
* DISPLAY
la var d_size_w_ln "Firm size (ln)"
la var d_growth_w "Growth rate (empl)"
la var lnraid "\# raided workers (ln)"
la var rd_coworker_fe "Quality of raided workers" 

    esttab c1 c2 c3 c4 c5 c6 c7   ,  /// 
    replace compress noconstant nomtitles nogap collabels(none) label ///   
    keep(d_size_w_ln d_growth_w lnraid rd_coworker_fe c.rd_coworker_fe#c.lnraid ) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors 
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
    indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" "Experience = pc_exp_ln" "Manager quality = pc_fe"  "\textbf{Destination firm}  \\ Wage premium = fe_firm_d"  ///	
	 , labels("\cmark" ""))

* SAVE 
    esttab  c1 c2 c3 c4 c5 c6 c7   using "${results}/table3_spv_ds.tex", booktabs  /// 
    replace compress noconstant nomtitles nogap collabels(none) label /// 
    mgroups("ln(wage) of poached manager at destination", /// 
       pattern(1 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
     keep(d_size_w_ln d_growth_w lnraid rd_coworker_fe c.rd_coworker_fe#c.lnraid ) ///
   cells(b(star fmt(3)) se(par fmt(3))) ///    
    refcat(o_size_w_ln "\midrule \textit{Destination firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
    indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" "Experience = pc_exp_ln" "Manager quality = pc_fe"  "\\ \textbf{Destination firm controls}  \\ Wage premium = fe_firm_d"  ///	
	 , labels("\cmark" ""))
 	

    
    // TABLE FOR EMP --> EMP (SAMPLE)
	use "${temp}/table3_emp_placebo_sample", clear
	
	
	drop d_hire_d0
	gen d_hire_d0 = 1 if d_hire == 0
	replace d_hire_d0 = 0 if d_hire != 0
	
	gen d_raid_individual = .
	replace d_raid_individual = 1 if rd_coworker_n >= 1 
	replace d_raid_individual = 0 if rd_coworker_n == .


	// Handling missing values -- all variables that are included in reg should be here 
	local missingvars pc_exp_ln pc_fe pc_wage_o_l1 fe_firm_d fe_firm_o ///
			  d_size_ln d_growth_winsor turnover rd_coworker_n rd_coworker_fe
							 
	foreach var of local missingvars {
								
			replace `var' = -99 if `var' == .
			gen `var'_m = (`var' == -99 )
									
		
	}
	// regressions
	
	local ctrl "pc_exp_ln pc_fe fe_firm_d fe_firm_o"
	local ctrl_m "pc_exp_ln_m pc_fe_m fe_firm_d_m fe_firm_o_m"
	
	// Check with Fabi the dates
	*eststo clear
		
		eststo c1_`e': reg pc_wage_d d_size_ln d_size_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
	
		eststo c2_`e': reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		eststo c3_`e': reg pc_wage_d d_size_ln d_size_ln_m turnover turnover_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		eststo c4_`e': reg pc_wage_d d_size_ln d_size_ln_m rd_coworker_n rd_coworker_n_m ///
				d_raid_individual rd_coworker_fe rd_coworker_fe_m d_hire ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		// eststo c4a_`e': reg pc_wage_d d_size_ln d_size_ln_m d_raid_individual ///
				//`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		// eststo c4b_`e': reg pc_wage_d d_size_ln d_size_ln_m d_raid_individual ratio_cw_new_hire ratio_cw_new_hire_m ///
				//`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		// eststo c5_`e': reg pc_wage_d d_size_ln d_size_ln_m rd_coworker_fe rd_coworker_fe_m ///
				//`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		// include quality of raided workers
		
		eststo c6_`e': reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				turnover turnover_m rd_coworker_n rd_coworker_n_m ///
				d_raid_individual d_hire rd_coworker_fe rd_coworker_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		eststo c7_`e': reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				turnover turnover_m rd_coworker_n rd_coworker_n_m ///
				d_raid_individual d_hire rd_coworker_fe rd_coworker_fe_m ///
				pc_wage_o_l1 pc_wage_o_l1_m  ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		// eststo c6a_`e': reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				//turnover turnover_m d_raid_individual ///
				//rd_coworker_fe rd_coworker_fe_m ///
				//`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		// eststo c7a_`e': reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				//turnover turnover_m d_raid_individual ///
				//rd_coworker_fe rd_coworker_fe_m pc_wage_o_l1 pc_wage_o_l1_m  ///
				//`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
    
	* DISPLAY
	
	local label = "mgr."
	if inlist("`e'", "emp_placebo", "emp_placebo_sample") local label "emp."
    
  esttab c1_`e' c2_`e' c3_`e' c4_`e' c6_`e' c7_`e' /// 
    using "${results}/table3_emp_placebo_sample.tex", tex /// 
    replace frag compress noconstant nomtitles nogap collabels(none) /// 
    mgroups("\textbf{Outcome var:} ln(wage) of poached `label' (at dest.)", /// 
       pattern(1 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///  
    keep(d_size_ln d_growth_winsor turnover rd_coworker_n d_raid_individual rd_coworker_fe) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(d_size_ln "\hline \\ Size (ln)" /// 
        d_growth_winsor "Growth rate" ///
	turnover "Annual turnover rate" ///
	rd_coworker_n "Number of raided hires" ///
	d_raid_individual "Dummy non-zero raided individuals" ///
	rd_coworker_fe "Raided worker AKM FE") ///
    refcat(d_size_ln "\textit{Destination firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines ///
     indicate("\\ Years of experience of pc. `label' = *pc_exp_ln*" ///	
	"AKM FE of pc. `label' (individual) = *pc_fe*" "ln(wage) of pc. `label' (at origin) = *pc_wage_o_l1*" ///
        "AKM FE of dest. firm = *fe_firm_d*" "AKM FE of origin firm = *fe_firm_o*" "Number of total hires = *d_hire*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01) 


// FABI'S VERSION: cols 4-7 considering only events that have at least one raided worker
// TABLE FOR SPV-->SPV + DIR-->SPV
	
use "${temp}/table3_spv_dir", clear
	
	replace ratio_cw_new_hire == . if ratio_cw_new_hire > 1
	
	drop d_hire_d0
	gen d_hire_d0 = 1 if d_hire == 0
	replace d_hire_d0 = 0 if d_hire != 0
	
	gen d_raid_individual = .
	replace d_raid_individual = 1 if rd_coworker_n >= 1 
	replace d_raid_individual = 0 if rd_coworker_n == .


	// Handling missing values 
	local missingvars pc_exp_ln pc_fe pc_wage_o_l1 fe_firm_d fe_firm_o ///
			  d_size_ln d_growth_winsor turnover rd_coworker_n rd_coworker_fe
							 
	foreach var of local missingvars {
								
			replace `var' = -99 if `var' == .
			gen `var'_m = (`var' == -99 )
									
		
	}
	// regressions
	
	local ctrl "pc_exp_ln pc_fe fe_firm_d fe_firm_o"
	local ctrl_m "pc_exp_ln_m pc_fe_m fe_firm_d_m fe_firm_o_m"
	
	// Check with Fabi the dates
	*eststo clear
		
		eststo c1_`e': reg pc_wage_d d_size_ln d_size_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
	
		eststo c2_`e': reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		eststo c3_`e': reg pc_wage_d d_size_ln d_size_ln_m turnover turnover_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		eststo c4_`e': reg pc_wage_d d_size_ln d_size_ln_m ratio_cw_new_hire ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		eststo c5_`e': reg pc_wage_d d_size_ln d_size_ln_m ratio_cw_new_hire ///
				rd_coworker_fe rd_coworker_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		eststo c6_`e': reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				turnover turnover_m ratio_cw_new_hire rd_coworker_fe rd_coworker_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		eststo c7_`e': reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				turnover turnover_m ratio_cw_new_hire rd_coworker_fe rd_coworker_fe_m ///
				pc_wage_o_l1 pc_wage_o_l1_m  ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		
	* DISPLAY
	
	local label = "mgr."
	if inlist("`e'", "emp_placebo", "emp_placebo_sample") local label "emp."
    
  esttab c1_`e' c2_`e' c3_`e' c4_`e' c5_`e' c6_`e' c7_`e' /// 
    using "${results}/table3_spv_dir.tex", tex /// 
    replace frag compress noconstant nomtitles nogap collabels(none) /// 
    mgroups("\textbf{Outcome var:} ln(wage) of poached `label' (at dest.)", /// 
       pattern(1 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///  
    keep(d_size_ln d_growth_winsor turnover ratio_cw_new_hire rd_coworker_fe) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(d_size_ln "\hline \\ Size (ln)" /// 
        d_growth_winsor "Growth rate" ///
	turnover "Annual turnover rate" ///
	ratio_cw_new_hire "Share of raided new hires" ///
	rd_coworker_fe "Raided worker AKM FE") ///
    refcat(d_size_ln "\textit{Destination firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines ///
     indicate("\\ Years of experience of pc. `label' = *pc_exp_ln*" ///	
	"AKM FE of pc. `label' (individual) = *pc_fe*" "ln(wage) of pc. `label' (at origin) = *pc_wage_o_l1*" ///
        "AKM FE of dest. firm = *fe_firm_d*" "AKM FE of origin firm = *fe_firm_o*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01) 

   // TABLE EMP --> EMP (SAMPLE)
use "${temp}/table3_emp_placebo_sample", clear
	
	replace ratio_cw_new_hire == . if ratio_cw_new_hire > 1
	
	drop d_hire_d0
	gen d_hire_d0 = 1 if d_hire == 0
	replace d_hire_d0 = 0 if d_hire != 0
	
	gen d_raid_individual = .
	replace d_raid_individual = 1 if rd_coworker_n >= 1 
	replace d_raid_individual = 0 if rd_coworker_n == .


	// Handling missing values 
	local missingvars pc_exp_ln pc_fe pc_wage_o_l1 fe_firm_d fe_firm_o ///
			  d_size_ln d_growth_winsor turnover rd_coworker_n rd_coworker_fe
							 
	foreach var of local missingvars {
								
			replace `var' = -99 if `var' == .
			gen `var'_m = (`var' == -99 )
									
		
	}
	// regressions
	
	local ctrl "pc_exp_ln pc_fe fe_firm_d fe_firm_o"
	local ctrl_m "pc_exp_ln_m pc_fe_m fe_firm_d_m fe_firm_o_m"
	
	// Check with Fabi the dates
	*eststo clear
		
		eststo c1_`e': reg pc_wage_d d_size_ln d_size_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
	
		eststo c2_`e': reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		eststo c3_`e': reg pc_wage_d d_size_ln d_size_ln_m turnover turnover_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		eststo c4_`e': reg pc_wage_d d_size_ln d_size_ln_m ratio_cw_new_hire ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		eststo c5_`e': reg pc_wage_d d_size_ln d_size_ln_m ratio_cw_new_hire ///
				rd_coworker_fe rd_coworker_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		eststo c6_`e': reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				turnover turnover_m ratio_cw_new_hire rd_coworker_fe rd_coworker_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		eststo c7_`e': reg pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				turnover turnover_m ratio_cw_new_hire rd_coworker_fe rd_coworker_fe_m ///
				pc_wage_o_l1 pc_wage_o_l1_m  ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		
	* DISPLAY
	
	local label = "mgr."
	if inlist("`e'", "emp_placebo", "emp_placebo_sample") local label "emp."
    
  esttab c1_`e' c2_`e' c3_`e' c4_`e' c5_`e' c6_`e' c7_`e' /// 
    using "${results}/table3_emp_placebo_sample.tex", tex /// 
    replace frag compress noconstant nomtitles nogap collabels(none) /// 
    mgroups("\textbf{Outcome var:} ln(wage) of poached `label' (at dest.)", /// 
       pattern(1 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///  
    keep(d_size_ln d_growth_winsor turnover ratio_cw_new_hire rd_coworker_fe) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(d_size_ln "\hline \\ Size (ln)" /// 
        d_growth_winsor "Growth rate" ///
	turnover "Annual turnover rate" ///
	ratio_cw_new_hire "Share of raided new hires" ///
	rd_coworker_fe "Raided worker AKM FE") ///
    refcat(d_size_ln "\textit{Destination firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines ///
     indicate("\\ Years of experience of pc. `label' = *pc_exp_ln*" ///	
	"AKM FE of pc. `label' (individual) = *pc_fe*" "ln(wage) of pc. `label' (at origin) = *pc_wage_o_l1*" ///
        "AKM FE of dest. firm = *fe_firm_d*" "AKM FE of origin firm = *fe_firm_o*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01) 



	
	
