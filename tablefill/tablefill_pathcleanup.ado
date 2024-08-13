program define tablefill_pathcleanup, rclass
    syntax , path(string) shell(string)
    
    local savefolder_use = regexreplaceall(`"`path'"',`"""',"")
	local savefolder_use = regexreplaceall("`savefolder_use'","\\","/")
	local savefolder_use = regexr("`savefolder_use'","/$","")

	local tableshellname = regexreplaceall("`shell'","\.","_")
	local tableshellname = regexreplaceall("`tableshellname'","\\","/")

    return local tableshell `shell'
    return local tableshellname `tableshellname'
    return local savefolder_use `savefolder_use'
end