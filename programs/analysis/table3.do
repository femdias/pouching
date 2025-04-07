// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Table 3

*--------------------------*
* PREPARE
*--------------------------*

set seed 12345

// organizing data sets for analysis (i.e., selecting events we want)

// events "spv --> spv"
		
use "${data}/poach_ind_spv", clear
	* we need to bind to get some selections of sample, don't worry about it
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	* keep only people that became spv
	keep if type_spv == 1
	
save "${temp}/table3_spv", replace
		
	// events "dir --> spv"
		
	use "${data}/poach_ind_dir", clear
	merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
	keep if type_spv == 1
	gen d_size_ln = ln(d_size)
	gen pc_exp_ln = ln(pc_exp)
	gen o_size_ln = ln(o_size)
	gen team_cw_ln = ln(team_cw)
		
save "${temp}/table3_dir", replace

// events "emp --> spv"
		
use "${data}/poach_ind_emp", clear
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	keep if type_spv == 1
		
save "${temp}/table3_emp", replace

// events "emp --> emp" (placebo)
		
use "${data}/poach_ind_emp", clear
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	keep if type_emp == 1
		
save "${temp}/table3_emp_placebo", replace
	
// subsample of placebo with 5775 obs. (same number as "spv --> spv" + "dir --> spv")
sample 5775, count
save "${temp}/table3_emp_placebo_sample", replace

// events "spv --> spv" + "dir --> spv"
		
use "${temp}/table3_spv", clear
	gen spv = 1
	append using "${temp}/table3_dir"
	replace spv = 0 if spv == .
		
*save "${temp}/table3_spv_dir", replace // FD NOTE: I CAN'T SAVE IT FOR SOME REASON!
save "${temp}/table3_spv_dir_df", replace

// spv --> emp
		
use "${data}/poach_ind_spv", clear
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	keep if type_emp == 1
		
save "${temp}/table3_spv_emp", replace

// events "spv --> spv" + "spv -->emp"
		
use "${temp}/table3_spv", clear
	gen spv = 1
	append using "${temp}/table3_spv_emp"
	replace spv = 0 if spv == .
	

use "${temp}/table3_spv", clear // start with spv-spv: info + accountability
	gen spv = 1
	append using "${temp}/table3_spv_emp" // append spv-emp: info but no accountability (maybe some?)
	replace spv = 2 if spv == .
	* tag top earners
	xtile waged_svpemp = pc_wage_d  if spv==2, nq(10)   
	
	append using "${temp}/table3_emp" // append emp-svp (no info, some accountability)
	replace spv = 3 if spv == .
	* tag top earners
	xtile waged_empspv = pc_wage_o_l1  if spv==3, nq(10)   
	

la def spv 1 "spv-spv" 2 "spv-emp" 3 "emp-spv"
la val spv spv

// organizing some variables
	
	// winsorize firm size
	winsor d_size, gen(d_size_w) p(0.005) highonly
	g d_size_w_ln = ln(d_size_w)
	winsor d_growth, gen(d_growth_w) p(0.05) 
		
	// organize raid variables
	g raidw = rd_coworker_n 
	replace raidw = 0 if raidw==.
		
	winsor raidw, gen(raidw_w) p(0.05) highonly
	g lnraid_w = ln(raidw_w+1)
		
	replace rd_coworker_n=0 if rd_coworker_n==.
		
	g lnraid = ln(rd_coworker_n)
		
	g raidratio = rd_coworker_n / d_hire
		
	// drop if raidratio doesn't make sense
	drop if raidratio>1
		
	// identifying events where there is at least 1 raided worker
	g atleastraid = (rd_coworker_n>=1)

	// deadling with missing obs in some variables
		
	// pc_exp_ln -- NOTE: WE SHOULD NOT HAVE MISSING VALUES HERE
	replace pc_exp_ln = -99 if pc_exp_ln==.
	g pc_exp_m =(pc_exp_ln==-99)
		
	// pc_fe
	replace pc_fe = -99 if pc_fe==.
	g pc_fe_m = (pc_fe==-99)
		
	// fe_firm_d
	replace fe_firm_d = -99 if fe_firm_d==.
	g fe_firm_d_m = (fe_firm_d==-99)
		
	// rd_coworker_fe
	replace rd_coworker_fe = -99 if rd_coworker_fe==.
	g rd_coworker_fe_m = (rd_coworker_fe==-99)

	// labeling variables -- we need this for the tables
	la var d_size_w_ln "Firm size (ln)"
	la var d_growth_w "Growth rate (empl)"
	la var lnraid "\# raided workers (ln)"
	la var rd_coworker_fe "Quality of raided workers" 
	
save "${temp}/table3", replace

