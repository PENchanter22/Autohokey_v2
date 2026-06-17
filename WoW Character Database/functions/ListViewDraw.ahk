; ============================================================
;  ListViewDraw.ahk — Custom draw for ListView
;  Provides zebra striping and a unique selection highlight.
;  Requires GlobalVARS.ahk to be included first.
;
;  Call InitListViewDraw(LV) once after the ListView is created.
; ============================================================

; Convert 0xRRGGBB → COLORREF (0xBBGGRR) as required by Win32
RGBtoCOLORREF(rgb) {
    r := (rgb >> 16) & 0xFF
    g := (rgb >>  8) & 0xFF
    b :=  rgb        & 0xFF
    return (b << 16) | (g << 8) | r
}

InitListViewDraw(lvCtrl) {
    global LV_FS
    ; Set ListView font size independently of the rest of the GUI
    lvCtrl.SetFont("s" LV_FS, "Segoe UI")
    ; Hook WM_NOTIFY (0x4E) on the parent GUI window
    OnMessage(0x4E, LV_CustomDraw)
}

LV_CustomDraw(wParam, lParam, msg, hwnd) {
    global LV, LV_ROW_ODD, LV_ROW_EVEN, LV_ROW_SEL, LV_TEXT, LV_TEXT_SEL

    ; Only handle notifications from our ListView's parent
    if (hwnd != LV.Gui.Hwnd)
        return

    ; Read the NMHDR structure to confirm it's from our LV and is NM_CUSTOMDRAW
    nmHwnd := NumGet(lParam, 0, "Ptr")
    if (nmHwnd != LV.Hwnd)
        return

    code := NumGet(lParam, A_PtrSize * 2, "Int")
    NM_CUSTOMDRAW := -12
    if (code != NM_CUSTOMDRAW)
        return

    CDDS_PREPAINT     := 0x00001
    CDDS_ITEMPREPAINT := 0x00010
    CDRF_DODEFAULT    := 0x00000
    CDRF_NOTIFYITEMDRAW := 0x00020

    dwDrawStage := NumGet(lParam, A_PtrSize * 3,      "UInt")
    dwItemSpec  := NumGet(lParam, A_PtrSize * 3 + 16, "UPtr")  ; item index (row)
    uItemState  := NumGet(lParam, A_PtrSize * 3 + 24, "UInt")  ; state flags
    hdc         := NumGet(lParam, A_PtrSize * 3 + 4,  "Ptr")   ; device context

    CDIS_SELECTED := 0x0001

    if (dwDrawStage == CDDS_PREPAINT)
        return CDRF_NOTIFYITEMDRAW   ; ask for per-item callbacks

    if (dwDrawStage == CDDS_ITEMPREPAINT) {
        isSelected := (uItemState & CDIS_SELECTED) != 0

        if isSelected {
            bg   := RGBtoCOLORREF(LV_ROW_SEL)
            txt  := RGBtoCOLORREF(LV_TEXT_SEL)
        } else if (Mod(dwItemSpec, 2) == 0) {
            bg   := RGBtoCOLORREF(LV_ROW_EVEN)
            txt  := RGBtoCOLORREF(LV_TEXT)
        } else {
            bg   := RGBtoCOLORREF(LV_ROW_ODD)
            txt  := RGBtoCOLORREF(LV_TEXT)
        }

        ; Set text and background colors via Win32 GDI
        DllCall("SetTextColor",   "Ptr", hdc, "UInt", txt)
        DllCall("SetBkColor",     "Ptr", hdc, "UInt", bg)

        ; Fill the row background rect ourselves
        ; NMCUSTOMDRAW.rc starts at offset A_PtrSize*3 + 8
        rcLeft   := NumGet(lParam, A_PtrSize * 3 + 8,  "Int")
        rcTop    := NumGet(lParam, A_PtrSize * 3 + 12, "Int")
        rcRight  := NumGet(lParam, A_PtrSize * 3 + 16, "Int")  ; note: reused offset on 32-bit; fine on 64
        rcBottom := NumGet(lParam, A_PtrSize * 3 + 20, "Int")

        hBrush := DllCall("CreateSolidBrush", "UInt", bg, "Ptr")
        rect   := Buffer(16)
        NumPut("Int", rcLeft,   rect,  0)
        NumPut("Int", rcTop,    rect,  4)
        NumPut("Int", rcRight,  rect,  8)
        NumPut("Int", rcBottom, rect, 12)
        DllCall("FillRect", "Ptr", hdc, "Ptr", rect, "Ptr", hBrush)
        DllCall("DeleteObject", "Ptr", hBrush)

        CDRF_NEWFONT := 0x00002
        return CDRF_NEWFONT   ; tell the control to use our new colors
    }
}
