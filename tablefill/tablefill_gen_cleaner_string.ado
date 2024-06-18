program define tablefill_gen_cleaner_string
    version 18 
    syntax namelist [if], from(varlist) 
    marksample touse 
    capture drop `namelist'
    quietly gen `namelist' = ""
    tempvar index
    quietly : gen `index' = _n if `touse'
    quietly : levelsof `index', local(rowlist)
    foreach i in `rowlist' {
        quietly : levelsof `from' if `index' == `i', local(oldstring)
        tablefill_string_cleaner `"`oldstring'"'
        quietly : replace `namelist' = r(cleaned) if `index' == `i' 
    }


end