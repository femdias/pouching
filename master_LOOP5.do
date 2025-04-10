// Poaching Project
// Created by: Fabiano Dal-Ri
// (fd237@cornell.edu; dalri.fabiano@gmail.com)
// Date created: April 2024

// Purpose: Master file for the "Poaching" project

*--------------------------*
* SET UP
*--------------------------*

	// working directory
	cd "/home/ecco_rais/data/interwrk/daniela_group"
	
	// clearing session
	clear all
	macro drop _all

	// default color scheme
	set scheme s1color
	
	// globals -- input files
	
	global RAIS_Clean 	"RAIS/output/data/identified/RAIS_Clean"
	global AKM 		"akm/output/data"
	global JointMovements 	"displacement/output/data/JointMovements"
	global Owners		"fabiano/jmp/output/data/Owners"
	global Firms_Panel	"fabiano/jmp/output/data/Firms_Panel"	
	
	// globals -- paths in this folder
	
	global input		"poaching/input"
	global prepare		"poaching/programs/prepare"
	global analysis		"poaching/programs/analysis"
	global auxiliary	"poaching/programs/auxiliary"
	global data		"poaching/output/data"
	global results		"poaching/output/results"
	global temp		"poaching/temp"
	
	// globals -- analysis
	
	global evt_vars evt_l9 evt_l8 evt_l7 evt_l6 evt_l5 evt_l4 evt_zero evt_l2 evt_l1 ///
	      evt_f0 evt_f1 evt_f2 evt_f3 evt_f4 evt_f5 evt_f6 evt_f7 evt_f8 evt_f9 evt_f10 evt_f11 evt_f12	
	
*-----------------------------------------*
* POPULATING INPUT FOLDER
*-----------------------------------------*

	// "auxiliary" folder:
	// -- ipca_brazil.dta: taken from other projects; no raw files available anymore
	// -- minwage_brazil.dta: taken from other projects; no raw files available anymore
	// -- georegions.dta: taken from Fabiano's JMP
	
*-----------------------------------------*
* PREPARE
*-----------------------------------------*

// PART I: organizing RAIS data 

	// create a monthly RAIS panel
	*do "${prepare}/rais_m"
	
// PART II: constructing auxiliary data sets

	// calculate average number of employees
	*do "${prepare}/plantsize_m"
	
	// calculate wage growth variables at the plant-level
	*do "${prepare}/wagegrowth_m"
	
	// calculate industry growth (employment)
	*do "${prepare}/industrygrowth_m" // IN PROGRESS
	
	// calculate positive employment dummy variable
	*do "${prepare}/posemp_m"
			
	// identify joing movements
	*do "${prepare}/jointmvt"

// PART III: constructing intermediate data sets

	// identifying poaching events
	*do "${prepare}/202503_evt_m"
	
	// constructing worker-level panel with coworkers of the poached individuals
	*do "${prepare}/202503_cowork_panel_m"
	*do "${prepare}/202503_cowork_panel_m_LOOP1"
	*do "${prepare}/202503_cowork_panel_m_LOOP2"
	*do "${prepare}/202503_cowork_panel_m_LOOP3"
	*do "${prepare}/202503_cowork_panel_m_LOOP4"
	do "${prepare}/202503_cowork_panel_m_LOOP5"
	*do "${prepare}/202503_cowork_panel_m_LOOP6"
	*do "${prepare}/202503_cowork_panel_m_LOOP7"
	
	// constructing event-level panel with poaching plants (destination plants)
	*do "${prepare}/202503_evt_panel_m"
	
	// event-level data set
	*do "${prepare}/202503_poach_ind"
	
	// constructing worker-level data set with poaching firms in t=0
	*do "${prepare}/dest_panel_m"
	
	// identifying event types (using destination occupation)
	*do "${prepare}/evt_type_m"
	
	// imposing sample selection restrictions to the analysis
	*do "${prepare}/sample_selection"
	
// PART IV: constructing main data sets

	*do "${prepare}/202503_poaching_evt"

*-----------------------------------------*
* ANALYSIS (FINAL) - FELIPE: USE THIS
*-----------------------------------------*

// MAIN ANALYSIS

	// imposing restrictions and listing the events we want
	*do "${analysis}/eventlist"	
	
	// exhibits
	*do "${analysis}/final_sumstats"
	*do "${analysis}/final_pred1"
	*do "${analysis}/final_pred2"
	*do "${analysis}/final_pred3"
	*do "${analysis}/final_pred4"
	*do "${analysis}/final_pred5"
	*do "${analysis}/final_pred6"
	*do "${analysis}/final_pred7"
	*do "${analysis}/final_alternatives"
	
	// other analyses
	*do "${analysis}/final_preddelta"
	
