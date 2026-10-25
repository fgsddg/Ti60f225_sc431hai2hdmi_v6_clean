@echo off
setlocal
cd /d "%~dp0.."
if not exist "work_sim_mix" mkdir "work_sim_mix"
iverilog -g2012 -o "work_sim_mix\style_hud_overlay.vvp" "rtl\scale\style_hud_font.v" "rtl\scale\style_hud_overlay.v" "tb\tb_style_hud_overlay.v"
if errorlevel 1 exit /b 1
vvp "work_sim_mix\style_hud_overlay.vvp"
exit /b %errorlevel%