; ============================================================
;  CharacterDB.ahk — Character CRUD, list, sort, entry dialog
;  Include this file from the master script.
; ============================================================

CharFile() {
    global ActivePro
    return A_ScriptDir "\" ActivePro ".json"
}

; ── Load / Save ──────────────────────────────────────────────

LoadCharDB() {
    global g_chars, g_selIdx, ActivePro
    g_chars  := []
    g_selIdx := 0
    f := CharFile()
    Log("SaveCharDB — writing to: " f " for profile: " ActivePro, "LINE")
    Log("LoadCharDB called — looking for: " f)
    if !FileExist(f) {
        Log("File not found: " f, "WARN")
;        SetStatus("No characters found for: " ActivePro, "warn")
        SetStatus("No file found at: " CharFile(), "warn")
        RefreshList()
        return
    }
    try {
        all := JsonParse(FileRead(f, "UTF-8"))
        Log("File loaded — total records in file: " all.Length)
        ; Filter to only characters belonging to this profile
        g_chars := []
        loop all.Length {
            ch := all[A_Index]
            if ch.Get("profile", "") == ActivePro {
                g_chars.Push(ch)
            }
        }
        Log("Records matching profile '" ActivePro "': " g_chars.Length)
        Log("About to call SortChars — g_chars.Length: " g_chars.Length)
        SortChars()
        Log("SortChars complete — about to call RefreshList")
        RefreshList()
        SetStatus("Found " g_chars.Length " character(s) for: " ActivePro)
    } catch as e {
		ShowMsg("Failed to load character file:`n" e.Message, "Load Error")
    }
}

SaveCharDB() {
    global g_chars, ActivePro
    try {
        ; Read existing file to preserve characters from other profiles
        f   := CharFile()
        all := []
        if FileExist(f) {
            existing := JsonParse(FileRead(f, "UTF-8"))
            loop existing.Length {
                ch := existing[A_Index]
                if ch.Get("profile", "") != ActivePro {
                    all.Push(ch)
                }
            }
        }
        ; Append current profile's characters (with profile field set)
        loop g_chars.Length {
            ch := g_chars[A_Index]
            ch["profile"] := ActivePro
            all.Push(ch)
        }
        ; Build ordered JSON manually for character array
        charParts := []
        loop all.Length {
            charParts.Push("  " JsonStringifyChar(all[A_Index], 1))
        }
        output := "[`n" JoinArr(charParts, ",`n") "`n]"
        FileOpen(f, "w", "UTF-8").Write(output)
;        FileOpen(f, "w", "UTF-8").Write(JsonStringify(all))
        SetStatus("Saved " g_chars.Length " character(s) for: " ActivePro, "ok")
    } catch as e {
		ShowMsg("Failed to save:`n" e.Message, "Save Error")
    }
}

; ── ListView ─────────────────────────────────────────────────

RefreshList(filter := "") {
    global g_chars, LV, ActivePro, StatusBar
    Log("RefreshList called — g_chars.Length: " g_chars.Length " filter: '" filter "'")
    LV.Delete()
    n := 0
    loop g_chars.Length {
        ch := g_chars[A_Index]
;        Log("RefreshList — row " A_Index ": " ch.Get("name","(no name)"), "DEBUG")
        if filter != "" {
            hit := false
            for _, fld in ["name", "class", "race", "realm", "guild", "spec"] {
                if InStr(ch.Get(fld, ""), filter, false) {
                    hit := true
                }
            }
            if !hit {
                continue
            }
        }
        n++
        LV.Add("",
            ch.Get("name",    ""),
            ch.Get("level",   ""),
            ch.Get("realm",   ""),
            ch.Get("guild",   ""),
            ch.Get("faction", ""),
            ch.Get("race",    ""),
            ch.Get("gender",  ""),
            ch.Get("class",   ""),
            ch.Get("spec",    ""),
            ch.Get("armor",   ""),
            ch.Get("prof1",   ""),
            ch.Get("prof2",   ""),
            ch.Get("sec1",    ""),
            ch.Get("sec2",    ""),
            ch.Get("sec3",    ""),
            ch.Get("status",  ""))
    }
    SetStatus("Found " n " character(s) for: " ActivePro)
}

LV_Select(ctrl, rowNum, *) {
    global g_selIdx
    if rowNum > 0 {
        ; Match visible row back to g_chars by name
        name := ctrl.GetText(rowNum, 1)
        g_selIdx := 0
        loop g_chars.Length {
            if g_chars[A_Index].Get("name", "") == name {
                g_selIdx := A_Index
                break
            }
        }
    } else {
        g_selIdx := 0
    }
}

