@echo off
setlocal
cd /d "%~dp0.."
if not exist "work_sim_mix" mkdir "work_sim_mix"
iverilog -g2012 -o "work_sim_mix\style_mix_3ch.vvp" "rtl\style_accel\style_mix_3ch.v" "tb\tb_style_mix_3ch.v"
if errorlevel 1 exit /b 1
vvp "work_sim_mix\style_mix_3ch.vvp"
exit /b %errorlevel%