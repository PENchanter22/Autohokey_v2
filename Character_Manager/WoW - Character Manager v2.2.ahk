#Requires AutoHotkey v2.0
Persistent
#SingleInstance Force
SetWorkingDir A_ScriptDir
;	DetectHiddenWindows, On
;	SetTitleMatchMode, 2
;	SetBatchLines -1
;	SendMode Input
;	#NoTrayIcon
;	#Warn All, OutputDebug

_staticdata := ".\ini\staticdata.ini"

; --- Load static sections up front ---
factionData	:= LoadIniSection(_staticdata, "factions")
profData	   := LoadIniSection(_staticdata, "professions")
primaryProfs   := profData["profession"]
secProfData	:= LoadIniSection(_staticdata, "secondary professions")
secondaryProfs := secProfData["secondary profession"]

;	==================================== allows a GUI to be 'draggable' without a "caption" [title bar]
OnMessage 0x200, WM_MOUSEMOVE
WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
	If wParam = 1	; LButton
		PostMessage 0xA1, 2,,, 'A' ; WM_NCLBUTTONDOWN
	}
;	====================================

SC_CLOSE := 0xF060
MF_BYCOMMAND := 0
MF_ENABLED := 0
MF_GRAYED := 1
MF_DISABLED := 2

; --- Build GUI ---
myGui := Gui()
myGui.Title := "Character Creator"
myGui.Opt("+AlwaysOnTop +Border +ToolWindow -Caption -Resize")
; myGui.Opt("+AlwaysOnTop -Caption +Resize +Border +ToolWindow")
myGui.SetFont("s14")
myGui.OnEvent("Close", (*) => ExitApp())
; hMenu := DllCall("GetSystemMenu", "Ptr", MyGui.Hwnd, "Int", 0, "Ptr")
; DllCall("RemoveMenu", "Ptr", hMenu, "UInt", 0xF060, "UInt", 0x0)  ; SC_CLOSE = 0xF060, MF_BYCOMMAND = 0x0
; DllCall('EnableMenuItem', 'Ptr', hMenu, 'UInt', SC_CLOSE, 'UInt', MF_BYCOMMAND | MF_GRAYED | MF_DISABLED)

_WoWlogo := ".\img\logo.png"
_WoWLOGOxy := MyGui.Add("Picture", "h100", _WoWlogo)
;	Sets the font typeface, size, style, and/or color for controls added to the window from this point onward.
;	MyGui.SetFont(Options, FontName)
_guiTITLE := MyGui.Add("Text", "cBLACK y+5", "CHARACTER MANAGER")	; why does this require "+5" to position this element closer to the logo?
_guiTITLE.SetFont("BOLD s13", "Arial Rounded MT Bold")

_PurpleUnderline := ".\img\purple underline 100x2a.png"
_PurpleUnderlineXY := MyGui.Add("Picture", "x0", _PurpleUnderline)
_PurpleUnderlineXY.GetPos(&underlineX, &underlineY, &underlineWIDTH, &underlineHEIGHT)

; MyTab := MyGui.Add("Tab3", "x10 y150 w500 h500 Choose1", ["Viewer", "Editor", "Profile"])

; G - Faction
AddLabel(myGui, "Faction")
ddlFaction := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(factionData["faction"]))
ddlFaction.Value := 1

; H - Race
AddLabel(myGui, "Race")
ddlRace := myGui.Add("DropDownList", "x175 yp-5 w200", [""])
ddlRace.Value := 1

; I - Class
AddLabel(myGui, "Class")
ddlClass := myGui.Add("DropDownList", "x175 yp-5 w200", [""])
ddlClass.Value := 1

; J - Specialization
AddLabel(myGui, "Specialization")
ddlSpec := myGui.Add("DropDownList", "x175 yp-5 w200", [""])
ddlSpec.Value := 1

; K - Armor Type (read-only label)
AddLabel(myGui, "Armor Type")
txtArmor := myGui.Add("Text", "x175 yp w200", "")

; L/M - Primary Professions
AddLabel(myGui, "Profession 1")
ddlProf1 := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(primaryProfs))
ddlProf1.Value := 1

AddLabel(myGui, "Profession 2")
ddlProf2 := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(primaryProfs))
ddlProf2.Value := 1

; N/O/P - Secondary Professions
AddLabel(myGui, "Profession 3")
ddlProf3 := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(secondaryProfs))
ddlProf3.Value := 1

AddLabel(myGui, "Profession 4")
ddlProf4 := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(secondaryProfs))
ddlProf4.Value := 1

AddLabel(myGui, "Profession 5")
ddlProf5 := myGui.Add("DropDownList", "x175 yp-5 w200", PrependBlank(secondaryProfs))
ddlProf5.Value := 1

; --- Get 'MyGui' X, Y, Width, Height ---
MyGui.Show("w420 h600 Hide")
MyGui.GetPos(&guiX, &guiY, &guiWidth, &guiHeight)

; --- Center LOGO ---
CenterLOGO(guiWidth)
CenterLOGO(width)
	{
		_WoWLOGOxy.GetPos( , , &logoWidth, )
		_WoWLOGOxy.Move( ( Round( width / 2 ) - Round( logoWidth / 2 ) ), , , )
	}

