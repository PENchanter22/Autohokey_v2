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
    global MyGui, FS_NORM, FS_BOLD, CTL_H
    EDIT_Y  := 10 + FS_NORM + 10          ; below prompt text
    BTN_Y   := EDIT_Y + CTL_H + 10        ; below edit box
    DLG_W   := 320
    D := Gui("+AlwaysOnTop +OwnDialogs", title)
    D.SetFont("s" FS_NORM, "Segoe UI")
    D.BackColor := "1E1E2E"
    D.Add("Text", "x10 y10 w300 cCDD6F4", prompt)
    EVal := D.Add("Edit", "x10 y" EDIT_Y " w300 h" CTL_H " Background2A2A3E cCDD6F4")
    EVal.Value := default
    D.SetFont("s" FS_BOLD " Bold cCDD6F4")
    BtnOK  := D.Add("Button", "x10  y" BTN_Y " w100 h" CTL_H " Default Background3D3D5C", "&OK")
    BtnCan := D.Add("Button", "x118 y" BTN_Y " w100 h" CTL_H " Background3D3D5C cFF6B6B", "&Cancel")
    result := Map("Result", "Cancel", "Value", "")
    BtnOK.OnEvent("Click", (*) => (result["Result"] := "OK", result["Value"] := EVal.Value, D.Destroy()))
    BtnCan.OnEvent("Click", (*) => D.Destroy())
    D.OnEvent("Close", (*) => D.Destroy())
    D.Show("w" DLG_W " AutoSize")
	RoundCorners(D.Hwnd)   ; ← add this
    WinWaitClose(D)
    return result
}

; Custom MsgBox replacement — always stays on top of everything
ShowMsg(text, title := "", flags := 262208) {
    global MyGui, FS_NORM, FS_BOLD, CTL_H
    btnType := flags & 0xF
    BTN_Y   := 10 + FS_NORM + 14          ; below message text
    DLG_W   := 360
    D := Gui("+AlwaysOnTop +OwnDialogs", title)
    D.SetFont("s" FS_NORM, "Segoe UI")
    D.BackColor := "1E1E2E"
    D.Add("Text", "x10 y10 w340 cCDD6F4", text)
    result := Map("Value", "OK")
    D.SetFont("s" FS_BOLD " Bold cCDD6F4")
    if btnType == 4 {
        ; Yes/No
        BtnY := D.Add("Button", "x10  y" BTN_Y " w100 h" CTL_H " Default Background3D3D5C cA6E3A1", "&Yes")
        BtnN := D.Add("Button", "x118 y" BTN_Y " w100 h" CTL_H " Background3D3D5C cFF6B6B", "&No")
        BtnY.OnEvent("Click", (*) => (result["Value"] := "Yes", D.Destroy()))
        BtnN.OnEvent("Click", (*) => (result["Value"] := "No",  D.Destroy()))
    } else {
        ; OK only
        BtnOK := D.Add("Button", "x10 y" BTN_Y " w100 h" CTL_H " Default Background3D3D5C", "&OK")
        BtnOK.OnEvent("Click", (*) => D.Destroy())
    }
    D.OnEvent("Close", (*) => D.Destroy())
    D.Show("w" DLG_W " AutoSize")
	RoundCorners(D.Hwnd)   ; ← add this
    WinWaitClose(D)
    return result["Value"]
}

RoundCorners(hwnd) {
    DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 33, "UInt*", 2, "UInt", 4)
}

SetDirty() {
    global StatusBar
    StatusBar.SetFont("cF9E2AF")
    StatusBar.Value := "  -:*:- Please [Save] any new changes!! -:*:-"
}
