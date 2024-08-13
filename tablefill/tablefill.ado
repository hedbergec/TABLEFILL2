program tablefill
	version 18 
	syntax using/ /// excel file to fill 
		[if] [in] /// overall selection 
		, /// start options
		STATistics(string) /// what stat? allowed are "total(varlist)", "mean(varlist)", "proportion_col", "proportion" with a row (proportion of each row within column) or column option, "rate(varlist)", "median(varlist)", syntax total v , p(B) se(C) | mean z , p(D) se(E), 
		Domainvars(varlist min = 1) /// variables that id rows and columns, need at least two
		[savefolder(string)] /// folder to save estimation files
		sheet(string) /// excel sheet
		[restore] /// lookfor and restore old estimates
		titlecell(string) title(string) ///
		[logfile(string)] ///put logs here
		[raw] [noisily]

	if "`logfile'" != "" {
	    log close _all
	    log using "`logfile'", replace text
		*log off
	}

	set type double

	tablefill_pathcleanup, path(`savefolder') shell(`using')
	local tableshell = r(tableshell)
	local tableshellname = r(tableshellname)
    local savefolder_use = r(savefolder_use)

	marksample touse

	di as text "Starting TABLESHELL procedures"

	di as text _newline "checking data headers"

	local k = 0
	local max_number_levels = 0
	foreach v in `domainvars' { //get and clean all variable labels and values and value labels
		local ++k
		quietly : tablefill_variable_details `v'
		local d_header_var_`k' = r(the_variable)
		local d_header_lab_`k' = r(the_var_label)
		local d_header_levels_`k' = r(the_levels)
		local d_header_n_levels_`k' = r(number_levels)
		forvalues i = 1/`d_header_n_levels_`k'' {
			local d_header_level_val_`k'_`i' = r(the_val_`i')
			local d_header_level_lab_`k'_`i' = r(the_val_label_`i')
		}
		if `d_header_n_levels_`k'' > `max_number_levels' {
			local max_number_levels = `d_header_n_levels_`k''
		}
	}
	local number_domain_vars = `k'
	local domain_format : display "%0" strlen("`number_domain_vars'") ".0f"
	local level_format : display "%0" strlen("`max_number_levels'") ".0f"

	***** Parse stat and shell commands *****
	di _newline "reading and analyzing `tableshell'"
	preserve
	quietly : import excel "`tableshell'", allstring clear
	***** Parse stat commands *****
	local the_stat_cmd = "`statistics'"
	gettoken the_focal_cmd the_stat_cmd : the_stat_cmd, parse("|")
	local j = 1
	tablefill_parse_stat `the_focal_cmd' 
	local stat_`j' = r(the_stat)
	local stat_var_`j' = r(varlist)
	local point_columns_`j' = r(point_columns)
	local se_columns_`j' = r(se_columns)
	local note_columns_`j' = r(note_columns)
	local factor_`j' = r(factor)
	local bformat_`j' = r(bformat)
	local seformat_`j' = r(seformat)
	local propway_`j' = r(propway)
	while ("`the_stat_cmd'" ! = "") {
		gettoken the_focal_cmd the_stat_cmd : the_stat_cmd, parse("|")
		if "`the_focal_cmd'" != "|" {
			local ++j
			tablefill_parse_stat `the_focal_cmd' 
			local stat_`j' = r(the_stat)
			local stat_var_`j' = r(varlist)
			local point_columns_`j' = r(point_columns)
			local se_columns_`j' = r(se_columns)
			local note_columns_`j' = r(note_columns)
			local factor_`j' = r(factor)
			local bformat_`j' = r(bformat)
			local seformat_`j' = r(seformat)
			local propway_`j' = r(propway)
			
		}
	}
	local number_stats = `j'
	**** get number of columns in Excel
	local letters =  c(ALPHA)
	quietly : lookfor `letters'
	local colvars = r(varlist)
	*assign number to each column, and letter to each number
	local c = 0
	foreach col in `colvars' {
		local ++c
		local col_`c' = "`col'" //col_number returns letter
		local col_`col' = "`c'" //col_letter return number
	}
	local total_columns = `c'
	local col_format : display "%0" strlen("`c'") ".0f"
	
	*create clean version of table shell strings
	foreach col in `colvars' {
		tempvar clean_`col'
		quietly tablefill_gen_cleaner_string `clean_`col'' if `col' != "", from(`col')
	}
	*list of cols that have rowheaders
	local the_rowheader_cols = "`rowheadercols'"
	if "`the_rowheader_cols'" == "" {
		local the_rowheader_cols = "A" //the default
	}
	*greate rownumber variable
	tempvar index
	quietly : gen `index' = _n //row number
	local total_rows = _N
	local row_format : display "%0" strlen("`total_rows'") ".0f"

	*record what variables go with what rows
	local domain_rows ""
	forvalues k = 1/`number_domain_vars' {
		foreach col in `the_rowheader_cols' {
			quietly : levelsof `index' if `clean_`col'' == "`d_header_lab_`k''", local(rowheadercheck)
			capture assert wordcount("`rowheadercheck'") <= 1
					if _rc != 0 {
						di as error "Something is wrong with your column specifications, check your shell"
						exit 9
					}
			if wordcount("`rowheadercheck'") == 1 {
				local d_header_lab_`k'_row : display `row_format' `rowheadercheck'
				local formatted_k : display `domain_format' `k'
				local domain_rows "`domain_rows' `d_header_lab_`k'_row':`formatted_k'"
			}
		}
	}
	*sort by table row
	local domain_rows : list sort domain_rows
	*record what rows go with what domain var values
	local domain_val_rows ""
	foreach rk in `domain_rows' {
		tokenize "`rk'", parse(":")
		local k = `3'
		forvalues i = 1/`d_header_n_levels_`k'' {
			foreach col in `the_rowheader_cols' {
				quietly : levelsof `index' if `clean_`col'' == "`d_header_level_lab_`k'_`i''", local(rowheadercheck)
				capture assert wordcount("`rowheadercheck'") <= 1
				if _rc != 0 {
					di as error "Something is wrong with your column specifications, check your shell"
					exit 9
				}
				if wordcount("`rowheadercheck'") == 1 {
					local d_header_level_lab_`k'_`i'_row : display `row_format'  `rowheadercheck'
					local formatted_k : display `domain_format' `k'
					local formatted_i : display `level_format' `i'
					*row:domainvarid:valueindex=variablevalue
					local domain_val_rows "`domain_val_rows' `d_header_level_lab_`k'_`i'_row':`formatted_k':`formatted_i'=`d_header_level_val_`k'_`i''"
				}
			}
		} 
	}
	local domain_val_rows : list sort domain_val_rows
	
	*what variables go with what column?
	*get row in which row labels start
	tokenize "`domain_val_rows'", parse(":")
	local first_row = `1'
	local domain_cols ""
	local domain_cols_n ""
	forvalues k = 1/`number_domain_vars' {
		foreach col in `colvars' {
			if regexm("`the_rowheader_cols'", "`col'") == 0 {
				quietly : levelsof `index' if `clean_`col'' != "" & ///
					 `clean_`col'' == "`d_header_lab_`k''" ///
					& `index' < `first_row', local(colheadercheck)
				if "`colheadercheck'" != "" {
					local d_header_lab_`k'_col_n : display `col_format' `col_`col''
					local formatted_k : display `domain_format' `k'
					local domain_cols "`domain_cols' `d_header_lab_`k'_col_n':`formatted_k'"
				}
			}
		}
	}
	local domain_cols : list sort domain_cols
	***** what values go with what cols? *****
	**first one **
	local domain_val_cols ""
	local running_domain_cols = "`domain_cols'"
	gettoken the_focal_col running_domain_cols : running_domain_cols
	tokenize "`the_focal_col'", parse(":")
	local first_col = `1'
	local k = `3'
	tokenize "`running_domain_cols'", parse(":")
	local last_col = `1'-1
	if `last_col' == -1 {
		local last_col = `total_columns'
	}
	forvalues i = 1/`d_header_n_levels_`k'' {
		local temp_domain_spec ""
		forvalues c = `first_col'/`last_col' {
			quietly : levelsof `index' if `clean_`col_`c''' == "`d_header_level_lab_`k'_`i''", local(colheadercheck)
				local formatted_k : display `domain_format' `k'
				local formatted_i : display `level_format' `i'
				capture assert wordcount("`colheadercheck'") <= 1
					if _rc != 0 {
						di as error "Something is wrong with your column specifications, check your shell"
						exit 9
					}
				if wordcount("`colheadercheck'") == 1 & "`temp_domain_spec'" == "" {
					local d_header_level_lab_`k'_`i'_col : display `col_format'  `c'
					local temp_domain_spec "`d_header_level_lab_`k'_`i'_col':`formatted_k':`formatted_i'=`d_header_level_val_`k'_`i''"
					*col:domainvarid:valueindex=variablevalue
					
				}
				if wordcount("`colheadercheck'") == 0 & "`temp_domain_spec'" != "" {
					local d_header_level_lab_`k'_`i'_col : display `col_format'  `c'
					local temp_domain_spec "`temp_domain_spec' `d_header_level_lab_`k'_`i'_col':`formatted_k':`formatted_i'=`d_header_level_val_`k'_`i''"
					*col:domainvarid:valueindex=variablevalue
					
				} 
		}
		local domain_val_cols "`domain_val_cols' `temp_domain_spec'"

	}
	** end first one **, now do others
	while ("`running_domain_cols'" ! = "") {
		gettoken the_focal_col running_domain_cols : running_domain_cols
		tokenize "`the_focal_col'", parse(":")
		local first_col = `1'
		local k = `3'
		tokenize "`running_domain_cols'", parse(":")
		local last_col = `1'-1
		if `last_col' == -1 {
			local last_col = `total_columns'
		}
		forvalues i = 1/`d_header_n_levels_`k'' {
			local temp_domain_spec ""
			forvalues c = `first_col'/`last_col' {
				quietly : levelsof `index' if `clean_`col_`c''' == "`d_header_level_lab_`k'_`i''", local(colheadercheck)
					local formatted_k : display `domain_format' `k'
					local formatted_i : display `level_format' `i'
					capture assert wordcount("`colheadercheck'") <= 1
					if _rc != 0 {
						di as error "Something is wrong with your column specifications, check your shell"
						exit 9
					}
					if wordcount("`colheadercheck'") == 1 & "`temp_domain_spec'" == "" {
						local d_header_level_lab_`k'_`i'_col : display `col_format'  `c'
						local temp_domain_spec "`d_header_level_lab_`k'_`i'_col':`formatted_k':`formatted_i'=`d_header_level_val_`k'_`i''"
						*col:domainvarid:valueindex=variablevalue
						
					}
					if wordcount("`colheadercheck'") == 0 & "`temp_domain_spec'" != "" {
						local d_header_level_lab_`k'_`i'_col : display `col_format'  `c'
						local temp_domain_spec "`temp_domain_spec' `d_header_level_lab_`k'_`i'_col':`formatted_k':`formatted_i'=`d_header_level_val_`k'_`i''"
						*col:domainvarid:valueindex=variablevalue
						
					} 
			}
			local domain_val_cols "`domain_val_cols' `temp_domain_spec'"

		}
	}
	* clean up
	local domain_val_cols : list sort domain_val_cols

	restore 

	**** END SHELL and Stat Command Parsing 

	di _newline "checking data settings..." _continue

	**** Build estimations file ****

	tempvar run_use
	quietly : gen `run_use' = 0
	
	*check for mi settings
	quietly : mi query
	if r(M) != 0 {
		di as text r(M) " multiple imputations detected..." _continue
		local micheck = "mi "
	}
	*check for survey settings
	quietly : `micheck' svyset
	local svysettings = r(settings)

	if r(settings) != ", clear" {
		di as text "`micheck'survey settings detected..." _continue
		local svyprefix "svy, subpop(if `touse' == 1) : "
		local if_postfix ""
		if "`micheck'" != "" {
			quietly : mi svyset `svysettings'
		}

	}
	else {
		local svyprefix ""
		local if_postfix "if `touse' == 1"
	}
	di "done." 
	forvalues j = 1/`number_stats' {
		if "`restore'" == "" di _newline "running `stat_`j'' commands"
		foreach rowspec in `domain_rows' {
			foreach colspec in `domain_cols' {
				tokenize "`rowspec'", parse(":")
				local rowvarid = `3'
				tokenize "`colspec'", parse(":")
				local colvarid = `3'
				*initialize some checks
				local restorecmd ""
				local miprefix ""
				*are anyvariables mi?
				tablefill_mi_var_check,  current_vars(`stat_var_`j'' `d_header_var_`rowvarid'' `d_header_var_`colvarid'' `if_postfix' )
				if r(check_ivars) > 0 & r(check_ivars) != . { //if we have any MI data
					local miprefix "mi estimate : "
					local restorecmd ""
				}
				else { //if no mi data used, preserve, extract, svyset (if needed) and plant restore command
					if "`micheck'" != "" { //...but only if there is any MI at all...
						local miprefix ""
						quietly : preserve 
						quietly : mi extract 0, clear
						if "`svyprefix'" != "" quietly : svyset `svysettings'
						local restorecmd "restore"
					}
					
				}
				if regexm("`stat_`j''","prop") == 1 {
					if `rowvarid' == `colvarid' {
						if "`propway_`j''" == "col" {
							capture confirm file "`savefolder_use'/est_prop_`propway'_`d_header_var_`rowvarid''_`tableshellname'.ster"
							if _rc != 0 | "`restore'" == "" {
								quietly : replace `run_use' = `d_header_var_`rowvarid'' < . `if_postfix'
								quietly : `noisily' `miprefix' `svyprefix'  proportion `d_header_var_`rowvarid'' `if_postfix'
								quietly : `noisily' estimates save "`savefolder_use'/est_prop_`propway'_`d_header_var_`rowvarid''_`tableshellname'.ster", replace
							}
						}
						if "`propway_`j''" == "row" {
							capture confirm file "`savefolder_use'/est_prop_`propway'_`d_header_var_`colvarid''_`tableshellname'.ster"
							if _rc != 0 | "`restore'" == "" {
								quietly : replace `run_use' = `d_header_var_`colvarid'' < . `if_postfix'
								quietly : `noisily' `miprefix' `svyprefix'  proportion `d_header_var_`colvarid'' `if_postfix'
								quietly : `noisily' estimates save "`savefolder_use'/est_prop_`propway'_`d_header_var_`colvarid''_`tableshellname'.ster", replace
							}
							
						}
					}
					else {
						if "`propway_`j''" == "col" {
							capture confirm file "`savefolder_use'/est_prop_`propway'_`d_header_var_`rowvarid''_by_`d_header_var_`colvarid''_`tableshellname'.ster"
							if _rc != 0 | "`restore'" == "" {
								quietly : replace `run_use' = `d_header_var_`colvarid'' < . & `d_header_var_`rowvarid'' < . `if_postfix'
								quietly : `noisily' `miprefix' `svyprefix'  proportion `d_header_var_`rowvarid'' `if_postfix', over(`d_header_var_`colvarid'')
								quietly : `noisily' estimates save "`savefolder_use'/est_prop_`propway'_`d_header_var_`rowvarid''_by_`d_header_var_`colvarid''_`tableshellname'.ster", replace
							}
							
						}
						if "`propway_`j''" == "row" {
							capture confirm file "`savefolder_use'/est_prop_`propway'_`d_header_var_`colvarid''_by_`d_header_var_`rowvarid''_`tableshellname'.ster"
							if _rc != 0 | "`restore'" == "" {
								quietly : replace `run_use' = `d_header_var_`colvarid'' < . & `d_header_var_`rowvarid'' < . `if_postfix'
								quietly : `noisily' `miprefix' `svyprefix'  proportion `d_header_var_`colvarid'' `if_postfix', over(`d_header_var_`rowvarid'')
								quietly : `noisily' estimates save "`savefolder_use'/est_prop_`propway'_`d_header_var_`colvarid''_by_`d_header_var_`rowvarid''_`tableshellname'.ster", replace
							}
						}
					}
				}
				else {
					if `rowvarid' == `colvarid' {
						capture confirm file "`savefolder_use'/est_`stat_`j''_`stat_var_`j''_by_`d_header_var_`rowvarid''_`tableshellname'.ster"
						if _rc != 0 | "`restore'" == "" {
							quietly : replace `run_use' = `stat_var_`j'' < . & `d_header_var_`rowvarid'' < . `if_postfix'
							
							quietly : `noisily' `miprefix' `svyprefix'  `stat_`j'' `stat_var_`j'' `if_postfix' , over(`d_header_var_`rowvarid'') 
							quietly : `noisily' estimates save "`savefolder_use'/est_`stat_`j''_`stat_var_`j''_by_`d_header_var_`rowvarid''_`tableshellname'.ster", replace
						}
						
					}
					else {
						capture confirm file "`savefolder_use'/est_`stat_`j''_`stat_var_`j''_by_`d_header_var_`rowvarid''_`d_header_var_`colvarid''_`tableshellname'.ster"
						if _rc != 0 | "`restore'" == "" {
							quietly : replace `run_use' = `stat_var_`j'' < . & `d_header_var_`rowvarid'' < . & `d_header_var_`colvarid'' < . `if_postfix'
							quietly : `noisily' `miprefix' `svyprefix'  `stat_`j'' `stat_var_`j'' `if_postfix' , over(`d_header_var_`rowvarid'' `d_header_var_`colvarid'') 
							quietly : `noisily' estimates save "`savefolder_use'/est_`stat_`j''_`stat_var_`j''_by_`d_header_var_`rowvarid''_`d_header_var_`colvarid''_`tableshellname'.ster", replace
						}
					}
				}
				`restorecmd' //if data were mi extracted return to memory
			} 
		}
	}
	

	***build estimation file of results

	preserve
	clear 

	tempfile estimates_file
	quietly : `noisily' save `estimates_file', replace emptyok

	forvalues j = 1/`number_stats' {
		foreach rowspec in `domain_rows' {
			foreach colspec in `domain_cols' {
				tokenize "`rowspec'", parse(":")
				local rowvarid = `3'
				tokenize "`colspec'", parse(":")
				local colvarid = `3'
				if regexm("`stat_`j''","prop") == 1 {
					if `rowvarid' == `colvarid' {
						if "`propway_`j''" == "col" {
							quietly : tablefill_parse_estimates using ///
								"`savefolder_use'/est_prop_`propway'_`d_header_var_`rowvarid''_`tableshellname'.ster", `raw'  	///
								bformat("`bformat_`j''") seformat("`seformat_`j''") factor(`factor_`j'') stat("`stat_`j''")
							quietly : append using `estimates_file'
							quietly : save `estimates_file', replace
							
						}
						if "`propway_`j''" == "row" {
							quietly : tablefill_parse_estimates using ///
								"`savefolder_use'/est_prop_`propway'_`d_header_var_`colvarid''_`tableshellname'.ster", `raw'   ///
								bformat("`bformat_`j''") seformat("`seformat_`j''") factor(`factor_`j'') stat("`stat_`j''")
							quietly : append using `estimates_file'
							quietly : save `estimates_file', replace
						}
					}
					else {
						if "`propway_`j''" == "col" {
							quietly : tablefill_parse_estimates using ///
								"`savefolder_use'/est_prop_`propway'_`d_header_var_`rowvarid''_by_`d_header_var_`colvarid''_`tableshellname'.ster", `raw'   ///
								bformat("`bformat_`j''") seformat("`seformat_`j''") factor(`factor_`j'') stat("`stat_`j''")
							quietly : append using `estimates_file'
							quietly : save `estimates_file', replace
							
						}
						if "`propway_`j''" == "row" {
							quietly : tablefill_parse_estimates using ///
								"`savefolder_use'/est_prop_`propway'_`d_header_var_`colvarid''_by_`d_header_var_`rowvarid''_`tableshellname'.ster", `raw'   ///
								bformat("`bformat_`j''") seformat("`seformat_`j''") factor(`factor_`j'') stat("`stat_`j''")
							quietly : append using `estimates_file'
							quietly : save `estimates_file', replace
						}
					}
				}
				else {
					if `rowvarid' == `colvarid' {
						quietly : tablefill_parse_estimates using ///
							"`savefolder_use'/est_`stat_`j''_`stat_var_`j''_by_`d_header_var_`rowvarid''_`tableshellname'.ster", `raw'   ///
							bformat("`bformat_`j''") seformat("`seformat_`j''") factor(`factor_`j'') stat("`stat_`j''")
						quietly : append using `estimates_file'
						quietly : save `estimates_file', replace
						
					}
					else {
						quietly : tablefill_parse_estimates using ///
							"`savefolder_use'/est_`stat_`j''_`stat_var_`j''_by_`d_header_var_`rowvarid''_`d_header_var_`colvarid''_`tableshellname'.ster", `raw'   ///
							bformat("`bformat_`j''") seformat("`seformat_`j''") factor(`factor_`j'') stat("`stat_`j''")
						quietly : append using `estimates_file'
						quietly : save `estimates_file', replace
					}
				}
			} 
		}
	}

	quietly : use `estimates_file', replace

	quietly : gen row = ""
	quietly : gen point_col = ""
	quietly : gen se_col = ""
	quietly : gen note_col = ""


	quietly : `noisily' di "Row specs row:domainvarid:valueindex=variablevalue"
	foreach rowspec in `domain_val_rows' {
		tokenize "`rowspec'", parse("=")
		local row_var_details `1'
		local the_val `3'
		tokenize "`row_var_details'", parse(":")
		local the_row = `1' //row number
		local rowvarid = `3' //variable id
		quietly : replace row = "`the_row'" if regexm(expression, "`the_val'\.`d_header_var_`rowvarid''") == 1
		quietly : `noisily' di "`rowspec'"
		
	}
	quietly : `noisily' di "Column specs col:domainvarid:valueindex=variablevalue"
	foreach colspec in `domain_val_cols' {
		tokenize "`colspec'", parse("=")
		local col_var_details `1'
		local the_val `3'
		tokenize "`col_var_details'", parse(":")
		local the_col = `1' //column number
		local rowvarid = `3' //variable id
		forvalues j = 1/`number_stats' {
			foreach coltype in point se note {
				foreach col in ``coltype'_columns_`j'' {
					quietly : replace `coltype'_col = "`col_`the_col''" if ///
						regexm(expression, "`the_val'\.`d_header_var_`rowvarid''") == 1 & ///
						"`col'" == "`col_`the_col''" & stat == "`stat_`j''"
				}
			}
			

		}
		quietly : `noisily' di "`colspec'"
	}

	**** Populate Shell

	quietly : `noisily' save "`savefolder_use'/table_estimates_`tableshellname'.dta", replace

	local populate_copy = regexr("`tableshell'","\.xls","_populated.xls")
	local populate_copy = regexr("`populate_copy'","\/|\\","_")

	quietly : `noisily'  copy "`tableshell'" "`savefolder_use'/`populate_copy'", replace 

	quietly : `noisily' putexcel set "`savefolder_use'/`populate_copy'", sheet("`sheet'") modify
	quietly : levelsof row , local(rowlist) clean 
	foreach r in `rowlist' {
		foreach coltype in point se note {
			forvalues j = 1/`number_stats' {
				quietly : levelsof `coltype'_col if stat == "`stat_`j''", local(collist) clean
				foreach c in `collist' {
					quietly : levelsof `coltype'_present if row == "`r'" & `coltype'_col == "`c'", local(tofill) clean 
					capture assert wordcount("`tofill'") <= 1
					if _rc != 0 {
						di as error "Something is wrong with your column specifications, check your shell"
						exit 9
					}
					quietly : putexcel `c'`r' = "`tofill'"
				}
			} 
		}
	}
	quietly : `noisily' putexcel `titlecell' = `"`title'"'

	di _newline "`savefolder_use'/`populate_copy' populated" 
	
	restore

	if "`logfile'" != "" {
		log close _all 
	}
	

end