*--------------------------*
* ANALYSIS
*--------------------------*
global mgr "pc_exp_ln pc_exp_m pc_fe pc_fe_m"
global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"
global spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "
global raidcond "rd_coworker_n>=1 & pc_ym >= ym(2010,1) & rd_coworker_fe_m==0  "


// BASELINE EVENTS: SPV-SPV
{	
use "${temp}/table3", clear // baseline events: "spv --> spv" 
 
	eststo c1_spv: reg pc_wage_d d_size_w_ln  ///
			pc_wage_o_l1 ///
			if $raidcond & $spvcond, rob
	
	eststo c2_spv: reg pc_wage_d d_size_w_ln d_growth_w   ///
			pc_wage_o_l1 ///
			if $raidcond & $spvcond, rob
	
	eststo c3_spv: reg pc_wage_d d_size_w_ln d_growth_w  rd_coworker_fe    ///
			pc_wage_o_l1 ///
			if $raidcond & $spvcond, rob
			
	eststo c4_spv: reg pc_wage_d d_size_w_ln d_growth_w rd_coworker_fe     ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m ///
			if $raidcond & $spvcond, rob
			
	eststo c5_spv: reg pc_wage_d d_size_w_ln d_growth_w rd_coworker_fe     ///
			pc_wage_o_l1  $mgr ///
			if $raidcond & $spvcond, rob
			
	eststo c5_spvs: reg pc_wage_d d_size_w_ln d_growth_w   rd_coworker_fe   ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==2 & waged_svpemp<10 & waged_svpemp>=1), rob
	
	eststo c5_espv: reg pc_wage_d d_size_w_ln d_growth_w   rd_coworker_fe   ///
			pc_wage_o_l1 $mgr ///
			if $raidcond  & (spv==3 & waged_empspv<10 & waged_empspv>=1) , rob
	
	eststo c6_spv: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid ///
			pc_wage_o_l1  $mgr  ///
			if $raidcond & $spvcond, rob
	margins, dydx(rd_coworker_fe) atmeans
	
	eststo c6_spvs: reg pc_wage_d d_size_w_ln d_growth_w    c.rd_coworker_fe##c.lnraid ///
			pc_wage_o_l1 $mgr ///
			if $raidcond & (spv==2 & waged_svpemp<10 & waged_svpemp>=1), rob
			
	eststo c6_epvs: reg pc_wage_d d_size_w_ln d_growth_w    c.rd_coworker_fe##c.lnraid ///
			pc_wage_o_l1 $mgr ///
			if $raidcond & (spv==3 & waged_empspv<10 & waged_empspv>=1) , rob
			
// display table
	
esttab   c3_spv c4_spv c5_spv  c6_spv c5_spvs c6_spvs c5_spv   c6_epvs,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel( "spv-spv"  "spv-spv" "spv-spv"  "spv-spv"  "spv-emp" "spv-emp" "emp-spv"  "emp-spv") ///
		keep(d_size_w_ln d_growth_w lnraid rd_coworker_fe  c.rd_coworker_fe#c.lnraid ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  ///
		, labels("\cmark" ""))
}
	 
	// save table

