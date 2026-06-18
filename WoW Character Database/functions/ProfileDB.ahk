; ============================================================
;  ProfileDB.ahk — Profile load/save/manage
;  Include this file from the master script.
; ============================================================

; Log("ManageProfiles — MyGui hwnd: " MyGui.Hwnd)

LoadProfileDB() {
    global Profiles, ActivePro, F_PROFILE
    if !FileExist(F_PROFILE) {
        Profiles  := [Map("name", "Default", "created", FormatDate(), "notes", "Default profile")]
        ActivePro := "Default"
        SaveProfileDB()
    } else {
        try {
            raw := JsonParse(FileRead(F_PROFILE, "UTF-8"))
            if !(raw is Map) {
                ShowMsg("ProfileDB.json failed to parse!`nRestore from backup.", "Fatal Error")
                return
            }
            ActivePro := raw["active_profile"]
            Profiles  := raw["profiles"]
            Log("ProfileDB loaded — active profile: " ActivePro)
        } catch as e {
            ShowMsg("Failed to load ProfileDB:`n" e.Message, "Fatal Error")
            return
        }
    }
    RebuildProfileDD()
    LoadCharDB()
}

SaveProfileDB() {
    global Profiles, ActivePro, F_PROFILE
    if (Profiles.Length == 0 || ActivePro == "") {
        Log("SaveProfileDB — aborted, empty state!", "WARN")
        return
    }
    obj := Map("active_profile", ActivePro, "profiles", Profiles)
    FileOpen(F_PROFILE, "w", "UTF-8").Write(JsonStringify(obj))
}

RebuildProfileDD() {
    global DDProfile, Profiles, ActivePro
    DDProfile.Delete()
    selIdx   := 1
    hasOther := false
    loop Profiles.Length {
        p := Profiles[A_Index]
        if p["name"] != "Default" {
            hasOther := true
        }
    }
    loop Profiles.Length {
        p := Profiles[A_Index]
        ; Hide "Default" if any other profile exists
        if p["name"] == "Default" && hasOther {
            continue
        }
        DDProfile.Add([p["name"]])
        if p["name"] == ActivePro {
            selIdx := DDProfile.Value ? DDProfile.Value : 1
        }
    }
    ; Ensure ActivePro is valid after possible hide of Default
    if DDProfile.Value == 0 {
        DDProfile.Value := 1
        ActivePro := DDProfile.Text
    } else {
        DDProfile.Value := selIdx
    }
    UpdateCaption()
}

OnProfileChange(*) {
    global ActivePro, DDProfile
    ActivePro := DDProfile.Text
    UpdateCaption()
    LoadCharDB()
    SaveProfileDB()   ; persist last-selected profile
}

