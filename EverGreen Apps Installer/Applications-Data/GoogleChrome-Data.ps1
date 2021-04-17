Function Get-AppInfo
    {
        [PSCustomObject]@{
            AppName = "GoogleChrome"
            AppVendor = "Google"
            AppFiendlyName = "Chrome"
            AppInstallName = "Google Chrome"
            AppExtension = ".msi"
            AppDetection_X86 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" 
            AppDetection_X64 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
            AppInstallCMD = "MsiExec"
            AppInstallParameters = "/i ##APP## ALLUSERS=1 /qb"
            AppInstallSuccessReturnCodes = @(0,3010)
            AppUninstallSuccessReturnCodes = @(0,3010)
        }
    }


Function Get-AppInstallStatus
    {
        Param([PsObject]$ObjAppInfo)

        ##== Check if Application is Already installed 
        If (($null -ne ($AppRegUninstall = Get-ItemProperty "$($ObjAppInfo.AppDetection_X64)\*" | Where-Object { $_.DisplayName -like "*$($ObjAppInfo.AppInstallName)" })))
            {
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppIsInstalled' -Value $true
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppArchitecture' -Value 'X64'
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppDetection' -Value $AppRegUninstall.PsPath
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppUninstallCommand' -Value $AppRegUninstall.UninstallString
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppInstalledVersion' -Value $AppRegUninstall.DisplayVersion
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppUninstallCMD' -Value $($ObjAppInfo.AppUninstallCommand).Split(" ")[0]
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppUninstallParameters' -Value $($ObjAppInfo.AppUninstallCommand).Replace($ObjAppInfo.AppUninstallCMD, "").trim() + " /qb"
            }  
        Elseif (($null -ne (Get-ItemProperty "$($ObjAppInfo.AppDetection_X86)\*" | Where-Object { $_.DisplayName -eq $ObjAppInfo.AppInstallName })))
            {
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppIsInstalled' -Value $true
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppArchitecture' -Value 'X86'
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppDetection' -Value $AppRegUninstall.PsPath
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppUninstallCommand' -Value $AppRegUninstall.UninstallString
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppInstalledVersion' -Value $AppRegUninstall.DisplayVersion
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppUninstallCMD' -Value $($ObjAppInfo.AppUninstallCommand).Split(" ")[0]
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppUninstallParameters' -Value $($ObjAppInfo.AppUninstallCommand).Replace($ObjAppInfo.AppUninstallCMD, "").trim() + " /qb"
            }
        Else
            {
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppIsInstalled' -Value $false
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppArchitecture' -Value $null
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppDetection' -Value $null
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppUninstallCommand' -Value $null
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppInstalledVersion' -Value $null
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppUninstallCMD' -Value $null
                $ObjAppInfo|Add-Member -MemberType NoteProperty -Name 'AppUninstallParameters' -Value $null
            }

        Return $ObjAppInfo
    } 


Function Get-AppUpdateStatus
    {    
        Param([PsObject]$ObjAppInfo,[PsObject]$GreenAppInfo )

        # Return $True if the application need to updated
        If ([version]($GreenAppInfo.Version) -gt [version]$ObjAppInfo.AppInstalledVersion)
            {Return $True}
        Else        
            {Return $False}
    }


Function Invoke-AdditionalUninstall
    {
        Param([PsObject]$ObjAppInfo)
        
        ##== Additionnal removal action
        If (Test-Path ("C:\Program Files (x86)\Google\NOUpdate"))
            {
                If ($UserIsSystem)
                    {Remove-Item "C:\Program Files (x86)\Google\NOUpdate" -Force -Recurse|Out-Null}
                Else
                    {Run-AsSystemNow -ScriptBlock {Remove-Item "C:\Program Files (x86)\Google\NOUpdate" -Force -Recurse|Out-Null}}
            }

        If (Test-Path ("C:\Program Files (x86)\Google\Update"))
            {
                If ($UserIsSystem)
                    {Remove-Item "C:\Program Files (x86)\Google\Update" -Force -Recurse|Out-Null}
                Else
                    {Run-AsSystemNow -ScriptBlock {Remove-Item "C:\Program Files (x86)\Google\Update" -Force -Recurse|Out-Null}}
            }

        If (Test-Path ("$env:UserProfile\Desktop\Google Chrome.lnk")){Remove-Item "$env:UserProfile\Desktop\Google Chrome.lnk" -Force|Out-Null}
    }