// TESTING OTHER HYPOTHESES

	// hypothesis: managers are the owners of the destination firm (spinoffs)
	*do "${analysis}/test_spinoffs"
	
	// hypothesis: tenure overlap + strength of information 
	*do "${analysis}/summary_tenureoverlap"
	
// ROBUSTNESS: RESULTS WITHOUT RECLASSIFICATIONS 	

	// imposing restrictions and listing the events we want
	*do "${analysis}/eventlist_noreclass"
	
	// organing exhibits before submission
	*do "${analysis}/final_pred1_noreclass"
	*do "${analysis}/final_pred2_noreclass"
	*do "${analysis}/final_pred3_noreclass"
	*do "${analysis}/final_pred4_noreclass"
	*do "${analysis}/final_pred5_noreclass"
	*do "${analysis}/final_pred6_noreclass"
	*do "${analysis}/final_pred7_noreclass"
	*do "${analysis}/final_alternatives_noreclass"

// ROBUSTNESS: TABLES WITH 0 RAIDES

	*do "${analysis}/final_pred4_zero"
	*do "${analysis}/final_pred5_zero"
	*do "${analysis}/final_alternatives_zero"
	
	*do "${analysis}/final_pred4_zeroonly"
	*do "${analysis}/final_pred5_zeroonly"
	*do "${analysis}/final_alternatives_zeroonly"

*-----------------------------------------*
* ANALYSIS (202503 WORK) -- FABIANO'S STUFF
*-----------------------------------------*

// MAIN ANALYSIS

	// imposing restrictions and listing the events we want
	*do "${analysis}/eventlist"	
	
	// exhibits
	*do "${analysis}/202503_sumstats"
	*do "${analysis}/202503_pred1"
	*do "${analysis}/202503_pred2"
	*do "${analysis}/final_pred3"
	*do "${analysis}/202503_pred4"
	*do "${analysis}/202503_pred5"
	*do "${analysis}/202503_pred6"
	*do "${analysis}/final_pred7"
	*do "${analysis}/final_alternatives"
	
	// other analyses
	*do "${analysis}/final_preddelta"
	
// TESTING OTHER HYPOTHESES

	// hypothesis: managers are the owners of the destination firm (spinoffs)
	*do "${analysis}/test_spinoffs"
	
	// hypothesis: tenure overlap + strength of information 
	*do "${analysis}/summary_tenureoverlap"
	
// ROBUSTNESS: RESULTS WITHOUT RECLASSIFICATIONS 	

	// imposing restrictions and listing the events we want
	*do "${analysis}/eventlist_noreclass"
	
	// organing exhibits before submission
	*do "${analysis}/final_pred1_noreclass"
	*do "${analysis}/final_pred2_noreclass"
	*do "${analysis}/final_pred3_noreclass"
	*do "${analysis}/final_pred4_noreclass"
	*do "${analysis}/final_pred5_noreclass"
	*do "${analysis}/final_pred6_noreclass"
	*do "${analysis}/final_pred7_noreclass"
	*do "${analysis}/final_alternatives_noreclass"

// ROBUSTNESS: TABLES WITH 0 RAIDES

	*do "${analysis}/final_pred4_zero"
	*do "${analysis}/final_pred5_zero"
	*do "${analysis}/final_alternatives_zero"
	
	*do "${analysis}/final_pred4_zeroonly"
	*do "${analysis}/final_pred5_zeroonly"
	*do "${analysis}/final_alternatives_zeroonly"





	



	

