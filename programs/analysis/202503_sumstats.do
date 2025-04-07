// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: January 2025

// Purpose: Summary statistics

*--------------------------*
* PREPARE
*--------------------------*

	use "${data}/poaching_evt", clear
	
	// we're only interested in spv-spv, spv-emp, and emp-spv
	keep if type == 1 | type == 2 | type == 3
	
	// keeping only the events we're interested in -- THIS PART HAS TO BE MODIFIED!!! USING TEMP FILE!!!
	// WHAT I SHOULD DO HERE: RUN THE COMPLETE REGRESSION (ONCE I'VE DEFINED IT) & KEEP E(SAMPLE) == 1
	// REVIEW THIS ONCE I GET TO PREDICTIONS 4, 5, AND 6
	rename type spv
	merge m:1 spv event_id using "${temp}/eventlist", keep(match)
	rename spv type
	
	// organizing some variables for this analysis
	// note: origin = 1, destination = 2 
	
		// fe_firm
		rename fe_firm_o fe_firm1
		rename fe_firm_d fe_firm2
		
		// fe_avgworker
		rename o_avg_fe_worker fe_avgworker1
		rename d_avg_fe_worker fe_avgworker2
		
		// size_w
		rename o_size size1
		rename d_size size2
		
		// rd_cw_wage_w 
		rename rd_coworker_wage_o_lvl rd_cw_wage1
		rename rd_coworker_wage_d_lvl rd_cw_wage2
		
		// pc_wage_w
		rename pc_wage_o_l1_lvl pc_wage1
		rename pc_wage_d_lvl pc_wage2
		
		// pc_age
		* already in data set
		
		// pc_exp
		* already in data set
		
		// pc_fe
		* already in data set
		
		// industry
		rename cnae_d cnae2
		rename cnae_o cnae1
					
		// industry: manufacturing
		g manu1 = (cnae1 >= 10 & cnae1 <= 33)
		g manu2 = (cnae2 >= 10 & cnae2 <= 33)
					
		// industry: services
		g serv1 = (cnae1 >= 55 & cnae1 <= 66) | (cnae1 >= 69 & cnae1 <= 82) | (cnae1 >= 94 & cnae1 <= 97)
		g serv2 = (cnae2 >= 55 & cnae2 <= 66) | (cnae2 >= 69 &	cnae2 <= 82) | (cnae2 >= 94 & cnae2 <= 97)
						
		// industry: retail
		g ret1 = (cnae1 >= 45 & cnae1 <= 47)
		g ret2 = (cnae2 >= 45 & cnae2 <= 47)
						
		// industry: other
		g oth1 = (manu1 == 0 & serv1 == 0 & ret1 == 0)
		g oth2 = (manu2 == 0 & serv2 == 0 & ret2 == 0)
	
	// only keeping what we need
	keep event_id type fe_firm1 fe_firm2 fe_avgworker1 fe_avgworker2 size1 size2 rd_cw_wage1 rd_cw_wage2 ///
		pc_wage1 pc_wage2 pc_age pc_exp pc_fe manu1 manu2 serv1 serv2 ret1 ret2 oth1 oth2
	
	// reshaping data set
	egen unique_id = group(event_id type)
	reshape long fe_firm fe_avgworker size rd_cw_wage pc_wage manu serv ret oth , ///
		i(unique_id) j(or_dest)	
		
	// labeling variables	
	la var fe_firm "Productivity proxy (firm AKM FE)"
	la var fe_avgworker "Avg. worker ability (worker AKM FE)"
	la var size "Firm size (\# workers)"
	la var rd_cw_wage "Raided workers wage (2008 BRL)"
	la var pc_wage "Salary"
	la var pc_age "Age"
	la var pc_exp "Experience"
	la var pc_fe "Ability"
	la var manu "Manufacturing"
	la var serv "Services"
	la var ret "Retail"
	la var oth "Other"
	
	// summary statistics
	
	cap drop estimates*
	
	// p10
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage pc_age pc_exp pc_fe if or_dest==1, detail
	matrix est1 = e(p10)
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage		     if or_dest==2, detail
	matrix est2 = e(p10)
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage pc_age pc_exp pc_fe		  , detail
	estadd matrix est1
	estadd matrix est2
	est store p10
	
	// p50
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage pc_age pc_exp pc_fe if or_dest==1, detail
	matrix est1 = e(p50)
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage                     if or_dest==2, detail
	matrix est2 = e(p50)
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage pc_age pc_exp pc_fe              , detail
	estadd matrix est1
	estadd matrix est2
	est store p50
	
	// p90
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage pc_age pc_exp pc_fe if or_dest==1, detail
	matrix est1 = e(p90)
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage                     if or_dest==2, detail
	matrix est2 = e(p90)
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage pc_age pc_exp pc_fe              , detail
	estadd matrix est1
	estadd matrix est2
	est store p90
	
	// mean
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage pc_age pc_exp pc_fe manu serv ret oth if or_dest==1, detail
	matrix est1 = e(mean)
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage manu serv ret oth  	               if or_dest==2, detail
	matrix est2 = e(mean)
	
	estpost su  fe_firm fe_avgworker size rd_cw_wage pc_wage pc_age pc_exp pc_fe manu serv ret oth              , detail
	estadd matrix est1
	estadd matrix est2
	est store mean
	
	// diff in means
	
	estpost ttest  fe_firm fe_avgworker size rd_cw_wage manu serv ret oth pc_wage, by(or_dest) unequal
	est store diff
	
	// displaying table
	
	esttab p10 p50 p90 mean diff, label nonotes nonum noobs ///
	cells("est1(fmt(2 2 0 2) label(Origin) pattern(1 1 1 1 0)) est2(fmt(2 2 0 2) label(Destination) pattern(1 1 1 1 0)) b(star pvalue(p) label(Diff) fmt(2 2 0 2) pattern(0 0 0 0 1))") starlevels(* 0.1 ** 0.05 *** 0.01)
		
	// export table

	esttab p10 p50 p90 mean diff using "${results}/202503_sumstats.tex", booktabs replace ///
		label nonotes nonum nomtitle noobs ///
		mgroups("\textbf{10th pct}" "\textbf{Median}" "\textbf{90th pct}" "\textbf{Mean}" "\textbf{Diff}" , ///
		pattern(1 1 1 1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
		refcat(fe_firm "\textbf{Firm variables}" manu "\\ \textbf{Industry}" pc_wage_w "\\ \textbf{Manager variables}" , nolabel) ///
		cells("est1(fmt(2 2 0 2) label(Origin) pattern(1 1 1 1 0)) est2(fmt(2 2 0 2) label(Destination) pattern(1 1 1 1 0)) b(star pvalue(p) label(Diff) fmt(2 2 0 2) pattern(0 0 0 0 1))") starlevels(* 0.1 ** 0.05 *** 0.01) ///
		scalars("n_1 Poaching events")
	
	
	
		
