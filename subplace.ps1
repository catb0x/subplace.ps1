<#
subplace.ps1
by kit (https://github.com/catb0x/subplace.ps1)
version 6 ^_^
subject to the terms of the MPL 2.0, you can get a copy at http://mozilla.org/MPL/2.0/
#>

[CmdletBinding()] param ()

$jsonPath = "$env:LOCALAPPDATA\subplace\settings.json"

if (Get-Command "gsudo" -errorAction SilentlyContinue) {
    $gsudoExists = $true
} else {
	$gsudoExists = $false
}
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (!($isAdmin) -and !($gsudoExists)) {
	Write-Warning "script is not running as administrator. relaunching with elevated permissions..."
	Start-Process powershell -ArgumentList "-NoExit", "-noprofile", "-executionpolicy bypass", "-file `"$PSCommandPath`"" -Verb RunAs
	exit
} elseif (!($isAdmin) -and ($gsudoExists)) {
	Write-Verbose "gsudo mode automatically enabled,,,"
	$gsudoMode = 2
} elseif (($isAdmin) -and ($gsudoExists)) {
	Write-Verbose "gsudo mode can be enabled if macros break,,,"
	$gsudoMode = 1
} else {
	Write-Warning "download gsudo if not running other macros as admin,,,"
	$gsudoMode = 0
}

function Is-WindowInForeground {
    $windowName = $args[0]
    $windowExists = Get-Process | Where-Object { $_.MainWindowTitle -like $windowName }
	return $windowExists
}

function Ask {
    $question = Read-Host $args[1]
	if ($question -eq "?") {
		Write-Host $args[2] -ForegroundColor Blue
		Ask $args[0] $args[1] $args[2]
	} elseif ($question -ne "") {
		Set-Variable -Name $args[0] -Value $question -Scope Script
	}
}

function BooleanAsk {
    $question = Read-Host $args[1]
	$booleanAnswer = $null
	if ($question -eq "?") {
		Write-Host $args[2] -ForegroundColor Blue
		BooleanAsk $args[0] $args[1] $args[2]
	} elseif ([bool]::TryParse($question, [ref]$booleanAnswer)) {
		Set-Variable -Name $args[0] -Value $booleanAnswer -Scope Script
	}
}

function IntAsk {
    $question = Read-Host $args[1]
	if ($question -eq "?") {
		Write-Host $args[2] -ForegroundColor Blue
		BooleanAsk $args[0] $args[1] $args[2]
	} elseif ($question -match "^\d+$") {
		Set-Variable -Name $args[0] -Value ([int]$question) -Scope Script
	}
}

function JobId {
    $question = Read-Host "instance/job id? (leave blank if none)"
	if ($question -eq "nvm") {
		Write-Host "not continuing..." -ForegroundColor Green
		$script:continue = $false
	} elseif ($question -ne "") {
		$other = "&gameInstanceId=${$question}"
	}
}

function SaveSettings {
    param (
		[Parameter(Position=0)]
		[string[]]$VariableNames
	)
    $varHash = @{}
    foreach ($varName in $VariableNames) {
        if (Get-Variable -Name $varName -ErrorAction SilentlyContinue) {
            $varHash[$varName] = (Get-Variable -Name $varName).Value
        }
    }
    New-Item -Path (Split-Path $jsonPath) -ItemType Directory -Force | Out-Null
    $varHash | ConvertTo-Json | Set-Content $jsonPath
}

function LoadSettings {
    if (Test-Path $jsonPath) {
        $varHash = Get-Content $jsonPath | ConvertFrom-Json
        foreach ($key in $varHash.PSObject.Properties.Name) {
            Set-Variable -Name $key -Value $varHash.$key -Scope Script -Force
        }
        Write-Verbose "settings loaded..."
    } else {
        Write-Verbose "settings not found... making them rn"
        $script:loop = 300
        $script:sleep = 100
        $script:manual = $false
        $script:gsudoOptional = $false
        SaveSettings "loop", "sleep", "manual", "gsudoOptional"
    }
}
LoadSettings

$defPath = (Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\roblox-player\shell\open\command").'(default)' -replace '^"(.+?)".+', '$1'
if ($defPath -eq "$($env:LOCALAPPDATA)\Bloxstrap\Bloxstrap.exe") {
	$bootstrapper = "Bloxstrap"
	$roblox = "$($env:LOCALAPPDATA)\Bloxstrap\Roblox\Player\RobloxPlayerBeta.exe"
} else {
	$bootstrapper = "Roblox"
	$roblox = $defPath
	Write-Warning "this will probably not work w/o bloxstrap lol"
}

Write-Host "            ___.          .__                                         ____ 
  ________ _\_ |__ ______ |  | _____    ____  ____      ______  _____/_   |
 /  ___/  |  \ __ \\____ \|  | \__  \ _/ ___\/ __ \     \____ \/  ___/|   |
 \___ \|  |  / \_\ \  |_> >  |__/ __ \\  \__\  ___/     |  |_> >___ \ |   |
/____  >____/|___  /   __/|____(____  /\___  >___  > /\ |   __/____  >|___|
     \/          \/|__|             \/     \/    \/  \/ |__|       \/      " -ForegroundColor Blue

while ($true) {
$other = ""

while ($true) { # intro,,,

$answer = Read-Host "join a subplace [1] settings [2] about [3]"
if ($answer -eq "3") {
	Write-Host "subplace.ps1 version 6. i think. made by kit. https://github.com/catb0x/subplace.ps1"
} elseif ($answer -eq "2") {
	Write-Host "enter ? if you want more information, leave blank if you dont want to change anything" -ForegroundColor Blue
	Ask "bootstrapper" "bootstrapper name? (currently ${bootstrapper})" "default is detected, either Bloxstrap or Roblox. put your bootstrapper name here if you arent using default roblox or bloxstrap"
	Ask "roblox" "full roblox path?" "currently ${roblox}. default is detected, put your RobloxPlayerBeta.exe path here if you arent using default roblox or bloxstrap"
	IntAsk "loop" "loop delay? (currently ${loop})" "default: 500, but can change based on saved settings. how many ms to sleep before repeating loops"
	IntAsk "sleep" "sleep delay? (currently ${sleep})" "default: 100. how many ms to sleep before loading the subplace. change depending on what happens"
	BooleanAsk "manual" "enable manual mode? (currently ${manual})" "default: false. input boolean. enable if you want"
	if (($isAdmin) -and ($gsudoExists)) { BooleanAsk "gsudoOptional" "enable gsudo loading mode? (currently ${gsudoOptional})" "default: depends. check source code." }
	BooleanAsk "load" "save settings as file?" "saves settings on a file to be used later."
	if ($load = $true) {
		SaveSettings "loop", "sleep", "manual", "gsudoOptional"
		$load = $false
	}
} elseif ($answer -eq "1") { break }

}

$placeId = Read-Host "enter the place id"
if ($placeId -eq "nvm") {
	Write-Host "not continuing..." -ForegroundColor Green
	continue
} elseif (!($placeId -match "^\d+$")) {
	Write-Error "invalid place id. please enter a valid integer..."
	continue
}
try {
	$request = Invoke-RestMethod -Uri "https://apis.roblox.com/universes/v1/places/${placeId}/universe"
	$universeId = $request.universeId
	$rootRequest = Invoke-RestMethod -Uri "https://games.roblox.com/v1/games?universeIds=${universeId}"
} catch {
	Write-Error "an error occured. either the place id isnt valid or roblox is down"
	continue
}
$rootId = $null
foreach ($place in $rootRequest.data) {
	$rootId = $place.rootPlaceId
	break
}
if ($placeId -eq $rootId) {
	Write-Verbose "universeid: ${universeId}"
	$places = Invoke-RestMethod -Uri "https://develop.roblox.com/v1/universes/${universeId}/places?limit=100"
	if (!($places.data)) {
		Write-Warning "no places found for the given universeid... roblox is possibly down? idk"
		continue
	}
	Write-Host "enter one of the following ids:"
	foreach ($place in $places.data) {
		Write-Host "$($place.name): $($place.id)" -ForegroundColor Blue
	}
	$subplace = Read-Host
	if ($subplace -eq "nvm") {
		Write-Host "not continuing..." -ForegroundColor Green
		continue
	}
	JobId
	Write-Host "joining the main place..." -ForegroundColor Green
} else {
	$subplace = $placeId
	Write-Host "placeid has been found to be a subplace." -ForegroundColor Green
	JobId
	Write-Host "joining..." -ForegroundColor Green
}

if ($gsudoOptional -and ($gsudoMode -eq 1)) {
	gsudo --integrity medium Start-Process "roblox://experiences/start?placeId=${rootId}"
	Write-Verbose "joining with gsudo..."
} else { Start-Process "roblox://experiences/start?placeId=${rootId}" }

while ($true) {
    if (Is-WindowInForeground "Roblox") {
        Write-Verbose "roblox is in the foreground. disabling internet..."
        break
    } else {
        Write-Verbose "roblox is not in the foreground."
    }
    Start-Sleep -Milliseconds $loop
}

Start-Sleep -Milliseconds $sleep

if ($gsudoMode -eq 2) {
	gsudo netsh advfirewall firewall add rule name="subplace inbound" dir=in action=block program=$roblox enable=yes | Write-Verbose
	gsudo netsh advfirewall firewall add rule name="subplace outbound" dir=out action=block program=$roblox enable=yes | Write-Verbose
	Write-Verbose "disabling internet with gsudo..."
} else {
	netsh advfirewall firewall add rule name="subplace inbound" dir=in action=block program=$roblox enable=yes | Write-Verbose
	netsh advfirewall firewall add rule name="subplace outbound" dir=out action=block program=$roblox enable=yes | Write-Verbose
}

Write-Host "internet disabled. joining subplace, do not press retry yet" -ForegroundColor Green

if ($gsudoOptional -and ($gsudoMode -eq 1)) {
	gsudo --integrity medium Start-Process "roblox://experiences/start?placeId=${subplace}${other}"
	Write-Verbose "joining with gsudo..."
} else { Start-Process "roblox://experiences/start?placeId=${subplace}${other}" }

if ($manual) {
	Start-Sleep -Milliseconds $sleep
} else {
while ($true) {
	if (Is-WindowInForeground $bootstrapper) {
		Write-Verbose "bootstrapper is in the foreground. continuing..."
		break
	} else {
		Write-Verbose "bootstrapper is not in the foreground."
	}
	Start-Sleep -Milliseconds $loop
}
while ($true) {
	if (Is-WindowInForeground $bootstrapper) {
		Write-Verbose "bootstrapper is not in the background."
	} else {
		Write-Verbose "bootstrapper is in the background. enabling internet..."
		break
	}
	Start-Sleep -Milliseconds $loop
}
}

if ($gsudoMode -eq 2) {
	gsudo netsh advfirewall firewall delete rule name="subplace inbound" | Write-Verbose
	gsudo netsh advfirewall firewall delete rule name="subplace outbound" | Write-Verbose
	Write-Verbose "enabling internet with gsudo..."
} else {
	netsh advfirewall firewall delete rule name="subplace inbound" | Write-Verbose
	netsh advfirewall firewall delete rule name="subplace outbound" | Write-Verbose
}

Write-Host "internet enabled. you can join now..." -ForegroundColor Green

}