LV_ColClick(ctrl, col, *) {
    global g_sortCol, g_sortAsc
    if g_sortCol == col {
        g_sortAsc := !g_sortAsc
    } else {
        g_sortCol := col
        g_sortAsc := true
    }
    SortChars()
    RefreshList(EditSearch.Value)
}

SortChars() {
    global g_chars, g_sortCol, g_sortAsc
    colMap := Map(
         1, "name",    2, "level",   3, "realm",   4, "guild",
         5, "faction", 6, "race",    7, "gender",  8, "class",
         9, "spec",   10, "armor",  11, "prof1",  12, "prof2",
        13, "sec1",   14, "sec2",   15, "sec3",   16, "status")
    key := colMap.Has(g_sortCol) ? colMap[g_sortCol] : "name"
    n   := g_chars.Length
    i   := 1
    while i < n {
        j := 1
        while j < n - i + 1 {
;            Log("SortChars comparing j=" j " of n=" n " key=" key, "DEBUG")
            a := String(g_chars[j].Get(key, ""))
            b := String(g_chars[j + 1].Get(key, ""))
;            Log("SortChars a='" a "' b='" b "'", "DEBUG")
            if key == "level" {
                numA := a != "" ? Integer(a) : 0
                numB := b != "" ? Integer(b) : 0
                doSwap := g_sortAsc ? (numA > numB) : (numA < numB)
             } else {
                cmp    := StrCompare(a, b, false)
                doSwap := g_sortAsc ? (cmp > 0) : (cmp < 0)
            }
            j++
        }
        i++
    }
    Log("SortChars complete on key: " key)
}


; ── CRUD ─────────────────────────────────────────────────────

NewEntry() {
    global g_chars
    ch := ShowEntryDialog("⚔ New Character")
    if ch.Count == 0 {
        return
    }
    ch["profile"] := ActivePro
    g_chars.Push(ch)
    SortChars()
    RefreshList()
    SetStatus("Added: " ch["name"] " — Found " g_chars.Length " character(s) for: " ActivePro)
}

EditEntry() {
    global g_chars, g_selIdx
    if g_selIdx == 0 {
        ShowMsg("Please select a character to edit.", "Edit")
        return
    }
    ch := ShowEntryDialog("⚔ Edit Character", g_chars[g_selIdx])
    if ch.Count == 0 {
        return
    }
    ch["profile"]      := ActivePro
    g_chars[g_selIdx] := ch
    SortChars()
    RefreshList()
    SetStatus("Updated: " ch["name"] " — Found " g_chars.Length " character(s) for: " ActivePro)
}

DeleteEntry() {
    global g_chars, g_selIdx
    if g_selIdx == 0 {
        ShowMsg("Please select a character to delete.", "Delete")
        return
    }
    name := g_chars[g_selIdx].Get("name", "(unnamed)")
    if ShowMsg("Delete '" name "'?  This cannot be undone.", "Confirm Delete", 262452) != "Yes" {
        return
    }
    g_chars.RemoveAt(g_selIdx)
    g_selIdx := 0
    SortChars()
    RefreshList()
    SetStatus("Deleted: " name " — Found " g_chars.Length " character(s) for: " ActivePro)
}

; ── Entry Dialog ─────────────────────────────────────────────

