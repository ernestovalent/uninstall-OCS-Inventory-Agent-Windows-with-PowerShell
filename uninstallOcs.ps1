#For run with policy execute next script: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Write-Output "-> Inicial Script to uninstall OCS"
#Check operating system version and PowerShell compatibility
$OSVersion = [Int][System.Environment]::OSVersion.Version.Build
if ($OSVersion -gt 6000) {
    Write-Output "--> Windows OS compilation: $($OSVersion) is accepted."
    #Check if OCS is installed (2 methods, service, installation folder)
    $OCSService = (Get-service -Name "OCS*" | Measure-Object).Count -gt 0
    $OCSInstallx64 = (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OCSInventory.exe") -or (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OcsSystray.exe") -or (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OcsService.exe")
    $OCSInstallx86 = (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OCSInventory.exe") -or (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OcsSystray.exe") -or (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OcsService.exe")
    if ($OCSService -or $OCSInstallx64 -or $OCSInstallx86) {
        Write-Output "--> OCS is installed."
        #Check installed OCS architecture
        if ($OCSInstallx86) {
            $OCSArchitecture = @("x86", "C:\Program Files (x86)\OCS Inventory Agent\OCSInventory.exe")
        }
        elseif ($OCSInstallx64) {
            $OCSArchitecture = @("x64", "C:\Program Files\OCS Inventory Agent\OCSInventory.exe")
        }
        else {
            $OCSArchitecture = @("undefined")
        }
        Write-Output "--> OCS Architecture is: $($OCSArchitecture[0])"
        #Check OCS version
        $OCSVersion = (Get-Item $OCSArchitecture[1]).VersionInfo.FileVersion
        Write-Output "--> OCS Version installed: $($OCSVersion)"
        switch ($OCSVersion) {
            "2.9.0.0" {
                #Check .ini file, OCS settings
                $OCSServer = $false
                foreach ($Configline in Get-Content "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini") {
                    if ($Configline -match "Server=") {
                        $ConfigServer = $Configline -split "="
                        if ($ConfigServer[1] -eq "https://ticket.grupoxcaret.com/ocsinventory") {
                            $OCSServer = $true
                        }
                    }
                }
                if ($OCSServer) {
                    Write-Output "--> OCS Config is configured correctly to $($ConfigServer[1])"
                }
                else {
                    Write-Output "---> OCS Config is not configured correctly to $($ConfigServer[1]). Changing..."
                    #Stop a OCS service.
                    $OCSService = Get-service -Name "OCS*"
                    if ($OCSService.Status -eq "Running") {
                        Stop-Service $OCSService.Name
                        Write-Output "----> Stoped OCS Service."
                    }
                    else {
                        Write-Output "----> OCS Service is: $($OCSService.Status)"
                    }
                    #Replace config.
                    (Get-Content "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini") -replace "Server=$($ConfigServer[1])", "Server=https://ticket.grupoxcaret.com/ocsinventory" | Set-Content -Path "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini"
                    Write-Output "----> OCS is now configured correctly."
                    Write-Output "----> Starting OCS Service again."
                    Start-Service $OCSService.Name
                }
            }
            Default {
                Write-Output "---> uninstall OCS"
                #Stop OCS Service
                $OCSService = Get-service -Name "OCS*"
                if ($OCSService.Status -eq "Running") {
                    Stop-Service $OCSService.Name
                    Write-Output "----> Stoped OCS Service."
                }
                else {
                    Write-Output "----> OCS Service is: $($OCSService.Status)"
                }
                #Uninstall OCS and erase config
                $OCSInstalled = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty |  Where-Object { $_.DisplayName -match "OCS" } | Select-Object -Property DisplayName, UninstallString
                foreach ($program in $OCSInstalled) {
                    if ($program.UninstallString) {
                        $uninstall = $program.UninstallString
                        & $uninstall "/run /exit /S /s"
                        Write-Output "----> OCS is uninstalled successfully."
                    }
                }
                Remove-Item -Force -Recurse -Path "C:\ProgramData\OCS Inventory NG\*"
                Write-Output "----> OCS Config is erased."
            }
        }
    }
    else {
        Write-Output "--> OCS is not installed."
        #If exist OCS config, eraser.
        if (Test-Path -Path "C:\ProgramData\OCS Inventory NG\") {
            Write-Output "--> OS have OCS config avaible."
            Remove-Item -Force -Recurse -Path "C:\ProgramData\OCS Inventory NG\*"
            Write-Output "---> OCS config erased successfully."
        }
    }
}
else {
    Write-Output "-> Windows not compatible."
}
Write-Output "-> Script finished successfully"