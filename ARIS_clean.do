cd "~/Library/CloudStorage/OneDrive-AbtAssociatesInc/_Solutions/tablefill/"

log close _all 

capture confirm file input_data.dta
if _rc != 0 {
    import sas using "tchpub99_sas/tchpub99.sas7bdat", clear //bcat("tchpub99_sas/formats.sas7bcat")
    tempfile teacher
    save `teacher'

    import sas using "schpub99_sas/schpub99.sas7bdat", clear //bcat("schpub99_sas/formats.sas7bcat")

    merge 1:m SCHCNTL using `teacher', nogen

    *data cleaned based on https://nces.ed.gov/surveys/sass/pdf/PublicTeacher/tchpub99_layout.pdf and 

    label var T0356 "Sex"
    label def sex 1 "Male" 2 "Female"
    label val T0356 sex 

    label var RACETH_T "Race/ethnicity"
    label def raceeth 1 "American Indian/Alaska Native" ///
        2 "Asian or Pacific Islander" ///
        3 "Black" ///
        4 "White" ///
        5 "Hispanic"
    label val RACETH_T raceeth

    label var AGE_T "Age"
    label def age 1 "Under 30" ///
        2 "30 to 39" ///
        3 "40 to 49" ///
        4 "50 and over"
    label val AGE_T age

    gen Highest_degree = .
    local i = 1
    foreach v in T0084 T0070 T0080 T0093 T0099 {
        replace Highest_degree = `i' if `v' == 1
        local ++i
    }
    label var Highest_degree "Highest degree earned"
    label def degre 1 "Associate" ///
        2 "Bachelor's" ///
        3 "Master's" ///
        4 "Education Specialist" ///
        5 "Doctor's"
    label val Highest_degree degre

    recode TOTEXPER (0/2 = 1 "Less than 3") ///
        (3/9 = 2 "3 to 9") ///
        (10/20 = 3 "10 to 20") ///
        (21/max = 4 "Over 20"), gen(TOTEXPER_rc)
    label var TOTEXPER_rc "Years of teaching experience"

    recode T0104 (3 = 2) (-8 = 6), gen(T0104_rc)
    label var T0104_rc "Certification type\2\"
    label def cert 1 "Regular" ///
        2 "Probationary" ///
        4 "Provisional or temporary" ///
        5 "Waiver or emergency" ///
        6 "No certification"
    label val T0104_rc cert

    label var URBANIC "School locale"
    label def urb 1 "Large or mid-size central city" ///
        2 "Urban fringe of large or mid-size city" ///
        3 "Small town/Rural"
    label val URBANIC urb

    label var TEALEV2 
    label def level 1 "Elementary" 2 "Secondary"
    label val TEALEV2 level
    gen elementary = 1 if TEALEV2 == 1
    label var elementary "Elementary"
    label def ele 1 "Elementary"
    label val elementary ele 
    gen secondary = 1 if TEALEV2 == 2
    label var secondary "Secondary"
    label def sec 1 "Secondary"
    label val secondary sec

    *based on https://nces.ed.gov/surveys/sass/pdf/PublicSchool/schpub99_layout.pdf

    recode S0285 (1 = .) (2 -8 = 5), gen(S0285_S0287)
    label var S0285_S0287 "Percent of students eligible for free or reduced-price lunch"
    replace S0285_S0287 =  S0287 if S0287 > 0
    label def lunch 5 "School does not participate" ///
        1 "0 to 5" ///
        2 "5 to 19" ///
        3 "20 to 49" ///
        4 "50 to 100"
    label val S0285_S0287 lunch

    destring REGION, force replace
    label var REGION "U.S. Region"
    label define region 1 "Northeast: Connecticut, Maine, Massachusetts, New Hampshire, New Jersey, New York, Pennsylvania, Rhode Island, Vermont" ///
        2 "Midwest: Illinois, Indiana, Iowa, Kansas, Michigan, Minnesota, Missouri, Nebraska, North Dakota, Ohio, South Dakota, Wisconsin" ///
        3 "South: Alabama, Arkansas, Delaware, District of Columbia, Florida, Georgia, Kentucky, Louisiana, Maryland, Mississippi, North Carolina, Oklahoma, South Carolina, Tennessee, Texas, Virginia, West Virginia" ///
        4 "West: Alaska, Arizona, California, Colorado, Hawaii, Idaho, Montana, Nevada, New Mexico, Oregon, Utah, Washington, Wyoming"
    label val REGION region 

    label var S0256 "Teacher vacancies"
    label def vacant 1 "No vacancies" 2 "Vacancies"
    label val S0256 vacant 

    keep T0356 RACETH_T AGE_T Highest_degree TOTEXPER_rc T0104_rc URBANIC TEALEV2 secondary elementary S0285_S0287 REGION S0256 TFNLWGT-TREPWT9

    gen all = 1
    label var all "Total"
    label defin tot 1 "Total"
    label val all tot

    save input_data.dta
}



