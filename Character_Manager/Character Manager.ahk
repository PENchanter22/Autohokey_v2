#Requires AutoHotkey v2.0
_staticdata := ".\ini\staticdata.ini"

; --- Load static sections up front ---
factionData    := LoadIniSection(_staticdata, "factions")
profData       := LoadIniSection(_staticdata, "professions")
primaryProfs   := profData["profession"]
secProfData    := LoadIniSection(_staticdata, "secondary professions")
secondaryProfs := secProfData["secondary profession"]

; --- Build GUI ---
myGui := Gui()
myGui.Title := "Character Manager"
myGui.SetFont("s16")
myGui.OnEvent("Close", (*) => ExitApp())

; G - Faction
AddLabel(myGui, "Faction")
ddlFaction := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(factionData["faction"]))
ddlFaction.Value := 1

; H - Race
AddLabel(myGui, "Race")
ddlRace := myGui.Add("DropDownList", "x175 yp-5 w200", [""])
ddlRace.Value := 1

; I - Class
AddLabel(myGui, "Class")
ddlClass := myGui.Add("DropDownList", "x175 yp-5 w200", [""])
ddlClass.Value := 1

; J - Specialization
AddLabel(myGui, "Specialization")
ddlSpec := myGui.Add("DropDownList", "x175 yp-5 w200", [""])
ddlSpec.Value := 1

; K - Armor Type (read-only label)
AddLabel(myGui, "Armor Type")
txtArmor := myGui.Add("Text", "x175 yp w200", "")

; L/M - Primary Professions
AddLabel(myGui, "Profession 1")
ddlProf1 := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(primaryProfs))
ddlProf1.Value := 1

AddLabel(myGui, "Profession 2")
ddlProf2 := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(primaryProfs))
ddlProf2.Value := 1

; N/O/P - Secondary Professions
AddLabel(myGui, "Profession 3")
ddlProf3 := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(secondaryProfs))
ddlProf3.Value := 1

AddLabel(myGui, "Profession 4")
ddlProf4 := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(secondaryProfs))
ddlProf4.Value := 1

AddLabel(myGui, "Profession 5")
ddlProf5 := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(secondaryProfs))
ddlProf5.Value := 1

myGui.Show()

; --- Cascading OnChange Events ---

ddlFaction.OnEvent("Change", FactionChanged)
ddlRace.OnEvent("Change", RaceChanged)
ddlClass.OnEvent("Change", ClassChanged)
ddlProf1.OnEvent("Change", (*) => RefreshPrimaryProfs())
ddlProf2.OnEvent("Change", (*) => RefreshPrimaryProfs())
ddlProf3.OnEvent("Change", (*) => RefreshSecondaryProfs())
ddlProf4.OnEvent("Change", (*) => RefreshSecondaryProfs())
ddlProf5.OnEvent("Change", (*) => RefreshSecondaryProfs())

FactionChanged(ctrl, *) {
    faction := StrLower(ctrl.Text)
    ResetDDL(ddlRace)
    ResetDDL(ddlClass)
    ResetDDL(ddlSpec)
    txtArmor.Value := ""
    if faction = ""
        return
    races := LoadIniKey(_staticdata, "races", faction)
    ddlRace.Delete()
    ddlRace.Add(PrependBlank(races))
    ddlRace.Value := 1
}

RaceChanged(ctrl, *) {
    race := ctrl.Text
    ResetDDL(ddlClass)
    ResetDDL(ddlSpec)
    txtArmor.Value := ""
    if race = ""
        return
    classes := LoadIniKey(_staticdata, "racial classes", race)
    ddlClass.Delete()
    ddlClass.Add(PrependBlank(classes))
    ddlClass.Value := 1
}

ClassChanged(ctrl, *) {
    class := ctrl.Text
    ResetDDL(ddlSpec)
    txtArmor.Value := ""
    if class = ""
        return
    specs  := LoadIniKey(_staticdata, "class specializations", class)
    armor  := LoadIniKey(_staticdata, "armor types", class)
    ddlSpec.Delete()
    ddlSpec.Add(PrependBlank(specs))
    ddlSpec.Value := 1
    txtArmor.Value := (armor.Length > 0) ? armor[1] : ""
}

RefreshPrimaryProfs() {
    chosen := [ddlProf1.Text, ddlProf2.Text]
    for ddl in [ddlProf1, ddlProf2] {
        cur := ddl.Text
        available := [""]
        for p in primaryProfs {
            if p = cur || !HasVal(chosen, p) || p = ""
                available.Push(p)
        }
        ddl.Delete()
        ddl.Add(available)
        ddl.Value := HasVal(available, cur) ? IndexOf(available, cur) : 1
    }
}

RefreshSecondaryProfs() {
    chosen := [ddlProf3.Text, ddlProf4.Text, ddlProf5.Text]
    for ddl in [ddlProf3, ddlProf4, ddlProf5] {
        cur := ddl.Text
        available := [""]
        for p in secondaryProfs {
            if p = cur || !HasVal(chosen, p) || p = ""
                available.Push(p)
        }
        ddl.Delete()
        ddl.Add(available)
        ddl.Value := HasVal(available, cur) ? IndexOf(available, cur) : 1
    }
}

~Escape::ExitApp()

; --- Helper Functions ---

LoadIniSection(file, section) {
    result := Map()
    raw := IniRead(file, section)
    for line in StrSplit(raw, "`n") {
        parts := StrSplit(line, "=", , 2)
        if parts.Length = 2 && parts[1] != "limit"
            result[parts[1]] := StrSplit(parts[2], "|")
    }
    return result
}

LoadIniKey(file, section, key) {
    try {
        raw := IniRead(file, section, key)
        return StrSplit(raw, "|")
    } catch {
        return []
    }
}

AddLabel(gui, label) {
    gui.Add("Text", "x10 w160", StrTitle(label))
}

ResetDDL(ctrl) {
    ctrl.Delete()
    ctrl.Add([""])
    ctrl.Value := 1
}

HasVal(arr, val) {
    for v in arr
        if v = val
            return true
    return false
}

IndexOf(arr, val) {
    for i, v in arr
        if v = val
            return i
    return 1
}

PrependBlank(arr) {
    result := [""]
    for v in arr
        result.Push(v)
    return result
}

StrTitle(str) {
    result := ""
    for word in StrSplit(str, " ")
        result .= (result ? " " : "") . StrUpper(SubStr(word,1,1)) . StrLower(SubStr(word,2))
    return result
}
