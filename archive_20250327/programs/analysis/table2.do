// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: August 2024

// Purpose: Table 2

*--------------------------*
* PREPARE
*--------------------------*

set seed 6543

// organizing data sets for analysis (i.e., selecting events we want)

// events "spv --> spv"
		
use "${data}/poach_ind_spv", clear
	* we need to bind to get some selections of sample, don't worry about it
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	* identifying event types (using destination occupation) -- we need this to see what's occup in dest.
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	* keep only people that became spv
	keep if type_spv == 1
		
save "${temp}/table2_spv", replace
		
// events "dir --> spv"
		
use "${data}/poach_ind_dir", clear
	merge m:1 event_id using "${data}/sample_selection_dir", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_dir", keep(match) nogen
	keep if type_spv == 1
	gen d_size_ln = ln(d_size)
	gen pc_exp_ln = ln(pc_exp)
	gen o_size_ln = ln(o_size)
	gen team_cw_ln = ln(team_cw)
		
	save "${temp}/table2_dir", replace

// events "emp --> spv"
		
use "${data}/poach_ind_emp", clear
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	keep if type_spv == 1
		
save "${temp}/table2_emp", replace

// events "emp --> emp" (placebo)
		
use "${data}/poach_ind_emp", clear
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	keep if type_emp == 1
		
save "${temp}/table2_emp_placebo", replace

// subsample of placebo with 5775 obs. (same number as "spv --> spv" + "dir --> spv")
sample 4617, count
save "${temp}/table2_emp_placebo_sample4617", replace


// subsample of placebo with 8693 obs. (same number as other)
sample 8693, count
save "${temp}/table2_emp_placebo_sample8693", replace

// events "spv --> spv" + "dir --> spv"
		
use "${temp}/table2_spv", clear
	gen spv = 1
	append using "${temp}/table2_dir"
	replace spv = 0 if spv == .
		
save "${temp}/table2_spv_dir_df", replace

// spv --> emp
		
use "${data}/poach_ind_spv", clear
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	keep if type_emp == 1
		
save "${temp}/table2_spv_emp", replace

// MULTIPLE EVENTS 

use "${temp}/table2_spv", clear // start with spv-spv: info + accountability
	gen spv = 1
	append using "${temp}/table2_spv_emp" // append spv-emp: info but no accountability (maybe some?)
	replace spv = 2 if spv == .
	* tag top earners
	xtile waged_svpemp = pc_wage_d  if spv==2, nq(10)   
	*sample 3493, count // sample the same size sample as emp-spv
	append using "${temp}/table2_emp" // append emp-svp (no info, some accountability)
	replace spv = 3 if spv == .
	xtile waged_empspv = pc_wage_o_l1  if spv==3, nq(10)   
*	append using "${temp}/table2_emp_placebo_sample8693" // append emp-emp (no info, no accountability)
*	replace spv = 4 if spv == .
	

la def spv 1 "spv-spv" 2 "spv-emp" 3 "emp-spv"
la val spv spv


	// winsorizing size variables to remove outliers
	
	winsor o_size, gen(o_size_w) p(0.005) highonly
	winsor o_size_ratio, g(o_size_ratio_w) p(0.005)

	g o_size_w_ln = ln(o_size_w)
		
	// dealing with missing obs in some vairables

	// pc_exp -- NOTE: WE SHOULD NOT HAVE MISSING VALUES HERE
	replace pc_exp_ln = -99 if pc_exp_ln==.
	g pc_exp_m =(pc_exp_ln==-99)
			
	// pc_fe
	replace pc_fe = -99 if pc_fe==.
	g pc_fe_m = (pc_fe==-99)
			
	// fe_firm_d
	replace fe_firm_d = -99 if fe_firm_d==.
	g fe_firm_d_m = (fe_firm_d==-99)
			
	// labeling variables -- we need this for the tables
		
	la var o_size_w_ln "Firm size (ln)"
	la var team_cw_ln "Dept size (ln)"
	la var department_fe "Dept avg quality"
	la var o_avg_fe_worker "Firm avg quality"
	
