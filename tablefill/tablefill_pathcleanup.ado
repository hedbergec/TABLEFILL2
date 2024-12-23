program define tablefill_pathcleanup, rclass
    syntax , path(string) shell(string)
    
    local savefolder_use = subinstr(`"`path'"',`"""',"",.)
	local savefolder_use = subinstr("`savefolder_use'","\","/",.)
	local savefolder_use = regexr("`savefolder_use'","/$","")

	local tableshellname = subinstr("`shell'","\.","_",.)
	local tableshellname = subinstr("`tableshellname'","\","/",.)

    return local tableshell `shell'
    return local tableshellname `tableshellname'
    return local savefolder_use `savefolder_use'
end