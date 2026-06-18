; ============================================================
;  RealmSearch.ahk — Reusable searchable autocomplete popup
;  Requires GlobalVARS.ahk to be included first.
;
;  Usage:
;    AttachSearch(editCtrl, dataArr, onSelect, strict := false)
;
;  Parameters:
;    editCtrl  — the Edit control to attach to
;    dataArr   — array of strings to search against
;    onSelect  — callback(selectedValue) called when user picks an entry
;    strict    — if true, clears field on blur if no exact match found
; ============================================================

; ── Popup state ──────────────────────────────────────────────
global g_searchPopup   := ""   ; active popup Gui object
global g_searchLV      := ""   ; active popup ListView
global g_searchEdit    := ""   ; the Edit control being served
global g_searchData    := []   ; current data array
global g_searchCB      := ""   ; onSelect callback
global g_searchStrict  := false

AttachSearch(editCtrl, dataArr, onSelect, strict := false) {
    editCtrl.OnEvent("Change", SearchEdit_Change)
    editCtrl.OnEvent("LoseFocus", SearchEdit_LoseFocus)
    editCtrl.OnEvent("Focus", SearchEdit_Focus)
    ; Store per-control metadata via a naming convention on the control
    editCtrl._searchData   := dataArr
    editCtrl._searchCB     := onSelect
    editCtrl._searchStrict := strict
}

SearchEdit_Change(ctrl, *) {
    ShowSearchPopup(ctrl)
}

SearchEdit_Focus(ctrl, *) {
    ShowSearchPopup(ctrl)
}

SearchEdit_LoseFocus(ctrl, *) {
    ; Small delay to allow LV click to register before destroying popup
    SetTimer(() => CloseSearchPopup(ctrl), -150)
}

SearchEdit_Key(ctrl, vk, *) {
    global g_searchLV, g_searchPopup
    ; Allow keyboard navigation into the popup
    if (g_searchPopup == "" || g_searchLV == "")
        return
    if (vk == 0x28) {   ; VK_DOWN
        cur := g_searchLV.GetNext(0)
        if (cur == 0)
            g_searchLV.Modify(1, "Select Focus")
        else if (cur < g_searchLV.GetCount())
            g_searchLV.Modify(cur + 1, "Select Focus")
        return 0
    }
    if (vk == 0x26) {   ; VK_UP
        cur := g_searchLV.GetNext(0)
        if (cur > 1)
            g_searchLV.Modify(cur - 1, "Select Focus")
        return 0
    }
    if (vk == 0x0D) {   ; VK_RETURN
        cur := g_searchLV.GetNext(0)
        if (cur > 0)
            SearchLV_Pick(ctrl, cur)
        return 0
    }
    if (vk == 0x1B) {   ; VK_ESCAPE
        DestroySearchPopup()
        return 0
    }
}

ShowSearchPopup(ctrl) {
    global g_searchPopup, g_searchLV, g_searchEdit
    global g_searchData, g_searchCB, g_searchStrict
    global FS_NORM, CTL_H

    filter := ctrl.Value
    data   := ctrl._searchData
    cb     := ctrl._searchCB
    strict := ctrl._searchStrict

    ; Build match list
    matches := []
    for _, v in data {
        if (filter == "" || InStr(v, filter, false))
            matches.Push(v)
    }

    ; Nothing to show — destroy popup
    if (matches.Length == 0) {
        DestroySearchPopup()
        return
    }

    ; Get screen position of the edit control
    ctrlHwnd := ctrl.Hwnd
    DllCall("GetWindowRect", "Ptr", ctrlHwnd, "Ptr", rc := Buffer(16))
    x := NumGet(rc, 0, "Int")
    y := NumGet(rc, 4, "Int")
    w := NumGet(rc, 8, "Int") - x
    h := NumGet(rc, 12, "Int") - y

    popX := x
    popY := y + h
    popW := Max(w, 260)
    popH := Min(matches.Length * (CTL_H + 2) + 4, CTL_H * 6)   ; max 6 rows

    ; Reuse or create popup
    if (g_searchPopup == "") {
        g_searchPopup := Gui("-Caption +AlwaysOnTop +ToolWindow", "")
        g_searchPopup.BackColor := "2A2A3E"
        g_searchLV := g_searchPopup.Add("ListView",
            "x0 y0 w" popW " h" popH " -Hdr -Multi Background2A2A3E cCDD6F4 NoSortHdr",
            ["Name"])
        g_searchLV.SetFont("s" FS_NORM, "Segoe UI")
        g_searchLV.OnEvent("DoubleClick", (*) => SearchLV_Pick(ctrl, g_searchLV.GetNext(0)))
        g_searchLV.OnEvent("ItemSelect",  (*) => SearchLV_Pick(ctrl, g_searchLV.GetNext(0)))
        g_searchEdit := ctrl
    } else {
        g_searchLV.Delete()
        g_searchLV.Move(,, popW, popH)
    }

    ; Populate
    for _, v in matches {
        g_searchLV.Add("", v)
    }
    g_searchLV.ModifyCol(1, "AutoHdr")

    g_searchPopup.Show("x" popX " y" popY " w" popW " h" popH " NoActivate")
    g_searchEdit   := ctrl
    g_searchData   := data
    g_searchCB     := cb
    g_searchStrict := strict
}

SearchLV_Pick(ctrl, rowNum) {
    global g_searchPopup, g_searchLV, g_searchCB
    if (rowNum == 0)
        return
    val := g_searchLV.GetText(rowNum, 1)
    DestroySearchPopup()
    ctrl.Value := val
    if (g_searchCB != "")
        g_searchCB(val)
}

CloseSearchPopup(ctrl) {
    global g_searchStrict, g_searchData
    if (g_searchStrict) {
        ; Validate exact match
        val     := ctrl.Value
        matched := false
        for _, v in ctrl._searchData {
            if (v == val) {
                matched := true
                break
            }
        }
        if (!matched)
            ctrl.Value := ""
    }
    DestroySearchPopup()
}

DestroySearchPopup() {
    global g_searchPopup, g_searchLV, g_searchEdit
    if (g_searchPopup != "") {
        g_searchPopup.Destroy()
        g_searchPopup := ""
        g_searchLV    := ""
        g_searchEdit  := ""
    }
}
