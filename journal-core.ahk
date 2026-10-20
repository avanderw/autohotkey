#Requires AutoHotkey v2.0

ActiveTime(now, startHour, endHour, weekends := true) {
    candidate := now
    Loop 8 {
        day := SubStr(candidate, 1, 8)
        start := day . Format("{:02}0000", startHour)
        finish := day . Format("{:02}0000", endHour)
        weekday := Integer(FormatTime(candidate, "WDay"))
        if (weekends || (weekday != 1 && weekday != 7)) {
            if (candidate < start)
                return start
            if (candidate < finish)
                return candidate
        }
        candidate := SubStr(DateAdd(day . "000000", 1, "d"), 1, 8) . "000000"
    }
    throw Error("Could not find the next active day")
}

NextThoughtTime(now, minutesOffset, startHour, endHour, weekends := true) {
    active := ActiveTime(now, startHour, endHour, weekends)
    if (active != now)
        return active
    return ActiveTime(DateAdd(now, minutesOffset, "m"), startHour, endHour, weekends)
}

ValidTimestamp(value) {
    if !RegExMatch(value, "^\d{14}$")
        return false
    try {
        DateDiff(value, value, "s")
        return true
    } catch {
        return false
    }
}

WriteNote(folder, text, timestamp := A_Now) {
    DirCreate(folder)
    temporary := ""
    Loop 100 {
        destination := folder . "\" . timestamp . (A_Index = 1 ? "" : "-" . A_Index) . ".md"
        temporary := destination . ".tmp"
        if FileExist(destination)
            continue
        handle := DllCall("CreateFileW", "Str", temporary, "UInt", 0x40000000,
            "UInt", 0, "Ptr", 0, "UInt", 1, "UInt", 0x80, "Ptr", 0, "Ptr")
        if (handle = -1)
            continue
        file := FileOpen(handle, "h", "UTF-8")
        try {
            file.Write(text)
            if !DllCall("FlushFileBuffers", "Ptr", handle)
                throw OSError()
            file.Close()
            DllCall("CloseHandle", "Ptr", handle)
            handle := 0
            FileMove(temporary, destination, false)
            return destination
        } catch as err {
            file.Close()
            if handle
                DllCall("CloseHandle", "Ptr", handle)
            try FileDelete(temporary)
            throw err
        }
    }
    throw Error("Cannot create a unique note in " . folder . ". Check folder permissions and available space.")
}