program define tablefill_parse_estimates, rclass
    version 18 
    syntax using/, [factor(string)] [bformat(string)] ///
        [seformat(string)] [natest(numlist)] stat(string) [raw]
    clear
    estimates use "`using'"
    matrix b = e(b)'
    local obs = rowsof(b)
    local expressions : rownames b
    set obs `obs'
    gen stat = "`stat'"
    gen expression = ""
    tokenize "`expressions'"
    forvalues i = 1/`obs' {
        replace expression = "``i''" if _n == `i'
    }
    svmat double b
    rename b1 point
    gen point_factor = point  `factor'
    tostring point_factor , force gen(point_present) format(`bformat')
    matrix V = e(V)
    gen double se = .
    forvalues i = 1/`obs' {
        replace se = sqrt(V[`i',`i']) if _n == `i'
    }
    replace se = . if se == 0
    gen se_factor = se `factor'
    tostring se_factor, force gen(se_present) format(`seformat')
    replace se_present = "(" + se_present + ")"
    if "`raw'" == "" replace se_present = "†" if se == 0 | se == .
    svmat V
    matrix casecount = e(_N)'
    svmat casecount
    gen cv = se/abs(point)
    replace expression = regexr(expression, "bn\.", ".")
    gen note_present = ""
    replace point_present = "—" if casecount == 0 | casecount == .
    if "`raw'" == "" replace point_present = "#" if point_factor != 0 & ///
        point_factor != . & /// if its not missing
        regexm(subinstr(point_present,".","",.),"^0+$") //and the formatted val is all zeros
    if "`raw'" == "" replace se_present = "†" if cv >= .5 & cv < .
    if "`raw'" == "" replace se_present = "†" if point_present == "#" 
    if "`raw'" == "" replace note_present = "!" if cv >= .3 & cv < .5 & point_present != "#"
    if "`raw'" == "" replace point_present = "‡" if cv >= .5 & cv < . & point_present != "#"
end



