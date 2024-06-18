program drop _all
adopath + "./TABLEFILL"

cls 

quietly : do "ARIS_clean.do"

use "input_data.dta", clear

*svyset the data per BRR
*svyset [pw = TFNLWGT] , vce(brr) brrweight(TREPWT*)

gen cons = 1

timer clear 

*log using test_run.smcl, replace 

*describe data
describe 

timer on 1

tablefill using "tabn209_21_SASS.xlsx", /// the shell
    sheet("Digest 2000 Table 209.21") /// the sheet
    statistics( /// describe what statistics to estimate and columns
    total cons, point(B E H) note(C F I) se(D G J) ///
        factor(*0.001) bformat(%6.0fc) seformat(%6.1f) ///
        | /// pipe for antoher statistic
    proportion, col p(K N Q) note(L O R) se(M P S) ///
        factor(*100) bformat(%3.0f) seformat(%3.1f) ///
    ) ///
    domainvars( ///
        all ///
        T0356 RACETH_T AGE_T Highest_degree ///
        TOTEXPER_rc T0104_rc URBANIC TEALEV2 ///
        secondary elementary S0285_S0287 REGION S0256 ///
    ) ///
    savefolder("Results")   ///
    titlecell(A1) ///
    title("Table 209.21. Number and percentage distribution of teachers in traditional public elementary and secondary schools, by instructional level and selected teacher and school characteristics: School year 1999-2000")


asdf

timer off 1

timer list 

**same game, but use saved results 

timer on 2

tablefill using "tabn209_21_SASS.xlsx", ///
    sheet("Digest 2000 Table 209.21") ///
    statistics( ///
    proportion, col p(K N Q) note(L O R) se(M P S) ///
        factor(*100) bformat(%3.0f) seformat(%3.1f) | ///
    total cons, point(B E H) note(C F I) se(D G J) ///
        factor(*0.001) bformat(%6.0f) seformat(%6.1f) ///
    ) ///
    domainvars( ///
        all ///
        T0356 RACETH_T AGE_T Highest_degree ///
        TOTEXPER_rc T0104_rc URBANIC TEALEV2 ///
        secondary elementary S0285_S0287 REGION S0256 ///
    ) ///
    savefolder("Results") restore ///
    titlecell(A1) ///
    title("Table 209.21. Number and percentage distribution of teachers in traditional public elementary and secondary schools, by instructional level and selected teacher and school characteristics: School year 1999-2000")

timer off 2

levelsof REGION, local(regions)
local timerval = 2
foreach r in `regions' {
    local ++timerval
    timer on `timerval'
    local rlab : label (REGION) `r'
    tokenize "`rlab'", parse(":")
    local rlab "`1'"

    copy "tabn209_21_SASS.xlsx" "tabn209_21_SASS_`rlab'.xlsx", replace

    tablefill using "tabn209_21_SASS_`rlab'.xlsx" if REGION == `r', ///
    sheet("Digest 2000 Table 209.21") ///
    statistics( ///
    proportion, col p(K N Q) note(L O R) se(M P S) ///
        factor(*100) bformat(%3.0f) seformat(%3.1f) | ///
    total cons, point(B E H) note(C F I) se(D G J) ///
        factor(*0.001) bformat(%6.0f) seformat(%6.1f) ///
    ) ///
    domainvars( ///
        all ///
        T0356 RACETH_T AGE_T Highest_degree ///
        TOTEXPER_rc T0104_rc URBANIC TEALEV2 ///
        secondary elementary S0285_S0287 REGION S0256 ///
    ) ///
    savefolder("Results")  ///
    titlecell(A1) ///
    title("Table 209.21. Number and percentage distribution of teachers in traditional" ///
      "public elementary and secondary schools in the `rlab' region," ///
      "by instructional level and selected teacher and school characteristics:" ///
      "School year 1999-2000")
    timer off `timerval'
}

timer list 

forvalues t = 1/`timerval' {
    di "t = `t' " r(t`t')/60
}

log close _all 

translate test_run.smcl test_run.pdf, replace 