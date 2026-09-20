@echo off
setlocal enabledelayedexpansion
cls
echo.
echo #########################################
echo #    Marauder Flasher Script v2.80      #
echo #   By UberGuidoZ, original by Frog     #
echo #    Tweaked by ImprovingRigmarole      #
echo #    WROOM inspired by SkeletonMan      #
echo #########################################
echo. 

:: Basic error checks
IF NOT EXIST esptool.exe GOTO ESPERROR

set BR=921600

:SCAN_DEVICE
set "_com="
set "_dev_type="

for /f "tokens=1,2,3 delims=:" %%A in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0detect.ps1"') do (
    if "%%A"=="RESULT" (
        set "_dev_type=%%B"
        set "_com=%%C"
    ) else (
        echo %%A:%%B:%%C
    )
)

if "!_dev_type!"=="DEVBOARD_BOOT" (
    echo.
    echo Attempting to use serial port: !_com!
    GOTO CHOOSE_FW
)

if "!_dev_type!"=="DEVBOARD_NORMAL" (
    echo.
    echo --------------------------------------------------------------------------
    echo NOTICE: Device detected in NORMAL/RUNTIME mode (!_com!), not BOOT mode.
    echo --------------------------------------------------------------------------
    echo 1. Continue with !_com! anyway
    echo 2. Specify a COM port manually (e.g. COM4)
    echo 3. Rescan for connected devices (hold BOOT and reconnect USB first)
    echo 4. Exit
    echo.
    set /p choice_mode= Type choice (1-4) and hit enter: 
    if "!choice_mode!"=="1" GOTO CHOOSE_FW
    if "!choice_mode!"=="2" GOTO MANUAL_COM
    if "!choice_mode!"=="3" cls & GOTO SCAN_DEVICE
    if "!choice_mode!"=="4" GOTO ERREXIT
    echo Invalid choice.
    ping 127.0.0.1 -n 3 > NUL
    cls
    GOTO SCAN_DEVICE
)

if "!_dev_type!"=="WROOM" (
    echo.
    echo Attempting to use serial port: !_com!
    GOTO WROOM
)

if "!_dev_type!"=="OTHER" (
    echo.
    echo No ESP32-S2 or CP210x device automatically recognized.
    echo 1. Use detected port !_com!
    echo 2. Specify a COM port manually
    echo 3. Rescan for connected devices
    echo 4. Exit
    echo.
    set /p choice_other= Type choice (1-4) and hit enter: 
    if "!choice_other!"=="1" GOTO CHOOSE_TARGET
    if "!choice_other!"=="2" GOTO MANUAL_COM
    if "!choice_other!"=="3" cls & GOTO SCAN_DEVICE
    if "!choice_other!"=="4" GOTO ERREXIT
)

echo.
echo Cannot find ESP32-S2 DevBoard or WROOM (Marauder)!
echo.
echo Troubleshooting:
echo  * For ESP32-S2 DevBoard (native USB): Hold BOOT button while plugging in USB cable.
echo  * For WROOM boards: Make sure CP210x USB-to-UART drivers are installed.
echo  * Check USB cable (ensure it is data-capable, not charging-only).
echo.
echo Options:
echo 1. Specify a COM port manually
echo 2. Open Silicon Labs CP210x Drivers web page (for WROOM boards)
echo 3. Rescan for devices
echo 4. Exit
echo.
set /p choice_err= Type choice (1-4) and hit enter: 
if "!choice_err!"=="1" GOTO MANUAL_COM
if "!choice_err!"=="2" GOTO DRIVERS
if "!choice_err!"=="3" cls & GOTO SCAN_DEVICE
GOTO ERREXIT

:MANUAL_COM
echo.
set /p _com= Enter COM port (e.g. COM4): 
if "!_com!"=="" GOTO SCAN_DEVICE
echo Using manually specified serial port: !_com!

:CHOOSE_TARGET
echo.
echo Which board target are you flashing?
echo 1. ESP32-S2 DevBoard / Flipper Blackmagic
echo 2. Marauder WROOM
echo.
set /p choice_tgt= Type choice and hit enter: 
if "!choice_tgt!"=="1" GOTO CHOOSE_FW
if "!choice_tgt!"=="2" GOTO WROOM
echo Please choose 1 or 2!
ping 127.0.0.1 -n 3 > NUL
GOTO CHOOSE_TARGET


