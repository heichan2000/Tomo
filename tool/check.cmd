@echo off
rem The one "done" command (spec 15.7), for cmd and PowerShell: tool\check
rem The work is in tool\check.dart.
dart run "%~dp0check.dart" %*
