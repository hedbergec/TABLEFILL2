*program to parse statistics command for tablefill with proc var, p(columns for point) se(columns for se) format
program define tablefill_parse_stat, rclass
    version 18 
    syntax anything, Point(varlist) [se(varlist)] [note(varlist)] ///
        [factor(string)] [bformat(string)] [seformat(string)] [natest(numlist)] ///
        [row] [col] 
    tokenize "`anything'"
    return local the_stat = "`1'"
    return local varlist = "`2'"
    return local point_columns "`point'"
    if regexm("`the_stat'","prop") == 1 {
        capture assert ("`row'" == "row" & "`col'" == "") | ("`row'" == "" & "`col'" == "col")
        if _rc != 0 {
            di as error "proportion statistics specs need either a row or column option stated" 
            exit
        }
    }
    return local se_columns "`se' " //need space to return something
    return local note_columns "`note' " //need space to return something
    return local factor "`factor' " //need space to return something
    return local bformat "`bformat' " //need space to return something
    return local seformat "`seformat' " //need space to return something
    if "`row'" == "" & "`col'" == "" {
        return local propway "notapropstat" //need space to return something
    }
    else {
        return local propway "`row'`col'" 
    }
    
end

