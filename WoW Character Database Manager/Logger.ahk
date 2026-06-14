; ============================================================
;  Logger.ahk — Writes timestamped log entries to CharManager.log
; ============================================================

global LOG_FILE := A_ScriptDir "\CharManager.log"

Log(msg, level := "INFO") {
    global LOG_FILE
    ts   := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    line := "[" ts "] [" level "] " msg "`n"
    try {
        FileAppend line, LOG_FILE, "UTF-8"
    }
}
