# Diagnose-PalRadar.ps1 - collects what matters when PalRadar shows nothing or the overlay stutters, and writes
# PalRadar-diagnostics.txt next to this script. Run it from the folder that holds PalRadar.exe, with the game running
# if the problem happens in game:   powershell -ExecutionPolicy Bypass -File .\Diagnose-PalRadar.ps1
# The report names your PC, user folders and player name. Read it before you send it to anyone.
param([string]$Exe = (Join-Path $PSScriptRoot 'PalRadar.exe'))
$ErrorActionPreference = 'Continue'
$lines = New-Object System.Collections.Generic.List[string]
function Say([string]$s) { $lines.Add($s); Write-Output $s }
function Head([string]$s) { Say ''; Say "== $s" }
function Flag([string]$s) { Say "  !! $s" }
function Age($path) { if (Test-Path $path) { '{0:N1} s old, {1} bytes' -f ((Get-Date) - (Get-Item $path).LastWriteTime).TotalSeconds, (Get-Item $path).Length } else { 'missing' } }

Head "PalRadar diagnostics $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$os = Get-CimInstance Win32_OperatingSystem
Say "  Windows $($os.Caption) build $($os.BuildNumber), $([int]($os.TotalVisibleMemorySize / 1MB)) GB RAM, PowerShell $($PSVersionTable.PSVersion)"
Say "  CPU $((Get-CimInstance Win32_Processor | Select-Object -First 1).Name)"
foreach ($g in Get-CimInstance Win32_VideoController) { Say "  GPU $($g.Name), driver $($g.DriverVersion) ($($g.DriverDate.ToString('yyyy-MM-dd')))" }
Add-Type -AssemblyName System.Windows.Forms
foreach ($s in [System.Windows.Forms.Screen]::AllScreens) { Say "  Monitor $($s.DeviceName) $($s.Bounds.Width)x$($s.Bounds.Height) at $($s.Bounds.X),$($s.Bounds.Y)$(if ($s.Primary) { ' primary' })" }
$dpi = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name LogPixels -ErrorAction SilentlyContinue).LogPixels
if ($dpi -and $dpi -ne 96) { Say "  Display scaling $([int](100 * $dpi / 96))%" }

Head 'PalRadar'
if (-not (Test-Path $Exe)) { Flag "PalRadar.exe not found at $Exe. Put this script next to it, or pass -Exe <path>."; }
else {
    $f = Get-Item $Exe
    Say "  $($f.FullName), version $($f.VersionInfo.ProductVersion), $([int]($f.Length / 1MB)) MB"
    if ($f.FullName -match '[^\u0000-\u007F]') { Flag 'The folder path has characters outside plain ASCII. The feed mod cannot write there: move PalRadar to a plain path.' }
    if ($f.FullName -like "$env:ProgramFiles*" -or $f.FullName -like "${env:ProgramFiles(x86)}*") { Flag 'PalRadar is under Program Files, where it cannot write its data or update itself.' }
    try { $t = Join-Path $f.DirectoryName ".write-test-$PID"; Set-Content $t 'x'; Remove-Item $t } catch { Flag "The folder is not writable: $($_.Exception.Message)" }
    foreach ($left in 'PalRadar.exe.old', 'PalRadar.exe.new') { if (Test-Path (Join-Path $f.DirectoryName $left)) { Say "  $left is present (normal right after an update)" } }
}
$dir = if (Test-Path $Exe) { (Get-Item $Exe).DirectoryName } else { $PSScriptRoot }
$data = Join-Path $dir 'data'
$procs = @(Get-Process -Name PalRadar -ErrorAction SilentlyContinue)
foreach ($proc in $procs) {
    Say "  Running: pid $($proc.Id) since $($proc.StartTime.ToString('HH:mm:ss')), $([int]($proc.WorkingSet64 / 1MB)) MB, $($proc.Path)"
    if ($proc.Path -and (Test-Path $Exe) -and $proc.Path -ne (Get-Item $Exe).FullName) { Flag "That running copy is not the one this report is about ($Exe). Two installs fight over the mod's feed path; keep one." }
}
if (-not $procs) { Say '  Not running' }
$log = Join-Path $dir 'hud.log'
if (Test-Path $log) {
    Say "  hud.log: $(Age $log)"
    $all = Get-Content $log
    foreach ($l in ($all | Where-Object { $_ -match 'update|feed mod|failed|not found|unavailable' } | Select-Object -Last 6)) { Say "    $l" }
    $perf = $all | Where-Object { $_ -match ' d2d mode ' } | Select-Object -Last 5
    if ($perf) {
        Say '  Overlay performance, last minutes (frames per minute, slowest frame, average frame, camera sample gap):'
        foreach ($l in $perf) {
            if ($l -match 'frames (\d+) slowest ([\d.]+) ms average ([\d.]+) ms .*sample gap ([\d.]+)-([\d.]+) ms \(mean ([\d.]+)\)') {
                $fps = [int]$matches[1] / 60
                Say ('    {0}  {1,4:N0} fps  slowest {2,6} ms  avg {3,6} ms  cam gap {4}-{5} ms (mean {6})' -f $l.Substring(0, 8), $fps, $matches[2], $matches[3], $matches[4], $matches[5], $matches[6])
                if ($fps -lt 55) { Flag 'Under 55 fps: the overlay is being throttled (GPU busy, window not composited, or power saving).' }
                if ([double]$matches[2] -gt 30) { Flag 'A frame over 30 ms: hitching. Check GPU driver and background apps.' }
                if ([double]$matches[6] -gt 25) { Flag 'Camera samples arrive slowly: the GAME is running under 40 fps, so markers will trail.' }
            } else { Say "    $l" }
        }
    } else { Say '  No performance lines yet (they appear once a minute while the overlay runs).' }
} else { Say '  hud.log missing: PalRadar has not run from this folder.' }

