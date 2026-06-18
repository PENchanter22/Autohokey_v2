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
    lvCtrl.SetFont("s" LV_FS, "Segoe UI")
    OnMessage(0x4E, LV_CustomDraw)
}

LV_CustomDraw(wParam, lParam, msg, hwnd) {
    global LV, LV_ROW_ODD, LV_ROW_EVEN, LV_ROW_SEL, LV_TEXT, LV_TEXT_SEL

    ; Only handle from our ListView's parent window
    if (hwnd != LV.Gui.Hwnd)
        return

    ; ── NMHDR ────────────────────────────────────────────────
    ; hwndFrom  : Ptr  (8 bytes on 64-bit)
    ; idFrom    : UPtr (8 bytes on 64-bit)
    ; code      : Int  (4 bytes, offset = A_PtrSize * 2)
    nmHwnd := NumGet(lParam, 0, "Ptr")
    if (nmHwnd != LV.Hwnd)
        return

    ; NMHDR size: 2 * A_PtrSize + 4, padded to next Ptr boundary
    nmhdrSize := (A_PtrSize == 8) ? 24 : 12

    code := NumGet(lParam, A_PtrSize * 2, "Int")
    NM_CUSTOMDRAW := -12
    if (code != NM_CUSTOMDRAW)
        return

    ; ── NMCUSTOMDRAW offsets (after NMHDR) ───────────────────
    ; dwDrawStage : UInt  +0
    ; hdc         : Ptr   +4  (padded to ptr boundary on 64-bit → +8)
    ; rc          : RECT  after hdc ptr
    ;   left, top, right, bottom : Int each
    ; dwItemSpec  : UPtr  after rc
    ; uItemState  : UInt  after dwItemSpec

    if (A_PtrSize == 8) {
        ; 64-bit layout
        off_stage   := nmhdrSize       ; 24
        off_hdc     := nmhdrSize + 8   ; 32  (4 bytes stage + 4 pad)
        off_rc      := nmhdrSize + 16  ; 40
        off_item    := nmhdrSize + 32  ; 56
        off_state   := nmhdrSize + 40  ; 64
    } else {
        ; 32-bit layout
        off_stage   := nmhdrSize       ; 12
        off_hdc     := nmhdrSize + 4   ; 16
        off_rc      := nmhdrSize + 8   ; 20
        off_item    := nmhdrSize + 24  ; 36
        off_state   := nmhdrSize + 28  ; 40
    }

    dwDrawStage := NumGet(lParam, off_stage, "UInt")
    hdc         := NumGet(lParam, off_hdc,   "Ptr")
    rcLeft      := NumGet(lParam, off_rc,      "Int")
    rcTop       := NumGet(lParam, off_rc +  4, "Int")
    rcRight     := NumGet(lParam, off_rc +  8, "Int")
    rcBottom    := NumGet(lParam, off_rc + 12, "Int")
    dwItemSpec  := NumGet(lParam, off_item,  "UPtr")
    uItemState  := NumGet(lParam, off_state, "UInt")

    CDDS_PREPAINT       := 0x0001
    CDDS_ITEMPREPAINT   := 0x0010
    CDRF_NOTIFYITEMDRAW := 0x0020
    CDRF_NEWFONT        := 0x0002
    CDIS_SELECTED       := 0x0001

    if (dwDrawStage == CDDS_PREPAINT)
        return CDRF_NOTIFYITEMDRAW

    if (dwDrawStage == CDDS_ITEMPREPAINT) {
        isSelected := (uItemState & CDIS_SELECTED) != 0

        if isSelected {
            bg  := RGBtoCOLORREF(LV_ROW_SEL)
            txt := RGBtoCOLORREF(LV_TEXT_SEL)
        } else if (Mod(dwItemSpec, 2) == 0) {
            bg  := RGBtoCOLORREF(LV_ROW_EVEN)
            txt := RGBtoCOLORREF(LV_TEXT)
        } else {
            bg  := RGBtoCOLORREF(LV_ROW_ODD)
            txt := RGBtoCOLORREF(LV_TEXT)
        }

        DllCall("SetTextColor", "Ptr", hdc, "UInt", txt)
        DllCall("SetBkColor",   "Ptr", hdc, "UInt", bg)

        hBrush := DllCall("CreateSolidBrush", "UInt", bg, "Ptr")
        rect   := Buffer(16)
        NumPut("Int", rcLeft,   rect,  0)
        NumPut("Int", rcTop,    rect,  4)
        NumPut("Int", rcRight,  rect,  8)
        NumPut("Int", rcBottom, rect, 12)
        DllCall("FillRect",    "Ptr", hdc, "Ptr", rect, "Ptr", hBrush)
        DllCall("DeleteObject","Ptr", hBrush)

        return CDRF_NEWFONT
    }
}
