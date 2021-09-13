$OSVersion = [Int][System.Environment]::OSVersion.Version.Build
if ($OSVersion -gt 6000) {
	$OCSService = (Get-service -Name "OCS*" | Measure-Object).Count -gt 0
	$OCSInstallx64 = (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OCSInventory.exe") -or (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OcsSystray.exe") -or (Test-Path -Path "C:\Program Files\OCS Inventory Agent\OcsService.exe")
	$OCSInstallx86 = (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OCSInventory.exe") -or (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OcsSystray.exe") -or (Test-Path -Path "C:\Program Files (x86)\OCS Inventory Agent\OcsService.exe")
	if ($OCSService -or $OCSInstallx64 -or $OCSInstallx86) {
		if ($OCSInstallx86) {
			$OCSArchitecture = @("x86", "C:\Program Files (x86)\OCS Inventory Agent\OCSInventory.exe")
		}
		elseif ($OCSInstallx64) {
			$OCSArchitecture = @("x64", "C:\Program Files\OCS Inventory Agent\OCSInventory.exe")
		}
		else {
			$OCSArchitecture = @("undefined")
		}
		$OCSVersion = (Get-Item $OCSArchitecture[1]).VersionInfo.FileVersion
		switch ($OCSVersion) {
			"2.9.0.0" {
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
				}
				else {
					$OCSService = Get-service -Name "OCS*"
					if ($OCSService.Status -eq "Running") {
						Stop-Service $OCSService.Name
					}
                    (Get-Content "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini") -replace "Server=$($ConfigServer[1])", "Server=https://ticket.grupoxcaret.com/ocsinventory" | Set-Content -Path "C:\ProgramData\OCS Inventory NG\Agent\ocsinventory.ini"
					Start-Service $OCSService.Name
				}
			}
			Default {
				$OCSService = Get-service -Name "OCS*"
				if ($OCSService.Status -eq "Running") {
					Stop-Service $OCSService.Name
				}
				$OCSInstalled = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty |  Where-Object { $_.DisplayName -match "OCS" } | Select-Object -Property DisplayName, UninstallString
				foreach ($program in $OCSInstalled) {
					if ($program.UninstallString) {
						$uninstall = $program.UninstallString
						& $uninstall "/run /exit /S /s"
					}
				}
				Remove-Item -Force -Recurse -Path "C:\ProgramData\OCS Inventory NG\*"
			}
		}
	}
	else {
		if (Test-Path -Path "C:\ProgramData\OCS Inventory NG\") {
			Remove-Item -Force -Recurse -Path "C:\ProgramData\OCS Inventory NG\*"
		}
	}
}