# Autohotkey scripts

You will require autohotkey to run these scripts.
They are intended to be my replacement for org-mode in emacs.

## Tasks

| Hotkey | Action |
| --- | --- |
|CTRL+NUMPAD0|Add task to inbox|
|CTRL+NUMPAD1|Refile task|
|CTRL+NUMPAD3|Open task refile path|

## Notes

| Hotkey | Action |
| --- | --- |
|CTRL+NUMPAD4|Add note to the notes folder|

## Jokes

| Hotkey | Action |
| --- | --- |
|CTRL+NUMPAD9|Display a random joke|

## IDs

| Hotkey | Action |
| --- | --- |
|CTRL+SHIFT+D|Send the isodate to the cursor position|
|CTRL+SHIFT+T|Send the isotime to the cursor position|


## settings.ini

```ini
[Environment]
task-inbox=~\org\inbox.todo.txt
task-refile-path=~\org
notes-path=~\org\notes
jokes-path=~\org\lists\jokes.txt

[Cache] 
task-refile-category=last
```
