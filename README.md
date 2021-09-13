# Uninstall OCS Inventory Agent Windows using PowerShell
This program uninstalls the OCS Windows Agent program from the computer where it is running.
OCS is software used to record inventory. You can find out more information at [https://ocsinventory-ng.org/](https://ocsinventory-ng.org/).

You can run this script as a policy on the active directory domain.

If you want to run this script manually on your computer, you will need to:
 1. [Allow external program execution policy.](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.1) run: *Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser*
 2. Execute as an administrator


You can see how it works in the following diagram:
![Diagram of script](https://github.com/ernestovalent/uninstall-OCS-Inventory-Agent-Windows-with-PowerShell/raw/main/Flow%20Diagrams%20Process.png)