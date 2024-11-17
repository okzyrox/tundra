@echo off

cd interpreter
cd src

nim c --out:..\..\bin\nb_debug.exe noba.nim