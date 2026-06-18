; ============================================================
;  GuildDB.ahk — Guild CRUD, Guild Manager dialog
;  Requires GlobalVARS.ahk, RealmSearch.ahk to be included first.
; ============================================================

global F_GUILD  := A_ScriptDir . "\records\GuildDB.json"
global F_CIDX   := A_ScriptDir . "\records\CharacterIndex.json"
global g_guilds := []

; ── Load / Save ──────────────────────────────────────────────

LoadGuildDB() {
    global g_guilds, F_GUILD
    g_guilds := []
    if !FileExist(F_GUILD) {
        Log("GuildDB not found — starting fresh.", "WARN")
        return
    }
    try {
        data := JsonParse(FileRead(F_GUILD, "UTF-8"))
        if data.Has("guilds")
            g_guilds := data["guilds"]
        SortGuilds()
        Log("GuildDB loaded — " g_guilds.Length " guild(s).")
    } catch as e {
        ShowMsg("Failed to load GuildDB:`n" e.Message, "Load Error")
    }
}

SaveGuildDB() {
    global g_guilds, F_GUILD
    try {
        parts := []
        loop g_guilds.Length {
            g := g_guilds[A_Index]
            parts.Push("    " JsonStringifyGuild(g))
        }
        output := "{`n  `"guilds`": [`n" JoinArr(parts, ",`n") "`n  ]`n}")
        FileOpen(F_GUILD, "w", "UTF-8").Write(output)
        Log("GuildDB saved — " g_guilds.Length " guild(s).")
    } catch as e {
        ShowMsg("Failed to save GuildDB:`n" e.Message, "Save Error")
    }
}

