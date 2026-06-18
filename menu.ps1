function CheckForUpdate {

    $versionUrl = "https://files.catbox.moe/9dml3t.txt"
    $scriptUrl  = "https://files.catbox.moe/25mqge.ps1"

    try {
        $remoteVersion = (Invoke-WebRequest $versionUrl -UseBasicParsing).Content.Trim()

        if ([version]$remoteVersion -gt [version]$global:Version) {

            Write-Host "`nUpdate found: $remoteVersion" -ForegroundColor Yellow
            Write-Host "Downloading update..." -ForegroundColor Cyan

            $tempFile = "$PSScriptRoot\menu_update.ps1"

            Invoke-WebRequest $scriptUrl -OutFile $tempFile -UseBasicParsing

            Write-Host "Restarting launcher..." -ForegroundColor Green

            Start-Process powershell "-ExecutionPolicy Bypass -File `"$tempFile`""
            exit
        }
    }
    catch {
        Write-Host "Update check failed (offline mode)." -ForegroundColor DarkYellow
    }
}

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class ConsoleWindow {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int W, int H, bool Repaint);
}
"@

$hwnd = [ConsoleWindow]::GetConsoleWindow()

# 1280x720 window size (screen pixels)
[ConsoleWindow]::MoveWindow($hwnd, 100, 100, 1280, 720, $true)
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll")]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll")]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    public const int GWL_STYLE = -16;
    public const int WS_SIZEBOX = 0x00040000;
    public const int WS_MAXIMIZEBOX = 0x00010000;
}
"@

$hwnd = [ConsoleWindow]::GetConsoleWindow()

$style = [Win32]::GetWindowLong($hwnd, [Win32]::GWL_STYLE)

# Remove resize border + maximize button
$style = $style -band (-bnot [Win32]::WS_SIZEBOX)
$style = $style -band (-bnot [Win32]::WS_MAXIMIZEBOX)

[Win32]::SetWindowLong($hwnd, [Win32]::GWL_STYLE, $style)
$gamesFolder = "$PSScriptRoot\Games"
New-Item -ItemType Directory -Force -Path $gamesFolder | Out-Null

# =========================
# STATE
# =========================
$global:cancelDownload = $false
$global:inDownload = $false
$global:gameRunning = $false
$global:deleteMode = $false

$global:Version = "1.0.3"

Write-Host "Checking for updates..." -ForegroundColor Green
CheckForUpdate

# =========================
# VERSION DATABASE
# =========================
$versions = @(
    @{
        Name="Gooner-Alpha (2018)"
        Url="1r4yuPqKtFlPQAwXCFj7lcRgL9ztzRniE"
        Type="drive"
        Folder="Pre-Alpha (2018)"
    },
    @{
        Name="Halloween Alpha (2018)"
        Url="1dtDOk6-grSH9hg4ZazcjGhfY93XcVYjZ"
        Type="drive"
        Folder="Halloween Alpha (2018)"
    },

    # NEW PLACEHOLDERS
    @{
        Name="Christmas Alpha (2018)"
        Url="1RT9IGThWNjQsvV0K9bDEpn74Y1zHM9t3"
        Type="drive"
        Folder="Christmas Alpha (2018)"
    },
    @{
        Name="Easter Alpha (2019)"
        Url="1oVkWwe8a50t14uMcL9LmQ98dUT70VK1x"
        Type="drive"
        Folder="Easter Alpha"
    },
    @{
        Name="Beta (2019)"
        Url="1gxQD7z6yUtgOn-uCzTRJH-0V4htHpxps"
        Type="drive"
        Folder="Beta (2019)"
    },
    @{
        Name="Halloween 2019"
        Url="1BaBawLUmlg_kbYitTWbGPW0m6a-it7sn"
        Type="drive"
        Folder="Halloween 2019"
    },
    @{
        Name="Christmas 2019"
        Url="1bdho6d-iL07xmyVg6DE_NjWcIPfY2f9n"
        Type="drive"
        Folder="Xmas 2019"
    },
    @{
        Name="Emotes Update (2020)"
        Url="1qbPzTghDFn8WtzrgQemE3fLO3spR0Z6J"
        Type="drive"
        Folder="Emotes Update (2020)"
    },
    @{
        Name="Easter 2020 (Last version with old ambience)"
        Url="1Emcf5eY6eTLtFTuwk8yMEbWgRm_dhqog"
        Type="drive"
        Folder="Easter 2020"
    },
     @{
        Name="Summer 2020 (LEVEL EDITOR!)"
        Url="1whu3sKw4uQoj72DD3mvELIKOb6YKfipO"
        Type="drive"
        Folder="Summer 2020"
    },
    @{
        Name="Rocket Science (2020, ROCKET EVENT!)"
        Url="1whu3sKw4uQoj72DD3mvELIKOb6YKfipO"
        Type="drive"
        Folder="Rocket Science (2020)"
    },
     @{
        Name="Christmas 2020"
        Url="1bzVtdhKjtCq7P75PDFYYzSaBxwIiggr4"
        Type="drive"
        Folder="Christmas 2020"
    },
    @{
        Name="Easter 2021"
        Url="1g4BAhQHTwBGUHFrbEdhr68_mwtr337kJ"
        Type="drive"
        Folder="Easter 2021"
    },
    @{
        Name="Summer 2021"
        Url="1Dfq5tC0Vw1xqr5opaFyoDsmaB3RNFuP6"
        Type="drive"
        Folder="Summer 2021"
    },
    @{
        Name="Paranormal Update (2021)"
        Url="1kcwZQDQasUZdaDgyhbVbd1nhR2ZXXnKp"
        Type="drive"
        Folder="Paranormal Update (2021)"
    }

)

$index = 0

# =========================
# MENU
# =========================
function DrawMenu {

    [Console]::SetCursorPosition(0,0)
    Write-Host "https://discord.gg/64tSXUurQC                                           Project BU v1.03 UPDATER TEST"
    Write-Host "  _____  _____   ____       _ ______ _____ _______      
 |  __ \|  __ \ / __ \     | |  ____/ ____|__   __|     
 | |__) | |__) | |  | |    | | |__ | |       | |        
 |  ___/|  _  /| |  | |_   | |  __|| |       | |        
 | |    | | \ \| |__| | |__| | |___| |____   | |        
 |_|    |_|  \_\\____/ \____/|______\_____|__|_| _    _ 
                                          |  _ \| |  | |
                                          | |_) | |  | |
                                          |  _ <| |  | |
                                          | |_) | |__| |
                                          |____/ \____/ 
                                                        
                                                        " -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $versions.Count; $i++) {

        $v = $versions[$i]
        $path = "$gamesFolder\$($v.Folder)"

        $label = "Download $($v.Name)"

        if (Test-Path $path) {
            $exe = Get-ChildItem $path -Recurse -Filter *.exe -ErrorAction SilentlyContinue |
                   Select-Object -First 1

            if ($exe) {

    if ($global:deleteMode -and $i -eq $index) {
        $label = "Delete $($v.Name)"
    }
    elseif ($global:gameRunning -eq $i) {
        $label = "Playing $($v.Name)"
    }
    else {
        $label = "Play $($v.Name)"
    }
}
        }

        if ($i -eq $index) {
            Write-Host " > $label" -ForegroundColor Green
        } else {
            Write-Host "   $label"
        }
    }

    Write-Host ""
    Write-Host "Use ↑ ↓ arrows, Enter to select"
}

# =========================
# DRIVE SUPPORT
# =========================
function GetDriveUrl($id) {
    return "https://drive.google.com/uc?export=download&id=$id"
}

function DownloadGoogleDriveFile($fileId, $zipPath)
{
    Add-Type -AssemblyName System.Net.Http

    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.AllowAutoRedirect = $true

    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromHours(1)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0")

    # Initial request (may return confirmation page)
    $response = $client.GetAsync("https://drive.google.com/uc?export=download&id=$fileId").Result
    $html = $response.Content.ReadAsStringAsync().Result

    $uuid = [regex]::Match($html,'name="uuid"\s+value="([^"]+)"').Groups[1].Value

    if (-not $uuid) {
        throw "Failed to find Google Drive UUID."
    }

    $downloadUrl =
        "https://drive.usercontent.google.com/download" +
        "?id=$fileId&export=download&confirm=t&uuid=$uuid"

    $response = $client.GetAsync($downloadUrl, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
    $stream = $response.Content.ReadAsStreamAsync().Result

    $fileStream = [System.IO.File]::Create($zipPath)

    $buffer = New-Object byte[] 65536
    $total = $response.Content.Headers.ContentLength
    $downloaded = 0

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    while (($read = $stream.Read($buffer, 0, $buffer.Length)) -gt 0)
    {
        if (CheckCancelKey) {
            Write-Host "`nDownload cancelled." -ForegroundColor Red
            $fileStream.Close()
            $stream.Close()
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            return
        }

        $fileStream.Write($buffer, 0, $read)
        $downloaded += $read

        $elapsed = $stopwatch.Elapsed.TotalSeconds
        if ($elapsed -gt 0) {

            $speed = $downloaded / $elapsed

            if ($speed -gt 1GB) {
                $speedText = "{0:N2} GB/s" -f ($speed / 1GB)
            }
            elseif ($speed -gt 1MB) {
                $speedText = "{0:N2} MB/s" -f ($speed / 1MB)
            }
            else {
                $speedText = "{0:N0} KB/s" -f ($speed / 1KB)
            }

            if ($total -gt 0) {
                $percent = [math]::Floor(($downloaded / $total) * 100)
                $bar = ("#" * ([math]::Floor($percent / 2))).PadRight(50, "-")

                Write-Host -NoNewline "`r[$bar] $percent%  $speedText"
            }
            else {
                Write-Host -NoNewline "`rDownloaded: $speedText"
            }
        }
    }

    $fileStream.Close()
    $stream.Close()

    Write-Host "`nDownload complete!" -ForegroundColor Green
}