Head 'Data folder'
if (Test-Path $data) {
    Say "  $data"
    Say "  feed.json  $(Age (Join-Path $data 'feed.json'))   (should be under 1 s old while in a world)"
    Say "  cam.txt    $(Age (Join-Path $data 'cam.txt'))   (should be under 0.1 s old while in a world)"
    $feedPath = Join-Path $data 'feed.json'
    if (Test-Path $feedPath) {
        try { $j = Get-Content $feedPath -Raw | ConvertFrom-Json; Say "  feed: version $($j.v), level '$($j.level)', $(@($j.actors).Count) actors, mod $($j.mod)" } catch { Flag "feed.json does not parse: $($_.Exception.Message)" }
        if (((Get-Date) - (Get-Item $feedPath).LastWriteTime).TotalSeconds -gt 5 -and (Get-Process -Name 'Palworld-Win64-Shipping' -ErrorAction SilentlyContinue)) { Flag 'The game is running but the feed is stale: the mod is not running. See the Mod section.' }
    }
    Say "  pals\names.json $(if (Test-Path (Join-Path $data 'pals\names.json')) { 'present' } else { 'MISSING (delete site.stamp and start PalRadar again)' })"
    if (Test-Path (Join-Path $data 'hud.json')) { Say '  hud.json:'; foreach ($l in (Get-Content (Join-Path $data 'hud.json'))) { Say "    $l" } }
} else { Flag "No data folder at $data. PalRadar unpacks it on first start." }

Head 'Palworld'
$game = Get-Process -Name 'Palworld-Win64-Shipping' -ErrorAction SilentlyContinue
if ($game) {
    Say "  Running: pid $($game.Id) since $($game.StartTime.ToString('HH:mm:ss'))"
    if (-not ([System.Management.Automation.PSTypeName]'Diag.Win').Type) {
        Add-Type -Namespace Diag -Name Win -MemberDefinition '[DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h, int i); [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r); public struct RECT { public int L, T, R, B; }'
    }
    if ($game.MainWindowHandle -ne 0) {
        $style = [Diag.Win]::GetWindowLong($game.MainWindowHandle, -16); $r = New-Object 'Diag.Win+RECT'; [void][Diag.Win]::GetWindowRect($game.MainWindowHandle, [ref]$r)
        $caption = ($style -band 0x00C00000) -ne 0
        Say "  Window $($r.R - $r.L)x$($r.B - $r.T) at $($r.L),$($r.T), $(if ($caption) { 'with a title bar (windowed)' } else { 'borderless' })"
        $on = [System.Windows.Forms.Screen]::AllScreens | Where-Object { $_.Bounds.Width -eq ($r.R - $r.L) -and $_.Bounds.Height -eq ($r.B - $r.T) }
        if (-not $caption -and -not $on) { Flag 'Borderless window does not match any monitor size: if this is exclusive fullscreen, the overlay cannot draw over it. Use borderless windowed.' }
        if ($caption) { Say '  (Windowed mode works; markers are measured against the whole window including its border.)' }
    } else { Say '  No main window yet' }
} else { Say '  Not running (start the game and run this again for the live checks)' }
$steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath
$libs = @(); if ($steam) { $libs += $steam; $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'; if (Test-Path $vdf) { $libs += [regex]::Matches((Get-Content $vdf -Raw), '"path"\s+"([^"]+)"') | ForEach-Object { $_.Groups[1].Value.Replace('\\', '\') } } }
$gameDir = $libs | ForEach-Object { Join-Path $_ 'steamapps\common\Palworld' } | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($gameDir) { Say "  Folder $gameDir" } else { Flag 'Palworld was not found in any Steam library. Start PalRadar once with --game "<Palworld folder>".' }

