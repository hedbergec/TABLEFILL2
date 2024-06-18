program define tablefill_string_cleaner, rclass
    version 18 
    syntax anything(everything)
    local to_clean = `"`anything'"'
    local to_clean = ustrnormalize(ustrregexra(`"`to_clean'"',",|\n|\s|\\[0-9]+\\|-|\(|\)|\.|\\|\/",""), "nfd")
    local to_clean = ustrregexra(`"`to_clean'"',"_","")
    local to_clean `"`to_clean'"'
    forvalues i = 1/10 { //knock out extra quotes
        local to_clean `to_clean'
    }
    local to_clean = trim(lower("`to_clean'"))
    return local cleaned `to_clean'
end

