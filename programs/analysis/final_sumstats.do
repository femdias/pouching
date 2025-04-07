// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Summary statistics

*--------------------------*
* PREPARE
*--------------------------*

/*

set seed 6543

// events "spv --> spv"
		
	use "${data}/poach_ind_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 1
	
	// saving
	save "${temp}/sumstats_spv_spv", replace

// events "spv --> emp"
		
	use "${data}/poach_ind_spv", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_spv", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest
	merge m:1 event_id using "${data}/evt_type_m_spv", keep(match) nogen
	
	// keep only people that became emp
	keep if type_emp == 1
	
	// generating identifier
	gen spv = 2
		
	save "${temp}/sumstats_spv_emp", replace
	
// events "emp --> spv"
		
	use "${data}/poach_ind_emp", clear
	
	// positive employment in all months
	merge m:1 event_id using "${data}/sample_selection_emp", keep(match) nogen
	
	// identifying event types (using destination occupation) -- we need this to see what's occup in dest
	merge m:1 event_id using "${data}/evt_type_m_emp", keep(match) nogen
	
	// keep only people that became spv
	keep if type_spv == 1
	
	// generating identifier
	gen spv = 3
	
	// saving	
	save "${temp}/sumstats_emp_spv", replace
	
*/	

// combining events and keeping what we need
		
	use "${temp}/sumstats_spv_spv", clear
	append using "${temp}/sumstats_spv_emp" 
	append using "${temp}/sumstats_emp_spv" 
	
	merge m:1 spv event_id using "${temp}/eventlist", keep(match)

	// labeling event typs		
	la def spv 1 "spv-spv" 2 "spv-emp" 3 "emp-spv", replace
	la val spv spv

	// winsorizing size variables to remove outliers
	winsor o_size, gen(o_size_w) p(0.005) highonly
	winsor o_size_ratio, g(o_size_ratio_w) p(0.005)
	g o_size_w_ln = ln(o_size_w)
	
	// winsoring level wage variables to remove outliers
	winsor rd_coworker_wage_o_lvl, gen(rd_cw_wage_o_w) p(0.005) highonly
	winsor rd_coworker_wage_d_lvl, gen(rd_cw_wage_d_w) p(0.005) highonly
	winsor pc_wage_o_l1_lvl,       gen(pc_wage_o_w) p(0.005) highonly
	winsor pc_wage_d_lvl,          gen(pc_wage_d_w) p(0.005) highonly
		
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
		
	// organizing some variables we need for the table
	// note: Destination = 1, Origin = 2 
		
	// firm variables:
		
	// wage premium: productivity proxy
	rename fe_firm_o fe_firm2
	rename fe_firm_d fe_firm1
	
	// avg. coworker wage premium
	rename o_avg_fe_worker fe_avgworker2
	rename d_avg_fe_worker fe_avgworker1
				
	// firm size (# workers)
	winsor d_size, gen(d_size_w) p(0.005) highonly
	rename o_size_w size_w2
	rename d_size_w size_w1
				
	// raided workers avg wage ---> in logs
	rename rd_coworker_wage_o rd_coworker_wage2
	rename rd_coworker_wage_d rd_coworker_wage1
	
	// raided workers avg wage --> in levels
	rename rd_coworker_wage_o_lvl rd_coworker_wage_lvl2
	rename rd_coworker_wage_d_lvl rd_coworker_wage_lvl1
	
	// raided workers avg wage --> in levels, winsorized
	rename rd_cw_wage_o_w rd_cw_wage_w2
	rename rd_cw_wage_d_w rd_cw_wage_w1
	
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

	// wage --> in logs
	rename pc_wage_o_l1 pc_wage2
	rename pc_wage_d pc_wage1
	
	// wage --> in levels
	rename pc_wage_o_l1_lvl pc_wage_lvl2
	rename pc_wage_d_lvl pc_wage_lvl1
	
	// wage --> in levels, winsorized
	rename pc_wage_o_w pc_wage_w2
	rename pc_wage_d_w pc_wage_w1
	
	// wages --> residualized, in levels
	
	reg pc_wage_lvl2 pc_fe pc_exp
	predict pc_wage_resid2, resid
	summ pc_wage_lvl2 if e(sample) == 1
	replace pc_wage_resid2 = pc_wage_resid2 + `r(mean)' if pc_wage_resid2 != .
	
	*replace pc_wage_resid2 = pc_wage_resid2 + _b[_cons]
	
	reg pc_wage_lvl1 pc_fe pc_exp
	predict pc_wage_resid1, resid
	summ pc_wage_lvl1 if e(sample) == 1
	replace pc_wage_resid1 = pc_wage_resid1 + `r(mean)' if pc_wage_resid1 != .
	
	*replace pc_wage_resid1 = pc_wage_resid1 + _b[_cons]
				
	// age
	rename pc_age pc_age2
				
	// experience
	rename pc_exp pc_exp2
				
	// quality
	rename pc_fe pc_fe2

	replace fe_firm1 = . if fe_firm1==-99
	replace fe_firm2 = . if fe_firm2==-99
	replace pc_fe2=. if pc_fe2==-99

	// reshaping data set
	egen unique_id = group(event_id spv)
	reshape long fe_firm fe_avgworker size_w rd_coworker_wage rd_coworker_wage_lvl rd_cw_wage_w ///
	manu serv ret oth pc_wage pc_wage_lvl pc_wage_w pc_wage_resid pc_age pc_exp pc_fe, ///
		i(unique_id) j(or_dest)

	// labeling variables -- we need this for the table	
	la var fe_firm "Productivity proxy (firm AKM FE)"
	la var fe_avgworker "Avg. worker ability (worker AKM FE)"
	la var size_w "Firm size (\# workers)"
	la var rd_coworker_wage "Raided workers wage (2008 BRL)"
	la var rd_coworker_wage_lvl "Raided workers wage (2008 BRL)"
	la var rd_cw_wage_w "Raided workers wage (2008 BRL)"
	la var manu "Manufacturing"
	la var serv "Services"
	la var ret "Retail"
	la var oth "Other"
	la var pc_wage "Salary"
	la var pc_wage_lvl "Salary"
	la var pc_wage_w "Salary"
	la var pc_wage_resid "Residualized salary"
	la var pc_age "Age"
	la var pc_exp "Experience"
	la var pc_fe "Ability"
	
	// summary statistics
	
	cap drop estimates*
	
	// number of events
	su size_w if or_dest == 2, d
	local n: display r(N)
	di "`n'"
	
	// p10
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid pc_age pc_exp pc_fe   if or_dest==2, d
	matrix est2 = e(p10)
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid  if or_dest==1, d
	matrix est1 = e(p10)
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid pc_age pc_exp pc_fe, d
	estadd matrix est2
	estadd matrix est1
	estadd scalar n = `n'
	est store p10
	
	// p50
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid pc_age pc_exp pc_fe   if or_dest==2, d
	matrix est2 = e(p50)
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid  if or_dest==1, d
	matrix est1 = e(p50)
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid pc_age pc_exp pc_fe, d
	estadd matrix est2
	estadd matrix est1
	est store p50
	
	// p90
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid pc_age pc_exp pc_fe  if or_dest==2, d
	matrix est2 = e(p90)
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid if or_dest==1, d
	matrix est1 = e(p90)
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid pc_age pc_exp pc_fe , d
	estadd matrix est2
	estadd matrix est1
	est store p90
	
	// mean
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid pc_age pc_exp pc_fe manu serv ret oth  if or_dest==2, d
	matrix est2 = e(mean)
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid manu serv ret oth  if or_dest==1, d
	matrix est1 = e(mean)
	
	estpost su  fe_firm fe_avgworker size_w rd_cw_wage_w pc_wage_w pc_wage_resid pc_age pc_exp pc_fe manu serv ret oth, d
	estadd matrix est2
	estadd matrix est1
	est store mean
	
	// diff in means
	
	estpost ttest  fe_firm fe_avgworker size_w rd_cw_wage_w manu serv ret oth pc_wage_w pc_wage_resid, by(or_dest) unequal
	est store diff
	
	// displaying table
	
	esttab p10 p50 p90 mean diff, label nonotes nonum noobs ///
	cells("est2(fmt(2 2 0 2) label(Origin) pattern(1 1 1 1 0)) est1(fmt(2 2 0 2) label(Destination) pattern(1 1 1 1 0)) b(star pvalue(p) label(Diff) fmt(2 2 0 2) pattern(0 0 0 0 1))") starlevels(* 0.1 ** 0.05 *** 0.01) ///
	scalars("n Poaching events")
		
	// export table

	esttab p10 p50 p90 mean diff using "${results}/summarystats_v2.tex", booktabs replace ///
		label nonotes nonum nomtitle noobs ///
		mgroups("\textbf{10th pct}" "\textbf{Median}" "\textbf{90th pct}" "\textbf{Mean}" "\textbf{Diff}" , ///
		pattern(1 1 1 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		refcat(fe_firm "\textbf{Firm variables}" manu "\\ \textbf{Industry}" pc_wage_w "\\ \textbf{Manager variables}" , nolabel) ///
		cells("est2(fmt(2 2 0 2) label(Origin) pattern(1 1 1 1 0)) est1(fmt(2 2 0 2) label(Destination) pattern(1 1 1 1 0)) b(star pvalue(p) label(Diff) fmt(2 2 0 2) pattern(0 0 0 0 1))") starlevels(* 0.1 ** 0.05 *** 0.01) ///
		scalars("n Poaching events")
	
	
	
		
