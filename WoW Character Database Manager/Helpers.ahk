; ============================================================
;  Helpers.ahk — Utility functions
;  Include this file from the master script.
; ============================================================

FindInArr(arr, val) {
    loop arr.Length {
        if arr[A_Index] == val {
            return A_Index
        }
    }
    return 0
}

FormatDate() {
    return SubStr(A_Now, 1, 4) "-" SubStr(A_Now, 5, 2) "-" SubStr(A_Now, 7, 2)
}

UpdateCaption() {
    global TitleBar, ActivePro, BTN_X_W
    txt     := "⚔   Character Manager  |  Profile: " ActivePro "   ⚔"
    ; Each space in Segoe UI s14 ≈ 5px; offset = BTN_X_W/2 pixels ÷ 5
    spaces  := ""
    loop (BTN_X_W // 10) {
        spaces .= " "
    }
    TitleBar.Value := spaces txt
}

DragWindow(*) {
    global MyGui
    PostMessage 0xA1, 2, 0, , "ahk_id " MyGui.Hwnd
}

SetStatus(msg, kind := "info") {
    global StatusBar
    col := "CDD6F4"
    if kind == "ok" {
        col := "A6E3A1"
    } else if kind == "warn" {
        col := "F9E2AF"
    } else if kind == "err" {
        col := "FF6B6B"
    }
    StatusBar.SetFont("c" col)
    StatusBar.Value := "  " msg
}

GetClassNames() {
    global SD
    names := []
    for k, _ in SD["classes"] {
        names.Push(k)
    }
    return names
}

GetRaceList(faction) {
    global SD
    rmap := SD["faction_races"]
    if rmap.Has(faction) {
        return rmap[faction]
    }
    return ["Human"]
}

GetSpecList(cls) {
    global SD
    cdata := SD["classes"]
    if cdata.Has(cls) {
        return cdata[cls]["specs"]
    }
    return ["—"]
}

TopMsgBox(text, title := "", flags := 262208) {
    global MyGui
    Log("TopMsgBox — lowering all script windows")
    WinSetAlwaysOnTop(0, "ahk_pid " DllCall("GetCurrentProcessId"))
    Log("TopMsgBox — all lowered, showing MsgBox")
    result := MsgBox(text, title, flags)
    Log("TopMsgBox — restoring AlwaysOnTop")
    WinSetAlwaysOnTop(1, "ahk_pid " DllCall("GetCurrentProcessId"))
    Log("TopMsgBox result: " result)
    return result
}

; Custom InputBox replacement — always stays on top of everything
ShowInput(prompt, title := "", default := "") {
    global MyGui
    D := Gui("+AlwaysOnTop +OwnDialogs", title)
    D.SetFont("s12", "Segoe UI")
    D.BackColor := "1E1E2E"
    D.Add("Text", "x10 y10 w300 cCDD6F4", prompt)
    EVal := D.Add("Edit", "x10 y36 w300 h26 Background2A2A3E cCDD6F4")
    EVal.Value := default
    D.SetFont("s12 Bold cCDD6F4")
    BtnOK  := D.Add("Button", "x10  y72 w100 h28 Default Background3D3D5C", "&OK")
    BtnCan := D.Add("Button", "x118 y72 w100 h28 Background3D3D5C cFF6B6B", "&Cancel")
    result := Map("Result", "Cancel", "Value", "")
    BtnOK.OnEvent("Click", (*) => (result["Result"] := "OK", result["Value"] := EVal.Value, D.Destroy()))
    BtnCan.OnEvent("Click", (*) => D.Destroy())
    D.OnEvent("Close", (*) => D.Destroy())
    D.Show("w320 AutoSize")
    WinWaitClose(D)
    return result
}

; Custom MsgBox replacement — always stays on top of everything
ShowMsg(text, title := "", flags := 262208) {
    global MyGui
    ; Determine buttons from flags
    btnType := flags & 0xF
    D := Gui("+AlwaysOnTop +OwnDialogs", title)
    D.SetFont("s12", "Segoe UI")
    D.BackColor := "1E1E2E"
    D.Add("Text", "x10 y10 w340 cCDD6F4", text)
    result := Map("Value", "OK")
    D.SetFont("s12 Bold cCDD6F4")
    if btnType == 4 {
        ; Yes/No
        BtnY := D.Add("Button", "x10  y60 w100 h28 Default Background3D3D5C cA6E3A1", "&Yes")
        BtnN := D.Add("Button", "x118 y60 w100 h28 Background3D3D5C cFF6B6B", "&No")
        BtnY.OnEvent("Click", (*) => (result["Value"] := "Yes", D.Destroy()))
        BtnN.OnEvent("Click", (*) => (result["Value"] := "No",  D.Destroy()))
    } else {
        ; OK only
        BtnOK := D.Add("Button", "x10 y60 w100 h28 Default Background3D3D5C", "&OK")
        BtnOK.OnEvent("Click", (*) => D.Destroy())
    }
    D.OnEvent("Close", (*) => D.Destroy())
    D.Show("w360 AutoSize")
    WinWaitClose(D)
    return result["Value"]
}
GetDDLItems(ctrl) {
    items := []
    loop ctrl.Value {          ; .Value after Delete+Add = count of items? No —
    }                          ; safer: use SendMessage to get the count
    ; CB_GETCOUNT = 0x146, CB_GETLBTEXTLEN = 0x149, CB_GETLBTEXT = 0x148
    count := SendMessage(0x146, 0, 0, ctrl)
    loop count {
        len := SendMessage(0x149, A_Index - 1, 0, ctrl)
        buf := Buffer(len + 2, 0)
        SendMessage(0x148, A_Index - 1, buf, ctrl)
        items.Push(StrGet(buf, "UTF-16"))
    }
    return items
}
