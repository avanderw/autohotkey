#Requires AutoHotkey v2.0

; ISO Date/Time Generator
; Quickly insert formatted dates and times

SetTrayTip()
TrayTip("Quick Dates", "Running", 1)
SetTimer(() => TrayTip(), 2000)

^!d:: {  ; Insert ISO date (YYYY-MM-DD)
    KeyWait("LAlt")
    formattedDate := FormatTime(A_Now, "yyyy-MM-dd")
    A_Clipboard := formattedDate
    SendText(formattedDate)
    ToolTip("Date copied & inserted: " formattedDate)
    SetTimer(RemoveToolTip, 1500)
}

^!t:: {  ; Insert ISO timestamp (YYYYMMDDTHHmmss)
    KeyWait("LAlt")
    formattedTime := FormatTime(A_Now, "yyyyMMddTHHmmss")
    A_Clipboard := formattedTime
    SendText(formattedTime)
    ToolTip("Timestamp copied & inserted: " formattedTime)
    SetTimer(RemoveToolTip, 1500)
}

RemoveToolTip() {
    ToolTip()
}

SetTrayTip() {
    try {
        A_TrayMenu.SetIcon(A_ScriptDir . "\key.ico", 1)
    }
    A_TrayMenu.Tip := "Quick Dates"
}