:CHOOSE_FW
echo.
echo Which action would you like to perform?
echo.
echo 1. Flash Marauder (no SD mod) to Devboard
echo 2. Flash Marauder (with SD mod) to Devboard
echo 3. Save Flipper Blackmagic WiFi settings
echo 4. Flash Flipper Blackmagic
echo 5. Download USB UART Drivers (Silicon Labs).
echo 6. Update Marauder BIN file (v1.0.0 included)
echo.
set choice_fw=
set /p choice_fw= Type choice and hit enter: 
if "!choice_fw!"=="1" GOTO MARAUDER
if "!choice_fw!"=="2" GOTO MARAUDERSD
if "!choice_fw!"=="3" GOTO BACKUP
if "!choice_fw!"=="4" GOTO FLIPPERBM
if "!choice_fw!"=="5" GOTO DRIVERS
if "!choice_fw!"=="6" GOTO UPDATE
echo Please choose 1, or 2!
ping 127.0.0.1 -n 5
cls
GOTO CHOOSE_FW

:MARAUDER
cls
echo.
echo #########################################
echo #    Marauder Flasher Script v2.80      #
echo #   By UberGuidoZ, original by Frog     #
echo #    Tweaked by ImprovingRigmarole      #
echo #    WROOM inspired by SkeletonMan      #
echo #########################################
echo. 
set last_firmware=
for /f "tokens=1" %%F in ('dir Marauder\esp32_marauder*flipper.bin /b /o-n') do set last_firmware=%%F
IF [!last_firmware!]==[] echo Please get and copy the last firmware from ESP32Marauder's Github Releases & GOTO ERREXIT
esptool.exe -p !_com! -b %BR% -c esp32s2 --before default_reset -a no_reset_stub erase_region 0x9000 0x6000
echo Firmware Erased, preparing write...
ping 127.0.0.1 -n 5 > NUL
esptool.exe -p !_com! -b %BR% -c esp32s2 --before default_reset -a no_reset_stub write_flash --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 Marauder\bootloader.bin 0x8000 Marauder\partitions.bin 0x10000 Marauder\!last_firmware!
GOTO DONE

:MARAUDERSD
cls
echo.
echo #########################################
echo #    Marauder Flasher Script v2.80      #
echo #   By UberGuidoZ, original by Frog     #
echo #    Tweaked by ImprovingRigmarole      #
echo #    WROOM inspired by SkeletonMan      #
echo #########################################
echo. 
echo  Make sure you have followed the instructions for your breakout board!
echo.
echo  Press any key to open a link to the instructions, then start the flashing process.
echo.
pause>nul
start https://github.com/justcallmekoko/ESP32Marauder/wiki/flipper-zero#sd-card-modification
echo.
set last_firmware=
for /f "tokens=1" %%F in ('dir Marauder\esp32_marauder*flipper.bin /b /o-n') do set last_firmware=%%F
IF [!last_firmware!]==[] echo Please get and copy the last firmware from ESP32Marauder's Github Releases & GOTO ERREXIT
esptool.exe -p !_com! -b %BR% -c esp32s2 --before default_reset -a no_reset_stub erase_region 0x9000 0x6000
echo Firmware Erased, preparing write...
ping 127.0.0.1 -n 5 > NUL
esptool.exe -p !_com! -b %BR% -c esp32s2 --before default_reset -a no_reset_stub write_flash --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 Marauder\bootloader.bin 0x8000 Marauder\partitions.bin 0x10000 Marauder\!last_firmware!
GOTO DONE

:BACKUP
cls
echo.
echo #########################################
echo #    Marauder Flasher Script v2.80      #
echo #   By UberGuidoZ, original by Frog     #
echo #    Tweaked by ImprovingRigmarole      #
echo #    WROOM inspired by SkeletonMan      #
echo #########################################
echo.
echo Saving Flipper Blackmagic WiFi Settings to "FlipperBlackmagic\nvs.bin"
esptool.exe -p !_com! -b %BR% -c esp32s2 -a no_reset_stub read_flash 0x9000 0x6000 FlipperBlackmagic\nvs.bin
GOTO DONE

:FLIPPERBM
cls
echo.
echo #########################################
echo #    Marauder Flasher Script v2.80      #
echo #   By UberGuidoZ, original by Frog     #
echo #    Tweaked by ImprovingRigmarole      #
echo #    WROOM inspired by SkeletonMan      #
echo #########################################
echo. 
IF EXIST FlipperBlackmagic\nvs.bin (
    echo Flashing Flipper Blackmagic with WiFi Settings restore
    esptool.exe -p !_com! -b %BR% -c esp32s2 --before default_reset -a no_reset_stub write_flash --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 FlipperBlackmagic\bootloader.bin 0x8000 FlipperBlackmagic\partition-table.bin 0x9000 FlipperBlackmagic\nvs.bin 0x10000 FlipperBlackmagic\blackmagic.bin
) ELSE (
    echo Flashing Flipper Blackmagic without WiFi Settings restore
    esptool.exe -p !_com! -b %BR% -c esp32s2 --before default_reset -a no_reset_stub erase_region 0x9000 0x6000
    echo Firmware Erased, preparing write...
    ping 127.0.0.1 -n 5 > NUL
    esptool.exe -p !_com! -b %BR% -c esp32s2 --before default_reset -a no_reset_stub write_flash --flash_mode dio --flash_freq 80m --flash_size 4MB 0x1000 FlipperBlackmagic\bootloader.bin 0x8000 FlipperBlackmagic\partition-table.bin 0x10000 FlipperBlackmagic\blackmagic.bin
)
GOTO DONE

