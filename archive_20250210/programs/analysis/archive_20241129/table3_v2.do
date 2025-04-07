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


// DANI'S VERSION
foreach e in spv_dir {
	
	
	

	display "`e'"
	use "${temp}/table3_`e'", clear
	
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
		
		eststo c1_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
	
		eststo c2_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c3_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m turnover turnover_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c4_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m rd_coworker_n rd_coworker_n_m ///
				d_raid_individual rd_coworker_fe rd_coworker_fe_m d_hire ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		// eststo c4a_`e': reg pc_wage_d d_size_ln d_size_ln_m d_raid_individual ///
				//`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		// eststo c4b_`e': reg pc_wage_d d_size_ln d_size_ln_m d_raid_individual ratio_cw_new_hire ratio_cw_new_hire_m ///
				//`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
				
		// eststo c5_`e': reg pc_wage_d d_size_ln d_size_ln_m rd_coworker_fe rd_coworker_fe_m ///
				//`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		// include quality of raided workers
		
		eststo c6_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				turnover turnover_m rd_coworker_n rd_coworker_n_m ///
				d_raid_individual d_hire rd_coworker_fe rd_coworker_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c7_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				turnover turnover_m rd_coworker_n rd_coworker_n_m ///
				d_raid_individual d_hire rd_coworker_fe rd_coworker_fe_m ///
				pc_wage_o_l1 pc_wage_o_l1_m  ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
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
    using "${results}/table3_`e'_v2_dani.tex", tex /// 
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
}

// FABI'S VERSION
foreach e in spv_dir {
	
	display "`e'"
	use "${temp}/table3_`e'", clear
	
	replace ratio_cw_new_hire = . if ratio_cw_new_hire > 1
	
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
		
		eststo c1_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c2_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c3_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m turnover turnover_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c4_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m ratio_cw_new_hire ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c5_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m ratio_cw_new_hire ///
				rd_coworker_fe rd_coworker_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c6_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				turnover turnover_m ratio_cw_new_hire rd_coworker_fe rd_coworker_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
				
		eststo c7_`e': reghdfe pc_wage_d d_size_ln d_size_ln_m d_growth_winsor d_growth_winsor_m ///
				turnover turnover_m ratio_cw_new_hire rd_coworker_fe rd_coworker_fe_m ///
				pc_wage_o_l1 pc_wage_o_l1_m  ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), ///
				vce(robust) absorb(cnae_d pc_ym)
				estadd local cnae_d "\cmark"
				estadd local pc_ym "\cmark"
		
	* DISPLAY
	
	local label = "mgr."
	if inlist("`e'", "emp_placebo", "emp_placebo_sample") local label "emp."
    
  esttab c1_`e' c2_`e' c3_`e' c4_`e' c5_`e' c6_`e' c7_`e' /// 
    using "${results}/table3_`e'_v2_fabi.tex", tex /// 
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
    stats(N r2 cnae_d pc_ym, fmt(0 3 0 0) label(" \\ Obs" "R-Squared" "\\ Dest. CNAE (2 dig.)" "Event time FE")) ///
    obslast nolines ///
     indicate("\\ Years of experience of pc. `label' = *pc_exp_ln*" ///	
	"AKM FE of pc. `label' (individual) = *pc_fe*" "ln(wage) of pc. `label' (at origin) = *pc_wage_o_l1*" ///
        "AKM FE of dest. firm = *fe_firm_d*" "AKM FE of origin firm = *fe_firm_o*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01) 
}


	
	
