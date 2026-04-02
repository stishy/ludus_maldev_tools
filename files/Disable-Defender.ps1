#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Disables Windows Defender, AMSI, and Windows Firewall.
    Use this to return to maldev mode after testing with AV enabled.

.NOTES
    Run as Administrator. To re-enable, run Enable-Defender.ps1.
#>

$ErrorActionPreference = 'Continue'

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Disabling Defender / AMSI / Firewall" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ─── Windows Defender ────────────────────────────────────────────────────────

Write-Host "[*] Setting DisableAntiSpyware policy..." -ForegroundColor Yellow
try {
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name DisableAntiSpyware -Value 1 -Type DWord -ErrorAction Stop
    Write-Host "[+] DisableAntiSpyware policy set" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not set DisableAntiSpyware: $_" -ForegroundColor Red
}

Write-Host "[*] Disabling real-time monitoring..." -ForegroundColor Yellow
try {
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
    Write-Host "[+] Real-time monitoring disabled" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not disable real-time monitoring: $_" -ForegroundColor Red
}

Write-Host "[*] Disabling cloud-delivered protection..." -ForegroundColor Yellow
try {
    Set-MpPreference -MAPSReporting Disabled -ErrorAction Stop
    Write-Host "[+] Cloud protection disabled" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not disable cloud protection: $_" -ForegroundColor Red
}

Write-Host "[*] Disabling automatic sample submission..." -ForegroundColor Yellow
try {
    Set-MpPreference -SubmitSamplesConsent NeverSend -ErrorAction Stop
    Write-Host "[+] Sample submission disabled" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not disable sample submission: $_" -ForegroundColor Red
}

# ─── AMSI ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[*] Disabling AMSI..." -ForegroundColor Yellow
try {
    $amsiPath = "HKLM:\SOFTWARE\Microsoft\AMSI"
    if (-not (Test-Path $amsiPath)) { New-Item -Path $amsiPath -Force | Out-Null }
    Set-ItemProperty -Path $amsiPath -Name Enabled -Value 0 -Type DWord -ErrorAction Stop
    Write-Host "[+] AMSI registry disabled" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not disable AMSI registry: $_" -ForegroundColor Red
}

Write-Host "[*] Disabling Windows Script Host..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings" `
        -Name Enabled -Value 0 -Type DWord -ErrorAction Stop
    Write-Host "[+] Windows Script Host disabled" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not disable Windows Script Host: $_" -ForegroundColor Red
}

# ─── Windows Firewall ────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[*] Disabling Windows Firewall (all profiles)..." -ForegroundColor Yellow
try {
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False -ErrorAction Stop
    Write-Host "[+] Firewall disabled on all profiles" -ForegroundColor Green
} catch {
    Write-Host "[-] Trying netsh fallback..." -ForegroundColor Yellow
    netsh advfirewall set allprofiles state off | Out-Null
    Write-Host "[+] Firewall disabled via netsh" -ForegroundColor Green
}

# ─── Done ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "============================================" -ForegroundColor Red
Write-Host "  Defender/AMSI/Firewall DISABLED" -ForegroundColor Red
Write-Host "  Run Enable-Defender.ps1 to re-enable" -ForegroundColor Red
Write-Host "============================================" -ForegroundColor Red
Write-Host ""

Read-Host "Press Enter to close"
