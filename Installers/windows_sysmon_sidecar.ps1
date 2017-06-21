#==========================================================================
#
# Monitoring powershell Script
#
# Based on both ionstorm's Sidecar installer and
# version of SwiftOnSecurity's Sysmon Config
#
# Thanks ionstorm! Sorry for anything that made you block me on twitter!
#
#========================================================================== 

#
#Identify if sysmon's path already exists, if not, creates it
#
If(!(test-path 'C:\Program Files\sysmon\'))	{
	New-Item -ItemType Directory -Force -Path 'C:\Program Files\sysmon\'
	}
#
#Prepare to use proxy, remove/comment second line if no proxy needed
#
$browser = New-Object System.Net.WebClient
$browser.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials 

#
#Identify if system is 32bit or 64bit and downloads the equivalent version of sysmon
#
if ([Environment]::Is64BitProcess) {
	$browser.DownloadFile('https://live.sysinternals.com/Sysmon64.exe','C:\Program Files\sysmon\sysmon64.exe')
	$sysmon = 'C:\Program Files\sysmon\sysmon64.exe'
	} else {
	$browser.DownloadFile('https://live.sysinternals.com/Sysmon.exe','C:\Program Files\sysmon\sysmon.exe')
	$sysmon = 'C:\Program Files\sysmon\sysmon.exe'
	}
	
#
#Downloads ionstorm's Sysmon Config
#
"[+] Downloading Sysmon config..."
$browser.DownloadFile('https://raw.githubusercontent.com/ion-storm/sysmon-config/master/sysmonconfig-export.xml','C:\Program Files\sysmon\sysmonconfig-export.xml')

#
#Install sysmon using ionstorm's Sysmon configuration
#
if ((Get-Service sysmon).Status -eq 'Running') {
		#update sysmon config
		$IC = '-c'
	} else {
		#install new sysmon
		$IC = '-i'
	}
$arguments = "-accepteula $IC 'C:\Program Files\sysmon\sysmonconfig-export.xml'"
Start-Process -FilePath $sysmon -ArgumentList $arguments -Wait -NoNewWindow

#
#Check if sysmon was successfully installed and is running
#
if ((Get-Service sysmon).Status -eq 'Running') {
	"[+] Sysmon running! Successfully Installed."
	} else {
	"[-] Sysmon not running, check for problems..."
	}

#
#Changes to user's temporary fodler
#
Set-Location $env:TEMP

#
#Identify latest release
#
"[+] Downloading Graylog Sidecar to: $env:TEMP\Sidecar.exe..."
$latestRelease = Invoke-WebRequest https://github.com/Graylog2/collector-sidecar/releases/latest -Headers @{"Accept"="application/json"}
$json = $latestRelease.Content | ConvertFrom-Json
$latestVersion = $json.tag_name

#
#Identify files from latest release
#
$latest = Invoke-RestMethod -Uri https://api.github.com/repos/Graylog2/collector-sidecar/releases/latest -Method Get

#
#Pick .exe file from latest release
#
$latestFilename = $latest.assets.name -like '*.exe'

#
#Download latest Sidecar
#
$url = "https://github.com/Graylog2/collector-sidecar/releases/download/$latestVersion/$latestFilename"
$browser.DownloadFile($url,"$env:TEMP\Sidecar.exe")

#
#Silently install Sidecar with SERVERURL and TAGS
#Remember to change HTTPS to HTTP if not using SSL
#Remember to customize TAGS as needed
#
.\Sidecar.exe /S -SERVERURL=https://SERVER:443/api -TAGS='windows,desktop' | Wait-Process

#
#Same change made by ionstorm, remove if not using encryption (SSL/HTTPS)
#
"[+] Executing Script to edit content of sidecar configuration..."
$content = [System.IO.File]::ReadAllText("C:\Program Files\Graylog\collector-sidecar\collector_sidecar.yml").Replace("tls_skip_verify: false","tls_skip_verify: true")
[System.IO.File]::WriteAllText("C:\Program Files\Graylog\collector-sidecar\collector_sidecar.yml", $content)

#
#Install and start sidecar service
#
"[+] Installing Graylog Services..."
Start-Process -FilePath 'C:\Program Files\graylog\collector-sidecar\graylog-collector-sidecar.exe' -Argumentlist '-service install' -Wait -WindowStyle Hidden
Start-Process -FilePath 'C:\Program Files\graylog\collector-sidecar\graylog-collector-sidecar.exe' -Argumentlist '-service start' -Wait -WindowStyle Hidden

#
#Check if sidecar was successfully installed and is running
#
"[+] Checking Services..." 
if ((Get-Service collector-sidecar).Status -eq 'Running') {
	"[+] Graylog Sidecar Successfully Installed and Configured!"
	} else {
	"[-] Sidecar not running. Check for problems..."
	}