function Get-MailboxesStatistics {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Wich company. Default is OPHEA"
        )]
        [ValidateSet("HM", "OPHEA")]
        [string]$Company = "OPHEA",

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Get (only) Shared Mailboxes or not. Default is no"
        )]
        [ValidateSet("no", "only", "include")]
        [string]$sharedMailboxes = "no",
        [Parameter(
            Mandatory = $false,
            HelpMessage = "Include Archive mailboxes. Default is false"
        )]
        [switch]$archive = $false 
    )
    
    begin {
        ConnectTo-EXO
        
    }
    
    process {

        switch ($sharedMailboxes) {
            "include" { $mailboxTypes = "UserMailbox,SharedMailbox" }
            "only" { $mailboxTypes = "SharedMailbox" }
            "no" { $mailboxTypes = "UserMailbox" }
        }

        switch ($Company) {
            "OPHEA" { $UserList = Get-User -Filter { Company -eq "OPHEA" } -RecipientTypeDetails $mailboxTypes | Select-Object UserPrincipalName, WindowsEmailAddress, Company, DisplayName }
            "HM" { $UserList = Get-User -Filter { Company -eq "HABITATION MODERNE" } -RecipientTypeDetails $mailboxTypes | Select-Object UserPrincipalName, WindowsEmailAddress, Company, DisplayName }
        }

        $result = @()
        $UserList | ForEach-Object {
            $mailboxSize = Get-MailboxStatistics -identity $_.UserPrincipalName | Select-Object TotalItemSize, TotalDeletedItemSize, ItemCount, DeletedItemCount, LastUserActionTime
        
        
            $Stat = [pscustomobject]@{
                "UPN"                     = $_.UserPrincipalName
                "Email Address"           = $_.WindowsEmailAddress
                "Last User Action Time"   = $mailboxSize.LastUserActionTime
                "Total Size (GB)"         = [math]::Round(($mailboxSize.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",", "")) / 1GB, 2)
                "Deleted Items Size (GB)" = [math]::Round(($mailboxSize.TotalDeletedItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",", "")) / 1GB, 2)
            }

            $result += $Stat
        }        
    }
    
    end {
        return $result
    }
}