; ── Profile Manager Popup ────────────────────────────────────
ManageProfiles() {
    global Profiles, ActivePro

    PG := Gui("+OwnDialogs +AlwaysOnTop", "Manage Profiles")
    PG.SetFont("s12", "Segoe UI")
    PG.BackColor := "1E1E2E"
    PG.SetFont("s12 cCDD6F4")

    PG.Add("Text", "x10 y10 w400 cCDD6F4", "Profiles:")
    PLV := PG.Add("ListView",
        "x10 y34 w400 h220 Background2A2A3E cCDD6F4 Grid NoSortHdr",
        ["Profile Name", "Created", "Notes"])
    PLV.ModifyCol(1, 130)
    PLV.ModifyCol(2, 90)
    PLV.ModifyCol(3, 170)

    RefreshPLV() {
        global Profiles
        PLV.Delete()
        loop Profiles.Length {
            p := Profiles[A_Index]
            PLV.Add("", p["name"], p.Get("created", ""), p.Get("notes", ""))
        }
    }
    RefreshPLV()

    PG.SetFont("s12 Bold cCDD6F4")
    BtnAdd  := PG.Add("Button", "x10  y264 w90  h30 Background3D3D5C", "&Add")
    BtnRen  := PG.Add("Button", "x108 y264 w90  h30 Background3D3D5C", "&Rename")
    BtnNot  := PG.Add("Button", "x206 y264 w90  h30 Background3D3D5C", "&Notes")
    BtnRem  := PG.Add("Button", "x304 y264 w106 h30 Background3D3D5C cFF6B6B", "Re&move")
    BtnDone := PG.Add("Button", "x304 y304 w106 h30 Background3D3D5C cA6E3A1", "&Done")

    BtnAdd .OnEvent("Click", AddProfile)
    BtnRen .OnEvent("Click", RenProfile)
    BtnNot .OnEvent("Click", EditNotes)
    BtnRem .OnEvent("Click", RemProfile)
    BtnDone.OnEvent("Click", (*) => PG.Destroy())
    PG.OnEvent("Close", (*) => PG.Destroy())

AddProfile(*) {
    global Profiles, ActivePro
    Log("AddProfile button clicked")
    n := ShowInput("New profile name:", "Add Profile")
    Log("InputBox result: " n["Result"]  " value: '" n["Value"]  "'")
    if n["Result"]  != "OK" {
        return
    }
    nm := Trim(n["Value"] )
    Log("Trimmed name: '" nm "'")
    if nm == "" {
        return
    }
    Log("Checking " Profiles.Length " profiles for duplicate")
    loop Profiles.Length {
        Log("  comparing '" Profiles[A_Index]["name"] "' vs '" nm "'")
        if Profiles[A_Index]["name"] == nm {
            TopMsgBox("Profile '" nm "' already exists.", "Add Profile", 262208)
            return
        }
    }
    Log("No duplicate found — adding profile")
    Profiles.Push(Map("name", nm, "created", FormatDate(), "notes", ""))
    SaveProfileDB()
    SetDirty()   ; ← add
    RefreshPLV()
    RebuildProfileDD()
}

    RenProfile(*) {
        global Profiles, ActivePro
        row := PLV.GetNext()
        if !row {
            TopMsgBox("Select a profile first.", , 262208)
            return
        }
        oldName := PLV.GetText(row, 1)
        n := ShowInput("Rename '" oldName "' to:", "Rename Profile")
        if n["Result"]  != "OK" {
            return
        }
        nm := Trim(n["Value"] )
        if nm == "" {
            return
        }
        loop Profiles.Length {
            p := Profiles[A_Index]
            if p["name"] == oldName {
                p["name"] := nm
                Profiles[A_Index] := p
                if ActivePro == oldName {
                    ActivePro := nm
                    UpdateCaption()
                }
                break
            }
        }
        SaveProfileDB()
        RefreshPLV()
        RebuildProfileDD()
    }

    EditNotes(*) {
        global Profiles
	    row := PLV.GetNext()
        if !row {
            TopMsgBox("Select a profile first.", , 262208)
            return
        }
        nm := PLV.GetText(row, 1)
        loop Profiles.Length {
            p := Profiles[A_Index]
            if p["name"] == nm {
				n := ShowInput("Notes for '" nm "':", "Edit Notes", p.Get("notes", ""))
                if n["Result"]  != "OK" {
                    return
                }
                p["notes"] := n["Value"] 
                Profiles[A_Index] := p
                SaveProfileDB()
                        RefreshPLV()
                return
            }
        }
    }

    RemProfile(*) {
        global Profiles, ActivePro
        row := PLV.GetNext()
        if !row {
            TopMsgBox("Select a profile first.", , 262208)
            return
        }
        nm := PLV.GetText(row, 1)
        if Profiles.Length == 1 {
            TopMsgBox("Cannot remove the last profile.", , 262208)
            return
        }
        if TopMsgBox("Remove profile '" nm "'?`nCharacter file will NOT be deleted.", "Confirm", 262452) != "Yes" {
            return
        }
        loop Profiles.Length {
            if Profiles[A_Index]["name"] == nm {
                Profiles.RemoveAt(A_Index)
                break
            }
        }
        if ActivePro == nm {
            ActivePro := Profiles[1]["name"]
            UpdateCaption()
            LoadCharDB()
        }
        SaveProfileDB()
        RefreshPLV()
        RebuildProfileDD()
    }

    PG.Show("w420 h345")
    Log("ManageProfiles — PG hwnd: " PG.Hwnd)
;    PG.OnEvent("LoseFocus", (*) => PG.Show())
    WinWaitClose(PG)
}
