#For run with policy execute next script: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
############################
#Firts setup this variables:
$OCSServerUrl = "https://ticket.grupoxcaret.com/ocsinventory"

########################################
#Init Script, dont modify the following:
########################################
Write-LogWindows "Starting uninstall OCS script"
#Check operating system version and PowerShell compatibility
$WindowsBuild = [Int][System.Environment]::OSVersion.Version.Build
Write-LogWindows "Windows OS compilation: $($WindowsBuild)."
#Check if OCS is installed (2 methods, service and installation folder)
$OCSService = Get-service -Name "OCS*"
$OCSInstallx64 = (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OCSInventory.exe") -or (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OcsSystray.exe") -or (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OcsService.exe")
$OCSInstallx86 = (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OCSInventory.exe") -or (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OcsSystray.exe") -or (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OcsService.exe")
if ($OCSService -or $OCSInstallx64 -or $OCSInstallx86) {
	Write-LogWindows "OCS is installed."
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
	Write-LogWindows "OCS Architecture: $($OCSArchitecture[0])"
	#Check OCS version
	$OCSVersion = (Get-Item $OCSArchitecture[1]).VersionInfo.FileVersion
	Write-LogWindows "OCS Version installed: $($OCSVersion)"
	switch ($OCSVersion) {
		"2.9.0.0" {
			#Check .ini file, OCS settings
			$OCSServer = $false
			foreach ($Configline in Get-Content "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini") {
				if ($Configline -match "Server=") {
					$ConfigServer = $Configline -split "="
					if ($ConfigServer[1] -eq $OCSServerUrl) {
						$OCSServer = $true
					}
				}
			}
			if ($OCSServer) {
				Write-LogWindows "OCS Config is configured correctly to $($ConfigServer[1])"
			}else {
				Write-LogWindows "OCS Config is not configured correctly to $($ConfigServer[1]). Changing..."
				#Stop a OCS service.
				if ($OCSService.Status -eq "Running") {
					Stop-Service $OCSService.Name
					Write-LogWindows "Stoped OCS Service."
				}else {
					Write-LogWindows "OCS Service is: $($OCSService.Status)"
				}
				#Replace OCS config.
                (Get-Content "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini") -replace "Server=$($ConfigServer[1])", "Server=https://ticket.grupoxcaret.com/ocsinventory" | Set-Content -Path "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini"
				Write-LogWindows "OCS is now configured correctly."
				#Restart Service
				Write-LogWindows "Starting OCS Service again."
				Start-Service $OCSService.Name
				#Send Email to notify the change
			}
		}
		Default {
			Write-LogWindows "uninstalling OCS"
			#Stop OCS Service
			if ($OCSService.Status -eq "Running") {
				Stop-Service $OCSService.Name
				Write-LogWindows "Stoped OCS Service."
			}
			else {
				Write-LogWindows "OCS Service is: $($OCSService.Status)"
			}
			#Uninstall OCS and erase config
			if($WindowsBuild -lt 10000){
				$OCSInstalled = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty |  Where-Object { $_.DisplayName -match "OCS" } | Select-Object -Property DisplayName, UninstallString
			}else{
				$OCSInstalled = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty |  Where-Object { $_.DisplayName -match "OCS" } | Select-Object -Property DisplayName, UninstallString
			}
			foreach ($program in $OCSInstalled) {
				if ($program.UninstallString.EndsWith("uninst.exe")) {
					$uninstall = $program.UninstallString
					& $uninstall "/run /exit /S /s"
					Write-LogWindows "OCS uninstalling from $uninstall"
					#Send Email to notify uninstall
				}
			}
			Remove-Ocsconfig
			Write-LogWindows "OCS Config is erased."
		}
	}
}else {
	Write-LogWindows "OCS is not installed."
	Remove-Ocsconfig
}
Write-LogWindows "####################################################################`n"
Function Write-LogWindows {
	Param ([string]$log)
	Add-content $ENV:TEMP"\OcsUninstallScript.log" -Value "$(Get-Date -Format u) $log"
}
Function Remove-Ocsconfig {
	if (Test-Path -Path "C:\ProgramData\OCS Inventory NG\") {
		Remove-Item -Force -Recurse -Path "C:\ProgramData\OCS Inventory NG\"
		Write-LogWindows "OCS config erased successfully."
	}
}