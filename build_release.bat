@echo off

cd interpreter
cd src

nim c -d:release --opt:speed --app:console --out:..\..\bin\nb.exe noba.nim