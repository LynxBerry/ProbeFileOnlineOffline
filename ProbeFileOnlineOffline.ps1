<#
.SYNOPSIS
Perform online & offline servers by modifying probe file names.

.DESCRIPTION
You can use this script to change probe file to online & offline servers.

.PARAMETER Action
Online server or offline server

.PARAMETER serverListFile
Specify path of server list file to read from.

.EXAMPLE
.\ProbleFileOnlineOffline.ps1 offline c:\serverlist\FE1.txt
.\ProbleFileOnlineOffline.ps1 online c:\serverlist\FE1.txt

.NOTES
Author: stevensh@microsoft.com
Created: Sept 8, 2017
Last Updated: Sept 8, 2017

#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('online', 'offline')]
    [string] $Action, # online & offline
    [Parameter(Mandatory=$true)]
    [string] $serverListFile # path, not array
    
)


function mainFunc {
        # to Array
    $serverlist = @(Get-Content $serverListFile)

    $config = @{
        'ProbeFileDrive'='D';
        'ProbeFilePath'='\mscomtest\test.aspx'; # online
        'ProbeFilePathOOS' = '\mscomtest\testOOS.aspx' # used for offline.
    }

    function pathFactory {
        Param(
            $Action,
            $drive,
            $pathIS,
            $pathOOS

        )

        return {
                    param(
                        $server,
                        [switch] $src,
                        [switch] $dest
                    )

                    function getPathHelper { #inner function
                        if ($Action -eq "online"){
                            if ($src) { #to online, so src should be oos.
                                return $pathOOS
                            } elseif ($dest){
                                return $pathIS

                            } else {
                                # error
                            }

                        } elseif ($Action -eq "offline"){
                            if ($src) { #to offline, so src should be is.
                                return $pathIS
                            } elseif ($dest){
                                return $pathOOS                            
                            } else {
                                                            # error
                        }

                        } else {
                            # error
                        }
                    } # end of helper
                

                    return '\\{0}\{1}${2}' -f $server,$drive,$(getPathHelper)

                }.GetNewClosure()
    }

    $GenPath = pathFactory -Action $Action -drive $config['ProbeFileDrive'] -pathIS $config['ProbeFilePath'] -pathOOS $config['ProbeFilePathOOS']

    # online or offline servers
    $serverlist | %{
        $tempSrv = $_
        write-host $('Info>>>Start to {0} {1}' -f $Action, $_ )
        try {
            if ( (-not (Test-Path $(& $GenPath $_ -src))) -and (Test-Path $(& $GenPath $_ -dest))){ # if already offline or online, no Action need to take
                write-host $('WARN>>>{0} already {1}d' -f $_, $Action)
            } else {
                Rename-Item $(& $GenPath $_ -src) $(& $GenPath $_ -dest) -ErrorAction Stop
                write-host $('Verbose>>>Probe File Change from {0} to {1}' -f $(& $GenPath $_ -src),$(& $GenPath $_ -dest))
            }

        } catch {
            write-host $('Error>>>failed to {0} {1}:{2}' -f $Action, $tempSrv, $_ ) # $_ here is error object.
            $host.SetShouldExit(1) # unexpected error
            exit 1
            
        }
        
    }

}# end of main func

try {
    mainFunc
    write-host "success"
    $host.SetShouldExit(0) # success path
    Start-Sleep -s 120
    exit 0
}catch{
    write-host $_
    $host.SetShouldExit(1) # unexpected error
    exit 1

}

