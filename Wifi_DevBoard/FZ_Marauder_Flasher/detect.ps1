# detect.ps1 - ESP32 COM Port Detector for Marauder Flasher v2.80
# Searches for serial ports via CIM Win32_SerialPort and Win32_PnPEntity

$ports = @()

# 1. Query Win32_SerialPort
Get-CimInstance Win32_SerialPort -ErrorAction SilentlyContinue | ForEach-Object {
    $pnp = $_.PNPDeviceID
    $com = $_.DeviceID
    $name = $_.Name
    $devVid = ''
    $devPid = ''
    if ($pnp -match 'VID_([0-9A-Fa-f]{4})') { $devVid = $Matches[1].ToUpper() }
    if ($pnp -match 'PID_([0-9A-Fa-f]{4})') { $devPid = $Matches[1].ToUpper() }
    $ports += [PSCustomObject]@{ COM=$com; VID=$devVid; PID=$devPid; PNP=$pnp; Name=$name }
}

# 2. Query Win32_PnPEntity for any ports not captured by Win32_SerialPort
Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.PNPClass -eq 'Ports' -or $_.Name -match '\(COM\d+\)' } | ForEach-Object {
    if ($_.Name -match '\((COM\d+)\)') {
        $com = $Matches[1]
        if (-not ($ports | Where-Object { $_.COM -eq $com })) {
            $pnp = $_.DeviceID
            $name = $_.Name
            $devVid = ''
            $devPid = ''
            if ($pnp -match 'VID_([0-9A-Fa-f]{4})') { $devVid = $Matches[1].ToUpper() }
            if ($pnp -match 'PID_([0-9A-Fa-f]{4})') { $devPid = $Matches[1].ToUpper() }
            $ports += [PSCustomObject]@{ COM=$com; VID=$devVid; PID=$devPid; PNP=$pnp; Name=$name }
        }
    }
}

Write-Host "Scanning for connected ESP32 devices..."
Write-Host ""

$bootDevice = $ports | Where-Object { $_.VID -eq '303A' -and $_.PID -eq '0002' } | Select-Object -First 1
$normalDevices = $ports | Where-Object { $_.VID -eq '303A' -and $_.PID -ne '0002' }
$wroomDevices = $ports | Where-Object { $_.VID -eq '10C4' }

if ($bootDevice) {
    Write-Host "ESP32-S2 boot/download device found:"
    Write-Host "  $($bootDevice.COM) - VID_$($bootDevice.VID) / PID_$($bootDevice.PID)"
    Write-Host ""
    Write-Host "RESULT:DEVBOARD_BOOT:$($bootDevice.COM)"
    exit 0
}

if ($normalDevices) {
    Write-Host "Espressif USB runtime device(s) found (NORMAL MODE):"
    foreach ($dev in $normalDevices) {
        Write-Host "  $($dev.COM) - VID_$($dev.VID) / PID_$($dev.PID)"
    }
    Write-Host ""
    Write-Host "WARNING: ESP32-S2 boot/download mode interface (PID_0002) not detected!"
    Write-Host "Please hold the BOOT button while plugging in the USB cable to enter download mode."
    Write-Host ""
    Write-Host "RESULT:DEVBOARD_NORMAL:$($normalDevices[0].COM)"
    exit 0
}

if ($wroomDevices) {
    $wroom = $wroomDevices | Select-Object -First 1
    Write-Host "Silicon Labs CP210x device found (WROOM):"
    Write-Host "  $($wroom.COM) - VID_$($wroom.VID) / PID_$($wroom.PID)"
    Write-Host ""
    Write-Host "RESULT:WROOM:$($wroom.COM)"
    exit 0
}

if ($ports.Count -gt 0) {
    Write-Host "Other serial port(s) found:"
    foreach ($dev in $ports) {
        Write-Host "  $($dev.COM) - $($dev.Name) (VID_$($dev.VID) / PID_$($dev.PID))"
    }
    Write-Host ""
    Write-Host "RESULT:OTHER:$($ports[0].COM)"
    exit 0
}

Write-Host "No serial ports found."
Write-Host "RESULT:NONE:"
exit 1