Head 'Mod'
if ($gameDir) {
    $ue4ss = Join-Path $gameDir 'Mods\NativeMods\UE4SS'
    if (-not (Test-Path (Join-Path $ue4ss 'Mods'))) { Flag "No UE4SS Mods folder at $ue4ss. The game's official mod support is not installed or not enabled." }
    $main = Join-Path $ue4ss 'Mods\PalRadarFeed\Scripts\main.lua'
    if (Test-Path $main) {
        $src = Get-Content $main -Raw
        $ver = [regex]::Match($src, 'MOD_VERSION\s*=\s*"([^"]+)"').Groups[1].Value
        $fp = [regex]::Match($src, 'local FEED_PATH = "([^"]+)"').Groups[1].Value.Replace('\\', '\')
        Say "  PalRadarFeed $ver installed, enabled.txt $(if (Test-Path (Join-Path $ue4ss 'Mods\PalRadarFeed\enabled.txt')) { 'present' } else { 'MISSING' })"
        Say "  Mod writes to $fp"
        if ($fp -and $fp -ne (Join-Path $data 'feed.json')) { Flag "The mod writes to a different folder than this PalRadar reads ($data). Start PalRadar from its folder with the game closed to reinstall." }
    } else { Flag 'The feed mod is not installed. Start PalRadar once with the game closed.' }
    $ini = Join-Path $gameDir 'Mods\PalModSettings.ini'
    if (Test-Path $ini) { $en = Select-String -Path $ini -Pattern 'bGlobalEnableMod\s*=\s*(\w+)' | Select-Object -First 1; if ($en) { Say "  PalModSettings.ini bGlobalEnableMod = $($en.Matches[0].Groups[1].Value)"; if ($en.Matches[0].Groups[1].Value -ne 'True') { Flag 'Mods are disabled in the game. Enable them in Palworld > Mod Management, then restart the game.' } } }
    $ulog = Join-Path $ue4ss 'UE4SS.log'
    if (Test-Path $ulog) {
        Say "  UE4SS.log: $(Age $ulog)"
        $ul = @(Select-String -Path $ulog -Pattern 'PalRadarFeed|\[Lua\].*error' | Select-Object -Last 8)
        foreach ($l in $ul) { Say "    $($l.Line.Trim())" }
        $minute = $ul | Where-Object { $_.Line -match 'this minute: .*average ([\d.]+) ms' } | Select-Object -Last 1
        if ($minute -and [double]$matches[1] -gt 20) { Flag "The mod's tick averages $($matches[1]) ms on the game thread: that costs game frames. Report it with this file." }
    } else { Say '  No UE4SS.log: UE4SS has not run (mods off, or the game has not started since install).' }
}

Head 'Speech'
try { Add-Type -AssemblyName System.Speech; $v = (New-Object System.Speech.Synthesis.SpeechSynthesizer).GetInstalledVoices() | Where-Object { $_.Enabled }; Say "  $(@($v).Count) voice(s): $(($v | ForEach-Object { $_.VoiceInfo.Name }) -join ', ')"; if (@($v).Count -eq 0) { Flag 'No Windows voice installed: spoken alerts will be silent. Settings > Time & Language > Speech.' } }
catch { Flag "Speech check failed: $($_.Exception.Message)" }

$out = Join-Path $PSScriptRoot 'PalRadar-diagnostics.txt'
$lines | Set-Content $out -Encoding UTF8
Say ''; Say "Saved to $out. It contains your PC name, folders and player name; read it before sharing."
