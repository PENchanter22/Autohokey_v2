; ── Global state ─────────────────────────────────────────────
global F_STATIC  := A_ScriptDir . "\references\" . "StaticData.json"
global F_PROFILE := A_ScriptDir . "\records\"    . "ProfileDB.json"
global SD        := Map()
global Profiles  := []
global ActivePro := ""
global g_chars   := []
global g_selIdx  := 0
global g_sortCol := 1       ; default sort = Name
global g_sortAsc := true

; ── Font sizes ───────────────────────────────────────────────
global FS_NORM  := 14   ; normal text, labels, dropdowns  (was 12)
global FS_TITLE := 16   ; title bar text                  (was 14)
global FS_BOLD  := 14   ; toolbar & dialog buttons        (was 12)
global FS_SB    := 14   ; status bar                      (was 12)
; Note: [X] and [_] buttons intentionally kept at s10 Bold

; ── GUI dimensions ───────────────────────────────────────────
global GUI_W    :=  1100
global GUI_H    :=   620
global PAD      :=    10

global TBAR_H   :=    42   ; title bar height                      (was 38)
global TBAR_W   :=     0    ; set below after BTN_X_W is known

global BTN_XW   :=    28   ; [X] / [_] button width
global BTN_XH   :=    28   ; [X] / [_] button height
global BTN_XG   :=     4    ; gap from right edge / between X buttons

global CTL_H    :=    30   ; standard control height (edits, DDLs) (was 28)
global BTN_H    :=    38   ; toolbar button height                 (was 34)
global BTN_W    :=   120  ; toolbar button width
global BTN_GAP  :=    10   ; gap between toolbar buttons
global BTN_COUNT :=    4

global SB_H     :=    28   ; status bar height                     (was 24)

global PRO_LBL_W :=   70  ; "Profile:" label width
global PRO_DDL_W :=  200 ; profile dropdown width
global PRO_BTN_W :=  160 ; "Manage Profiles" button width

global SRCH_W   :=   260  ; search edit width
global SRCH_LBL_W :=  60 ; "Search:" label width

; ── ListView appearance ───────────────────────────────────────
global LV_FS         := 13       ; ListView font size (separate from FS_NORM)
global LV_ROW_ODD    := 0x1A1A2E ; odd row background  (current base color)
global LV_ROW_EVEN   := 0x2A2A3E ; even row background (slightly lighter)
global LV_ROW_SEL    := 0x45475A ; selected row background
global LV_TEXT       := 0xCDD6F4 ; normal row text color
global LV_TEXT_SEL   := 0xFFFFFF ; selected row text color