JsonStringifyGuild(g) {
    fields := ["created", "name", "leader", "realm", "faction", "funds", "notes"]
    parts  := []
    for _, f in fields {
        v := g.Has(f) ? g[f] : ""
        parts.Push("`"" f "`": `"" EscapeJson(v) "`"")
    }
    return "{" JoinArr(parts, ", ") "}"
}

SortGuilds() {
    global g_guilds
    n := g_guilds.Length
    i := 1
    while i < n {
        j := 1
        while j <= n - i {
            a := g_guilds[j].Get("name", "")
            b := g_guilds[j+1].Get("name", "")
            if StrCompare(a, b, false) > 0 {
                tmp          := g_guilds[j]
                g_guilds[j]   := g_guilds[j+1]
                g_guilds[j+1] := tmp
            }
            j++
        }
        i++
    }
}

GetGuildNames() {
    global g_guilds
    names := []
    loop g_guilds.Length
        names.Push(g_guilds[A_Index].Get("name", ""))
    return names
}

FindGuild(name) {
    global g_guilds
    loop g_guilds.Length {
        if (g_guilds[A_Index].Get("name", "") == name)
            return g_guilds[A_Index]
    }
    return ""
}

LoadCharIndex() {
    global F_CIDX
    try {
        data := JsonParse(FileRead(F_CIDX, "UTF-8"))
        if data.Has("roster")
            return data["roster"]
    } catch {
        Log("CharacterIndex not found or unreadable.", "WARN")
    }
    return []
}

GetCharNames() {
    roster := LoadCharIndex()
    names  := []
    loop roster.Length
        names.Push(roster[A_Index].Get("character", ""))
    return names
}

; ── Guild Manager Dialog ──────────────────────────────────────

ManageGuilds() {
    global g_guilds, SD, MyGui
    global FS_NORM, FS_BOLD, CTL_H, FS_TITLE

    ; Restore main GUI if minimized
    MyGui.Show()

    ; Working copy so unsaved changes are discarded on Close
    workGuilds := []
    loop g_guilds.Length {
        g := g_guilds[A_Index]
        workGuilds.Push(g.Clone())
    }

    guildNames := []
    RebuildGuildNames() {
        guildNames := []
        loop workGuilds.Length
            guildNames.Push(workGuilds[A_Index].Get("name", ""))
    }
    RebuildGuildNames()

    charNames  := GetCharNames()
    realmList  := []
    loop SD["realms"].Length
        realmList.Push(SD["realms"][A_Index]["name"])
    factions   := SD["factions"]

    D := Gui("+OwnDialogs +AlwaysOnTop", "⚔ Guild Manager")
    D.SetFont("s" FS_NORM, "Segoe UI")
    D.BackColor := "1E1E2E"
    D.SetFont("s" FS_NORM " cCDD6F4", "Segoe UI")

    lw  := 90
    fw  := 240
    px  := 14
    y   := 14

    ; ── Name (searchable) ─────────────────────────────────────
    D.Add("Text", "x" px " y" (y+4) " w" lw " cCDD6F4", "Name:")
    EName := D.Add("Edit", "x" (px+lw) " y" y " w" fw " h" CTL_H " Background2A2A3E cCDD6F4")
    y += CTL_H + 6

    ; ── Guild list LV (filtered by Name field) ────────────────
    LVG := D.Add("ListView",
        "x" (px+lw) " y" y " w" fw " h" (CTL_H*5) " -Hdr -Multi Background1A1A2E cCDD6F4 NoSortHdr",
        ["Name"])
    LVG.SetFont("s" FS_NORM, "Segoe UI")
    y += CTL_H*5 + 8

    ; ── Leader (searchable) ───────────────────────────────────
    D.Add("Text", "x" px " y" (y+4) " w" lw " cCDD6F4", "Leader:")
    ELeader := D.Add("Edit", "x" (px+lw) " y" y " w" fw " h" CTL_H " Background2A2A3E cCDD6F4")
    y += CTL_H + 6

    ; ── Realm (searchable, strict) ────────────────────────────
    D.Add("Text", "x" px " y" (y+4) " w" lw " cCDD6F4", "Realm:")
    ERealm := D.Add("Edit", "x" (px+lw) " y" y " w" fw " h" CTL_H " Background2A2A3E cCDD6F4")
    y += CTL_H + 6

    ; ── Faction (DDL) ─────────────────────────────────────────
    D.Add("Text", "x" px " y" (y+4) " w" lw " cCDD6F4", "Faction:")
    DDFac := D.Add("DropDownList", "x" (px+lw) " y" y " w" fw " h300 Background2A2A3E cCDD6F4")
    loop factions.Length
        DDFac.Add([factions[A_Index]])
    DDFac.Value := 1
    y += CTL_H + 6

    ; ── Funds ─────────────────────────────────────────────────
    D.Add("Text", "x" px " y" (y+4) " w" lw " cCDD6F4", "Funds:")
    EFunds := D.Add("Edit", "x" (px+lw) " y" y " w" fw " h" CTL_H " Background2A2A3E cCDD6F4")
    y += CTL_H + 6

    ; ── Created (with calendar button) ───────────────────────
    D.Add("Text", "x" px " y" (y+4) " w" lw " cCDD6F4", "Created:")
    ECreated := D.Add("Edit", "x" (px+lw) " y" y " w" (fw-CTL_H-4) " h" CTL_H " Background2A2A3E cCDD6F4")
    D.SetFont("s" FS_BOLD " Bold cCDD6F4")
    BtnCal := D.Add("Button", "x" (px+lw+fw-CTL_H) " y" y " w" CTL_H " h" CTL_H " Background3D3D5C", "📅")
    D.SetFont("s" FS_NORM " Norm cCDD6F4", "Segoe UI")
    y += CTL_H + 6

    ; ── Notes (255 char cap) ──────────────────────────────────
    NOTE_H := CTL_H * 3
    D.Add("Text", "x" px " y" (y+4) " w" lw " cCDD6F4", "Notes:")
    ENotes := D.Add("Edit",
        "x" (px+lw) " y" y " w" fw " h" NOTE_H " Multi VScroll Background2A2A3E cCDD6F4")
    y += NOTE_H + 10

    ; ── Buttons ───────────────────────────────────────────────
    D.SetFont("s" FS_BOLD " Bold cCDD6F4")
    BtnAdd  := D.Add("Button", "x" (px+lw)       " y" y " w80 h" CTL_H " Background3D3D5C",        "➕ &Add")
    BtnDel  := D.Add("Button", "x" (px+lw+88)    " y" y " w80 h" CTL_H " Background3D3D5C cFF6B6B","🗑 &Delete")
    BtnSave := D.Add("Button", "x" (px+lw+176)   " y" y " w80 h" CTL_H " Background3D3D5C cA6E3A1","💾 &Save")
    BtnClose:= D.Add("Button", "x" (px+lw+264)   " y" y " w80 h" CTL_H " Background3D3D5C",        "✖ &Close")

    ; ── Populate LV ───────────────────────────────────────────
    RefreshGuildLV(filter := "") {
        LVG.Delete()
        loop workGuilds.Length {
            n := workGuilds[A_Index].Get("name", "")
            if (filter == "" || InStr(n, filter, false))
                LVG.Add("", n)
        }
        LVG.ModifyCol(1, "AutoHdr")
    }
    RefreshGuildLV()

    ; ── Populate edit fields from guild record ─────────────────
    PopulateFields(g) {
        EName   .Value := g.Get("name",    "")
        ELeader .Value := g.Get("leader",  "")
        ERealm  .Value := g.Get("realm",   "")
        EFunds  .Value := g.Get("funds",   "")
        ECreated.Value := g.Get("created", "")
        ENotes  .Value := g.Get("notes",   "")
        fac := g.Get("faction", "")
        idx := FindInArr(factions, fac)
        DDFac.Value := Max(1, idx)
    }

    ClearFields() {
        EName   .Value := ""
        ELeader .Value := ""
        ERealm  .Value := ""
        EFunds  .Value := ""
        ECreated.Value := ""
        ENotes  .Value := ""
        DDFac.Value    := 1
    }

    ; ── Name field filters LV, and fills fields if exact match ─
    EName.OnEvent("Change", (*) => {
        filter := EName.Value
        RefreshGuildLV(filter)
        g := FindGuildInWork(filter, workGuilds)
        if (g != "")
            PopulateFields(g)
    })

    LVG.OnEvent("DoubleClick", (*) => {
        row := LVG.GetNext(0)
        if (row == 0)
            return
        name := LVG.GetText(row, 1)
        g    := FindGuildInWork(name, workGuilds)
        if (g != "")
            PopulateFields(g)
    })

    ; ── Calendar popup ────────────────────────────────────────
    BtnCal.OnEvent("Click", (*) => {
        picked := ShowCalendar(D)
        if (picked != "")
            ECreated.Value := picked
    })

    ; ── Notes 255 char cap ────────────────────────────────────
    ENotes.OnEvent("Change", (*) => {
        if (StrLen(ENotes.Value) > 255)
            ENotes.Value := SubStr(ENotes.Value, 1, 255)
    })

    ; ── Add ───────────────────────────────────────────────────
    BtnAdd.OnEvent("Click", (*) => {
        name := Trim(EName.Value)
        if (name == "") {
            ShowMsg("Guild name cannot be empty!", "Add Guild")
            return
        }
        ; Check for duplicate
        if (FindGuildInWork(name, workGuilds) != "") {
            ShowMsg("A guild named '" name "' already exists!", "Add Guild")
            return
        }
        g := Map(
            "created", Trim(ECreated.Value),
            "name",    name,
            "leader",  Trim(ELeader.Value),
            "realm",   Trim(ERealm.Value),
            "faction", DDFac.Text,
            "funds",   Trim(EFunds.Value),
            "notes",   Trim(ENotes.Value))
        workGuilds.Push(g)
        SortWorkGuilds(workGuilds)
        RebuildGuildNames()
        RefreshGuildLV()
        ClearFields()
    })

    ; ── Delete ────────────────────────────────────────────────
    BtnDel.OnEvent("Click", (*) => {
        name := Trim(EName.Value)
        if (name == "") {
            ShowMsg("Please enter or select a guild name to delete.", "Delete Guild")
            return
        }
        if ShowMsg("Delete guild '" name "'? This cannot be undone.", "Confirm Delete", 262452) != "Yes"
            return
        loop workGuilds.Length {
            if (workGuilds[A_Index].Get("name","") == name) {
                workGuilds.RemoveAt(A_Index)
                break
            }
        }
        RebuildGuildNames()
        RefreshGuildLV()
        ClearFields()
    })

    ; ── Save ──────────────────────────────────────────────────
    BtnSave.OnEvent("Click", (*) => {
        ; Flush any edited fields back to workGuilds
        name := Trim(EName.Value)
        if (name != "") {
            g := FindGuildInWork(name, workGuilds)
            if (g != "") {
                g["leader"]  := Trim(ELeader.Value)
                g["realm"]   := Trim(ERealm.Value)
                g["faction"] := DDFac.Text
                g["funds"]   := Trim(EFunds.Value)
                g["created"] := Trim(ECreated.Value)
                g["notes"]   := Trim(ENotes.Value)
            }
        }
        g_guilds := workGuilds
        SaveGuildDB()
        ShowMsg("Guild database saved!", "Save")
    })

    ; ── Close ─────────────────────────────────────────────────
    BtnClose.OnEvent("Click", (*) => D.Destroy())
    D.OnEvent("Close",        (*) => D.Destroy())

    ; ── Attach autocomplete ───────────────────────────────────
    AttachSearch(EName,   guildNames, (*) => {}, false)
    AttachSearch(ELeader, charNames,  (*) => {}, false)
    AttachSearch(ERealm,  realmList,  (*) => {}, true)

    D.Show("AutoSize")
    RoundCorners(D.Hwnd)
    WinWaitClose(D)
    MyGui.Show()
}

; ── Helpers ───────────────────────────────────────────────────

FindGuildInWork(name, workGuilds) {
    loop workGuilds.Length {
        if (workGuilds[A_Index].Get("name","") == name)
            return workGuilds[A_Index]
    }
    return ""
}

SortWorkGuilds(arr) {
    n := arr.Length
    i := 1
    while i < n {
        j := 1
        while j <= n - i {
            a := arr[j].Get("name","")
            b := arr[j+1].Get("name","")
            if StrCompare(a, b, false) > 0 {
                tmp      := arr[j]
                arr[j]   := arr[j+1]
                arr[j+1] := tmp
            }
            j++
        }
        i++
    }
}

; ── Calendar popup ────────────────────────────────────────────

ShowCalendar(ownerGui) {
    global FS_NORM, CTL_H
    result := ""
    C := Gui("+OwnDialogs +AlwaysOnTop", "Pick a Date")
    C.SetFont("s" FS_NORM, "Segoe UI")
    C.BackColor := "1E1E2E"
    Cal := C.Add("MonthCal", "x10 y10 Background1A1A2E")
    C.SetFont("s" FS_NORM " Bold cCDD6F4")
    BtnOK  := C.Add("Button", "x10 y+8 w100 h" CTL_H " Default Background3D3D5C", "&OK")
    BtnCan := C.Add("Button", "x118 yp w100 h" CTL_H " Background3D3D5C cFF6B6B", "&Cancel")
    BtnOK.OnEvent("Click", (*) => {
        raw    := Cal.Value          ; YYYYMMDDHHmmss
        result := SubStr(raw,1,4) "-" SubStr(raw,5,2) "-" SubStr(raw,7,2)
        C.Destroy()
    })
    BtnCan.OnEvent("Click", (*) => C.Destroy())
    C.OnEvent("Close",      (*) => C.Destroy())
    C.Show("AutoSize")
    RoundCorners(C.Hwnd)
    WinWaitClose(C)
    return result
}