save "${temp}/table2", replace


*--------------------------*
* ANALYSIS
*--------------------------*

global mgr "pc_exp_ln pc_fe pc_exp_m pc_fe_m"
global firm_d "d_size_ln fe_firm_d  fe_firm_d_m"

// MAIN EVENTS:  
use "${temp}/table2", clear 
{
g spvsample = .
g spvssample = . 
g espvsample = .

local spvcond "(spv==1 | (spv==2 & waged_svpemp==10) | (spv==3 & waged_empspv==10)) "

	* SPV-SPV + SPV-EMP BASELINE
	qui eststo c1_spv: reg pc_wage_d o_size_w_ln o_avg_fe_worker    ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) & `spvcond', rob
		
	qui eststo c2_spv: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker     ///
			pc_wage_o_l1 if  pc_ym >= ym(2010,1) & `spvcond', rob
				  
	qui eststo c3_spv: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1) & `spvcond', rob
				
	qui eststo c4_spv: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 $mgr if pc_ym >= ym(2010,1) & `spvcond', rob
				
	qui eststo c5_spv: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d   if pc_ym >= ym(2010,1) & `spvcond',  rob 
	replace spvsample = e(sample)
	
	qui eststo c5_spvs: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & ( spv==2 & waged_svpemp<10 & waged_svpemp>=1),  rob 
	
	replace spvssample = e(sample)
			
	qui eststo c5_espv: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 $mgr $firm_d  if pc_ym >= ym(2010,1) & (spv==3 & waged_empspv<10 & waged_empspv>=1) ,  rob 
	replace espvsample = e(sample)
	
	// display table
	    
	esttab c1_spv c2_spv c3_spv c4_spv c5_spv c5_spvs c5_espv,  /// 
		replace compress noconstant nomtitles nogap collabels(none) label ///   
		mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-emp" "emp-spv") ///
		keep(o_size_w_ln o_avg_fe_worker  c.o_size_w_ln#c.o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		, labels("\cmark" ""))

}		
*	suest c5_spv c5_espv, vce(robust)
*	test [c5_spv_mean]o_avg_fe_worker = [c5_espv_mean]o_avg_fe_worker
	
	// save table
	
	esttab c1_spv c2_spv c3_spv c4_spv c5_spv c5_spvs c5_espv using "${results}/table2.tex", booktabs  /// 
		replace compress noconstant nomtitles nogap collabels(none) label /// 
		mgroups("Mgr to mgr" "Mgr to non-mgr" "Non-mgr to mgr",  /// 
		pattern(1 0 0 0 0 1 1 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
		keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
		cells(b(star fmt(3)) se(par fmt(3))) ///    
		refcat(o_size_w_ln "\midrule \textit{Origin firm characteristics}", nolabel) ///
		stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
		obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
		indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
		"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
		"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
		, labels("\cmark" ""))


// SUMMARY STATISTICS
 
egen unique_id = group(event_id spv)
	
// Not all events are events we should be using 
	
// organizing some variables we need for the table
// note: Destination = 1, Origin = 2 
	
// firm variables:
	
// wage premium: productivity proxy
rename fe_firm_o fe_firm2
rename fe_firm_d fe_firm1
			
// firm size (# workers)
winsor d_size, gen(d_size_w) p(0.005) highonly
rename o_size_w size_w2
rename d_size_w size_w1
			
// raided workers avg wage ---> SHOULDN'T BE IN LOG!
rename rd_coworker_wage_o rd_coworker_wage2
rename rd_coworker_wage_d rd_coworker_wage1
				
// industry
rename cnae_d cnae2
rename cnae_o cnae1
			
// industry: manufacturing
g manu1 = (cnae1 >= 10 & cnae1 <= 33)
g manu2 = (cnae2 >= 10 & cnae2 <= 33)
			
// industry: services
g serv1 = (cnae1 >= 55 & cnae1 <= 66) | ( cnae1 >= 69 & cnae1 <= 82) | (cnae1 >= 94 & cnae1 <= 97)
g serv2 = (cnae2 >= 55 & cnae2 <= 66) | ( cnae2 >= 69 & cnae2 <= 82) | (cnae2 >= 94 & cnae2 <= 97)
				
// industry: retail
g ret1 = (cnae1 >= 45 & cnae1 <= 47)
g ret2 = (cnae2 >= 45 & cnae2 <= 47)
				
// industry: other
g oth1 = (manu1 == 0 & serv1 == 0 & ret1 == 0)
g oth2 = (manu2 == 0 & serv2 == 0 & ret2 == 0)

// wage
rename pc_wage_o_l1 pc_wage2
rename pc_wage_d pc_wage1
			
// age
rename pc_age pc_age2
			
// experience
rename pc_exp pc_exp2
			
// quality
rename pc_fe pc_fe2

keep if spvsample==1

replace fe_firm1 = . if fe_firm1==-99
replace fe_firm2 = . if fe_firm2==-99
replace pc_fe2=. if pc_fe2==-99

	// reshaping data set	
	reshape long fe_firm size_w rd_coworker_wage  manu serv ret oth pc_wage pc_age pc_exp pc_fe, i(unique_id) j(or_dest)

	// labeling variables -- we need this for the table	
	la var fe_firm "Wage premium"
	la var size_w "Firm size (\# workers)"
	la var rd_coworker_wage "Raided workers wage"
	la var manu "Industry: manufacturing"
	la var serv "Industry: services"
	la var ret "Industry: retail"
	la var oth "Industry: other"
	la var pc_wage "Wage"
	la var pc_age "Age"
	la var pc_exp "Experience"
	la var pc_fe "Quality"
	
	// summary statistics
	
	estpost su  fe_firm size_w rd_coworker_wage manu serv ret oth pc_wage pc_age pc_exp pc_fe if or_dest==2, d
	est store sumO

	estpost su  fe_firm size_w rd_coworker_wage manu serv ret oth pc_wage if or_dest==1, d
	est store sumD 
				
	// display table
	
	esttab sumO sumD, label nonotes nonum ///
		cells("mean(fmt(2) label(Mean)) p10(fmt(2) label(10th pct)) p50(fmt(2) label(Median)) p90(fmt(2) label(90th pct))")

	// export table

	esttab sumO sumD using "${results}/sumstats.tex", booktabs replace ///
		label nonotes nonum ///
		mgroups("\textbf{Origin firm}" "\textbf{Destination firm}", ///
		pattern(1 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		refcat(fe_firm "\textbf{Firm variables}" pc_wage "\\ \textbf{Manager variables}" , nolabel) ///
		cells("mean(fmt(2) label(Mean)) p10(fmt(2) label(10th pct)) p50(fmt(2) label(Median)) p90(fmt(2) label(90th pct))") 


	// figure: firm productivity 
	
		ksmirnov fe_firm, by(or_dest)
		
		la def or_dest 1 "Destination" 2 "Origin"
		la val or_dest or_dest
		
		distplot fe_firm, over(or_dest) xtitle("Firm productivity proxy (wage premium)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(solid dash) ///
		legend(order(2 1) region(lstyle(none)))
				
			graph export "${results}/quality_dest_hire.pdf", as(pdf) replace
			graph export "${results}/quality_dest_hire.png", as(png) replace
			
	// figure: firm productivity (winsorize top and bottom 1%)
	
		winsor fe_firm, gen(fe_firm_w) p(0.01)

		ksmirnov fe_firm_w, by(or_dest)

		distplot fe_firm_w, over(or_dest) xtitle("Firm productivity proxy (wage premium)") ///
		ytitle("Cumulative probability") plotregion(lcolor(white)) ///
		lcolor(black black) lpattern(solid dash) lwidth(medthick medthick) ///
		legend(order(2 1) region(lstyle(none)))
			
			graph export "${results}/prod_od_w.pdf", as(pdf) replace
			graph export "${results}/prod_od_w.png", as(png) replace

			

























/*
// PLACEBO EVENTS: EMP-EMP PLACEBO c5_emppl
{
use "${temp}/table2_emp_placebo_sample4617", clear // placebo events: "emp --> emp"
	 
	
	// organizing some variables
	
	// winsorizing size variables to remove outliers
	
	winsor o_size, gen(o_size_w) p(0.005) highonly
	winsor o_size_ratio, g(o_size_ratio_w) p(0.005)

	g o_size_w_ln = ln(o_size_w)
		
	// dealing with missing obs in some vairables

	// pc_exp -- NOTE: WE SHOULD NOT HAVE MISSING VALUES HERE
	replace pc_exp_ln = -99 if pc_exp_ln==.
	g pc_exp_m =(pc_exp_ln==-99)
			
	// pc_fe
	replace pc_fe = -99 if pc_fe==.
	g pc_fe_m = (pc_fe==-99)
			
	// fe_firm_d
	replace fe_firm_d = -99 if fe_firm_d==.
	g fe_firm_d_m = (fe_firm_d==-99)
			
	// labeling variables -- we need this for the tables
		
	la var o_size_w_ln "Firm size (ln)"
	la var team_cw_ln "Dept size (ln)"
	la var department_fe "Dept avg quality"
	la var o_avg_fe_worker "Firm avg quality"

	// regressions
	
	eststo c1_emppl: reg pc_wage_d c.o_size_w_ln   c.o_avg_fe_worker    ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) , rob
		
	eststo c2_emppl: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker      ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1), rob
				  
	eststo c3_emppl: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker    /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1), rob
				
	eststo c4_emppl: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker     /// 
			pc_wage_o_l1 pc_exp_ln pc_fe pc_exp_m pc_fe_m if pc_ym >= ym(2010,1), rob
				
	eststo c5_emppl: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker      ///
			fe_firm_d d_size_ln fe_firm_d_m ///
			pc_wage_o_l1 pc_exp_ln pc_fe pc_exp_m pc_fe_m   if pc_ym >= ym(2010,1), rob  
}

// SECOND PLACEBO EVENTS: EMP-SPV c5_empspv
{
use "${temp}/table2_emp", clear // baseline events: "emp --> spv"

	// organizing some variables
	
	// winsorizing size variables to remove outliers
	
	winsor o_size, gen(o_size_w) p(0.005) highonly
	winsor o_size_ratio, g(o_size_ratio_w) p(0.005)

	g o_size_w_ln = ln(o_size_w)
		
	// dealing with missing obs in some vairables

	// pc_exp -- NOTE: WE SHOULD NOT HAVE MISSING VALUES HERE
	replace pc_exp_ln = -99 if pc_exp_ln==.
	g pc_exp_m =(pc_exp_ln==-99)
			
	// pc_fe
	replace pc_fe = -99 if pc_fe==.
	g pc_fe_m = (pc_fe==-99)
			
	// fe_firm_d
	replace fe_firm_d = -99 if fe_firm_d==.
	g fe_firm_d_m = (fe_firm_d==-99)
			
	// labeling variables -- we need this for the tables
		
	la var o_size_w_ln "Firm size (ln)"
	la var team_cw_ln "Dept size (ln)"
	la var department_fe "Dept avg quality"
	la var o_avg_fe_worker "Firm avg quality"

	// regressions
	
	eststo c1_empspv: reg pc_wage_d o_size_w_ln o_avg_fe_worker    ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) , rob
		
	eststo c2_empspv: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker     ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1), rob
				  
	eststo c3_empspv: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1), rob
				
	eststo c4_empspv: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 pc_exp_ln pc_fe pc_exp_m pc_fe_m if pc_ym >= ym(2010,1), rob
				
	eststo c5_empspv: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    ///
			fe_firm_d d_size_ln fe_firm_d_m ///
			pc_wage_o_l1 pc_exp_ln pc_fe pc_exp_m pc_fe_m   if pc_ym >= ym(2010,1), rob  
  
}

// THIRD PLACEBO EVENTS: SPV-EMP c5_semp
{
use "${temp}/table2_spv_emp", clear // baseline events: "spv --> spv"

	// organizing some variables
	
	// winsorizing size variables to remove outliers
	
	winsor o_size, gen(o_size_w) p(0.005) highonly
	winsor o_size_ratio, g(o_size_ratio_w) p(0.005)

	g o_size_w_ln = ln(o_size_w)
		
	// dealing with missing obs in some vairables

	// pc_exp -- NOTE: WE SHOULD NOT HAVE MISSING VALUES HERE
	replace pc_exp_ln = -99 if pc_exp_ln==.
	g pc_exp_m =(pc_exp_ln==-99)
			
	// pc_fe
	replace pc_fe = -99 if pc_fe==.
	g pc_fe_m = (pc_fe==-99)
			
	// fe_firm_d
	replace fe_firm_d = -99 if fe_firm_d==.
	g fe_firm_d_m = (fe_firm_d==-99)
			
	// labeling variables -- we need this for the tables
		
	la var o_size_w_ln "Firm size (ln)"
	la var team_cw_ln "Dept size (ln)"
	la var department_fe "Dept avg quality"
	la var o_avg_fe_worker "Firm avg quality"

	// regressions
	
	eststo c1_semp: reg pc_wage_d o_size_w_ln o_avg_fe_worker    ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1) , rob
		
	eststo c2_semp: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker     ///
			pc_wage_o_l1 if pc_ym >= ym(2010,1), rob
				  
	eststo c3_semp: reg pc_wage_d  c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 pc_exp_ln pc_exp_m if pc_ym >= ym(2010,1), rob
				
	eststo c4_semp: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker   /// 
			pc_wage_o_l1 pc_exp_ln pc_fe pc_exp_m pc_fe_m if pc_ym >= ym(2010,1), rob
				
	eststo c5_semp: reg pc_wage_d   c.o_size_w_ln##c.o_avg_fe_worker    ///
			fe_firm_d d_size_ln fe_firm_d_m ///
			pc_wage_o_l1 pc_exp_ln pc_fe pc_exp_m pc_fe_m   if pc_ym >= ym(2010,1), rob  
 }
 
 
// display table
	    
esttab c1_spv c2_spv c3_spv c4_spv c5_spv c5_semp c5_empspv,  /// 
	replace compress noconstant nomtitles nogap collabels(none) label ///   
	keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
	mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-emp" "emp-spv") ///
	cells(b(star fmt(3)) se(par fmt(3))) ///  only display standard errors 
	stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
	obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
	indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
	"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
	"\textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
	, labels("\cmark" ""))

// save table
	
esttab c1_spv c2_spv c3_spv c4_spv c5_spv c5_semp c5_empspv using "${results}/table2.tex", booktabs  /// 
	replace compress noconstant nomtitles nogap collabels(none) label /// 
	mgroups("ln(wage) of poached manager at destination", /// 
	pattern(1 0 0 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///    
	mlabel("spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-spv" "spv-emp" "emp-spv") ///
	keep(o_size_w_ln o_avg_fe_worker c.o_size_w_ln#c.o_avg_fe_worker ) ///
	cells(b(star fmt(3)) se(par fmt(3))) ///    
	refcat(o_size_w_ln "\midrule \textit{Origin firm characteristics}", nolabel) ///
	stats(N r2 , fmt(0 3) label(" \\ Obs" "R-Squared")) ///
	obslast nolines  starlevels(* 0.1 ** 0.05 *** 0.01) ///
	indicate("\textbf{Manager controls} \\ Origin wage = pc_wage_o_l1" ///
	"Experience = pc_exp_ln" "Manager quality = pc_fe" ///
	"\\ \textbf{Destination firm}  \\ Size = d_size_ln" "Wage premium = fe_firm_d"  ///
	, labels("\cmark" ""))

