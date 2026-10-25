@echo off
rem ---------------------------------------------------------------------------
rem  scaler / output-timing / OSD regression
rem    [1] nearest   :  64x48   to 40x30   (fast, ratio 1.6 x 1.6)
rem    [2] nearest   : 1024x600 to 640x480 (one frame, deployment target ratio)
rem    [3] bilinear  :  64x40   to 40x32   (M2, ratio 1.6 x 1.25 = deployment)
rem    [4] out timing: 640x480 raster generator (video_out_timing)
rem    [5] fps OSD  : frame-rate meter + font overlay (fps_overlay)
rem    [6] gamma    : BRAM gamma LUT vs original register-file version (cycle-exact)
rem  requires iverilog in PATH or at D:\iverilog\bin
rem ---------------------------------------------------------------------------
setlocal
set IVERILOG=iverilog
set VVP=vvp
where %IVERILOG% >nul 2>nul || set IVERILOG=D:\iverilog\bin\iverilog.exe
where %VVP%      >nul 2>nul || set VVP=D:\iverilog\bin\vvp.exe
cd /d "%~dp0\.."

echo === [1/6] nearest  64x48 to 40x30 ===========================
%IVERILOG% -g2012 -o "%TEMP%\sim_scaler_small.vvp" rtl\scale\video_scaler_top.v tb\tb_video_scaler_top.v || exit /b 1
%VVP% "%TEMP%\sim_scaler_small.vvp" || exit /b 1

echo === [2/6] nearest  1024x600 to 640x480 ======================
%IVERILOG% -g2012 -o "%TEMP%\sim_scaler_real.vvp" rtl\scale\video_scaler_top.v tb\tb_video_scaler_real.v || exit /b 1
%VVP% "%TEMP%\sim_scaler_real.vvp" || exit /b 1

echo === [3/6] bilinear 64x40 to 40x32 (1.6 x 1.25) ==============
%IVERILOG% -g2012 -o "%TEMP%\sim_bilin.vvp" rtl\scale\video_scaler_bilinear.v tb\tb_video_scaler_bilinear.v || exit /b 1
%VVP% "%TEMP%\sim_bilin.vvp" || exit /b 1

echo === [4/6] out timing 640x480 raster =======================
%IVERILOG% -g2012 -o "%TEMP%\sim_timing.vvp" rtl\scale\video_out_timing.v tb\tb_video_out_timing.v || exit /b 1
%VVP% "%TEMP%\sim_timing.vvp" || exit /b 1

echo === [5/6] fps overlay (meter + font) =======================
%IVERILOG% -g2012 -o "%TEMP%\sim_fps.vvp" rtl\scale\fps_overlay.v tb\tb_fps_overlay.v || exit /b 1
%VVP% "%TEMP%\sim_fps.vvp" || exit /b 1

echo === [6/6] gamma equivalence (BRAM vs original) ================
%IVERILOG% -g2012 -o "%TEMP%\sim_gamma.vvp" rtl\gamma_conrrection\gamma_correction.v tb\gamma_correction_ref.v rtl\true_dual_port_ram.v tb\tb_gamma_equiv.v || exit /b 1
%VVP% "%TEMP%\sim_gamma.vvp" || exit /b 1

echo === done ===
