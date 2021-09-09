#Run to execute script with policy permission: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Write-Host "-> Inicial Script to uninstall OCS"
# Comprobar la versión del sistema operativo y la compatibilidad de PowerShell
$OSVersion = [Int](Get-CimInstance win32_operatingsystem).BuildNumber
if($OSVersion -gt 6000){
    Write-Host "--> Windows OS compilation:" $OSVersion "is correct."
    #Comprobar si OCS se encuentra instalado (3 metodos, servicio, carpeta instalación y carpeta configuración)
    $OCSService = (Get-service -Name "OCS*" | Measure-Object).Count -gt 0
    $OCSInstallx64 = (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OcsSystray.exe") -or (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OCSInventory.exe") -or (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OCSInventory.exe")
    $OCSInstallx84 = (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OcsSystray.exe") -or (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OCSInventory.exe") -or (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OCSInventory.exe")
    if ($OCSService -or $OCSInstallx64 -or $OCSInstallx84){
        Write-Host "--> OCS is installed."
        #Comprobar arquitectura de OCS instalada
        if ($OCSInstallx64){
            $OCSArchitecture = "x64"
        }elseif($OCSInstallx84){
            $OCSArchitecture = "x64"
        }else{
            $OCSArchitecture = "undefined"
        }
        Write-Host "--> OCS Architecture is:" $OCSArchitecture
        #Comprobar versión de OCS
        $OCSVersion = (Get-Item "C:\Program Files\OCS Inventory Agent\OCSInventory.exe").VersionInfo.FileVersion
        Write-Host "--> OCS Version installed:" $OCSVersion
        switch ($OCSVersion) {
            "2.9.0.0" { Write-Host "---> OCS is correct, must see a config.ini" }
            Default { Write-Host "---> uninstall OCS" }
        }
    }else{
        Write-Host "--> OCS is not installed."
    }
}else{
    Write-Host "-> Windows not compatible."
}