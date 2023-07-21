<#
    .SYNOPSIS 
    Windows 10 Software packaging wrapper

    .DESCRIPTION
    C:\Windows\SysNative\WindowsPowershell\v1.0\PowerShell.exe -ExecutionPolicy Bypass -Command .\Invoke-DellBloatware-Removal.ps1
    
    .ENVIRONMENT
    PowerShell 5.0
    
    .AUTHOR
    Niklas Rast
#>

$ErrorActionPreference = "SilentlyContinue"
$logFile = ('{0}\{1}.log' -f "C:\Windows\Logs", [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name))

#Test if registry folder exists
if ($true -ne (test-Path -Path "HKLM:\SOFTWARE\COMPANY")) {
    New-Item -Path "HKLM:\SOFTWARE\" -Name "COMPANY" -Force
}

Start-Transcript -path $logFile -Append

#Get Dell Services and Stop them and prevent them to Startup automatically
$DellServices = (Get-Service | ? DisplayName -match "Dell").Name
foreach ($item in $DellServices)
{
    Write-Host "Stopping and Disabling Service $item"
    Stop-Service -Name $item -Force
    Set-Service -Name $item -StartupType Disabled
}

#Query for DELL Software and remove it
$DellSoftwareMSI = (gwmi win32_product | where Name -match Dell).IdentifyingNumber
foreach ($item in $DellSoftwareMSI)
{
    Write-Host "Removing $item ..."
    $CleanupArgs = "/x $item /q"
    Start-Process -FilePath "msiexec" -ArgumentList $CleanupArgs -Wait
}

#Query for NON-MSI Software to remove
Write-Host "Removing DELLOptimizer ..."
try {
    if ($true -eq (Test-Path -Path "C:\Program Files (x86)\InstallShield Installation Information\{286A9ADE-A581-43E8-AA85-6F5D58C7DC88}\DellOptimizer.exe")) {
        Start-Process -FilePath "C:\Program Files (x86)\InstallShield Installation Information\{286A9ADE-A581-43E8-AA85-6F5D58C7DC88}\DellOptimizer.exe" -ArgumentList "-remove -silent" -Wait
    } else {
        Write-Host "DellOptimizer.exe not found"
    }
    
}
catch {
    Write-Host "DellOptimizer.exe not found"
}

Write-Host "Removing DELLSupportAssist ..."
try {
    if ($true -eq (Test-Path -Path "C:\ProgramData\Package Cache\{2a8bafd6-22ae-4d0e-87a4-686b2a4a2ab0}\DellUpdateSupportAssistPlugin.exe")) {
        Start-Process -FilePath "C:\ProgramData\Package Cache\{2a8bafd6-22ae-4d0e-87a4-686b2a4a2ab0}\DellUpdateSupportAssistPlugin.exe" -ArgumentList "/uninstall /quiet" -Wait
    } else {
        Write-Host "DellUpdateSupportAssistPlugin.exe not found"
    }
}
catch {
    Write-Host "DellUpdateSupportAssistPlugin.exe not found"
}

Write-Host "Removing DELLOSRecoveryTool ..."
try {
    if ($true -eq (Test-Path -Path "C:\ProgramData\Package Cache\{9255a761-3ba1-447c-855b-4b67716f9f6d}\DellOSRecoveryTool.exe")) {
        Start-Process -FilePath "C:\ProgramData\Package Cache\{9255a761-3ba1-447c-855b-4b67716f9f6d}\DellOSRecoveryTool.exe" -ArgumentList "/uninstall /quiet" -Wait
    } else {
        Write-Host "DellOSRecoveryTool.exe not found"
    }
}
catch {
    Write-Host "DellOSRecoveryTool.exe not found"
}

#Register package in registry
New-Item -Path "HKLM:\SOFTWARE\COMPANY\" -Name "RemoveDellBloatware"
New-ItemProperty -Path "HKLM:\SOFTWARE\COMPANY\RemoveDellBloatware" -Name "Version" -PropertyType "String" -Value "1.0.0" -Force

Stop-Transcript