:WROOM
echo.
echo Which action would you like to perform?
echo.
echo 1. Flash Marauder WROOM (including older v4 OEM).
echo 2. Update Marauder BIN file (v1.0.0 included).
echo 3. Download USB UART Drivers (Silicon Labs).
echo.
set choice=
set /p choice= Type choice and hit enter: 
if "!choice!"=="1" GOTO WRMARAUDER
if "!choice!"=="2" GOTO WRUPDATE
if "!choice!"=="3" GOTO DRIVERS
echo Please choose 1, 2, or 3!
ping 127.0.0.1 -n 5
cls
GOTO CHOOSE

:WRMARAUDER
cls
echo.
echo #########################################
echo #    Marauder Flasher Script v2.80      #
echo #   By UberGuidoZ, original by Frog     #
echo #    Tweaked by ImprovingRigmarole      #
echo #    WROOM inspired by SkeletonMan      #
echo #########################################
echo. 
set last_firmware=
for /f "tokens=1" %%F in ('dir WROOM\esp32_marauder*_old_hardware.bin /b /o-n') do set last_firmware=%%F
IF [!last_firmware!]==[] echo Please get and copy the last firmware from ESP32Marauder's Github Releases & GOTO ERREXIT
esptool.exe -p !_com! -b %BR% -c esp32 --before default_reset -a no_reset erase_region 0x9000 0x6000
echo Firmware Erased, preparing write...
ping 127.0.0.1 -n 3 > NUL
esptool.exe -p !_com! -b %BR% --before default_reset -a hard_reset -c esp32 write_flash --flash_mode dio --flash_freq 80m --flash_size 2MB 0x1000 WROOM\bootloader.bin 0x8000 WROOM\partitions.bin 0x10000 WROOM\!last_firmware! 0xE000 WROOM\boot_app.bin
GOTO WRDONE

:WRUPDATE
cls
echo.
echo #########################################
echo #    Marauder Flasher Script v2.80      #
echo #   By UberGuidoZ, original by Frog     #
echo #    Tweaked by ImprovingRigmarole      #
echo #    WROOM inspired by SkeletonMan      #
echo #########################################
echo.
echo Please download OLD_HARDWARE.BIN file to WROOM folder, delete any other BIN files, and rerun Flasher.
echo.
echo Press any key to open Marauder download location in default browser...
pause>NUL
start https://github.com/justcallmekoko/ESP32Marauder/releases/latest
GOTO ERREXIT

:DRIVERS
cls
echo.
echo #########################################
echo #    Marauder Flasher Script v2.80      #
echo #   By UberGuidoZ, original by Frog     #
echo #    Tweaked by ImprovingRigmarole      #
echo #    WROOM inspired by SkeletonMan      #
echo #########################################
echo.
echo Please download and install the correct drivers and rerun Flasher.
echo.
echo Press any key to open driver download location in default browser...
pause>NUL
start https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
GOTO ERREXIT

:UPDATE
cls
echo.
echo #########################################
echo #    Marauder Flasher Script v2.80      #
echo #   By UberGuidoZ, original by Frog     #
echo #    Tweaked by ImprovingRigmarole      #
echo #    WROOM inspired by SkeletonMan      #
echo #########################################
echo.
echo Please download the correct flipper BIN file to Marauder or SD folder,
echo delete any other BIN files, and rerun Flasher...
echo.
echo Press any key to open Marauder download location in default browser...
pause>NUL
start https://github.com/justcallmekoko/ESP32Marauder/releases/latest
GOTO ERREXIT

:DONE
echo.
echo -------------------------------------------------------------------------------------------
echo Process has completed! Please disconnect your Devboard and connect it to your Flipper Zero.
echo -------------------------------------------------------------------------------------------
echo.
echo ==========================================================================
echo ERRORS ABOVE MAY BE NORMAL - Please ignore them for now and give it a try.
echo ==========================================================================
echo.
echo (You may now close this window or press any key to exit.)
pause>nul
exit

:WRDONE
echo.
echo ---------------------------------------------------------------
echo Process has completed. Device may reboot to finish the update.
echo Otherwise, disconnect the device and plug it into your Flipper!
echo ---------------------------------------------------------------
echo.
echo ==========================================================================
echo ERRORS ABOVE MAY BE NORMAL - Please ignore them for now and give it a try.
echo ==========================================================================
echo.
echo (You may now close this window or press any key to exit.)
pause>nul
exit

:ESPERROR
echo esptool.exe is missing. Please download and extract the full package.
GOTO ERREXIT

:ERREXIT
echo.
echo (You may now close this window or press any key to exit.)
pause>nul
exit