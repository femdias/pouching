// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Summary statistics

*--------------------------*
* PREPARE
*--------------------------*

	use "${data}/202503_poach_ind", clear
	
	// we're only interested in spv-spv (5) and high-earning spv-emp (6) and emp-spv (8)
	keep if (type == 5) | (type == 6 & waged_spvemp == 10) | (type == 8 & waged_empspv == 10)

	// at least 50 employees
	keep if d_n_emp_lavg >= 50 & o_n_emp_lavg >= 50
	
		// keeping this list of events -- this is temporary
		
		preserve
		
		keep eventid
		save "${temp}/202503_eventlist", replace
		
		restore
		
	
	// organizing some variables for this analysis
	// note: origin = 1, destination = 2 
	
		// fe_firm
		rename o_firm_akm_fe fe_firm1
		rename d_firm_akm_fe fe_firm2
		
		// fe_avgworker
		rename o_avg_worker_akm_fe fe_avgworker1
		rename d_avg_worker_akm_fe fe_avgworker2
		
		// size
		rename o_size size1
		rename d_size size2
		
		// size_lavg
		rename o_n_emp_lavg size_lavg1
		rename d_n_emp_lavg size_lavg2
		
		// rdpc_cw_wage_w 
		rename rdpc_coworker_wage_o_lvl rdpc_cw_wage1
		rename rdpc_coworker_wage_d_lvl rdpc_cw_wage2
		
		// main_wage_w
		rename main_wage_o_l1_lvl main_wage1
		rename main_wage_d_lvl    main_wage2
		
		// main_age
		* already in data set
		
		// main_exp
		* already in data set
		
		// main_worker_akm_fe
		* already in data set
		
		// industry
		rename cnae_o cnae1
		rename cnae_d cnae2
				
		// industry: manufacturing
		g manu1 = (cnae1 >= 10 & cnae1 <= 33)
		g manu2 = (cnae2 >= 10 & cnae2 <= 33)
					
		// industry: services
		g serv1 = (cnae1 >= 55 & cnae1 <= 66) | (cnae1 >= 69 & cnae1 <= 82) | (cnae1 >= 94 & cnae1 <= 97)
		g serv2 = (cnae2 >= 55 & cnae2 <= 66) | (cnae2 >= 69 & cnae2 <= 82) | (cnae2 >= 94 & cnae2 <= 97)
						
		// industry: retail
		g ret1 = (cnae1 >= 45 & cnae1 <= 47)
		g ret2 = (cnae2 >= 45 & cnae2 <= 47)
						
		// industry: other
		g oth1 = (manu1 == 0 & serv1 == 0 & ret1 == 0)
		g oth2 = (manu2 == 0 & serv2 == 0 & ret2 == 0)
	
	// only keeping what we need
	keep eventid fe_firm1 fe_firm2 fe_avgworker1 fe_avgworker2 size1 size2 size_lavg1 size_lavg2 ///
		rdpc_cw_wage1 rdpc_cw_wage2 main_wage1 main_wage2 main_age main_exp main_worker_akm_fe ///
		manu1 manu2 serv1 serv2 ret1 ret2 oth1 oth2
	
	// reshaping data set
	reshape long fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage manu serv ret oth, ///
		i(eventid) j(or_dest)	
		
	// labeling variables	
	la var fe_firm "Productivity proxy (firm AKM FE)"
	la var fe_avgworker "Avg. worker ability (worker AKM FE)"
	la var size "Firm size (\# workers)"
	la var size_lavg "Firm size (\# workers, 3 yr avg)"
	la var rdpc_cw_wage "Raided workers wage (2008 BRL)"
	la var main_wage "Salary"
	la var main_age "Age"
	la var main_exp "Experience"
	la var main_worker_akm_fe "Ability"
	la var manu "Manufacturing"
	la var serv "Services"
	la var ret "Retail"
	la var oth "Other"
	
	// summary statistics
	
	cap drop estimates*
	
	// number of events
	su size if or_dest == 2, d
	local n: display r(N)
	di "`n'"
	
	// p10
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage main_age ///
		main_exp main_worker_akm_fe if or_dest==1, detail
	
		matrix est1 = e(p10)
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage if or_dest==2, detail
	
		matrix est2 = e(p10)
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage main_age ///
		main_exp main_worker_akm_fe, detail
	
		estadd matrix est1
		estadd matrix est2
		estadd scalar n = `n'
		est store p10
	
	// p50
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage main_age ///
		main_exp main_worker_akm_fe if or_dest==1, detail
	
		matrix est1 = e(p50)
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage if or_dest==2, detail
	
		matrix est2 = e(p50)
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage main_age ///
		main_exp main_worker_akm_fe, detail
	
		estadd matrix est1
		estadd matrix est2
		est store p50
	
	// p90
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage main_age ///
		main_exp main_worker_akm_fe if or_dest==1, detail
		
		matrix est1 = e(p90)
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage if or_dest==2, detail
	
		matrix est2 = e(p90)
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage main_age ///
		main_exp main_worker_akm_fe, detail
	
		estadd matrix est1
		estadd matrix est2
		est store p90
	
	// mean
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage main_age ///
		main_exp main_worker_akm_fe manu serv ret oth if or_dest==1, detail
	
		matrix est1 = e(mean)
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage manu serv ret oth if or_dest==2, detail
	
		matrix est2 = e(mean)
	
	estpost su fe_firm fe_avgworker size size_lavg rdpc_cw_wage main_wage main_age ///
		main_exp main_worker_akm_fe manu serv ret oth, detail
	
		estadd matrix est1
		estadd matrix est2
		est store mean
	
	// diff in means
	
		// inverting the groups for the ttest
		gen or_dest_inv = .
		replace or_dest_inv = 1 if or_dest == 2
		replace or_dest_inv = 2 if or_dest == 1
	
	estpost ttest fe_firm fe_avgworker size size_lavg rdpc_cw_wage manu serv ret ///
		oth main_wage, by(or_dest_inv) unequal
	
		est store diff
	
	// displaying table
	
	esttab p10 p50 p90 mean diff, label nonotes nonum noobs ///
	cells("est1(fmt(2 2 0 2) label(Origin) pattern(1 1 1 1 0)) est2(fmt(2 2 0 2) label(Destination) pattern(1 1 1 1 0)) b(star pvalue(p) label(Diff) fmt(2 2 0 2) pattern(0 0 0 0 1))") starlevels(* 0.1 ** 0.05 *** 0.01)
		
	// export table

	esttab p10 p50 p90 mean diff using "${results}/202503_sumstats.tex", booktabs replace ///
		label nonotes nonum nomtitle noobs ///
		mgroups("\textbf{10th pct}" "\textbf{Median}" "\textbf{90th pct}" "\textbf{Mean}" "\textbf{Diff}" , ///
		pattern(1 1 1 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		refcat(fe_firm "\textbf{Firm variables}"  main_wage "\\ \textbf{Manager variables}" manu "\\ \textbf{Industry}", nolabel) ///
		cells("est1(fmt(2 2 0 2) label(Origin) pattern(1 1 1 1 0)) est2(fmt(2 2 0 2) label(Destination) pattern(1 1 1 1 0)) b(star pvalue(p) label(Diff) fmt(2 2 0 2) pattern(0 0 0 0 1))") starlevels(* 0.1 ** 0.05 *** 0.01) ///
		scalars("n Poaching events")
	
	
	
		
