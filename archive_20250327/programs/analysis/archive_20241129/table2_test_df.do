// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Table 2

*--------------------------*
* ANALYSIS
*--------------------------*

// MAIN ANALYSIS

// spv --> spv
use "${data}/poach_ind_spv", clear
* we need to bind to get some selections of sample, don't worry about it
merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
* keep only people that became spv
keep if type_spv == 1
save "${temp}/table2_spv", replace

	
// dir --> spv
use "${data}/poach_ind_dir", clear
merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
keep if type_spv == 1
gen d_size_ln = ln(d_size)
gen pc_exp_ln = ln(pc_exp)
gen o_size_ln = ln(o_size)
gen team_cw_ln = ln(team_cw)
save "${temp}/table2_dir", replace

// emp --> spv
use "${data}/poach_ind_emp", clear
merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
keep if type_spv == 1
save "${temp}/table2_emp", replace

// emp --> emp (placebo)
use "${data}/poach_ind_emp", clear
merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
keep if type_emp == 1
save "${temp}/table2_emp_placebo", replace

// subsample of placebo with 5775 obs. (same number as spv --> spv and dir --> spv)
sample 5775, count
save "${temp}/table2_emp_placebo_sample", replace

// spv --> spv + dir --> spv
use "${temp}/table2_spv", clear
gen spv = 1
append using "${temp}/table2_dir"
replace spv = 0 if spv == .
*save "${temp}/table2_spv_dir", replace

save "${temp}/table2_spv_dir_df", replace

// spv --> emp
use "${data}/poach_ind_spv", clear
* we need to bind to get some selections of sample, don't worry about it
merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
* keep only people that became spv
keep if type_emp == 1
save "${temp}/table2_spv_emp", replace



// TABLE FOR SPV --> SPV 
*+ DIR --> SPV
*use "${temp}/table2_spv_dir", clear
use "${temp}/table2_spv", clear


winsor o_size, gen(o_size_w) p(0.005) highonly
winsor o_size_ratio, g(o_size_ratio_w) p(0.005)

g o_size_w_ln = ln(o_size_w)

/*
// Fix for missing team size
drop team_cw_ln
replace team_cw = o_size_ratio if (team_cw==0 | team_cw==.) & o_size_ratio!=.
drop if team_cw ==0 // 7 obs deleted
g team_cw_ln = ln(team_cw) 

replace department_fe = o_avg_fe_worker if department_fe == . // 742 changes made 
*/

replace pc_exp_ln = -99 if pc_exp_ln==.
g pc_exp_m =(pc_exp_ln==-99)
replace pc_fe = -99 if pc_fe==.
g pc_fe_m = (pc_fe==-99)
replace fe_firm_d = -99 if fe_firm_d==.
g fe_firm_d_m = (fe_firm_d==-99)


		* Firm size and quality
		eststo c1: reg pc_wage_d o_size_w_ln o_avg_fe_worker    ///
				 pc_wage_o_l1 if pc_ym >= ym(2010,1) , rob
		
		eststo c2: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker     ///
				 pc_wage_o_l1 if pc_ym >= ym(2010,1), rob
				  
		eststo c3: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker   /// 
				pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1), rob
				
		eststo c4: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker   /// 
				pc_wage_o_l1 pc_exp_ln pc_fe pc_exp_m pc_fe_m if pc_ym >= ym(2010,1), rob
				
		eststo c5: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    ///
				fe_firm_d d_size_ln fe_firm_d_m ///
				pc_wage_o_l1 pc_exp_ln pc_fe pc_exp_m pc_fe_m   if pc_ym >= ym(2010,1), rob  
  
  
			
				  
la var o_size_w_ln "Firm size (ln)"
la var team_cw_ln "Dept size (ln)"
la var department_fe "Dept avg quality"
la var o_avg_fe_worker "Firm avg quality"
    
