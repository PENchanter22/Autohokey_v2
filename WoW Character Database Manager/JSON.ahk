; ============================================================
;  JSON.ahk — Parser & Stringifier
;  Include this file from the master script.
; ============================================================

JsonParse(txt) {
    txt := Trim(txt)
    pos := 1
    return ParseValue(txt, &pos)
}

ParseValue(txt, &pos) {
    SkipWS(txt, &pos)
    ch := SubStr(txt, pos, 1)
    if ch == '"' {          ; '"'
        return ParseString(txt, &pos)
    }
    if ch == "{" {
        return ParseObject(txt, &pos)
    }
    if ch == "[" {
        return ParseArray(txt, &pos)
    }
    if ch == "t" {
        pos += 4
        return true
    }
    if ch == "f" {
        pos += 5
        return false
    }
    if ch == "n" {
        pos += 4
        return ""
    }
    start := pos
        while pos <= StrLen(txt) && InStr("0123456789.-+eE", SubStr(txt, pos, 1)) {
            pos++
        }
    raw := SubStr(txt, start, pos - start)
    Log("ParseValue — number parse on: '" raw "'", "DEBUG")
    if raw == "" {
        Log("ParseValue — unexpected character at pos " pos ": '" SubStr(txt, pos, 10) "'", "ERROR")
        pos++
        return ""
    }
    return raw + 0
}

ParseString(txt, &pos) {
    pos++
    out := ""
    loop {
        ch := SubStr(txt, pos, 1)
        if ch == '"' {      ; '"'
            pos++
            return out
        }
        if ch == "\" {
            pos++
            esc := SubStr(txt, pos, 1)
            pos++
            if esc == "n" {
                out .= "`n"
            } else if esc == "t" {
                out .= "`t"
            } else if esc == "r" {
                out .= "`r"
            } else {
                out .= esc
            }
        } else {
            out .= ch
            pos++
        }
    }
}

ParseObject(txt, &pos) {
    pos++
    obj := Map()
    loop {
        SkipWS(txt, &pos)
        ch := SubStr(txt, pos, 1)
        if ch == "}" {
            pos++
            return obj
        }
        if ch == "," {
            pos++
            SkipWS(txt, &pos)
        }
        key := ParseString(txt, &pos)
        SkipWS(txt, &pos)
        pos++
        obj[key] := ParseValue(txt, &pos)
    }
}

ParseArray(txt, &pos) {
    pos++
    arr := []
    loop {
        SkipWS(txt, &pos)
        ch := SubStr(txt, pos, 1)
        if ch == "]" {
            pos++
            return arr
        }
        if ch == "," {
            pos++
        }
        arr.Push(ParseValue(txt, &pos))
    }
}

SkipWS(txt, &pos) {
    while pos <= StrLen(txt) && InStr(" `t`r`n", SubStr(txt, pos, 1)) {
        pos++
    }
}

JsonStringify(val, indent := 0) {
    pad := ""
    loop indent {
        pad .= "  "
    }
    ipad := pad "  "
    if val is Array {
        if val.Length == 0 {
            return "[]"
        }
        parts := []
        loop val.Length {
            parts.Push(ipad JsonStringify(val[A_Index], indent + 1))
        }
        return "[`n" JoinArr(parts, ",`n") "`n" pad "]"
    }
    if val is Map {
        if val.Count == 0 {
            return "{}"
        }
        parts := []
        for k, v in val {
            parts.Push(ipad JsonEscStr(k) ": " JsonStringify(v, indent + 1))
        }
        return "{`n" JoinArr(parts, ",`n") "`n" pad "}"
    }
    if val is Integer {
        return val
    }
    if val is Float {
        return val
    }
    if val == true {
        return "true"
    }
    if val == false {
        return "false"
    }
    return JsonEscStr(String(val))
}

JsonStringifyChar(ch, indent := 0) {
    pad  := ""
    loop indent {
        pad .= "  "
    }
    ipad := pad "  "
    keys := ["profile","name","level","realm","guild","faction","race",
             "gender","class","spec","armor","prof1","prof2",
             "sec1","sec2","sec3","status","notes"]
    parts := []
    loop keys.Length {
        k := keys[A_Index]
        v := ch.Has(k) ? ch[k] : ""
        parts.Push(ipad JsonEscStr(k) ": " JsonStringify(v, indent + 1))
    }
    return "{`n" JoinArr(parts, ",`n") "`n" pad "}"
}

JsonEscStr(s) {
    s := StrReplace(s, "\",   "\\")
    s := StrReplace(s, '"',   '\"')    ; '"'
    s := StrReplace(s, "`n",  "\n")
    s := StrReplace(s, "`r",  "\r")
    s := StrReplace(s, "`t",  "\t")
    return '"' s '"'                   ; '"'
}

JoinArr(arr, sep) {
    out := ""
    loop arr.Length {
        if A_Index > 1 {
            out .= sep
        }
        out .= arr[A_Index]
    }
    return out
}
