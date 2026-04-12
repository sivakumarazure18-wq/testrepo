param(
    [string]$Repo1Url = "https://github.com/sivakumarazure18-wq/RAG_CHAT_APP.git",
    [string]$Repo2Url = "https://github.com/sivakumarazure18-wq/RAG_CHAT_APP.git",
    [string[]]$FilesToCopy = @("config.json", "credentials.template")
)

#Requires -RunAsAdministrator

# ============================================================
# PATHS (ALL ON DESKTOP)
# ============================================================
$Desktop   = "C:\Users\Public\Desktop"
$Repo1Dest = Join-Path $Desktop "rag-chat-app"
$Repo2Dest = Join-Path $Desktop "ai-evaluator-tool"
$LogFile   = "C:\Windows\Temp\CSE_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# ============================================================
# LOGGING
# ============================================================
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')][$Level] $Message"
    Write-Output $line
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

# ============================================================
# INSTALL CHOCOLATEY
# ============================================================
function Install-Choco {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Log "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
}

# ============================================================
# INSTALL GIT
# ============================================================
function Install-Git {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Log "Installing Git..."
        Install-Choco
        choco install git -y --no-progress
    }
}

# ============================================================
# CLONE REPO
# ============================================================
function Clone-Repo {
    param($Url, $Destination)

    if (Test-Path $Destination) {
        Write-Log "Repo exists: $Destination"
        return
    }

    Write-Log "Cloning $Url → $Destination"
    git clone --depth 1 $Url $Destination
}

# ============================================================
# COPY FILES
# ============================================================
function Copy-Files {
    param($Source, $Files)

    foreach ($file in $Files) {
        $src = Join-Path $Source $file
        $dst = Join-Path $Desktop $file

        if (Test-Path $src) {
            Copy-Item $src $dst -Force
            Write-Log "Copied $file to Desktop"
        } else {
            Write-Log "File missing: $src" "WARN"
        }
    }
}

# ============================================================
# INSTALL CHROME
# ============================================================
function Install-Chrome {
    $chrome = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"
    if (-not (Test-Path $chrome)) {
        Write-Log "Installing Chrome..."
        Install-Choco
        choco install googlechrome -y --no-progress
    }
}

# ============================================================
# INSTALL EDGE
# ============================================================
function Install-Edge {
    $edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    if (-not (Test-Path $edge)) {
        Write-Log "Installing Edge..."
        $msi = "$env:TEMP\edge.msi"
        $url = "https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/MicrosoftEdgeEnterpriseX64.msi"
        (New-Object Net.WebClient).DownloadFile($url, $msi)
        Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn /norestart" -Wait
    }
}

# ============================================================
# CREATE SHORTCUT (FIXED)
# ============================================================
function Create-Shortcut {
    $shortcutPath = Join-Path $Desktop "Azure Portal.lnk"

    if (Test-Path $shortcutPath) {
        Write-Log "Shortcut already exists"
        return
    }

    $edgePath = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $edgePath) {
        Write-Log "Edge not found, cannot create shortcut" "WARN"
        return
    }

    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = $edgePath
        $Shortcut.Arguments  = "https://portal.azure.com"
        $Shortcut.WorkingDirectory = Split-Path $edgePath
        $Shortcut.Save()
        Write-Log "Shortcut created successfully"
    }
    catch {
        Write-Log "Shortcut creation failed: $_" "ERROR"
    }
}

# ============================================================
# MAIN
# ============================================================
try {
    Write-Log "===== START ====="

    Install-Git

    Clone-Repo $Repo1Url $Repo1Dest
    Clone-Repo $Repo2Url $Repo2Dest

    Copy-Files $Repo1Dest $FilesToCopy

    Install-Chrome
    Install-Edge

    Create-Shortcut

    Write-Log "===== COMPLETED ====="
}
catch {
    Write-Log "ERROR: $_" "ERROR"
}cd