; --- Center TITLE ---
CenterGuiTITLE(guiWidth, _guiTITLE.Text)
CenterGuiTITLE(_width, _text)
	{
		_Length := StrLen(_text)
		_guiTITLE.Move( ( Round( _width / 2 ) / 2 - Round( _Length / 2 ) ), , , )
	}

; --- Center UNDERLINE ---
StretchPurpleUnderline(guiWidth)
StretchPurpleUnderline(width)
	{
		Global _guiTITLE
		_guiTITLE.GetPos(&titleX, &titleY, &titleWidth, &titleHeight)
		_PurpleUnderlineXY.Move( 0, titleY+25, width)	; "+25" to position 'below' the above 'GuiTITLE' element
	}


myGui.Show()

; --- add 'rounded corners' to GUI
	RoundCorners(MyGui.Hwnd)
	RoundCorners(Hwnd) {
		WinGetClientPos(&gX, &gY, &gWidth, &gHeight, Hwnd)
		WinSetRegion(Format("0-0 w{1} h{2} r15-15", gWidth, gHeight), Hwnd)
	}

; --- Cascading OnChange Events ---

ddlFaction.OnEvent("Change", FactionChanged)
ddlRace.OnEvent("Change", RaceChanged)
ddlClass.OnEvent("Change", ClassChanged)
ddlProf1.OnEvent("Change", (*) => RefreshPrimaryProfs())
ddlProf2.OnEvent("Change", (*) => RefreshPrimaryProfs())
ddlProf3.OnEvent("Change", (*) => RefreshSecondaryProfs())
ddlProf4.OnEvent("Change", (*) => RefreshSecondaryProfs())
ddlProf5.OnEvent("Change", (*) => RefreshSecondaryProfs())

FactionChanged(ctrl, *) {
	faction := StrLower(ctrl.Text)
	ResetDDL(ddlRace)
	ResetDDL(ddlClass)
	ResetDDL(ddlSpec)
	txtArmor.Value := ""
	If faction = ""
		return
	races := LoadIniKey(_staticdata, "races", faction)
	ddlRace.Delete()
	ddlRace.Add(PrependBlank(races))
	ddlRace.Value := 1
}

RaceChanged(ctrl, *) {
	race := ctrl.Text
	ResetDDL(ddlClass)
	ResetDDL(ddlSpec)
	txtArmor.Value := ""
	If race = ""
		return
	classes := LoadIniKey(_staticdata, "racial classes", race)
	ddlClass.Delete()
	ddlClass.Add(PrependBlank(classes))
	ddlClass.Value := 1
}

ClassChanged(ctrl, *) {
	class := ctrl.Text
	ResetDDL(ddlSpec)
	txtArmor.Value := ""
	If class = ""
		return
	specs  := LoadIniKey(_staticdata, "class specializations", class)
	armor  := LoadIniKey(_staticdata, "armor types", class)
	ddlSpec.Delete()
	ddlSpec.Add(PrependBlank(specs))
	ddlSpec.Value := 1
	txtArmor.Value := (armor.Length > 0) ? armor[1] : ""
}

RefreshPrimaryProfs() {
	chosen := [ddlProf1.Text, ddlProf2.Text]
	for ddl in [ddlProf1, ddlProf2] {
		cur := ddl.Text
		available := [""]
		for p in primaryProfs {
			If p = cur || !HasVal(chosen, p) || p = ""
				available.Push(p)
		}
		ddl.Delete()
		ddl.Add(available)
		ddl.Value := HasVal(available, cur) ? IndexOf(available, cur) : 1
	}
}

RefreshSecondaryProfs() {
	chosen := [ddlProf3.Text, ddlProf4.Text, ddlProf5.Text]
	for ddl in [ddlProf3, ddlProf4, ddlProf5] {
		cur := ddl.Text
		available := [""]
		for p in secondaryProfs {
			If p = cur || !HasVal(chosen, p) || p = ""
				available.Push(p)
		}
		ddl.Delete()
		ddl.Add(available)
		ddl.Value := HasVal(available, cur) ? IndexOf(available, cur) : 1
	}
}

F9::RELOAD
~Escape::ExitApp()

; --- Helper Functions ---

LoadIniSection(file, section) {
	result := Map()
	raw := IniRead(file, section)
	for line in StrSplit(raw, "`n") {
		parts := StrSplit(line, "=", , 2)
		If parts.Length = 2 && parts[1] != "limit"
			result[parts[1]] := StrSplit(parts[2], "|")
	}
	return result
}

LoadIniKey(file, section, key) {
	try {
		raw := IniRead(file, section, key)
		return StrSplit(raw, "|")
	} catch {
		return []
	}
}

AddLabel(gui, label) {
	gui.Add("Text", "x10 w160", StrTitle(label))
}

ResetDDL(ctrl) {
	ctrl.Delete()
	ctrl.Add([""])
	ctrl.Value := 1
}

HasVal(arr, val) {
	for v in arr
		If v = val
			return true
	return false
}

IndexOf(arr, val) {
	for i, v in arr
		If v = val
			return i
	return 1
}

PrependBlank(arr) {
	result := [""]
	for v in arr
		result.Push(v)
	return result
}

StrTitle(str) {
	result := ""
	for word in StrSplit(str, " ")
		result .= (result ? " " : "") . StrUpper(SubStr(word,1,1)) . StrLower(SubStr(word,2))
	return result
}
