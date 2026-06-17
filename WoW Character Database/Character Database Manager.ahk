; ============================================================
;  ⚔  Character Manager — Master Script
;  Handles GUI layout only. All logic is in included files.
;
;  Required files (same folder as this script):
;    JSON.ahk          — JSON parser & stringifier
;    Helpers.ahk       — Utility functions
;    ProfileDB.ahk     — Profile management
;    CharacterDB.ahk   — Character CRUD & list
;    StaticData.json   — Game static data
;    ProfileDB.json    — Auto-created on first run
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir

#Include .\functions\
#Include JSON.ahk
#Include Helpers.ahk
#Include ProfileDB.ahk
#Include CharacterDB.ahk
#Include Logger.ahk

; ── Global state ─────────────────────────────────────────────
global F_STATIC  := A_ScriptDir . ".\references\" . "StaticData.json"
global F_PROFILE := A_ScriptDir . ".\records\"    . "ProfileDB.json"
global SD        := Map()
global Profiles  := []
global ActivePro := ""
global g_chars   := []
global g_selIdx  := 0
global g_sortCol := 1       ; default sort = Name
global g_sortAsc := true

Tooltipping("show")

; ── Load static data ─────────────────────────────────────────
if !FileExist(F_STATIC) {
    MsgBox "StaticData.json not found!`nPlace it in:`n" F_STATIC, "Fatal Error", 0x10
    ExitApp()
}
SD := JsonParse(FileRead(F_STATIC, "UTF-8"))

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

global TBAR_H   :=    42   ; title bar height        (was 38)
global TBAR_W   :=     0    ; set below after BTN_X_W is known

global BTN_XW   :=    28   ; [X] / [_] button width
global BTN_XH   :=    28   ; [X] / [_] button height
global BTN_XG   :=     4    ; gap from right edge / between X buttons

global CTL_H    :=    30   ; standard control height (edits, DDLs) (was 28)
global BTN_H    :=    38   ; toolbar button height                  (was 34)
global BTN_W    :=   120  ; toolbar button width
global BTN_GAP  :=    10   ; gap between toolbar buttons
global BTN_COUNT :=    4

global SB_H     :=    28   ; status bar height       (was 24)

global PRO_LBL_W :=   70  ; "Profile:" label width
global PRO_DDL_W :=  200 ; profile dropdown width
global PRO_BTN_W :=  160 ; "Manage Profiles" button width

global SRCH_W   :=   260  ; search edit width
global SRCH_LBL_W :=  60 ; "Search:" label width

; ── Main GUI — fixed size, always on top, no caption ─────────
global MyGui := Gui("-Caption +AlwaysOnTop", "CharDB")
MyGui.SetFont("s" FS_NORM, "Segoe UI")
MyGui.BackColor := "1E1E2E"
MyGui.OnEvent("Close", CloseApp)

; [X] close and [_] minimise buttons — top-right of title bar
MyGui.SetFont("s10 Bold cFF6B6B", "Segoe UI")
BtnX := MyGui.Add("Button",
    "x" (GUI_W - BTN_XW - BTN_XG) " y" BTN_XG " w" BTN_XW " h" BTN_XH " Background2A2A3E",
    "X")
BtnX.OnEvent("Click", CloseApp)

MyGui.SetFont("s10 Bold cF9E2AF", "Segoe UI")
BtnMin := MyGui.Add("Button",
    "x" (GUI_W - BTN_XW*2 - BTN_XG*2) " y" BTN_XG " w" BTN_XW " h" BTN_XH " Background2A2A3E",
    "_")
BtnMin.OnEvent("Click", MinimizeApp)

; ── Title bar ────────────────────────────────────────────────
BTN_X_W := BTN_XW*2 + BTN_XG*3   ; total width consumed by X + _ buttons
TBAR_W  := GUI_W - BTN_X_W
global TitleBar := MyGui.Add("Text",
    "x0 y0 w" TBAR_W " h" TBAR_H " +0x200 Background2A2A3E cCDD6F4 Center",
    "")
TitleBar.SetFont("s" FS_TITLE " Bold", "Segoe UI")
TitleBar.OnEvent("Click", DragWindow)

; ── Profile row ──────────────────────────────────────────────
ROW1_Y := TBAR_H + 8
MyGui.SetFont("s" FS_NORM " Norm cCDD6F4", "Segoe UI")
MyGui.Add("Text", "x" PAD " y" (ROW1_Y + 4) " w" PRO_LBL_W, "Profile:")

global DDProfile := MyGui.Add("DropDownList",
    "x" (PAD + PRO_LBL_W + 4) " y" ROW1_Y " w" PRO_DDL_W " h300 Background2A2A3E cCDD6F4")
DDProfile.OnEvent("Change", OnProfileChange)

MyGui.SetFont("s" FS_BOLD " Bold cCDD6F4")
BtnManPro := MyGui.Add("Button",
    "x" (PAD + PRO_LBL_W + 4 + PRO_DDL_W + 8) " y" ROW1_Y " w" (PRO_BTN_W + 32) " h" CTL_H " Background3D3D5C",
    "⚙ &Manage Profiles")
BtnManPro.OnEvent("Click", (*) => ManageProfiles())

; Search — right-aligned on the same row
MyGui.SetFont("s" FS_NORM " Norm cCDD6F4")
MyGui.Add("Text",
    "x" (GUI_W - PAD - SRCH_W - SRCH_LBL_W - 8) " y" (ROW1_Y + 4) " w" SRCH_LBL_W,
    "Search:")