* DISPLAY
	    
    esttab c1 c2 c3 c4 c5    ,  /// 
    replace compress noconstant nomtitles nogap collabels(none) label ///   
    keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors 
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
    indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" "Experience = pc_exp_ln" "Manager quality = pc_fe"  "\textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///	
	 , labels("\cmark" ""))
* SAVE 
    esttab c1 c2 c3 c4 c5 using "${results}/table2_spv2spv.tex", booktabs  /// 
    replace compress noconstant nomtitles nogap collabels(none) label /// 
    mgroups("ln(wage) of poached manager at destination", /// 
       pattern(1 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
    keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///    
    refcat(o_size_w_ln "\midrule \textit{Origin firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
    indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" "Experience = pc_exp_ln" "Manager quality = pc_fe"  "\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///	
	 , labels("\cmark" ""))
 
 
   


// TABLE FOR EMP --> EMP (SAMPLE)
use "${temp}/table2_emp_placebo_sample", clear


	// Handling missing values 
	local missingvars d_size_ln pc_exp_ln pc_fe pc_wage_o_l1 fe_firm_d fe_firm_o ///
			  o_size_ln o_avg_fe_worker team_cw_ln department_fe
							 
	foreach var of local missingvars {
								
			replace `var' = -99 if `var' == .
			gen `var'_m = (`var' == -99 )
									
		
	}
	// regressions
	
	local ctrl "d_size_ln pc_exp_ln pc_fe fe_firm_d fe_firm_o"
	local ctrl_m "d_size_ln_m pc_exp_ln_m pc_fe_m fe_firm_d_m fe_firm_o_m"
	
	// Check with Fabi the dates
	*eststo clear
		
		eststo c1_`e': reg pc_wage_d o_size_ln o_size_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
	
		eststo c2_`e': reg pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		eststo c3_`e': reg pc_wage_d team_cw_ln team_cw_ln_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob

		eststo c4_`e': reg pc_wage_d team_cw_ln team_cw_ln_m ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob

		eststo c5_`e': reg pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				team_cw_ln team_cw_ln_m  ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
		
		eststo c6_`e': reg pc_wage_d o_size_ln o_size_ln_m o_avg_fe_worker o_avg_fe_worker_m ///
				team_cw_ln team_cw_ln_m  pc_wage_o_l1 pc_wage_o_l1_m ///
				department_fe department_fe_m ///
				`ctrl' `ctrl_m' if pc_ym >= ym(2010,1), rob
    
	* DISPLAY
	
	local label = "mgr."
	if inlist("`e'", "emp_placebo", "emp_placebo_sample") local label "emp."
	
esttab c1_`e' c2_`e' c3_`e' c4_`e' c5_`e' c6_`e' /// 
    using "${results}/table2_emp_placebo_sample.tex", tex /// 
    replace frag compress noconstant nomtitles nogap collabels(none) /// 
    mgroups("\textbf{Outcome var:} ln(wage) of poached `label' (at dest.)", /// 
       pattern(1 0 0 0 0 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///  
    keep(o_size_ln o_avg_fe_worker team_cw_ln department_fe) ///
    cells(b(star fmt(3)) se(par fmt(3))) ///  % Only display standard errors
    coeflabels(o_size_ln "\hline \\ Size (ln)" /// 
        o_avg_fe_worker "Avg. worker quality (AKM FE)" ///
	team_cw_ln "Department size (ln)" ///
	department_fe "Avg. worker quality by department (AKM FE)") ///
    refcat(o_size_ln "\textit{Origin firm characteristics}", nolabel) ///
    stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
    obslast nolines ///
     indicate("\\ Size (ln) of dest. firm = *d_size_ln*" "Years of experience of pc. `label' = *pc_exp_ln*" ///	
	"AKM FE of pc. `label' (individual) = *pc_fe*" "ln(wage) of pc. `label' (at origin) = *pc_wage_o_l1*" ///
        "AKM FE of dest. firm = *fe_firm_d*" "AKM FE of origin firm = *fe_firm_o*", ///
        labels("\cmark" "")) ///
    starlevels(* 0.1 ** 0.05 *** 0.01) 
}











