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

#Include JSON.ahk
#Include Helpers.ahk
#Include ProfileDB.ahk
#Include CharacterDB.ahk
#Include Logger.ahk

; ── Global state ─────────────────────────────────────────────
global F_STATIC  := A_ScriptDir "\StaticData.json"
global F_PROFILE := A_ScriptDir "\ProfileDB.json"
global SD        := Map()
global Profiles  := []
global ActivePro := ""
global g_chars   := []
global g_selIdx  := 0
global g_sortCol := 1       ; default sort = Name
global g_sortAsc := true

; ── Load static data ─────────────────────────────────────────
if !FileExist(F_STATIC) {
    MsgBox "StaticData.json not found!`nPlace it in:`n" F_STATIC, "Fatal Error", 0x10
    ExitApp()
}
SD := JsonParse(FileRead(F_STATIC, "UTF-8"))

; ── GUI dimensions ───────────────────────────────────────────
GUI_W  := 1100
GUI_H  := 620
PAD    := 10
TBAR_H := 38    ; title bar height
BTN_H  := 34    ; toolbar button height
SB_H   := 24    ; status bar height

; ── Main GUI — fixed size, always on top, no caption ─────────
global MyGui := Gui("-Caption +AlwaysOnTop", "CharDB")
MyGui.SetFont("s12", "Segoe UI")
MyGui.BackColor := "1E1E2E"
MyGui.OnEvent("Close", CloseApp)

; [X] close button — right side of title bar
MyGui.SetFont("s10 Bold cFF6B6B", "Segoe UI")
BtnX := MyGui.Add("Button",
    "x" (GUI_W - 36) " y4 w28 h28 Background2A2A3E",
    "X")
BtnX.OnEvent("Click", CloseApp)
; BtnX.OnEvent("Click", (*) => ExitApp())
BtnMin := MyGui.Add("Button",
    "x" (GUI_W - 68) " y4 w28 h28 Background2A2A3E cF9E2AF",
    "_")
BtnMin.OnEvent("Click", MinimizeApp)

; ── Title bar ────────────────────────────────────────────────
; BTN_X_W := 36   ; [X] button width
BTN_X_W := 72   ; [X] button width to accommodate the minimize button to its left
TBAR_W  := GUI_W - BTN_X_W
global TitleBar := MyGui.Add("Text",
    "x0 y0 w" TBAR_W " h" TBAR_H " +0x200 Background2A2A3E cCDD6F4 Center",
    "")
TitleBar.SetFont("s14 Bold", "Segoe UI")
TitleBar.OnEvent("Click", DragWindow)

; ── Profile row ──────────────────────────────────────────────
ROW1_Y := TBAR_H + 8
MyGui.SetFont("s12 Norm cCDD6F4", "Segoe UI")
MyGui.Add("Text", "x" PAD " y" (ROW1_Y + 4) " w70", "Profile:")

global DDProfile := MyGui.Add("DropDownList",
    "x" (PAD + 74) " y" ROW1_Y " w200 h300 Background2A2A3E cCDD6F4")
DDProfile.OnEvent("Change", OnProfileChange)

MyGui.SetFont("s12 Bold cCDD6F4")
BtnManPro := MyGui.Add("Button",
    "x" (PAD + 282) " y" ROW1_Y " w160 h28 Background3D3D5C",
    "⚙ &Manage Profiles")
BtnManPro.OnEvent("Click", (*) => ManageProfiles())

; Search — right-aligned on the same row
SRCH_W := 260
MyGui.SetFont("s12 Norm cCDD6F4")
MyGui.Add("Text",
    "x" (GUI_W - PAD - SRCH_W - 68) " y" (ROW1_Y + 4) " w60",
    "Search:")
global EditSearch := MyGui.Add("Edit",
    "x" (GUI_W - PAD - SRCH_W) " y" ROW1_Y " w" SRCH_W " h28 Background2A2A3E cCDD6F4")
EditSearch.OnEvent("Change", (*) => RefreshList(EditSearch.Value))

; ── ListView ─────────────────────────────────────────────────
LV_Y := ROW1_Y + 38
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
BTN_W   := 120
BTN_GAP := 10
BTN_COUNT := 4
BTN_ROW_W := BTN_COUNT * BTN_W + (BTN_COUNT - 1) * BTN_GAP
BTN_Y  := LV_Y + LV_H + 8
BTN_X1 := (GUI_W - BTN_ROW_W) // 2

MyGui.SetFont("s12 Bold cCDD6F4")
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
StatusBar.SetFont("s12", "Segoe UI")

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

~ESC::CloseApp
; ~ESC::ExitApp