ShowEntryDialog(title, ch := "") {
    global SD
    isNew := (ch == "")
    if isNew {
        ch := Map(
            "name",    "",       "level",   "1",
            "realm",   "",       "guild",   "",
            "faction", "Alliance","race",   "Human",
            "gender",  "Male",   "class",   "Warrior",
            "spec",    "Arms",   "armor",   "Plate",
            "prof1",   "",       "prof2",   "",
            "sec1",    "",       "sec2",    "",
            "sec3",    "",       "status",  "Active",
            "notes",   "",       "profile", "")
    }

    D := Gui("+OwnDialogs +AlwaysOnTop", title)
    D.SetFont("s12", "Segoe UI")
    D.BackColor := "1E1E2E"
    D.SetFont("s12 cCDD6F4", "Segoe UI")

    lw := 110
    fw := 220
    px := 14
    y  := 16

    AddRow(lbl, type, opts) {
        D.Add("Text", "x" px " y" (y + 4) " w" lw " cCDD6F4", lbl)
        ctrl := D.Add(type, "x" (px + lw) " y" y " w" fw " " opts " Background2A2A3E cCDD6F4")
        y += 32
        return ctrl
    }

    EName  := AddRow("Name:",     "Edit",         "")
    EName.Value := ch.Get("name", "")

    ELevel := AddRow("Level:",    "Edit",         "w70")
    ELevel.Value := ch.Get("level", "1")

    ERealm := AddRow("Realm:",    "Edit",         "")
    ERealm.Value := ch.Get("realm", "")

    EGuild := AddRow("Guild:",    "Edit",         "")
    EGuild.Value := ch.Get("guild", "")

    factions := SD["factions"]
    DDFac  := AddRow("Faction:",  "DropDownList", "")
    loop factions.Length {
        DDFac.Add([factions[A_Index]])
    }
    DDFac.Value := Max(1, FindInArr(factions, ch.Get("faction", "Alliance")))

    DDRace  := AddRow("Race:",    "DropDownList", "")
    DDClass := AddRow("Class:",   "DropDownList", "")
    DDSpec  := AddRow("Spec:",    "DropDownList", "")
    EArmor  := AddRow("Armor:",   "Edit",         "ReadOnly w130")

    classes := GetClassNames()
    loop classes.Length {
        DDClass.Add([classes[A_Index]])
    }
    DDClass.Value := Max(1, FindInArr(classes, ch.Get("class", "Warrior")))

    genders := SD["genders"]
    DDGender := AddRow("Gender:", "DropDownList", "")
    loop genders.Length {
        DDGender.Add([genders[A_Index]])
    }
    DDGender.Value := Max(1, FindInArr(genders, ch.Get("gender", "Male")))

    prim := ["(none)"]
    loop SD["primary_professions"].Length {
        prim.Push(SD["primary_professions"][A_Index])
    }
    sec := ["(none)"]
    loop SD["secondary_professions"].Length {
        sec.Push(SD["secondary_professions"][A_Index])
    }

    DDProf1 := AddRow("Primary 1:",   "DropDownList", "")
    loop prim.Length {
        DDProf1.Add([prim[A_Index]])
    }
    DDProf1.Value := Max(1, FindInArr(prim, ch.Get("prof1", "")))

    DDProf2 := AddRow("Primary 2:",   "DropDownList", "")
    loop prim.Length {
        DDProf2.Add([prim[A_Index]])
    }
    DDProf2.Value := Max(1, FindInArr(prim, ch.Get("prof2", "")))

    DDSec1 := AddRow("Secondary 1:",  "DropDownList", "")
    loop sec.Length {
        DDSec1.Add([sec[A_Index]])
    }
    DDSec1.Value := Max(1, FindInArr(sec, ch.Get("sec1", "")))

    DDSec2 := AddRow("Secondary 2:",  "DropDownList", "")
    loop sec.Length {
        DDSec2.Add([sec[A_Index]])
    }
    DDSec2.Value := Max(1, FindInArr(sec, ch.Get("sec2", "")))

    DDSec3 := AddRow("Secondary 3:",  "DropDownList", "")
    loop sec.Length {
        DDSec3.Add([sec[A_Index]])
    }
    DDSec3.Value := Max(1, FindInArr(sec, ch.Get("sec3", "")))

    statuses := SD["statuses"]
    DDStatus := AddRow("Status:",     "DropDownList", "")
    loop statuses.Length {
        DDStatus.Add([statuses[A_Index]])
    }
    DDStatus.Value := Max(1, FindInArr(statuses, ch.Get("status", "Active")))

    D.Add("Text", "x" px " y" (y + 4) " w" lw " cCDD6F4", "Notes:")
    ENotes := D.Add("Edit",
        "x" (px + lw) " y" y " w" fw " h60 Multi VScroll Background2A2A3E cCDD6F4")
    ENotes.Value := ch.Get("notes", "")
    y += 70

    D.SetFont("s12 Bold cCDD6F4")
    BtnOK  := D.Add("Button", "x" (px + lw)       " y" y " w100 h30 Default Background3D3D5C", "&OK")
    BtnCan := D.Add("Button", "x" (px + lw + 110) " y" y " w100 h30 Background3D3D5C cFF6B6B",  "&Cancel")

    result := Map()

    UpdateRaces(*) {
        fac   := DDFac.Text
        rmap  := SD["faction_races"]
        rlist := rmap.Has(fac) ? rmap[fac] : ["Human"]
        DDRace.Delete()
        loop rlist.Length {
            DDRace.Add([rlist[A_Index]])
        }
        DDRace.Value := Max(1, FindInArr(rlist, ch.Get("race", "Human")))
    }

    UpdateSpecs(*) {
        cls   := DDClass.Text
        cdata := SD["classes"]
        if cdata.Has(cls) {
            specs := cdata[cls]["specs"]
            armor := cdata[cls]["armor"]
        } else {
            specs := ["—"]
            armor := "—"
        }
        DDSpec.Delete()
        loop specs.Length {
            DDSpec.Add([specs[A_Index]])
        }
        DDSpec.Value := Max(1, FindInArr(specs, ch.Get("spec", "")))
        EArmor.Value := armor
    }

    RebuildPrimDD(target, other) {
        Log("RebuildPrimDD called — cur: " target.Text " exclude: " other.Text)
        cur     := target.Text
        exclude := other.Text
        target.Delete()
        newIdx  := 1
        i       := 0
        loop prim.Length {
            v := prim[A_Index]
            if (exclude != "(none)" && v == exclude)
                continue
            i++
            target.Add([v])
            if (v == cur)
                newIdx := i
        }
        target.Value := newIdx
    }

    RebuildSecDD(target, other1, other2) {
        cur := target.Text
        ex1 := other1.Text
        ex2 := other2.Text
        target.Delete()
        newIdx := 1
        i      := 0
        loop sec.Length {
            v := sec[A_Index]
            if (ex1 != "(none)" && v == ex1)
                continue
            if (ex2 != "(none)" && v == ex2)
                continue
            i++
            target.Add([v])
            if (v == cur)
                newIdx := i
        }
        target.Value := newIdx
    }

    UpdateProfDDs(changedCtrl, *) {
        if (changedCtrl == DDProf1)
            RebuildPrimDD(DDProf2, DDProf1)
        else
            RebuildPrimDD(DDProf1, DDProf2)
    }

    UpdateSecDDs(changedCtrl, *) {
        if (changedCtrl == DDSec1) {
            RebuildSecDD(DDSec2, DDSec1, DDSec3)
            RebuildSecDD(DDSec3, DDSec1, DDSec2)
        } else if (changedCtrl == DDSec2) {
            RebuildSecDD(DDSec1, DDSec2, DDSec3)
            RebuildSecDD(DDSec3, DDSec1, DDSec2)
        } else {
            RebuildSecDD(DDSec1, DDSec2, DDSec3)
            RebuildSecDD(DDSec2, DDSec1, DDSec3)
        }
    }

    DDFac  .OnEvent("Change", UpdateRaces)
    DDClass.OnEvent("Change", UpdateSpecs)
    DDProf1.OnEvent("Change", UpdateProfDDs)
    DDProf2.OnEvent("Change", UpdateProfDDs)
    DDSec1 .OnEvent("Change", UpdateSecDDs)
    DDSec2 .OnEvent("Change", UpdateSecDDs)
    DDSec3 .OnEvent("Change", UpdateSecDDs)
    BtnOK  .OnEvent("Click", ConfirmDlg)
    BtnCan .OnEvent("Click", (*) => D.Destroy())

    UpdateRaces()
    DDRace.Value := Max(1, FindInArr(GetRaceList(DDFac.Text), ch.Get("race", "Human")))
    UpdateSpecs()
    DDSpec.Value := Max(1, FindInArr(GetSpecList(DDClass.Text), ch.Get("spec", "")))

    ConfirmDlg(*) {
        n := Trim(EName.Value)
        if n == "" {
            ShowMsg("Character name cannot be empty!", "Validation")
            return
        }
        result["profile"]  := ActivePro
        result["name"]     := n
        result["level"]    := Trim(ELevel.Value)
        result["realm"]    := Trim(ERealm.Value)
        result["guild"]    := Trim(EGuild.Value)
        result["faction"]  := DDFac.Text
        result["race"]     := DDRace.Text
        result["gender"]   := DDGender.Text
        result["class"]    := DDClass.Text
        result["spec"]     := DDSpec.Text
        result["armor"]    := EArmor.Value
        result["prof1"]    := DDProf1.Text == "(none)" ? "" : DDProf1.Text
        result["prof2"]    := DDProf2.Text == "(none)" ? "" : DDProf2.Text
        result["sec1"]     := DDSec1.Text  == "(none)" ? "" : DDSec1.Text
        result["sec2"]     := DDSec2.Text  == "(none)" ? "" : DDSec2.Text
        result["sec3"]     := DDSec3.Text  == "(none)" ? "" : DDSec3.Text
        result["status"]   := DDStatus.Text
        result["notes"]    := Trim(ENotes.Value)
        D.Destroy()
    }

; ── REPLACE the existing OnEvent block (the three lines before D.Show)
;    with this expanded version ──────────────────────────────

    DDFac  .OnEvent("Change", UpdateRaces)
    DDClass.OnEvent("Change", UpdateSpecs)
    DDProf1.OnEvent("Change", UpdateProfDDs)
    DDProf2.OnEvent("Change", UpdateProfDDs)
    DDSec1 .OnEvent("Change", UpdateSecDDs)
    DDSec2 .OnEvent("Change", UpdateSecDDs)
    DDSec3 .OnEvent("Change", UpdateSecDDs)

    D.Show("w" (px * 2 + lw + fw + 20) " AutoSize")
    WinWaitClose(D)
    return result
}