esttab c3_spv c4_spv c5_spv  c6_spv c5_spvs c6_spvs c5_spv   c6_epvs using "${results}/table3.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		mgroups("Mgr to mgr" "Mgr to non-mgr" "Non-mgr to mgr",  /// 
		pattern(1 0 0 1 0 1 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(d_size_w_ln d_growth_w lnraid rd_coworker_fe c.rd_coworker_fe#c.lnraid ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		refcat(d_size_w_ln "\midrule \textit{Destination firm characteristics}", nolabel) ///
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\\ \textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe"  /// 
		, labels("\cmark" ""))
/*
// BASELINE EVENTS: EMP-SPV
{
use "${temp}/table3_emp", clear // baseline events: "emp --> spv"
	
// organizing some variables
	
	// winsorize firm size
	winsor d_size, gen(d_size_w) p(0.005) highonly
	g d_size_w_ln = ln(d_size_w)
	winsor d_growth, gen(d_growth_w) p(0.05) 
		
	// organize raid variables
	g raidw = rd_coworker_n 
	replace raidw = 0 if raidw==.
		
	winsor raidw, gen(raidw_w) p(0.05) highonly
	g lnraid_w = ln(raidw_w+1)
		
	replace rd_coworker_n=0 if rd_coworker_n==.
		
	g lnraid = ln(rd_coworker_n)
		
	g raidratio = rd_coworker_n / d_hire
		
	// drop if raidratio doesn't make sense
	drop if raidratio>1
		
	// identifying events where there is at least 1 raided worker
	g atleastraid = (rd_coworker_n>=1)

	// deadling with missing obs in some variables
		
	// pc_exp_ln -- NOTE: WE SHOULD NOT HAVE MISSING VALUES HERE
	replace pc_exp_ln = -99 if pc_exp_ln==.
	g pc_exp_m =(pc_exp_ln==-99)
		
	// pc_fe
	replace pc_fe = -99 if pc_fe==.
	g pc_fe_m = (pc_fe==-99)
		
	// fe_firm_d
	replace fe_firm_d = -99 if fe_firm_d==.
	g fe_firm_d_m = (fe_firm_d==-99)
		
	// rd_coworker_fe
	replace rd_coworker_fe = -99 if rd_coworker_fe==.
	g rd_coworker_fe_m = (rd_coworker_fe==-99)

	// labeling variables -- we need this for the tables
	la var d_size_w_ln "Firm size (ln)"
	la var d_growth_w "Growth rate (empl)"
	la var lnraid "\# raided workers (ln)"
	la var rd_coworker_fe "Quality of raided workers" 
	
	// regressions
	
	eststo c1_espv: reg pc_wage_d d_size_w_ln  ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
	
	eststo c2_espv: reg pc_wage_d d_size_w_ln d_growth_w   ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
	
	eststo c3_espv: reg pc_wage_d d_size_w_ln d_growth_w  rd_coworker_fe  rd_coworker_fe_m ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c4_espv: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c5_espv: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m ///
			if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c6_espv: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m pc_fe pc_fe_m ///
			if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c7_espv: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m pc_fe pc_fe_m fe_firm_d fe_firm_d_m ///
			if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c8_espv: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m pc_fe pc_fe_m ///
			if rd_coworker_n>=2 & pc_ym >= ym(2010,1), rob
	
}

// BASELINE EVENTS: SPV-EMP

{
use "${temp}/table3_spv_emp", clear // baseline events: "spv --> spv"
	
// organizing some variables
	
	// winsorize firm size
	winsor d_size, gen(d_size_w) p(0.005) highonly
	g d_size_w_ln = ln(d_size_w)
	winsor d_growth, gen(d_growth_w) p(0.05) 
		
	// organize raid variables
	g raidw = rd_coworker_n 
	replace raidw = 0 if raidw==.
		
	winsor raidw, gen(raidw_w) p(0.05) highonly
	g lnraid_w = ln(raidw_w+1)
		
	replace rd_coworker_n=0 if rd_coworker_n==.
		
	g lnraid = ln(rd_coworker_n)
		
	g raidratio = rd_coworker_n / d_hire
		
	// drop if raidratio doesn't make sense
	drop if raidratio>1
		
	// identifying events where there is at least 1 raided worker
	g atleastraid = (rd_coworker_n>=1)

	// deadling with missing obs in some variables
		
	// pc_exp_ln -- NOTE: WE SHOULD NOT HAVE MISSING VALUES HERE
	replace pc_exp_ln = -99 if pc_exp_ln==.
	g pc_exp_m =(pc_exp_ln==-99)
		
	// pc_fe
	replace pc_fe = -99 if pc_fe==.
	g pc_fe_m = (pc_fe==-99)
		
	// fe_firm_d
	replace fe_firm_d = -99 if fe_firm_d==.
	g fe_firm_d_m = (fe_firm_d==-99)
		
	// rd_coworker_fe
	replace rd_coworker_fe = -99 if rd_coworker_fe==.
	g rd_coworker_fe_m = (rd_coworker_fe==-99)

	// labeling variables -- we need this for the tables
	la var d_size_w_ln "Firm size (ln)"
	la var d_growth_w "Growth rate (empl)"
	la var lnraid "\# raided workers (ln)"
	la var rd_coworker_fe "Quality of raided workers" 
	
	// regressions
	
	eststo c1_spve: reg pc_wage_d d_size_w_ln  ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
	
	eststo c2_spve: reg pc_wage_d d_size_w_ln d_growth_w   ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
	
	eststo c3_spve: reg pc_wage_d d_size_w_ln d_growth_w  rd_coworker_fe  rd_coworker_fe_m ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c4_spve: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c5_spve: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m ///
			if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c6_spve: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m pc_fe pc_fe_m ///
			if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob
			
	eststo c7_spve: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m pc_fe pc_fe_m fe_firm_d fe_firm_d_m ///
			if rd_coworker_n>=1 & pc_ym >= ym(2010,1), rob

	eststo c8_spve: reg pc_wage_d d_size_w_ln d_growth_w  c.rd_coworker_fe##c.lnraid##i.rd_coworker_fe_m ///
			pc_wage_o_l1 pc_exp_ln pc_exp_m pc_fe pc_fe_m ///
			if rd_coworker_n>=2 & pc_ym >= ym(2010,1), rob
				
}



	 