# =========================
# CANCEL CHECK
# =========================
function CheckCancelKey {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq "Enter") {
            return $true
        }
    }
    return $false
}

# =========================
# ZIP VALIDATION
# =========================
function ValidateZip($zipPath) {
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::OpenRead($zipPath).Dispose()
        return $true
    } catch {
        return $false
    }
}

# =========================
# INSTALL GAME
# =========================
function InstallGame($v) {

    if ($global:gameRunning) {
        Write-Host ""
        Write-Host "A game is already running. Close it first." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    $zipPath = "$gamesFolder\$($v.Folder).zip"
    $outDir  = "$gamesFolder\$($v.Folder)"

    $global:cancelDownload = $false
    $global:inDownload = $true

    try {

        $url = if ($v.Type -eq "drive") { GetDriveUrl $v.Url } else { $v.Url }

        if ($v.Type -eq "drive")
{
    DownloadGoogleDriveFile $v.Url $zipPath

    Write-Host ""
    Write-Host "Download complete!" -ForegroundColor Green

    if (Test-Path $outDir) {
        Remove-Item $outDir -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $outDir -Force
    Remove-Item $zipPath -Force

    Write-Host "Installed!" -ForegroundColor Green
    return
}

        if ($url -eq "test") {
            Write-Host ""
            Write-Host "This version is not available yet." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return
        }

        Write-Host ""
        Write-Host "Downloading $($v.Name)..." -ForegroundColor Yellow
        Write-Host "Press ENTER to cancel" -ForegroundColor Red

        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

Add-Type -AssemblyName System.Net.Http

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $true

$client = New-Object System.Net.Http.HttpClient($handler)
$client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0")

$client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0")

$response = $client.GetAsync($url).Result

# Handle Google Drive large file confirmation page
if ($response.Content.Headers.ContentType.MediaType -like "*html*") {

    $html = $response.Content.ReadAsStringAsync().Result

    if ($html -match 'confirm=([0-9A-Za-z\-_]+)') {

        $token = $matches[1]

        if ($url -match 'id=([^&]+)') {

            $fileId = $matches[1]

            $confirmUrl =
                "https://drive.google.com/uc?export=download&confirm=$token&id=$fileId"

            $response = $client.GetAsync($confirmUrl).Result
        }
    }
}

if (-not $response.IsSuccessStatusCode) {
    throw "HTTP Error: $($response.StatusCode)"
}

        
        $fileStream = [System.IO.File]::Create($zipPath)

        $buffer = New-Object byte[] 65536
        $total = $response.ContentLength
        $downloaded = 0

        while (($read = $stream.Read($buffer,0,$buffer.Length)) -gt 0) {

            if (CheckCancelKey) {
                $global:cancelDownload = $true
            }

            if ($global:cancelDownload) {

                Write-Host ""
                Write-Host "Download cancelled." -ForegroundColor Red

                $fileStream.Close()
                $stream.Close()
                $response.Close()

                Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

                $global:cancelDownload = $false
                $global:inDownload = $false
                return
            }

            $fileStream.Write($buffer,0,$read)
            $downloaded += $read

            if ($total -gt 0) {
                $percent = [math]::Floor(($downloaded / $total) * 100)
                $bar = ("#" * ([math]::Floor($percent/2))).PadRight(50,"-")
                Write-Host -NoNewline "`r[$bar] $percent% "
            }
        }

        $fileStream.Close()
        $stream.Close()
        $response.Close()

        $global:inDownload = $false

        Write-Host ""
        Write-Host "Download complete!" -ForegroundColor Green

        if (-not (ValidateZip $zipPath)) {
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
            throw "Broken ZIP detected"
        }

        if (Test-Path $outDir) {
            Remove-Item $outDir -Recurse -Force
        }

        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        Expand-Archive -Path $zipPath -DestinationPath $outDir -Force
        Remove-Item $zipPath -Force

        Write-Host "Installed!" -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "Install error: $($_.Exception.Message)" -ForegroundColor Red
        $global:inDownload = $false
    }
}

# =========================
# LAUNCH GAME
# =========================
function LaunchGame($v, $i) {

    if ($global:gameRunning) {
        Write-Host ""
        Write-Host "A game is already running." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    $path = "$gamesFolder\$($v.Folder)"

    $exe = Get-ChildItem $path -Recurse -Filter *.exe -ErrorAction SilentlyContinue |
           Select-Object -First 1

    if ($exe) {
        Write-Host ""
        Write-Host "Launching $($v.Name)..." -ForegroundColor Cyan

        $global:gameRunning = $i

        $proc = Start-Process $exe.FullName -PassThru
        $proc.WaitForExit()

        $global:gameRunning = $false
    }
}

function DeleteVersion($v) {

    $path = "$gamesFolder\$($v.Folder)"

    if (Test-Path $path) {

        Remove-Item $path -Recurse -Force

        Write-Host ""
        Write-Host "$($v.Name) deleted." -ForegroundColor Green
        Write-Host "You must download it again to play."
        Start-Sleep -Seconds 2
    }
}

# =========================
# MAIN LOOP
# =========================
while ($true) {

    DrawMenu

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    if ($global:inDownload -and $key.VirtualKeyCode -eq 13) {
        $global:cancelDownload = $true
        continue
    }

    switch ($key.VirtualKeyCode) {

    38 {
        $index--
        if ($index -lt 0) { $index = $versions.Count - 1 }
        $global:deleteMode = $false
    }

    40 {
        $index++
        if ($index -ge $versions.Count) { $index = 0 }
        $global:deleteMode = $false
    }

    39 {

        $v = $versions[$index]

        if (Test-Path "$gamesFolder\$($v.Folder)") {
            $global:deleteMode = $true
        }
    }

    37 {
        $global:deleteMode = $false
    }

    13 {

    $v = $versions[$index]

    if ($global:deleteMode) {

        [Console]::SetCursorPosition(0,0)
        Write-Host ""
        Write-Host "Delete $($v.Name)?"
        Write-Host ""
        Write-Host "Are you sure? Y/N"

        $confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        if ($confirm.Character -eq 'Y' -or $confirm.Character -eq 'y') {
            DeleteVersion $v
        }

        $global:deleteMode = $false
    }
    else {

        if (Test-Path "$gamesFolder\$($v.Folder)") {
            LaunchGame $v $index
        }
        else {
            InstallGame $v
        }
    }
}
    }
}
