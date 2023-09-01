function Get-ADUserLockoutReason {
    [CmdletBinding()]
    param (
        [System.String]$Computer,
        [datetime]$StartTime,
        [datetime]$EndTime
    )

    begin {
        $filterHt = @{
            LogName = 'Security'
            ID = 4625
            ComputerName = $Computer
        }

        if ($PSBoundParameters.ContainsKey('StartTime')){
            $filterHt['StartTime'] = $StartTime
        }
        if ($PSBoundParameters.ContainsKey('EndTime')){
            $filterHt['EndTime'] = $EndTime
        }


    }

    process {
        $lockoutEvents = $null
        try {
            $lockoutEvents = Get-WinEvent -FilterHashTable $filterHash -ErrorAction Stop
        }
        catch {
            if ($_.Exception.Message -match "No events were found that match the specified selection criteria") {
                Write-Verbose ('[{0:O}] No logs found' -f (get-date))
            }
        }

        if ($lockoutEvents) {
            # Building output based on advanced properties
            $lockoutEvents | Select-Object @{Name = "Workstation Name"; Expression = {($_.Message | grep 'Workstation Name:').split(":")[-1].trim()}}, `
                                    @{Name = "LockedUserName"; Expression = {($_.Message | grep 'Account Name:').split(":")[-1].trim()}}, `
                                    @{Name = "LogonType"; Expression = {[logontypes]((($lockoutEvents[-1].Message) |  Select-String -Pattern 'Logon Type:.*(\D)' -CaseSensitive).Matches.Value).split(":")[-1].trim()}}, `
                                    @{Name = "Logon Process"; Expression = {($_.Message | grep 'Logon Process:').split(":")[-1].trim()}}, `
                                    @{Name = "Caller Name"; Expression = {($_.Message | grep 'Caller Process Name:').split(":")[-1].trim()}}, `
                                    @{Name = "Failure Reason"; Expression = {($_.Message | grep 'Failure Reason:').split(":")[-1].trim()}}, `
                                    @{Name= 'Failure Status';Expression={Get-FailureReason -FailureReason ((($_.Message) |  Select-String -Pattern 'Status:.*(0x.*)' -CaseSensitive).Matches.Value).split(":")[-1].trim()}}, `
                                    @{Name= 'Failure Sub Status';Expression={Get-FailureReason -FailureReason ((($_.Message) |  Select-String -Pattern 'Sub Status:.*(0x.*)' -CaseSensitive).Matches.Value).split(":")[-1].trim()}}
            }
    }

    end {

    }
}
