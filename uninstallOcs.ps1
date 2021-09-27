#For run with policy execute next script: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
############################
#Firts setup this variables:
$OCSServerUrl = "https://ticket.grupoxcaret.com/ocsinventory"
########################################
#Init Script, dont modify the following:
########################################
$logs = "Logs on $(Get-Date -Format u) `n"
$logs += "Starting uninstall OCS script from $($ENV:COMPUTERNAME) `n"
try {
	#Check operating system version and PowerShell compatibility
	$WindowsBuild = [Int][System.Environment]::OSVersion.Version.Build
	$logs += "Windows OS compilation: $($WindowsBuild).`n"
	#Check if OCS is installed (2 methods, service and installation folder)
	$OCSService = Get-service -Name "OCS*"
	$OCSInstallx64 = (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OCSInventory.exe") -or (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OcsSystray.exe") -or (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OcsService.exe")
	$OCSInstallx86 = (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OCSInventory.exe") -or (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OcsSystray.exe") -or (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OcsService.exe")
	if ($OCSService -or $OCSInstallx64 -or $OCSInstallx86) {
		$logs += "OCS is installed.`n"
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
		$logs += "OCS Architecture: $($OCSArchitecture[0]) `n"
		#Check OCS version
		$OCSVersion = (Get-Item $OCSArchitecture[1]).VersionInfo.FileVersion
		$logs += "OCS Version installed: $($OCSVersion) `n"
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
					$logs += "OCS Config is configured correctly to $($ConfigServer[1]) `n"
				}
				else {
					$logs += "OCS Config is not configured correctly to $($ConfigServer[1]). Changing...`n"
					#Stop a OCS service.
					if ($OCSService.Status -eq "Running") {
						Stop-Service $OCSService.Name
						$logs += "Stoped OCS Service.`n"
					}
					else {
						$logs += "OCS Service is: $($OCSService.Status) `n"
					}
					#Replace OCS config.
                (Get-Content "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini") -replace "Server=$($ConfigServer[1])", "Server=https://ticket.grupoxcaret.com/ocsinventory" | Set-Content -Path "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini"
					$logs += "OCS is now configured correctly.`n"
					#Restart Service
					$logs += "Starting OCS Service again.`n"
					Start-Service $OCSService.Name
				}
			}
			Default {
				$logs += "uninstalling OCS.`n"
				#Stop OCS Service
				if ($OCSService.Status -eq "Running") {
					Stop-Service $OCSService.Name
					$logs += "Stoped OCS Service.`n"
				}
				else {
					$logs += "OCS Service is: $($OCSService.Status) `n"
				}
				#Uninstall OCS and erase config
				if ($WindowsBuild -lt 10000) {
					$OCSInstalled = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty |  Where-Object { $_.DisplayName -match "OCS" } | Select-Object -Property DisplayName, UninstallString
				}
				else {
					$OCSInstalled = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty |  Where-Object { $_.DisplayName -match "OCS" } | Select-Object -Property DisplayName, UninstallString
				}
				foreach ($program in $OCSInstalled) {
					if ($program.UninstallString.EndsWith("uninst.exe")) {
						$uninstall = $program.UninstallString
						& $uninstall "/run /exit /S /s"
						$logs += "OCS uninstalling from $uninstall `n"
					}
				}
				if (Test-Path -Path "C:\ProgramData\OCS Inventory NG\") {
					Remove-Item -Force -Recurse -Path "C:\ProgramData\OCS Inventory NG\"
					$logs += "OCS config erased successfully.`n"
				}
				$logs += "OCS Config is erased.`n"
			}
		}
	}
	else {
		$logs += "OCS is not installed.`n"
		if (Test-Path -Path "C:\ProgramData\OCS Inventory NG\") {
			Remove-Item -Force -Recurse -Path "C:\ProgramData\OCS Inventory NG\"
			$logs += "OCS config erased successfully.`n"
		}
	}
	$logs += "####################################################################`n"
}
catch {
	Add-Content $ENV:TEMP"\OcsScriptByPowerShell.log" -Value $logs
}finally{
	Add-Content $ENV:TEMP"\OcsScriptByPowerShell.log" -Value $logs
	$Subject = "OCS Script PowerShell execute on $($ENV:COMPUTERNAME)"
	$password = ConvertTo-SecureString "passwordemail" -AsPlainText -Force
	$Cred = New-Object System.Management.Automation.PSCredential("email@domain.com", $password)
	Send-MailMessage -From "email@domain.com" -To "email@domain.com" -Subject $Subject -Body $logs -Credential $Cred -SmtpServer "smtp.com" -Port 587 -UseSsl
}