global EditSearch := MyGui.Add("Edit",
    "x" (GUI_W - PAD - SRCH_W) " y" ROW1_Y " w" SRCH_W " h" CTL_H " Background2A2A3E cCDD6F4")
EditSearch.OnEvent("Change", (*) => RefreshList(EditSearch.Value))

; ── ListView ─────────────────────────────────────────────────
LV_Y := ROW1_Y + CTL_H + 8
LV_H := GUI_H - LV_Y - BTN_H - SB_H - 28

global LV := MyGui.Add("ListView",
    "x" PAD " y" LV_Y " w" (GUI_W - PAD*2) " h" LV_H
    " Background1A1A2E cCDD6F4 Grid LV0x4000 NoSortHdr",
    ["Name","Level","Realm","Guild","Faction","Race","Gender",
     "Class","Spec","Armor","Prof 1","Prof 2","Sec 1","Sec 2","Sec 3","Status"])

; Col widths — first 10 cols visible without scrolling
LV.ModifyCol( 1, 130)   ; Name
LV.ModifyCol( 2,  55)   ; Level
LV.ModifyCol( 3, 120)   ; Realm
LV.ModifyCol( 4, 120)   ; Guild
LV.ModifyCol( 5,  80)   ; Faction
LV.ModifyCol( 6, 100)   ; Race
LV.ModifyCol( 7,  70)   ; Gender
LV.ModifyCol( 8, 110)   ; Class
LV.ModifyCol( 9, 110)   ; Spec
LV.ModifyCol(10,  65)   ; Armor  ← last fully visible
LV.ModifyCol(11, 120)   ; Prof 1
LV.ModifyCol(12, 120)   ; Prof 2
LV.ModifyCol(13,  90)   ; Sec 1
LV.ModifyCol(14,  90)   ; Sec 2
LV.ModifyCol(15,  90)   ; Sec 3
LV.ModifyCol(16,  80)   ; Status

LV.OnEvent("ItemSelect",  LV_Select)
LV.OnEvent("DoubleClick", (*) => EditEntry())
LV.OnEvent("ColClick",    LV_ColClick)

; ── Toolbar buttons — centered ───────────────────────────────
BTN_ROW_W := BTN_COUNT * BTN_W + (BTN_COUNT - 1) * BTN_GAP
BTN_Y  := LV_Y + LV_H + 8
BTN_X1 := (GUI_W - BTN_ROW_W) // 2

MyGui.SetFont("s" FS_BOLD " Bold cCDD6F4")
BtnNew  := MyGui.Add("Button",
    "x" BTN_X1                              " y" BTN_Y " w" BTN_W " h" BTN_H " Background3D3D5C",
    "➕ &New")
BtnEdit := MyGui.Add("Button",
    "x" (BTN_X1 + (BTN_W+BTN_GAP))         " y" BTN_Y " w" BTN_W " h" BTN_H " Background3D3D5C",
    "✏ &Edit")
BtnDel  := MyGui.Add("Button",
    "x" (BTN_X1 + (BTN_W+BTN_GAP)*2)       " y" BTN_Y " w" BTN_W " h" BTN_H " Background3D3D5C cFF6B6B",
    "🗑 &Delete")
BtnSave := MyGui.Add("Button",
    "x" (BTN_X1 + (BTN_W+BTN_GAP)*3)       " y" BTN_Y " w" BTN_W " h" BTN_H " Background3D3D5C cA6E3A1",
    "💾 &Save")

BtnNew .OnEvent("Click", (*) => NewEntry())
BtnEdit.OnEvent("Click", (*) => EditEntry())
BtnDel .OnEvent("Click", (*) => DeleteEntry())
BtnSave.OnEvent("Click", (*) => SaveCharDB())

; ── Status bar ───────────────────────────────────────────────
SB_Y := GUI_H - SB_H - 4
global StatusBar := MyGui.Add("Text",
    "x0 y" SB_Y " w" GUI_W " h" SB_H " Background2A2A3E cCDD6F4",
    "  Loading…")
StatusBar.SetFont("s" FS_SB, "Segoe UI")

; ── Show & load ──────────────────────────────────────────────
MyGui.Show("w" GUI_W " h" GUI_H)
WinRedraw("ahk_id " MyGui.Hwnd)
LoadProfileDB()

return

; ── Exit handler — save last profile ─────────────────────────
CloseApp(*) {
    Log("─────────────────────────────────────────────────────", "LINE")
    SaveProfileDB()
    ExitApp()
}

; ── minimize handler —────────────────────────────────────────
MinimizeApp(*) {
    global MyGui
    MyGui.Minimize()
}

~F4::
	{
		Tooltipping("show")
	}

Tooltipping(show, *)
	{
				TraySetIcon(A_ScriptDir "\_icons_\logo2026c.ico", 1)
		If (show)
			{
				TrayTip("Use this software`nto manage your`nWorld of Warcraft`ncharacters!", "WoW Character Manager")
				SetTimer TraytipDismiss, 2000
			} Else {
				SetTimer TraytipDismiss, 0
				TrayTip
			}
	}
TraytipDismiss(*)
	{
		TrayTip
	}

F9::RELOAD
; ~ESC::CloseApp
; ~ESC::ExitApp
