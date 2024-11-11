<#
subplace.ps1
by kit
version 5 !!! NOt release candidate oops this is final v5
:3
#>

[CmdletBinding()] param ()

function Is-WindowInForeground {
    $windowName = $args[0]
    $windowExists = Get-Process | Where-Object { $_.MainWindowTitle -like $windowName }
	return $windowExists
}

$wshell = New-Object -ComObject wscript.shell

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Output "Script is not running as Administrator. Relaunching with elevated permissions..."
    Start-Process powershell -ArgumentList "-NoExit", "-noprofile", "-executionpolicy bypass", "-file `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "            ___.          .__                                         ____ 
  ________ _\_ |__ ______ |  | _____    ____  ____      ______  _____/_   |
 /  ___/  |  \ __ \\____ \|  | \__  \ _/ ___\/ __ \     \____ \/  ___/|   |
 \___ \|  |  / \_\ \  |_> >  |__/ __ \\  \__\  ___/     |  |_> >___ \ |   |
/____  >____/|___  /   __/|____(____  /\___  >___  > /\ |   __/____  >|___|
     \/          \/|__|             \/     \/    \/  \/ |__|       \/      " -ForegroundColor Blue

$robloxPath = (Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\roblox-player\shell\open\command").'(default)' -replace '^"(.+?)".+', '$1'
if ($robloxPath -eq "$($env:LOCALAPPDATA)\Bloxstrap\Bloxstrap.exe") {
	$bootstrapper = "Bloxstrap"
	$roblox = "$($env:LOCALAPPDATA)\Bloxstrap\Roblox\Player\RobloxPlayerBeta.exe"
} else {
	$bootstrapper = "Roblox"
	$roblox = $robloxPath
	Write-Warning "this will probably not work w/o bloxstrap lol"
}

$loop = 300
$sleep = 0

while ($true) {
$other = ""
while ($true) {
	$answer = Read-Host "join a subplace [1] settings [2] about [3]"
	if ($answer -eq "3") {
		Write-Host "subplace.ps1 version 5. i think. made by kit. https://github.com/catb0x/subplace.ps1"
    } elseif ($answer -eq "2") {
		Write-Host "leave anything blank if u dont want to change it"
		$bootstrapperQ = Read-Host "bootstrapper name? (default: detected (Bloxstrap or Roblox))"
		if ($bootstrapperQ -ne "") { $bootstrapper = $bootstrapperQ }
		$robloxQ = Read-Host "roblox location? (default: detected (Bloxstrap path or Roblox path))"
		if ($robloxQ -ne "") { $roblox = $robloxQ }
		$otherQ = Read-Host "instance/job id?"
		if ($otherQ -ne "") { $other = "&gameInstanceId=${otherQ}" }
		$loopQ = Read-Host "milliseconds to wait until repeating loops? (default: 300)"
		if ($loopQ -ne "") { $loop = $loopQ }
		$sleepQ = Read-Host "milliseconds to sleep until joining subplace? (default: 0) (make higher if it breaks)"
		if ($sleepQ -ne "") { $sleep = $sleepQ }
	} elseif ($answer -eq "1") {
		break
	}
}

while ($true) {
	$placeId = Read-Host "enter the place id"
	if ($placeId -match "^\d+$") {
		break
	} else {
		Write-Error "invalid place id. please enter a valid integer..."
	}
}

$request = Invoke-RestMethod -Uri "https://apis.roblox.com/universes/v1/places/${placeId}/universe"
$universeId = $request.universeId
$rootRequest = Invoke-RestMethod -Uri "https://games.roblox.com/v1/games?universeIds=${universeId}"
$rootId = $null
foreach ($place in $rootRequest.data) {
	$rootId = $place.rootPlaceId
	break
}
if ($placeId -eq $rootId) {
	if ($universeId) {
		Write-Verbose "universeid: ${universeId}"
	} else {
		Write-Warning "no universeid found for the given placeid..."
		Exit
	}
	$places = Invoke-RestMethod -Uri "https://develop.roblox.com/v1/universes/${universeId}/places?limit=100"
	if (!($places.data)) {
		Write-Warning "no places found for the given universeid..."
		Exit
	}
	Write-Host "enter one of the following ids:"
	foreach ($place in $places.data) {
		Write-Host "$($place.name): $($place.id)" -ForegroundColor Blue
	}
	$subplace = Read-Host
	Write-Host "joining the main place..." -ForegroundColor Green
} else {
	$subplace = $placeId
	Write-Host "placeid has been found to be a subplace. joining..." -ForegroundColor Green
}



Start-Process "roblox://experiences/start?placeId=${rootId}"

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
netsh advfirewall firewall add rule name="subplace inbound" dir=in action=block program=$roblox enable=yes | Write-Verbose
netsh advfirewall firewall add rule name="subplace outbound" dir=out action=block program=$roblox enable=yes | Write-Verbose
Write-Host "internet disabled. joining subplace, do not press retry yet" -ForegroundColor Green

Start-Process "roblox://experiences/start?placeId=${subplace}${other}"

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

netsh advfirewall firewall delete rule name="subplace inbound" | Write-Verbose
netsh advfirewall firewall delete rule name="subplace outbound" | Write-Verbose
Write-Host "internet enabled. you can join now..." -ForegroundColor Green
}
