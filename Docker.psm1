Function Set-Docker {
    ForEach ($Command in @('docker', 'docker-compose')) {
        $Invoke = If ($Command -eq 'docker') { 'Invoke-DockerCommand' } Else { 'Invoke-DockerComposeCommand' }
        Set-Alias -Name $Command -Value $Invoke -Scope Global -ErrorAction Stop
        If (-Not (Test-Path -PathType Leaf -Path $Profile)) {
            New-Item -ItemType File -Path $Profile
        }
        $Content = "Set-Alias -Name $Command -Value $Invoke"
        If (-Not (Get-Content -Path $Profile | Select-String -SimpleMatch $Content)) {
            Add-Content -Path $Profile -Value "`r`n$Content"
        }
    }
}
Function Mount-VirtualHosts {
    Param(
        [Parameter(Mandatory = $True)] $Command,
        $Arguments
    )
    If (($Command -Eq 'docker') -And ($Arguments[0] -Eq 'run')) {
        $Content = [String] $Arguments
        $Pattern = '-e\s+VIRTUAL_HOST=(\S+)'
    }
    If (($Command -Eq 'docker-compose') -And ($Arguments[0] -Eq 'up')) {
        $File = 'docker-compose.yml'
        If ($MatchFile = [String] $Arguments | Select-String -Pattern "-f\s+(\S+)") {
            $File = ((($MatchFile.Matches[0].Groups[1].Value) -Replace "'", '') -Replace '"', '')
        }
        $Content = Get-Content -Path $File
        $Pattern = '^[\s-]*VIRTUAL_HOST\s*[=:]\s*(.+)\s*$'
    }
    If ($Content -and ($MatchHosts = $Content | Select-String -Pattern $Pattern)) {
        Foreach ($VirtualHost in (((($MatchHosts.Matches[0].Groups[1].Value) -Replace "'", '') -Replace '"', '') -Split ',')) {
            New-HostnameMapping -Hostname $VirtualHost
        }
    }
}
Function Get-DockerStatus {
    If (([String](Docker.exe info 2>&1)).Contains('ERROR')) {
        &'C:\Program Files\Docker\Docker\Docker Desktop.exe'
        While (([String](Docker.exe info 2>&1)).Contains('ERROR')) {
            Start-Sleep -Seconds 1
        }
    }
}
Function Invoke-DockerCommand {
    Get-DockerStatus
    Mount-VirtualHosts -Command docker -Arguments $Args
    Docker.exe $Args
}
Function Invoke-DockerComposeCommand {
    Get-DockerStatus
    Mount-VirtualHosts -Command docker-compose -Arguments $Args
    Docker-compose.exe $Args
}