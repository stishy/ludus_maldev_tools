#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Re-enables Windows Defender, AMSI, and Windows Firewall.
    Use this before running tools that require AV/AMSI access (YARA, ThreatCheck, etc.)

.NOTES
    Run as Administrator. To disable again, run Disable-Defender.ps1.
#>

$ErrorActionPreference = 'Continue'

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Enabling Defender / AMSI / Firewall" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ─── Windows Defender ────────────────────────────────────────────────────────

Write-Host "[*] Removing DisableAntiSpyware policy key..." -ForegroundColor Yellow
try {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" `
        -Name DisableAntiSpyware -ErrorAction SilentlyContinue
    Write-Host "[+] DisableAntiSpyware policy removed" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not remove DisableAntiSpyware: $_" -ForegroundColor Red
}

Write-Host "[*] Re-enabling Defender real-time monitoring..." -ForegroundColor Yellow
try {
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
    Write-Host "[+] Real-time monitoring enabled" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not enable real-time monitoring: $_" -ForegroundColor Red
}

# ─── Cloud Protection + Sample Submission: intentionally left OFF ────────────
# Keeping these disabled so payloads in C:\Tools don't get fingerprinted/burnt.

Write-Host "[*] Enforcing cloud-delivered protection OFF (payload protection)..." -ForegroundColor Yellow
try {
    Set-MpPreference -MAPSReporting Disabled -ErrorAction Stop
    Write-Host "[+] Cloud protection remains OFF" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not set cloud protection: $_" -ForegroundColor Red
}

Write-Host "[*] Enforcing sample submission OFF (payload protection)..." -ForegroundColor Yellow
try {
    Set-MpPreference -SubmitSamplesConsent NeverSend -ErrorAction Stop
    Write-Host "[+] Sample submission remains OFF" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not set sample submission: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "[*] NOTE: C:\Tools exclusion is kept + cloud/sample submission stays OFF (payload safe)" -ForegroundColor Cyan

# ─── AMSI ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[*] Re-enabling AMSI..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\AMSI" `
        -Name Enabled -Value 1 -Type DWord -ErrorAction Stop
    Write-Host "[+] AMSI registry enabled" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not set AMSI registry: $_" -ForegroundColor Red
}

Write-Host "[*] Re-enabling Windows Script Host..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings" `
        -Name Enabled -Value 1 -Type DWord -ErrorAction Stop
    Write-Host "[+] Windows Script Host enabled" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not enable Windows Script Host: $_" -ForegroundColor Red
}

# ─── Windows Firewall ────────────────────────────────────────────────────────

Write-Host ""
Write-Host "[*] Re-enabling Windows Firewall (all profiles)..." -ForegroundColor Yellow
try {
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction Stop
    Write-Host "[+] Firewall enabled on all profiles" -ForegroundColor Green
} catch {
    Write-Host "[-] Could not enable firewall via cmdlet, trying netsh..." -ForegroundColor Yellow
    netsh advfirewall set allprofiles state on | Out-Null
    Write-Host "[+] Firewall enabled via netsh" -ForegroundColor Green
}

# ─── Done ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  Defender/AMSI/Firewall ENABLED" -ForegroundColor Green
Write-Host "  Cloud protection + sample submission: OFF (payloads safe)" -ForegroundColor Green
Write-Host "  Run Disable-Defender.ps1 to fully disable again" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to close"
