$settings = @{
    Rules = @{
        PSUseCompatibleSyntax = @{
            # This turns the rule on (setting it to false will turn it off)
            Enable = $true

            # List the targeted versions of PowerShell here
            TargetVersions = @(
                '3.0',
                '5.1',
                '6.2'
            )
        }
    }
}

$diagnostics = Invoke-ScriptAnalyzer -Path .\uninstallOcs.ps1 -Settings $settings
$diagnostics[0].SuggestedCorrections