Function Get-ADUserLockouts {
    [CmdletBinding(
        DefaultParameterSetName = 'All'
    )]
    param (
        [Parameter(
            ValueFromPipeline = $true,
            ParameterSetName = 'ByUser'
        )]
        [System.String]$Identity,
        [datetime]$StartTime,
        [datetime]$EndTime,
        [Parameter(ParameterSetName = 'ByUser')]
        [Switch]$FailureReason
    )
    Begin{

        $filterHt = @{
            LogName = 'Security'
            ID = 4740
        }
        if ($PSBoundParameters.ContainsKey('StartTime')){
            $filterHt['StartTime'] = $StartTime
        }
        if ($PSBoundParameters.ContainsKey('EndTime')){
            $filterHt['EndTime'] = $EndTime
        }
        $PDCEmulator = (Get-ADDomain).PDCEmulator
        $events = $null
        # Query the event log just once instead of for each user if using the pipeline
        try {
            $events = Get-WinEvent -ComputerName $PDCEmulator -FilterHashtable $filterHt -ErrorAction Stop
        }
        catch {
            if ($_.Exception.Message -match "No events were found that match the specified selection criteria") {
                Write-Error ('[{0:O}] No logs found' -f (get-date))
            }
        }
    }

    Process {
        if ($null -ne $events) {
            if ($PSCmdlet.ParameterSetName -eq 'ByUser'){
                $user = Get-ADUser $Identity
                # Filter the events
                $output = $events | Where-Object {$_.Properties[0].Value -eq $user.SamAccountName}
            } else {
                $output = $events
            }

            if ($FailureReason) {
                foreach ($event in $output) {

                    $ParamReason = @{
                        Computer = ($event | Select-Object @{Name = "Workstation Name"; Expression = {($_.Message | grep 'Caller Computer Name:').split(":")[-1].trim()}}) | Select-Object -ExpandProperty "Workstation Name"
                    }

                    if ($PSBoundParameters.ContainsKey('StartTime')){
                        $ParamReason['StartTime'] = $StartTime
                    }
                    if ($PSBoundParameters.ContainsKey('EndTime')){
                        $ParamReason['EndTime'] = $EndTime
                    }
                    Get-ADUserLockoutReason @ParamReason
                }
            }
            else {
                foreach ($event in $output){
                    [pscustomobject]@{
                        UserName = $event.Properties[0].Value
                        CallerComputer = $event.Properties[1].Value
                        TimeStamp = $event.TimeCreated
                    }
                }
            }
        } else
        {
            Write-Error ('[{0:O}] No logs found' -f (get-date))
        }

    }
    End{}
}