*******************************************************************************
/* ARCHIVE

*--------------------------- mar 27 2025 archive -------------------------------

	// Figure 1: 
	
		// baseline graph
		do "${analysis}/es_baseline"
	
		// understanding baseline (raw averages)
		do "${analysis}/es_baseline_raw" // FD NOTE: I haven't organized this yet
	
	// Figure 2: 
	
		// quality of new hires
		do "${analysis}/quality_dest_hire"
	
	// Table 1:
	
		// summary statistics
		do "${analysis}/summary_statistics"
	
	// Table 2
	
		// information available
		do "${analysis}/table2"
		
	// Table 3
	
		// information is needed
		do "${analysis}/table3"
		
	// Destination growth
	
		// # of hires and # total employess
		do "${analysis}/destgrowth"
		
	// Trying something different: overlap between spv-spv and emp-emp
	do "${analysis}/overlap"
	
	// Review why there are missing values
	do "${auxiliary}/review_missing_variables"
	
	// Check if some variables are created correctly
	do "${auxiliary}/vars_dont_look_right"
	
	// Check creation of variables for which we nly had the log
	do "${auxiliary}/check_vars_in_levels"

*--------------------------- nov 19 2024 archive -------------------------------

	// Figure 3: 
	
		// CDF quality at origin
		do "${analysis}/quality_origin"
	
		// reg quality at origin
		do "${analysis}/reg_quality_origin"
		
		// generating CDF for subset of events that have at least 1 raided worker and at least 1 moveable worker
		do "${analysis}/quality_origin_sel_evts"
		
	// Table 2:
	
		// v1
		do "${analysis}/table2"
	
		// v2: include ind. and event time FE
		do "${analysis}/table2_v2"

	// Table 3:
	
		// v1
		do "${analysis}/table3"
	
		// v2: include ind. and event time FE
		do "${analysis}/table3_v2"
		
*-------------------------- other archive -------------------------------------


	// firm-level event study: baseline figures with raw averages
	*do "${analysis}/es_raw_firm"
	
	// firm-level event study: analysis using regressions
	*do "${analysis}/es_reg_firm"
	
		// heterogeneity: by type of movement (to dir, to spv, to emp)
		*do "${analysis}/es_reg_firm_type"
		
		// heterogeneity: by origin firm size
		*do "${analysis}/es_reg_firm_originsize"
		
		// heterogeneity: by destination firm size
		*do "${analysis}/es_reg_firm_destinationsize"
		
		// heterogeneity: by region (same or different)
		*do "${analysis}/es_reg_firm_region"
	
	// hires-level "event study" -- ?? -- tentative analysis so far	
	*do "${analysis}/es_reg_hires"
	
	// table: wage regressions
	
		// testing information hypothesis
		*do "${analysis}/reg_wage_info"		

*------------------------------ monthly rs -------------------------------------

	// prepare

		// organizing full RAIS (monthly panel)
		do "programs/prepare/archive_20240708/rais_m_rs"
		
		// identifying poaching events
		do "programs/prepare/archive_20240708/evt_m_rs"
		
		// constructing worker-level data set with poaching events in t=0
		do "programs/prepare/archive_20240708/evt_work_m_rs"
		
		// constructing worker-level panel with coworkers only
		do "programs/prepare/archive_20240708/cowork_panel_m_rs"
		
		// constructing event-level panel with poaching plants (d_plants)
		do "programs/prepare/archive_20240708/evt_panel_m_rs"
		
		// auxiliary data set: wages for coworkers
		do "programs/prepare/archive_20240708/wage_real_ln_cw"
		
	// analysis
	
		// sample selection (imposing additional criteria on the events)
		do "programs/analysis/archive_20240708/sample_selection"

		// summary stats
		do "programs/analysis/archive_20240708/sumstats"
	
		// firm-level event study
		do "programs/analysis/archive_20240708/es_firm_dir"
	
		// wage distribution: before vs. after poaching
		do "programs/analysis/archive_20240708/wage_dist_dir"
	
		// wage regression: poached workers only; correlation with "information"
		do "programs/analysis/archive_20240708/wage_corrinfo_dir"
	
		// wage regression: comparison with similar retained workers
		do "programs/analysis/archive_20240708/wage_xretained_dir"


*------------------------------- quarterly -------------------------------------

	// organizing quarterly panel
	do "programs/prepare/archive_20240430/RAIS_Quarterly_RS"
	
	// identifying poaching events
	do "programs/prepare/archive_20240430/PoachingEvents_Quarterly_RS"
	
		// Daniela's version
		do "programs/prepare/archive_20240430/evtdefine"
	
	// constructing the panel with coworkers
	do "programs/prepare/archive_20240430/CoWorkers_Panel_Quarterly_RS"
	
		// Daniela's version
		do "programs/prepare/archive_20240430/coworker_panel_q_rs"
	
	// creating the panel with poaching firms
	do "programs/prepare/archive_20240430/PoachingEvents_Panel_Quarterly_RS"
	
		// Daniela's version
		do "programs/prepare/archive_20240430/events_panel_rs" 
		
