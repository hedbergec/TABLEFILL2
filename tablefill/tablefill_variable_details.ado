program define tablefill_variable_details, rclass
    version 18 
    syntax varlist [if] [in]
    marksample touse
    return local the_variable = "`varlist'"
    local the_var_label : variable label `varlist'
    tablefill_string_cleaner `"`the_var_label'"'
    return local the_var_label = r(cleaned)
    levelsof `varlist' if `touse', local(the_levels)
    return local the_levels = "`the_levels'"
    local i = 0
    foreach l in `the_levels' {
        local ++i 
        return local the_val_`i' = "`l'"
        local the_val_label_`i' : label (`varlist') `l'
        tablefill_string_cleaner `"`the_val_label_`i''"'
        return local the_val_label_`i' = r(cleaned)
    }
    return local number_levels = "`i'"
end

