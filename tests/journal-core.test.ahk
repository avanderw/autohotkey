#Requires AutoHotkey v2.0
#Include ..\journal-core.ahk

AssertEqual(actual, expected, label) {
    if (actual != expected)
        throw Error(label . ": expected " . expected . ", got " . actual)
}

testFolder := A_Temp . "\Self-Check-In-tests-" . DllCall("GetCurrentProcessId")
try {
    AssertEqual(NextThoughtTime("20261020070000", 60, 9, 17), "20261020090000", "Before opening")
    AssertEqual(NextThoughtTime("20261020100000", 60, 9, 17), "20261020110000", "During hours")
    AssertEqual(NextThoughtTime("20261020163000", 60, 9, 17), "20261021090000", "Cross closing")
    AssertEqual(NextThoughtTime("20261020170000", 60, 9, 17), "20261021090000", "At closing")
    AssertEqual(NextThoughtTime("20261023170000", 60, 9, 17, false), "20261026090000", "Skip weekend")
    AssertEqual(NextThoughtTime("20261023170000", 60, 9, 17, true), "20261024090000", "Include weekend")
    AssertEqual(ActiveTime("20261020113000", 9, 17), "20261020113000", "Catch up once in hours")
    AssertEqual(NextThoughtTime("20261231233000", 60, 9, 17), "20270101090000", "Year rollover")
    AssertEqual(ValidTimestamp("broken"), false, "Reject invalid timestamp")
    AssertEqual(ValidTimestamp("20261020113000"), true, "Accept timestamp")
    noteText := "# Test`n`n" . Chr(0x03A9) . "`nSecond line"
    first := WriteNote(testFolder, noteText, "20261020120000")
    second := WriteNote(testFolder, "Second note", "20261020120000")
    AssertEqual(first != second, true, "Unique note names")
    AssertEqual(FileRead(first, "UTF-8"), noteText, "UTF-8 round trip")
    AssertEqual(FileRead(second, "UTF-8"), "Second note", "No append to existing note")
    AssertEqual(FileExist(first . ".tmp"), "", "No leftover temporary file")
    FileAppend("PASS: 14 scheduling and note-storage assertions`n", "*")
} catch as err {
    FileAppend("FAIL: " . err.Message . " (line " . err.Line . ")`n", "**")
    ExitApp(1)
} finally {
    if DirExist(testFolder)
        DirDelete(testFolder, true)
}
ExitApp(0)