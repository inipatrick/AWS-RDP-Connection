<#
.SYNOPSIS
Adds a file name extension to a supplied name.

.DESCRIPTION
This is a PowerShell script to allow multiple RDP sessions to be started within AWS.

.EXAMPLE
PS> SAWS 

.LINK
http://www.NerdRays.com

Scott Barton 25/3/2022
#>


class AWSUsers : System.Management.Automation.IValidateSetValuesGenerator { 
    [String[]] GetValidValues() { 
        $Global:AWSUserList = @()
        Get-Content -path $ENV:USERPROFILE\.aws\credentials | Foreach-Object {
            if ($_ -match '[[].+]') { 
                $Global:AWSUserList += $($_ -replace "\[" , "" -replace "\]", "") 
            }
        }
        return $Global:AWSUserList
    }
}

function Start-AWS {
    Param (
        [Parameter(Mandatory)]
        [ValidateSet([AWSUsers], ErrorMessage = "Invalid entry {0} - Please enter a valid entry: {1}")]
        [String]$AWSProfile
    )
    
    Clear-Host
    Set-TabTitle -TabTitle "Not Connected 🔴"
    Set-AWSENV -AWSProfile $AWSProfile
    Clear-Jobs

    $Result = Read-AWSInstall
    
    if ($Result -like "* installed *") {
        Read-AWSSelect
    }
}

function Set-AWSENV { 
    Param (
        [Parameter(Mandatory)]
        [ValidateSet([AWSUsers], ErrorMessage = "Invalid entry {0} - Please enter a valid entry: {1}")]
        [String]$AWSProfile
    )

    if ($ENV:AWS_Profile -ne $AWSProfile) { 
        $ENV:AWS_Profile = $($AWSProfile)
    }
}

function Read-AWSInstall { 
    $Result = & 'C:\Program Files\Amazon\SessionManagerPlugin\bin\session-manager-plugin.exe'
    return $Result
}

function Set-TabTitle { 
    Param (
        [string]$TabTitle
    )
    $Host.UI.RawUI.WindowTitle = $TabTitle
}

$StartSSM = {
    Param (                      
        [Parameter(Mandatory=$true)] 
        [String]$target,
        [String]$PortToUse
    )
    aws ssm start-session --target $target --document-name AWS-StartPortForwardingSession --parameters portNumber=3389,localPortNumber=$($PortToUse) --profile $($ENV:AWS_Profile)
}

function Read-AWSSelect { 

    $AWSInstances = (aws ec2 describe-instances --region eu-west-2 | ConvertFrom-Json).Reservations
    # needs to be ordered

    $Servers = @()

    $AWSInstances | Select-Object -ExpandProperty Instances | Foreach-Object {
        $ServerDetails = New-Object psobject
        $ServerDetails | Add-Member "NoteProperty" -Name "InstanceId" -Value $_.InstanceId
        $ServerDetails | Add-Member "NoteProperty" -Name "ServerName" -Value ($_ | Select-Object -ExpandProperty Tags | Where-Object {$_.Key -eq "Name"} | Select-Object -ExpandProperty Value)
        $ServerDetails | Add-Member "NoteProperty" -Name "ServerState" -Value ($_ | Select-Object -ExpandProperty State | Select-Object -ExpandProperty Name)
        $Servers += $ServerDetails
    }

    $AWSENV = $(Write-Host "Setup connection to $($ENV:AWS_Profile) select an instance?" -ForeGroundColor Green

    Write-host "ID `t | InstanceID `t | Server State `t | Server Name"
    Write-Host "".PadRight((("ID     | InstanceID     | Server State     | Server Name").Length), '_')

    ###### sort this to have a where-object in it::: $Servers | Where-object {$Servername -match '[$anyinput.+]'} | Sort-object ServerName | Foreach-object {
    ###### Remove the first 5 count below and add it as an option. 
    ###### might be worth putting the below into it's own function
    $i = 0;
    $Servers | Sort-object ServerName | Select-Object -First 5 | Foreach-object {
        $Iid = $_.InstanceId
        $SN = $_.ServerName
        $SS = $_.ServerState
        $Colour = Get-Colour

        Write-Host "$($i) $($Iid) `t $($SS) `t $($SN)" -ForeGroundColor $Colour
        $i++
    }

    Read-Host)

    if ($AWSENV -match "[0-9]") { 
        $Server = ($Service.GetEnumerator() | Where-Object { ($_.Name -split (' - '))[0] -eq $AWSENV } | Select-Object -Last 1).Value
        $PortToUse = Get-Port
        Write-Host "Server $Server" -BackgroundColor Blue -ForeGroundColor White
        Set-TabTitle -TabTitle "$Server : $($PortToUse) 🟢"
        Start-Job -ScriptBlock $StartSSM -ArgumentList @($Server, $PortToUse) | Out-Null
        Start-RDP -PortToUse $PortToUse
    } else {
        Read-AWSSelect
    }
}

function Get-Port { 
    $PortToUse = 4460 .. 4480 | Get-Random

    $UsedPorts = Get-NetTCPConnection | Where-Object {$_.LocalPort -Match '^44..$'} | Select-Object LocalPort

    if ($PortToUse -in $UsedPorts) { 
        Get-Port
    }

    return $PortToUse
}

function Clear-Jobs { 
    $CurrentJobs = (Get-Job | Foreach-Object { $_.id })

    $CurrentJobs | Foreach-Object { 
        Stop-Job -id $_
        Remove-Job -id $_
    }
}

function Start-RDP {
    Param ( 
        [string]$PortToUse
    )

    if ($Host.UI.RawUI.WindowTitle -match '[0-9]') { 
        $PortToUse = $(($Host.UI.RawUI.WindowTitle).Split(': ')[1].split(" ")[0])
    }

    mstsc "G:\Documents\Development\RDP Sessions\AWS\RDP_$($ENV:AWS_Profile).rdp" /v:localhost:$PortToUse
}

function Get-Colour { 
    $ColourList = @{
        1 = "DarkBlue"
        2 = "DarkGreen"
        3 = "DarkCyan"
        4 = "DarkRed"
        5 = "DarkMagenta"
        6 = "DarkYellow"
        7 = "Blue"
        8 = "Green"
        9 = "Cyan"
        10 = "Red"
        11 = "Magenta"
        12 = "Yellow"
    }

    $Number = Get-Random -Maximum 12 -Minimum 1
    $ColourValue = ($ColourList.GetEnumerator() | Where-Object {$_.Key -eq $number}).Value

    return $ColourValue
}


Set-Alias SAWS Start-AWS