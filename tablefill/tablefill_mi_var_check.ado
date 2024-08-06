program define tablefill_mi_var_check, rclass
    syntax, current_vars(string) 
    local char_ivars : char _dta[_mi_ivars]
    local the_ivars : list current_vars & char_ivars
    return scalar check_ivars = wordcount("`the_ivars'")
end