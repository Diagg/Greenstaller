<#
.SYNOPSIS
Bootstrapper that seek and download Evergreen application installer.

.DESCRIPTION
Performs download and execution of evergreen application installer from the Powershell Gallery
Minimal parameter requieres the name of the application that you wish to install
Default behavior will silent install the lastest x64 version 

.PARAMETER Application
Application Name you wish to install

.PARAMETER Architecture
Application Architecture. If omitted, it will default to x64

.PARAMETER Edition
Application Edition. may not apply to all application 

.PARAMETER DisableUpdate
Will disable all update mechanisme of Google Chrome after installation

.PARAMETER Uninstall
Will Silently uninstall any installed version of Google Chrome

.PARAMETER PreScriptURI
Will download and execute a script from github/gist before installing the application

.PARAMETER PostScriptURI
Will download and execute a script from github/gist after installing the application

.PARAMETER Log
Path to log file. If not specified will default to 
C:\Windows\Logs\EvergreenApplication\EverGreen-Installer.log 

.OUTPUTS
all action are logged to the log file specified by the log parameter

.EXAMPLE
C:\PS> .\BootStrap-EverGreenInstallation -Application GoogleChrome -Architecture x86

Download and silently Install the lastest x86 version of Google Chrome.

.EXAMPLE
C:\PS> .\BootStrap-EverGreenInstallation -Application GoogleChrome -DisableUpdate

Download and silently Install the lastest x64 version of Google Chrome.
And disable all update mechanism

.EXAMPLE
C:\PS> .\BootStrap-EverGreenInstallation -Application GoogleChrome -Uninstall

Uninstall any locally installed version of Google Chrome

.EXAMPLE
C:\PS> .\BootStrap-EverGreenInstallation -Application GoogleChrome -PostScriptURI https://gist.github.com/smuel1414/87ca0ab4544d95556c778908afad2f1d -GithubToken 992a03b2846cb2d1d3e323ca25f1e60e7caabf0a

Download and silently Install the lastest x64 version of Google Chrome,
Then download and execute the script from gist repo.


.LINK
http://www.OSD-Couture.com

.NOTES
By Diagg/OSD-Couture.com - 
Twitter: @Diagg

Additional Credits
Get-GithubContent based on work by Darren J. Robinson 
https://blog.darrenjrobinson.com/searching-and-retrieving-your-github-gists-using-powershell/

Invoke-AsCurrentUser based on work by Kelvin Tegelaar
https://www.cyberdrain.com/automating-with-powershell-impersonating-users-while-running-as-system/


Release date: 06/05/2021
Version: 0.18
#>

#Requires -Version 5
#Requires -RunAsAdministrator 

[CmdletBinding()]
param(

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName='Online')]
        [Parameter(ParameterSetName = 'Offline')]
        [Parameter(ParameterSetName = 'Predownload')]
        [ValidateSet("1Password","7zip","AdobeAcrobat","AdobeAcrobatReaderDC","AdobeBrackets","AdoptOpenJDK","Anki","AtlassianBitbucket","BISF","BitwardenDesktop","CitrixAppLayeringFeed",
        "CitrixApplicationDeliveryManagementFeed","CitrixEndpointManagementFeed","CitrixGatewayFeed","CitrixHypervisorFeed","CitrixLicensingFeed","CitrixReceiverFeed","CitrixSdwanFeed",
        "CitrixVirtualAppsDesktopsFeed","CitrixVMTools","CitrixWorkspaceApp","CitrixWorkspaceAppFeed","ControlUpAgent","ControlUpConsole","Cyberduck","dnGrep","FileZilla","Fork",
        "FoxitReader","Gimp","GitForWindows","GitHubAtom","GitHubRelease","GoogleChrome","Greenshot","Handbrake","JamTreeSizeFree","JamTreeSizeProfessional","KeePass","KeePassXCTeamKeePassXC",
        "LibreOffice","Microsoft.NET","Microsoft365Apps","MicrosoftAzureDataStudio","MicrosoftBicep","MicrosoftEdge","MicrosoftFSLogixApps","MicrosoftOneDrive","MicrosoftPowerShell",
        "MicrosoftPowerToys","MicrosoftSsms","MicrosoftTeams","MicrosoftVisualStudio","MicrosoftVisualStudioCode","MicrosoftWindowsPackageManagerClient","MicrosoftWvdBootloader",
        "MicrosoftWvdInfraAgent","MicrosoftWvdRemoteDesktop","MicrosoftWvdRtcService","MozillaFirefox","MozillaThunderbird","mRemoteNG","NETworkManager","NotepadPlusPlus","OpenJDK","OpenShellMenu",
        "OracleJava8","OracleVirtualBox","PaintDotNet","PDFForgePDFCreator","PeaZipPeaZip","ProjectLibre","RCoreTeamRforWindows","RingCentral","ScooterBeyondCompare","ShareX","Slack","StefansToolsgregpWin",
        "SumatraPDFReader","TeamViewer","TelegramDesktop","TelerikFiddlerEverywhere","Terminals","VastLimitsUberAgent","VercelHyper","VideoLanVlcPlayer","VMwareTools","Win32OpenSSH",
        "WinMerge","WinSCP","WixToolset","Zoom")]        
        [string]$Application,

        [Parameter(ParameterSetName = 'Online')]
        [Parameter(ParameterSetName = 'Offline')]
        [Parameter(ParameterSetName = 'Predownload')]
        [string]$GithubRepo = "https://github.com/Diagg/EverGreen-Application-Installer",


        [Parameter(ParameterSetName='Predownload', Mandatory = $true, Position = 0)]
        [string]$PreDownloadPath,

        [Parameter(ParameterSetName='Offline', Mandatory = $true, Position = 0)]
        [string]$InstallSourcePath,

        [Parameter(ParameterSetName = 'Online')]
        [Parameter(ParameterSetName = 'Offline')]
        [Parameter(ParameterSetName = 'Predownload')]
        [ValidateSet("x86", "x64")]
        [string]$Architecture = "X64",

        [Parameter(ParameterSetName = 'Online')]
        [Parameter(ParameterSetName = 'Offline')]
        [Parameter(ParameterSetName = 'Predownload')]        
        [string]$Log,

        [Parameter(ParameterSetName = 'Online')]
        [Parameter(ParameterSetName = 'Offline')]
        [switch]$DisableUpdate,

        [Parameter(ParameterSetName = 'Online')]
        [Parameter(ParameterSetName = 'Offline')]        
        [switch]$Uninstall,

        [Parameter(ParameterSetName = 'Online')]
        [Parameter(ParameterSetName = 'Offline')]
        [Parameter(ParameterSetName = 'Predownload')]
        [string]$GithubToken,

        [Parameter(ParameterSetName = 'Online')]
        [string]$PreScriptURI,

        [Parameter(ParameterSetName = 'Online')]
        [string]$PostScriptURI
     )

##== Debug
$ErrorActionPreference = "stop"
#$ErrorActionPreference = "Continue"

##== Global Variables
$Script:CurrentScriptName = $MyInvocation.MyCommand.Name
$Script:CurrentScriptFullName = $MyInvocation.MyCommand.Path
$Script:CurrentScriptPath = split-path $MyInvocation.MyCommand.Path


##== Functions

