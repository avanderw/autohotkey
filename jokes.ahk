#SingleInstance Force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

EnvGet, vUserProfile, USERPROFILE
IniRead, jokesPath, settings.ini, Environment, jokes-path
if (jokesPath="ERROR") {
    InputBox, jokesPath, Jokes Path, Enter the path to your jokes file
    if ErrorLevel
        return
    IniWrite, %jokesPath%, settings.ini, Environment, jokes-path
}
StringReplace, jokesPath, jokesPath, ~, %vUserProfile%, All

^Numpad9::
Loop, Read, %jokesPath%
  numlines := A_Index

Random, idx, 1, %numlines%
FileReadLine, joke, %jokesPath%, idx
Msgbox, %joke%