#region Functions
function Write-log 
    {
         Param(
              [parameter()]
              [String]$Path=$Script:log,

              [parameter(Position=0)]
              [String]$Message,

              [parameter()]
              [String]$Component=$Script:CurrentScriptName,

		      #Severity  Type(1 - Information, 2- Warning, 3 - Error)
		      [parameter(Mandatory=$False)]
		      [ValidateRange(1,3)]
		      [Single]$Type = 1
        )

		# Create Folder path if not present
        $oFolderPath = Split-Path $Path
		If (-not (test-path $oFolderPath)){New-Item -Path $oFolderPath -ItemType Directory -Force|out-null}

        # Create a log entry
        $Content = "<![LOG[$Message]LOG]!>" +`
            "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
            "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
            "component=`"$Component`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"$Type`" " +`
            "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
            "file=`"`">"

        # Write the line to the log file
        Add-Content -Path $Path -Value $Content -Encoding UTF8 -ErrorAction SilentlyContinue
    }


Function Get-GithubContent
    {
        param(

            [Parameter(Mandatory = $true, Position=0)]
            [string]$URI,
            
            [string]$GithubToken,

            [string]$ScriptName
         )
        
        If([string]::IsNullOrWhiteSpace($GithubToken))
            {
                ## This a public Repo/Gist

                If($URI -like '*/gist.github.com*')
                    {
                        ##This is a Gist
                        $URI = $URI.replace("gist.github.com","gist.githubusercontent.com")
                        If ($URI.Split("/")[$_.count-1] -notlike '*raw*'){$URI = "$URI/raw"}
                    }
                ElseIf($URI -like '*//gist.githubusercontent.com*')
                    {
                        ##This is a Github raw content
                    }
                ElseIf($URI -like '*/github.com*')
                    {
                        ##This is a Github repo
                        $URI = $URI.replace("github.com","raw.githubusercontent.com")
                        $URI = $URI.replace("blob/","")
                    } 
                ElseIf($URI -like '*/raw.githubusercontent.com*')
                    {
                        ##This is a Github raw content
                    }
                Else
                    {
                       Write-Error "[ERROR] Unsupported URI $URI, Aborting !!!"
                       Return $false     
                    } 

                
                Try 
                    {
                        $Fileraw = Invoke-WebRequest -URI $URI -UseBasicParsing
                        $Fileraw = $fileraw.Content
                    }
                Catch
                    {
                        Write-Error "[ERROR] Unable to get script content, Aborting !!!" 
                        Write-Error $Error[0].InvocationInfo.PositionMessage.ToString()
                        Write-Error $Error[0].Exception.Message.ToString()
                        $Fileraw = $False
                    }
                
                Return $fileraw
            }
        Else
            {
                ## This a private Repo/Gist

                # Authenticate 
                $clientID = $URI.split("/")[3]
                $GistID = $URI.split("/")[4]
        
                # Basic Auth
                $Bytes = [System.Text.Encoding]::utf8.GetBytes("$($clientID):$($GithubToken)")
                $encodedAuth = [Convert]::ToBase64String($Bytes)

                $Headers = @{Authorization = "Basic $($encodedAuth)"; Accept = 'application/vnd.github.v3+json'}
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $githubURI = "https://api.github.com/user"

                $githubBaseURI = "https://api.github.com"
                $auth = Invoke-RestMethod -Method Get -Uri $githubURI -Headers $Headers -SessionVariable GITHUB -ErrorAction SilentlyContinue

                if ($auth) 
                    {
                        If($URI -like '*/gist.github.com*')
                            { 
                                # Get my GISTS
                                $myGists = Invoke-RestMethod -method Get -Uri "$($githubBaseURI)/users/$($clientID)/gists" -Headers $Headers -WebSession $GITHUB
                                $script = $myGists | Select-Object | Where-Object {$_.id -eq $GistID}
            
                                if ($script)
                                    {
                                        foreach ($fileObj in ($script.files| Get-Member  | Where-Object {$_.memberType -eq "NoteProperty"}))
                                            {
                                                $File = $fileObj.definition

                                                $File = $File -split("@")
                                                $File = ($File[1]).replace("{","").replace("}","")
                                                $File = ($File.split(";")).trim()|ConvertFrom-StringData

                                                # Get File
                                                If (($File.Filename).ToUpper() -eq $ScriptName.ToUpper())
                                                    {
                                                        $rawURL = $File.raw_url
                                                        $fileraw = Invoke-RestMethod -Method Get -Uri $rawURL -WebSession $GITHUB
                                                        Return $fileraw  
                                                    } 
                                            }
                                    }
                            }
                        ElseIf($URI -like '*/github.com*')
                            {

                                Function Local:Explore-Repo
                                    {
                                        param (
                                            [Parameter( Position = 0, Mandatory = $True )]
                                            [String]$Path
                                        )



                                        $myGithubRepos = Invoke-RestMethod -method Get -Uri $path -Headers $Headers -WebSession $GITHUB

	                                    $files = $myGithubRepos | Where-Object {$_.type -eq "file"}
	                                    $directories = $myGithubRepos | Where-Object {$_.type -eq "dir"}

                                        $directories | ForEach-Object {Explore-Repo -path ($_._links).self}
        
                                        foreach ($file in $files) 
                                            {
                                                If (($File.Name).toUpper() -eq $ScriptName.ToUpper())
                                                    {
                                                        $rawURL = $File.download_url
                                                        $fileraw = Invoke-RestMethod -Method Get -Uri $rawURL -WebSession $GITHUB
                                                        $fileraw
                                                        break
                                                    }
                                            }
                                        Return
                                    }
                                
                                # Get my GItHub
                                $SelectedFile = Explore-Repo -path "$($githubBaseURI)/repos/$($clientID)/$($GistID)/contents"
                                Return $SelectedFile
                            }
                        Else
                            {
                               Write-Error "[ERROR] Unsupported URI $URI, Aborting !!!"
                               Return $false  
                            }
                    }
                Else
                    {
                        Write-Error "[ERROR] Unable to authenticate to github, Aborting !!!" 
                        Write-Error $Error[0].InvocationInfo.PositionMessage.ToString()
                        Write-Error $Error[0].Exception.Message.ToString()
                    }
            }
    }


Function Invoke-AsSystemNow
    {
        Param(
                [Parameter(Mandatory = $true)]
                [scriptblock]$ScriptBlock
            )
        
        $TaskName = "EverGreen Installer"
        $SchedulerPath = "\Microsoft\Windows\PowerShell\ScheduledJobs"
        $trigger = New-JobTrigger -AtStartup
        $options = New-ScheduledJobOption -StartIfOnBattery  -RunElevated

        $task = Get-ScheduledJob -Name $taskName  -ErrorAction SilentlyContinue
        if ($null -ne $task){Unregister-ScheduledJob $task -Confirm:$false}

        Register-ScheduledJob -Name $taskName  -Trigger $trigger  -ScheduledJobOption $options -ScriptBlock $ScriptBlock|Out-Null
        $principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount  -RunLevel Highest
        Set-ScheduledTask -TaskPath $SchedulerPath -TaskName $taskName -Principal $principal|Out-Null
        Write-log "Starting Scheduled scriptblock with name $TaskName as System Account"
        Start-Job -DefinitionName $taskName|Out-Null

        $attempts = 1
        While ((get-job -Name $taskname).State -ne "Completed" -or $attempts -le 15)
            {
                Start-Sleep -Seconds 1
                $attempts += 1
            }

        If ((get-job -Name $taskname).State -eq "Completed")
            {
                Write-log "Scheduled scriptblock with name $TaskName completed successfully !"
                Unregister-ScheduledJob $TaskName -Confirm:$false
                Return $true
            }
        Else
            {
                Write-log "[Error] Scheduled job with name $TaskName, returned with status $((get-job -Name $taskname).State)"
                Unregister-ScheduledJob $TaskName -Confirm:$false
                Return $false                        
            }
    }


Function Initialize-Prereq
    {

        Param(
                [Parameter(Mandatory = $false)]
                [switch]$NoModuleUpdate
            )


        ## Set Tls to 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        ## Add Scripts path to $env:PSModulePath
        $CurrentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
        If ($CurrentValue -notlike "*C:\Program Files\WindowsPowerShell\scripts*") {[Environment]::SetEnvironmentVariable("PSModulePath", $CurrentValue + [System.IO.Path]::PathSeparator + "C:\Program Files\WindowsPowerShell\Scripts", "Machine")}

        If ($NoModuleUpdate -eq $true){Return}

        Try 
            {
                ## install providers
                If (-not(Test-path "C:\Program Files\PackageManagement\ProviderAssemblies\nuget\2.8.5.208\Microsoft.PackageManagement.NuGetProvider.dll"))
                    {
                        Write-log "Nuget provider is not to up to date, Installing Latest version !"
                        Install-PackageProvider -Name 'nuget' -Force |Out-Null
                    }

                Write-log "Nuget provider installed version: $(((Get-PackageProvider -Name 'nuget'|Sort-Object|Select-Object -First 1).version.tostring()))"
        
                If ((Get-PSRepository -Name "PsGallery").InstallationPolicy -ne "Trusted"){Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted}                
                If ([version]((Get-Module PowerShellGet|Sort-Object|Select-Object -First 1).version.tostring()) -lt [version]"2.2.5" )
                    {
                        Write-log "Powershell provider is not to up to date, Installing Latest version !"
                        Install-Module -Name PowerShellGet -MinimumVersion 2.2.5 -Force
                    }
        
                Import-Module PowershellGet
                Write-log "PowershellGet module installed version: $(((Get-Module PowerShellGet|Sort-Object|Select-Object -First 1).version.tostring()))"
            } 
        Catch 
            {Write-log "[Error] Unable to install default providers, Aborting!!!" -type 3 ; Exit}


        ##== Get evergreen
        Try 
            {
                If ($null -eq (Get-module -Name "evergreen" -ListAvailable))
                    {
                        Write-log "Installing Evergreen Module"
                        Install-Module "Evergreen" -MinimumVersion 2104.337 -force
                    }
                Else 
                    {
                        Write-log "Updating Evergreen Module"
                        Update-Module "evergreen" 
                    }

                Import-Module "Evergreen"    
                Write-log "Evergreen module installed version: $(((Get-Module Evergreen|Sort-Object|Select-Object -First 1).version.tostring()))"
            }
        Catch
            {Write-log "[Error] Unable to install Evergreen, Aborting!!!" ; Exit}
    }


Function Invoke-AsCurrentUser
    {
        
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [scriptblock]$ScriptBlock,
            [Parameter(Mandatory = $false)]
            [String]$ScriptBlockLog = $Script:log,
            [Parameter(Mandatory = $false)]
            [switch]$NoWait,
            [Parameter(Mandatory = $false)]
            [ValidateSet("x86","x64","X86","X64")]
            [String]$Architecture = "x64",
            [Parameter(Mandatory = $false)]
            [switch]$UseWindowsPowerShell,
            [Parameter(Mandatory = $false)]
            [switch]$NonElevatedSession,
            [Parameter(Mandatory = $false)]
            [switch]$Visible,
            [Parameter(Mandatory = $false)]
            [switch]$CacheToDisk
        )        
        

        $Source = @"
        using Microsoft.Win32.SafeHandles;
        using System;
        using System.Runtime.InteropServices;
        using System.Text;
        namespace RunAsUser
        {
            internal class NativeHelpers
            {
                [StructLayout(LayoutKind.Sequential)]
                public struct PROCESS_INFORMATION
                {
                    public IntPtr hProcess;
                    public IntPtr hThread;
                    public int dwProcessId;
                    public int dwThreadId;
                }
                [StructLayout(LayoutKind.Sequential)]
                public struct STARTUPINFO
                {
                    public int cb;
                    public String lpReserved;
                    public String lpDesktop;
                    public String lpTitle;
                    public uint dwX;
                    public uint dwY;
                    public uint dwXSize;
                    public uint dwYSize;
                    public uint dwXCountChars;
                    public uint dwYCountChars;
                    public uint dwFillAttribute;
                    public uint dwFlags;
                    public short wShowWindow;
                    public short cbReserved2;
                    public IntPtr lpReserved2;
                    public IntPtr hStdInput;
                    public IntPtr hStdOutput;
                    public IntPtr hStdError;
                }
                [StructLayout(LayoutKind.Sequential)]
                public struct WTS_SESSION_INFO
                {
                    public readonly UInt32 SessionID;
                    [MarshalAs(UnmanagedType.LPStr)]
                    public readonly String pWinStationName;
                    public readonly WTS_CONNECTSTATE_CLASS State;
                }
            }
            internal class NativeMethods
            {
                [DllImport("kernel32", SetLastError=true)]
                public static extern int WaitForSingleObject(
                  IntPtr hHandle,
                  int dwMilliseconds);
                [DllImport("kernel32.dll", SetLastError = true)]
                public static extern bool CloseHandle(
                    IntPtr hSnapshot);
                [DllImport("userenv.dll", SetLastError = true)]
                public static extern bool CreateEnvironmentBlock(
                    ref IntPtr lpEnvironment,
                    SafeHandle hToken,
                    bool bInherit);
                [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
                public static extern bool CreateProcessAsUserW(
                    SafeHandle hToken,
                    String lpApplicationName,
                    StringBuilder lpCommandLine,
                    IntPtr lpProcessAttributes,
                    IntPtr lpThreadAttributes,
                    bool bInheritHandle,
                    uint dwCreationFlags,
                    IntPtr lpEnvironment,
                    String lpCurrentDirectory,
                    ref NativeHelpers.STARTUPINFO lpStartupInfo,
                    out NativeHelpers.PROCESS_INFORMATION lpProcessInformation);
                [DllImport("userenv.dll", SetLastError = true)]
                [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool DestroyEnvironmentBlock(
                    IntPtr lpEnvironment);
                [DllImport("advapi32.dll", SetLastError = true)]
                public static extern bool DuplicateTokenEx(
                    SafeHandle ExistingTokenHandle,
                    uint dwDesiredAccess,
                    IntPtr lpThreadAttributes,
                    SECURITY_IMPERSONATION_LEVEL ImpersonationLevel,
                    TOKEN_TYPE TokenType,
                    out SafeNativeHandle DuplicateTokenHandle);
                [DllImport("advapi32.dll", SetLastError = true)]
                public static extern bool GetTokenInformation(
                    SafeHandle TokenHandle,
                    uint TokenInformationClass,
                    SafeMemoryBuffer TokenInformation,
                    int TokenInformationLength,
                    out int ReturnLength);
                [DllImport("wtsapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
                public static extern bool WTSEnumerateSessions(
                    IntPtr hServer,
                    int Reserved,
                    int Version,
                    ref IntPtr ppSessionInfo,
                    ref int pCount);
                [DllImport("wtsapi32.dll")]
                public static extern void WTSFreeMemory(
                    IntPtr pMemory);
                [DllImport("kernel32.dll")]
                public static extern uint WTSGetActiveConsoleSessionId();
                [DllImport("Wtsapi32.dll", SetLastError = true)]
                public static extern bool WTSQueryUserToken(
                    uint SessionId,
                    out SafeNativeHandle phToken);
            }
            internal class SafeMemoryBuffer : SafeHandleZeroOrMinusOneIsInvalid
            {
                public SafeMemoryBuffer(int cb) : base(true)
                {
                    base.SetHandle(Marshal.AllocHGlobal(cb));
                }
                public SafeMemoryBuffer(IntPtr handle) : base(true)
                {
                    base.SetHandle(handle);
                }
                protected override bool ReleaseHandle()
                {
                    Marshal.FreeHGlobal(handle);
                    return true;
                }
            }
            internal class SafeNativeHandle : SafeHandleZeroOrMinusOneIsInvalid
            {
                public SafeNativeHandle() : base(true) { }
                public SafeNativeHandle(IntPtr handle) : base(true) { this.handle = handle; }
                protected override bool ReleaseHandle()
                {
                    return NativeMethods.CloseHandle(handle);
                }
            }
            internal enum SECURITY_IMPERSONATION_LEVEL
            {
                SecurityAnonymous = 0,
                SecurityIdentification = 1,
                SecurityImpersonation = 2,
                SecurityDelegation = 3,
            }
            internal enum SW
            {
                SW_HIDE = 0,
                SW_SHOWNORMAL = 1,
                SW_NORMAL = 1,
                SW_SHOWMINIMIZED = 2,
                SW_SHOWMAXIMIZED = 3,
                SW_MAXIMIZE = 3,
                SW_SHOWNOACTIVATE = 4,
                SW_SHOW = 5,
                SW_MINIMIZE = 6,
                SW_SHOWMINNOACTIVE = 7,
                SW_SHOWNA = 8,
                SW_RESTORE = 9,
                SW_SHOWDEFAULT = 10,
                SW_MAX = 10
            }
            internal enum TokenElevationType
            {
                TokenElevationTypeDefault = 1,
                TokenElevationTypeFull,
                TokenElevationTypeLimited,
            }
            internal enum TOKEN_TYPE
            {
                TokenPrimary = 1,
                TokenImpersonation = 2
            }
            internal enum WTS_CONNECTSTATE_CLASS
            {
                WTSActive,
                WTSConnected,
                WTSConnectQuery,
                WTSShadow,
                WTSDisconnected,
                WTSIdle,
                WTSListen,
                WTSReset,
                WTSDown,
                WTSInit
            }
            public class Win32Exception : System.ComponentModel.Win32Exception
            {
                private string _msg;
                public Win32Exception(string message) : this(Marshal.GetLastWin32Error(), message) { }
                public Win32Exception(int errorCode, string message) : base(errorCode)
                {
                    _msg = String.Format("{0} ({1}, Win32ErrorCode {2} - 0x{2:X8})", message, base.Message, errorCode);
                }
                public override string Message { get { return _msg; } }
                public static explicit operator Win32Exception(string message) { return new Win32Exception(message); }
            }
            public static class ProcessExtensions
            {
                #region Win32 Constants
                private const int CREATE_UNICODE_ENVIRONMENT = 0x00000400;
                private const int CREATE_NO_WINDOW = 0x08000000;
                private const int CREATE_NEW_CONSOLE = 0x00000010;
                private const uint INVALID_SESSION_ID = 0xFFFFFFFF;
                private static readonly IntPtr WTS_CURRENT_SERVER_HANDLE = IntPtr.Zero;
                #endregion
                // Gets the user token from the currently active session
                private static SafeNativeHandle GetSessionUserToken(bool elevated)
                {
                    var activeSessionId = INVALID_SESSION_ID;
                    var pSessionInfo = IntPtr.Zero;
                    var sessionCount = 0;
                    // Get a handle to the user access token for the current active session.
                    if (NativeMethods.WTSEnumerateSessions(WTS_CURRENT_SERVER_HANDLE, 0, 1, ref pSessionInfo, ref sessionCount))
                    {
                        try
                        {
                            var arrayElementSize = Marshal.SizeOf(typeof(NativeHelpers.WTS_SESSION_INFO));
                            var current = pSessionInfo;
                            for (var i = 0; i < sessionCount; i++)
                            {
                                var si = (NativeHelpers.WTS_SESSION_INFO)Marshal.PtrToStructure(
                                    current, typeof(NativeHelpers.WTS_SESSION_INFO));
                                current = IntPtr.Add(current, arrayElementSize);
                                if (si.State == WTS_CONNECTSTATE_CLASS.WTSActive)
                                {
                                    activeSessionId = si.SessionID;
                                    break;
                                }
                            }
                        }
                        finally
                        {
                            NativeMethods.WTSFreeMemory(pSessionInfo);
                        }
                    }
                    // If enumerating did not work, fall back to the old method
                    if (activeSessionId == INVALID_SESSION_ID)
                    {
                        activeSessionId = NativeMethods.WTSGetActiveConsoleSessionId();
                    }
                    SafeNativeHandle hImpersonationToken;
                    if (!NativeMethods.WTSQueryUserToken(activeSessionId, out hImpersonationToken))
                    {
                        throw new Win32Exception("WTSQueryUserToken failed to get access token.");
                    }
                    using (hImpersonationToken)
                    {
                        // First see if the token is the full token or not. If it is a limited token we need to get the
                        // linked (full/elevated token) and use that for the CreateProcess task. If it is already the full or
                        // default token then we already have the best token possible.
                        TokenElevationType elevationType = GetTokenElevationType(hImpersonationToken);
                        if (elevationType == TokenElevationType.TokenElevationTypeLimited && elevated == true)
                        {
                            using (var linkedToken = GetTokenLinkedToken(hImpersonationToken))
                                return DuplicateTokenAsPrimary(linkedToken);
                        }
                        else
                        {
                            return DuplicateTokenAsPrimary(hImpersonationToken);
                        }
                    }
                }
                public static int StartProcessAsCurrentUser(string appPath, string cmdLine = null, string workDir = null, bool visible = true,int wait = -1, bool elevated = true)
                {
                    using (var hUserToken = GetSessionUserToken(elevated))
                    {
                        var startInfo = new NativeHelpers.STARTUPINFO();
                        startInfo.cb = Marshal.SizeOf(startInfo);
                        uint dwCreationFlags = CREATE_UNICODE_ENVIRONMENT | (uint)(visible ? CREATE_NEW_CONSOLE : CREATE_NO_WINDOW);
                        startInfo.wShowWindow = (short)(visible ? SW.SW_SHOW : SW.SW_HIDE);
                        //startInfo.lpDesktop = "winsta0\\default";
                        IntPtr pEnv = IntPtr.Zero;
                        if (!NativeMethods.CreateEnvironmentBlock(ref pEnv, hUserToken, false))
                        {
                            throw new Win32Exception("CreateEnvironmentBlock failed.");
                        }
                        try
                        {
                            StringBuilder commandLine = new StringBuilder(cmdLine);
                            var procInfo = new NativeHelpers.PROCESS_INFORMATION();
                            if (!NativeMethods.CreateProcessAsUserW(hUserToken,
                                appPath, // Application Name
                                commandLine, // Command Line
                                IntPtr.Zero,
                                IntPtr.Zero,
                                false,
                                dwCreationFlags,
                                pEnv,
                                workDir, // Working directory
                                ref startInfo,
                                out procInfo))
                            {
                                throw new Win32Exception("CreateProcessAsUser failed.");
                            }
                            try
                            {
                                NativeMethods.WaitForSingleObject( procInfo.hProcess, wait);
                                return procInfo.dwProcessId;
                            }
                            finally
                            {
                                NativeMethods.CloseHandle(procInfo.hThread);
                                NativeMethods.CloseHandle(procInfo.hProcess);
                            }
                        }
                        finally
                        {
                            NativeMethods.DestroyEnvironmentBlock(pEnv);
                        }
                    }
                }
                private static SafeNativeHandle DuplicateTokenAsPrimary(SafeHandle hToken)
                {
                    SafeNativeHandle pDupToken;
                    if (!NativeMethods.DuplicateTokenEx(hToken, 0, IntPtr.Zero, SECURITY_IMPERSONATION_LEVEL.SecurityImpersonation,
                        TOKEN_TYPE.TokenPrimary, out pDupToken))
                    {
                        throw new Win32Exception("DuplicateTokenEx failed.");
                    }
                    return pDupToken;
                }
                private static TokenElevationType GetTokenElevationType(SafeHandle hToken)
                {
                    using (SafeMemoryBuffer tokenInfo = GetTokenInformation(hToken, 18))
                    {
                        return (TokenElevationType)Marshal.ReadInt32(tokenInfo.DangerousGetHandle());
                    }
                }
                private static SafeNativeHandle GetTokenLinkedToken(SafeHandle hToken)
                {
                    using (SafeMemoryBuffer tokenInfo = GetTokenInformation(hToken, 19))
                    {
                        return new SafeNativeHandle(Marshal.ReadIntPtr(tokenInfo.DangerousGetHandle()));
                    }
                }
                private static SafeMemoryBuffer GetTokenInformation(SafeHandle hToken, uint infoClass)
                {
                    int returnLength;
                    bool res = NativeMethods.GetTokenInformation(hToken, infoClass, new SafeMemoryBuffer(IntPtr.Zero), 0,
                        out returnLength);
                    int errCode = Marshal.GetLastWin32Error();
                    if (!res && errCode != 24 && errCode != 122)  // ERROR_INSUFFICIENT_BUFFER, ERROR_BAD_LENGTH
                    {
                        throw new Win32Exception(errCode, String.Format("GetTokenInformation({0}) failed to get buffer length", infoClass));
                    }
                    SafeMemoryBuffer tokenInfo = new SafeMemoryBuffer(returnLength);
                    if (!NativeMethods.GetTokenInformation(hToken, infoClass, tokenInfo, returnLength, out returnLength))
                        throw new Win32Exception(String.Format("GetTokenInformation({0}) failed", infoClass));
                    return tokenInfo;
                }
            }
        }
"@

        # Load the custom type
        if (!("RunAsUser.ProcessExtensions" -as [type])) {Add-Type -TypeDefinition $source -Language CSharp}

       
		# Create Log Folder path if not present        
        $oFolderPath = Split-Path $ScriptBlockLog
		If (-not (test-path $oFolderPath)){New-Item -Path $oFolderPath -ItemType Directory -Force|out-null}
            

        # Enhance Scriptblock
        $Script_LogPath = "`$Script:LogPath = ""$ScriptBlockLog"" `n"

        $Script_Init = {

            function Write-log 
                {
                    Param(
                          [parameter()]
                          [String]$Path=$Script:LogPath,

                          [parameter(Position=0)]
                          [String]$Message,

                          [parameter()]
                          [String]$Component="Invoke-AsCurrentUser",

		                  #Severity  Type(1 - Information, 2- Warning, 3 - Error)
		                  [parameter(Mandatory=$False)]
		                  [ValidateRange(1,3)]
		                  [Single]$Type = 1
                    )


                    # Create a log entry
                    $Content = "<![LOG[$Message]LOG]!>" +`
                        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
                        "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
                        "component=`"$Component`" " +`
                        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
                        "type=`"$Type`" " +`
                        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
                        "file=`"`">"

                    # Write the line to the log file
                    Add-Content -Path $Path -Value $Content -Encoding UTF8 -ErrorAction SilentlyContinue
                }


            function Write-Errorlog 
                {
                    Param([parameter(Position=0)][String]$Message)
                    Write-log -Message $Message -type 3
                }


            function Write-Warninglog 
                {
                    Param([parameter(Position=0)][String]$Message)
                    Write-log -Message $Message -type 2
                }

        }

        $ScriptBlock = [ScriptBlock]::Create($Script_LogPath.ToString() + $Script_Init.ToString() + $ScriptBlock.ToString().replace("Write-Host", "Write-log").replace("Write-Warning", "Write-Warninglog").replace("Write-Error", "Write-Errorlog"))
        $encodedcommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptBlock))

        $OSLevel = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentVersion
        if ($OSLevel -lt 6.2) { $MaxLength = 8190 } else { $MaxLength = 32767 }
        if ($encodedcommand.length -gt $MaxLength -and $CacheToDisk -eq $false) 
            {
                Write-Log "The encoded script is longer than the command line parameter limit. The script will be cached to disk"
                $CacheToDisk = $true
            }

        if ($CacheToDisk) 
            {
                $ScriptGuid = new-guid
                $ScriptBlock|Out-File -FilePath "$($ENV:TEMP)\$($ScriptGuid).ps1" -Encoding default
                Write-log "Script Block converted to file $($ENV:TEMP)\$($ScriptGuid).ps1"
                $pwshcommand = "-ExecutionPolicy Bypass -Window Normal -file `"$($ENV:TEMP)\$($ScriptGuid).ps1`""
            }
        else 
            {$pwshcommand = "-ExecutionPolicy Bypass -Window Normal -EncodedCommand $($encodedcommand)"}

        $privs = whoami /priv /fo csv | ConvertFrom-Csv | Where-Object { $_.'Privilege Name' -eq 'SeDelegateSessionUserImpersonatePrivilege' }
        if ($privs.State -eq "Disabled") 
            {
                Write-log -Message "Not running with correct privilege. You must run this script as system or have the SeDelegateSessionUserImpersonatePrivilege token." -Type 3
                return
            }
        else 
            {
                try 
                    {
                        # Use the same PowerShell executable as the one that invoked the function, Unless -UseWindowsPowerShell is defined
           
                        if (!$UseWindowsPowerShell) 
                            { $pwshPath = (Get-Process -Id $pid).Path } 
                        else 
                            { 
                                If ($Architecture.ToUpper() = "X64")
                                    {$pwshPath = "$($ENV:windir)\system32\WindowsPowerShell\v1.0\powershell.exe"}
                                Else
                                    {$pwshPath = "$($ENV:windir)\SysWOW64\WindowsPowerShell\v1.0\powershell.exe"}     
                            }
                        
                        if ($NoWait) { $ProcWaitTime = 1 } else { $ProcWaitTime = -1 }
                        if ($NonElevatedSession) { $RunAsAdmin = $false } else { $RunAsAdmin = $true }
                        
                        [RunAsUser.ProcessExtensions]::StartProcessAsCurrentUser($pwshPath, "`"$pwshPath`" $pwshcommand",(Split-Path $pwshPath -Parent), $Visible, $ProcWaitTime, $RunAsAdmin)|Out-Null
                        
                        if ($CacheToDisk) { $null = remove-item "$($ENV:TEMP)\$($ScriptGuid).ps1" -Force }
                    }
                catch 
                    {
                        Write-Log "Could not execute as currently logged on user: $($_.Exception.Message)" -Exception $_.Exception -Type 3
                        return
                    }
            }
    }

 
#endregion 

##== Initializing Environement
If (-not [string]::IsNullOrWhiteSpace($Log))
    {$Script:Log = $Log}
Else    
    {$Script:Log = $("$env:Windir\Logs\EvergreenApplication\EverGreen-" + $Application + "_"  + "Intaller.log")}

$Script:TsEnv = New-Object PSObject
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentLoggedOnUser' -Value (Get-CimInstance �ClassName Win32_ComputerSystem | Select-Object -expand UserName)

If ([String]::IsNullOrWhiteSpace($Script:TsEnv.CurrentLoggedOnUser))
    {
        # Get user when in Windows Sandbox
        If ((Get-CimInstance -Class Win32_UserAccount -Filter "LocalAccount=True AND Disabled=False AND Status='OK'").Name -eq 'WDAGUtilityAccount')
            {$Script:TsEnv.CurrentLoggedOnUser = "$($env:COMPUTERNAME)\WDAGUtilityAccount"}
        # Get Azure AD User
        Else
            {
                If([string]::IsNullOrWhiteSpace($(Get-PSDrive -Name HKU -ErrorAction SilentlyContinue))){New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | out-null}
                $UserReg = Get-Itemproperty "HKU:\*\Volatile Environment"
                $CurrentLoggedOnUser = "$($UserReg.USERDOMAIN)\$($UserReg.USERNAME)"
                $CurrentLoggedOnUserSID = split-path $UserReg.PSParentPath -leaf
                If(Get-ChildItem HKLM:\SOFTWARE\Microsoft\IdentityStore\LogonCache -Recurse -Depth 2 -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $CurrentLoggedOnUserSID})
                    {
                        $Script:TsEnv.CurrentLoggedOnUser = $CurrentLoggedOnUser
                        $Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentUserSID' -Value $CurrentLoggedOnUserSID
                        $Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentLoggedOnUserUPN' -Value $(Get-ItemProperty -Path $((Get-ChildItem HKLM:\SOFTWARE\Microsoft\IdentityStore\LogonCache -Recurse -Depth 2 | Where-Object { $_.Name -match $CurrentLoggedOnUserSID}).pspath) | Select-Object -ExpandProperty IdentityName)
                    }
            }
    }

If ([String]::IsNullOrWhiteSpace($Script:TsEnv.CurrentLoggedOnUser)){Write-log "[ERROR] Unable to detect current user, Aborting...." ; Exit}


$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'SystemHostName' -Value ([System.Environment]::MachineName)
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'SystemIPAddress' -Value (Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp -AddressState Preferred).IPAddress
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'SystemOSversion' -Value ([System.Environment]::OSVersion.VersionString)
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'SystemOSArchitectureIsX64' -Value ([System.Environment]::Is64BitOperatingSystem)
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentUserExecutionContext' -Value ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentUserIsAdmin' -Value (New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentUserIsSystem' -Value $([System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem)
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentUserIsTrustedInstaller' -Value ([System.Security.Principal.WindowsIdentity]::GetCurrent().groups.value -contains "S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464")
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentUserName' -Value ($Script:TsEnv.CurrentLoggedOnUser).split("\")[1]
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentUserDomain' -Value ($Script:TsEnv.CurrentLoggedOnUser).split("\")[0]
If(-not ($Script:TsEnv.CurrentUserSID)){$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentUserSID' -Value (New-Object System.Security.Principal.NTAccount($Script:TsEnv.CurrentLoggedOnUser)).Translate([System.Security.Principal.SecurityIdentifier]).value}
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentUserProfilePath' -Value (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'| Where-Object {$PSItem.pschildname -eq $Script:TsEnv.CurrentUserSID}|Get-ItemPropertyValue -Name ProfileImagePath)
$Script:TsEnv|Add-Member -MemberType NoteProperty -Name 'CurrentUserRegistryPath' -Value "HKU:\$($Script:TsEnv.CurrentUserSID)" 


##== Local Constantes
$AppDownloadDir = "$env:Public\Downloads" 

$StartupTime = [DateTime]::Now
Write-log 
Write-log "***************************************************************************************************"
Write-log "***************************************************************************************************"
Write-log "Started processing time: [$StartupTime]"
Write-log "Script Name: $CurrentScriptName"
Write-log "Selected Application: $Application"
If ($Uninstall -ne $true) {Write-log "Selected Application Architecture: $Architecture"}
Write-log "***************************************************************************************************"
Write-log "Log Path: $log"
Write-log "System Host Name: $($Script:TsEnv.SystemHostName)"
Write-log "System IP Address: $($Script:TsEnv.SystemIPAddress)"
Write-log "System OS version: $($Script:TsEnv.SystemOSversion)"
Write-log "System OS Architecture is x64: $($Script:TsEnv.SystemOSArchitectureIsX64)"
Write-Log "Logged on user: $($Script:TsEnv.CurrentLoggedOnUser)"
If($Script:TsEnv.CurrentLoggedOnUserUPN) {Write-Log "Logged on user UPN: $($Script:TsEnv.CurrentLoggedOnUserUPN)"}
Write-Log "Execution Context is Admin: $($Script:TsEnv.CurrentUserIsAdmin)" 
Write-Log "Execution Context is System: $($Script:TsEnv.CurrentUserIsSystem)"
Write-Log "Execution Context is TrustedInstaller: $($Script:TsEnv.CurrentUserIsTrustedInstaller)" 


If ($Uninstall -eq $true){Write-log "Selected Action: Uninstallation"}
else
    {
        if (-not([String]::IsNullOrWhiteSpace($InstallSourcePath)))
            {
                Write-log "Selected Action: Installation from offline source"
                Write-log "Install Option: Offline location $InstallSourcePath"
                $OfflineInstall = $true
            }    
        Else
            {Write-log "Selected Action: Installation"}
    }

If ($DisableUpdate -eq $true){Write-log "Install Option: Disabling update feature"}

if (-not([String]::IsNullOrWhiteSpace($PreDownloadPath)))
    {
        Write-log "Selected Action: Predownloading without installation"
        Write-log "Install Option: Download location $PreDownloadPath"
    }


##== Init        
If ($Uninstall -eq $true){Initialize-Prereq -NoModuleUpdate}
Else {Initialize-Prereq}

##== Download APP Data
Write-Log "Retriving data from Github for Application $Application"
$AppDataCode = Get-GithubContent -URI "$GithubRepo/blob/master/EverGreen%20Apps%20Installer/Applications-Data/$Application-Data.ps1"
Try 
    {
        If ($AppDataCode -ne $False) 
            {
                $AppDataScriptPath = "$($env:temp)\Github-GoogleChrome-Data.ps1"
                $AppDataCode|Out-File $AppDataScriptPath
                ."$AppDataScriptPath"
            } 
        Else
            {Write-log "[Error] Unable to execute $Application data garthering, bad return code, Aborting !!!" -Type 3 ; Exit} 
    }
Catch 
    {
        Write-log "[Error] Unable to execute $Application data garthering, logical error occurs, Aborting !!!" -Type 3
        Write-log $Error[0].InvocationInfo.PositionMessage.ToString() -type 3
        Write-log $Error[0].Exception.Message.ToString() -type 3
        Exit
    }

##############################
#### Pre-Script
##############################
If ($PreScriptURI -and $GithubToken)
    {
        Write-log "Invoking Prescript"
        $PreScript = Get-GistContent -PreScriptURI $PreScriptURI -GithubToken $GithubToken
        Try {Invoke-Command $PreScript}
        Catch {Write-log "[Error] Prescript Failed to execute" -Type 3}
    }


##############################
#### Application installation
##############################

##== Gather Informations
$Script:AppInfo = Get-AppInfo
$Script:AppInfo|Add-Member -MemberType NoteProperty -Name 'AppInstallArchitecture' -Value $Architecture.ToUpper()
Get-AppInstallStatus

If ($Script:AppInfo.AppIsInstalled)
    {Write-log "Version $($Script:AppInfo.AppInstalledVersion) of $Application detected!"}
Else
    {
        $AppInstallNow = $true
        Write-log "No Installed version of $Application detected!"
    }


If ($Uninstall -ne $true)
    {
        If ($InstallSourcePath){$AppInstallNow = $true}
        
        ##==Check for latest version
        $Script:AppEverGreenInfo = Get-EvergreenApp -Name $Application | Where-Object Architecture -eq $Architecture

        ##==Check if we need to update
        $AppUpdateStatus = Get-AppUpdateStatus
        If ($AppUpdateStatus)
            {
                $AppInstallNow = $true
                Write-log "New version of $Application detected! Release version: $($Script:AppEverGreenInfo.Version)"
            } 
        Else 
            {
                $AppInstallNow = $False
                Write-log "Version Available online is similar to installed version, Nothing to install !"
            } 


        ##==Download
        if (-not([String]::IsNullOrWhiteSpace($PreDownloadPath)))
            {
                If (-not(Test-path $PreDownloadPath))
                    {
                        $Iret = New-Item $PreDownloadPath -ItemType Directory -Force -ErrorAction SilentlyContinue
                        If ([string]::IsNullOrWhiteSpace($Iret)){Write-log "[ERROR] Unable to create download folder at $PreDownloadPath, Aborting !!!" -Type 3 ; Exit}
                    }
                
                $AppDownloadDir = $PreDownloadPath
                $AppInstallNow = $False
            }

        If (([String]::IsNullOrWhiteSpace($InstallSourcePath) -and $AppInstallNow -eq $True) -or (-not([String]::IsNullOrWhiteSpace($PreDownloadPath))))
            {
                Write-log "Found $Application - version: $($Script:AppEverGreenInfo.version) - Architecture: $Architecture - Release Date: $($Script:AppEverGreenInfo.Date) available on Internet"
                Write-log "Download Url: $($Script:AppEverGreenInfo.uri)"
                Write-log "Downloading installer for $Application - $Architecture"

                $InstallSourcePath = $Script:AppEverGreenInfo|Save-EvergreenApp -Path $AppDownloadDir
                $InstallSourcePath = ($InstallSourcePath.Split("=")[1]).replace("}","")

                Write-log "Successfully downloaded $Application to folder $InstallSourcePath"
            }

        
        ##== Uninstall before Update if requiered
        If ($Script:AppInfo.AppIsInstalled -eq $True -and [String]::IsNullOrWhiteSpace($PreDownloadPath))
            {
                If (($Script:AppInfo.AppMustUninstallBeforeUpdate -eq $true) -or ($Script:AppInfo.AppInstallArchitecture -ne $Script:AppInfo.AppArchitecture -and $Script:AppInfo.AppMustUninstallOnArchChange -eq $true))
                    {
                        ##== Uninstall
                        Write-log "Uninstalling $Application before reinstall/Update !"
                        $Iret = (Start-Process $Script:AppInfo.AppUninstallCMD -ArgumentList $Script:AppInfo.AppUninstallParameters -Wait -Passthru).ExitCode
                        If ($Script:AppInfo.AppUninstallSuccessReturnCodes -contains $Iret)
                            {Write-log "Application $Application - version $($Script:AppInfo.AppInstalledVersion) Uninstalled Successfully before reinstall/Update!!!"}
                        Else
                            {Write-log "[Warning] Application $Application - version $($Script:AppInfo.AppInstalledVersion) returned code $Iret while trying to uninstall before new update !!!" -Type 2}

                        ##== Additionnal removal action
                        Write-log "Uninstalling addintionnal items before reinstall/Update !"
                        Invoke-AdditionalUninstall
                    }
            }


        ##==Install
        if ($AppInstallNow -eq $True)
            {
                ## Rebuild Parametrers
                If (-not([String]::IsNullOrWhiteSpace($InstallSourcePath)))
                    {
                        Write-log "Download directory: $InstallSourcePath" 
                        If ((Test-Path $InstallSourcePath) -and (([System.IO.Path]::GetExtension($InstallSourcePath)).ToUpper() -eq $Script:AppInfo.AppExtension.ToUpper()))
                            {$Script:AppInfo.AppInstallParameters = $Script:AppInfo.AppInstallParameters.replace("##APP##",$InstallSourcePath)}
                        Else
                            {Write-log "[ERROR] Unable to find application at $InstallSourcePath or Filename with extension may be missing, Aborting !!!" -Type 3 ; Exit}
                    }
                Else
                    {$Script:AppInfo.AppInstallParameters = $Script:AppInfo.AppInstallParameters.replace("##APP##","$AppDownloadDir\$AppInstaller")}
                
                ## Execute Intall Program
                write-log "Installing $Application with command $($Script:AppInfo.AppInstallCMD) and parameters $($Script:AppInfo.AppInstallParameters)"
                $Iret = (Start-Process $Script:AppInfo.AppInstallCMD -ArgumentList $Script:AppInfo.AppInstallParameters -Wait -Passthru).ExitCode
                If ($Script:AppInfo.AppInstallSuccessReturnCodes -contains $Iret)
                    {Write-log "Application $Application - version $($Script:AppEverGreenInfo.version) Installed Successfully !!!"}
                Else
                    {Write-log "[ERROR] Application $Application - version $($Script:AppEverGreenInfo.version) returned code $Iret while trying to Install !!!" -Type 3}


                ## Clean Download Folder
                if ([String]::IsNullOrWhiteSpace($PreDownloadPath) -and $OfflineInstall -ne $true )
                    {
                        Write-log "cleaning Download folder"
                        Remove-Item $InstallSourcePath -Force -ErrorAction SilentlyContinue
                    }
            }

 
        ##== Remove Update capabilities
        If ($DisableUpdate -and [String]::IsNullOrWhiteSpace($PreDownloadPath))
            {
                Write-log "Disabling $Application update feature !"
                Invoke-DisableUpdateCapability
            }


        ##== Tag in registry
        $RegTag = "HKLM:\SOFTWARE\OSDC\EverGreenInstaller"
        If (-not(Test-path $RegTag)){New-item -Path $RegTag -Force|Out-Null}
        If (-not(Test-path "$RegTag\$Application")){New-item -Path "$RegTag\$Application" -Force|Out-Null}
        New-ItemProperty -Path "$RegTag\$Application" -Name "Install Date" -Value $([DateTime]::Now) -Force -ErrorAction SilentlyContinue|Out-Null
        New-ItemProperty -Path "$RegTag\$Application" -Name "Version" -Value $($Script:AppInfo.AppInstalledVersion) -Force -ErrorAction SilentlyContinue|Out-Null
        New-ItemProperty -Path "$RegTag\$Application" -Name "Architecture" -Value $($Script:AppInfo.AppArchitecture) -Force -ErrorAction SilentlyContinue|Out-Null
        New-ItemProperty -Path "$RegTag\$Application" -Name "Status" -Value "UpToDate" -Force -ErrorAction SilentlyContinue|Out-Null


        ##== Create Scheduled task
        $ScriptBlock_UpdateEval = {
            ##== Functions
            function Write-log 
                {
                     Param(
                          [parameter()]
                          [String]$Path="C:\Windows\Logs\EvergreenApplication\ApplicationUpdateEvaluation.log",

                          [parameter(Position=0)]
                          [String]$Message,

                          [parameter()]
                          [String]$Component="ApplicationUpdateEvaluation",

		                  #Severity  Type(1 - Information, 2- Warning, 3 - Error)
		                  [parameter(Mandatory=$False)]
		                  [ValidateRange(1,3)]
		                  [Single]$Type = 1
                    )

		            # Create Folder path if not present
                    $oFolderPath = Split-Path $Path
		            If (-not (test-path $oFolderPath)){New-Item -Path $oFolderPath -ItemType Directory -Force|out-null}

                    # Create a log entry
                    $Content = "<![LOG[$Message]LOG]!>" +`
                        "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
                        "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
                        "component=`"$Component`" " +`
                        "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
                        "type=`"$Type`" " +`
                        "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
                        "file=`"`">"

                    # Write the line to the log file
                    Add-Content -Path $Path -Value $Content -Encoding UTF8 -ErrorAction SilentlyContinue
                }


            ##== Main
            $StartupTime = [DateTime]::Now
            Write-log 
            Write-log "***************************************************************************************************"
            Write-log "***************************************************************************************************"
            Write-log "Started processing time: [$StartupTime]"
            Write-log "Script Name: ApplicationUpdateEvaluation"
            Write-log "***************************************************************************************************"

            $RegTag = "HKLM:\SOFTWARE\OSDC\EverGreenInstaller"
            $EverGreenApps = (Get-ChildItem $RegTag).PSChildName

            ForEach ($Regitem in $EverGreenApps)
                {
                    $AppInfo = Get-ItemProperty -Path "$RegTag\$Regitem"
                    If (-not ([string]::IsNullOrWhiteSpace($AppInfo)))
                        {
                            Write-log "Application : $Regitem"
                            $AppInstalledVersion = $AppInfo.DisplayVersion
                            $AppInstalledArchitecture = $AppInfo.Architecture
                            Write-log "Installed version : $AppInstalledVersion"

                            Write-log "Checking for Newer version online..."
                            $AppEverGreenInfo = Get-EvergreenApp -Name $Regitem | Where-Object Architecture -eq $AppInstalledArchitecture
                            Write-log "Latest verion available online: $($AppEverGreenInfo.Version)"

                            If ([version]($AppEverGreenInfo.Version) -gt [version]$AppInstalledVersion)
                                {
                                    Set-ItemProperty "$RegTag\$Regitem" -name 'Status' -Value "Obsolete" -force|Out-Null
                                    Write-log "$Regitem application status changed to Obsolete !"
                                }
                        }
                }

            $FinishTime = [DateTime]::Now
            Write-log "***************************************************************************************************"
            Write-log "Finished processing time: [$FinishTime]"
            Write-log "Operation duration: [$(($FinishTime - $StartupTime).ToString())]"
            Write-log "All Operations Finished!! Exit !"
            Write-log "***************************************************************************************************"  
        }

        $TaskName = "EverGreen Update Evaluation"
        $SchedulerPath = "\Microsoft\Windows\PowerShell\ScheduledJobs"
        $trigger = New-JobTrigger -Daily -At 12:00
        $options = New-ScheduledJobOption -StartIfOnBattery  -RunElevated

        $task = Get-ScheduledJob -Name $taskName  -ErrorAction SilentlyContinue
        if ($null -ne $task){Unregister-ScheduledJob $task -Confirm:$false}

        Register-ScheduledJob -Name $taskName  -Trigger $trigger  -ScheduledJobOption $options -ScriptBlock $ScriptBlock_UpdateEval|Out-Null
        $principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount  -RunLevel Highest
        Set-ScheduledTask -TaskPath $SchedulerPath -TaskName $taskName -Principal $principal|Out-Null
        write-log "Update Evaluation Scheduled task installed successfully under name $Taskname!"
        
    }
Else
    {
        If ($Script:AppInfo.AppIsInstalled -eq $False)
            {Write-log "Application $Application is not installed, nothing to uninstall ! All operation finished!!"}
        Else
            {
                ##== Uninstall
                $Iret = (Start-Process $Script:AppInfo.AppUninstallCMD -ArgumentList $Script:AppInfo.AppUninstallParameters -Wait -Passthru).ExitCode
                If ($Script:AppInfo.AppUninstallSuccessReturnCodes -contains $Iret)
                    {Write-log "Application $Application - version $($Script:AppInfo.AppInstalledVersion) Uninstalled Successfully !!!"}
                Else
                    {Write-log "[Warning] Application $Application - version $($Script:AppInfo.AppInstalledVersion) returned code $Iret while trying to uninstall !!!" -Type 2}

                ##== Additionnal removal action
                Write-log "Uninstalling addintionnal items !"
                Invoke-AdditionalUninstall
                Remove-Item "HKLM:\SOFTWARE\OSDC\EverGreenInstaller\$Application" -Recurse -Force -ErrorAction SilentlyContinue
            }
    }


##############################
#### Post-Script
##############################
If ($PostScriptURI -and $GithubToken)
    {
        Write-log "Invoking Postscript"
        $PostScript = Get-GistContent -PreScriptURI $PreScriptURI -GithubToken $GithubToken
        Try {Invoke-Command $PostScript}
        Catch {Write-log "[Error] Postscript Failed to execute" -Type 3}
    }

$FinishTime = [DateTime]::Now
Write-log "***************************************************************************************************"
Write-log "Finished processing time: [$FinishTime]"
Write-log "Operation duration: [$(($FinishTime - $StartupTime).ToString())]"
Write-log "All Operations for $Application Finished!! Exit !"
Write-log "***************************************************************************************************"    