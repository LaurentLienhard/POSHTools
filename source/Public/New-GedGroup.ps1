function New-GedGroup {
    [CmdletBinding(DefaultParameterSetName="ByGroupName")]
    param (
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName="ByGroupName",
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$Identity,
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName="ByFile")]
        [string]$Path,
        [Parameter(Mandatory=$true,
        Position=1,
        ParameterSetName="ByFile")]
        [string]$WorkSheetName,
        [Parameter(Mandatory=$true,
        Position=2,
        ParameterSetName="ByFile")]
        [System.String]$HeaderRow,
        [Parameter(Mandatory=$true,
                   Position=10)]
        [System.Management.Automation.PSCredential]$Credential
    )

    begin {

    }
    
    process {
        switch ($PsCmdlet.ParameterSetName) {
            "ByGroupName" { 
                $GroupNames = $Identity
             }
            "ByFile" {
                $Data = Import-Excel -Path $Path -WorksheetName $WorkSheetName -HeaderRow $Header
                $GroupNames = $Data."Groupe IRISNext" | Select-Object -Unique
            }
        }

        foreach ($group in $GroupNames) {
            Write-Verbose "test if AD group $group exists"
            try {
                $null = Get-ADGroup -Identity $group -ErrorAction Stop  
                Write-Verbose "AD group $group exists"
            }
            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                Write-Verbose "AD group $group does not exist"
                Write-Verbose "creating AD group $group"
                New-ADGroup -Name $group -SamAccountName $group -GroupCategory "Security" -GroupScope "Global" -Path "OU=GED,OU=Applicatifs,OU=Groupes,OU=GIP,OU=PHS,DC=netintra,DC=local"
                If ($group -like "OP_*") {
                    Write-Verbose "adding $group to group OP_All-groups"
                    Add-ADGroupMember -Identity "OP_All-groups" -Members $group
                } elseif ($group -like "HM_*") {
                    Write-Verbose "adding $group to group HM_ALL-Groups"
                    Add-ADGroupMember -Identity "HM_ALL-Groups" -Members $group
                }
            }

            $group = $group + "-Test"
            Write-Verbose "test if AD group $group exists"
            try {
                $null = Get-ADGroup -Identity $group -ErrorAction Stop  
                Write-Verbose "AD group $group exists"
            }
            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                Write-Verbose "AD group $group does not exist"
                Write-Verbose "creating AD group $group"
                New-ADGroup -Name $group -SamAccountName $group -GroupCategory "Security" -GroupScope "Global" -Path "OU=TEST,OU=GED,OU=Applicatifs,OU=Groupes,OU=GIP,OU=PHS,DC=netintra,DC=local"
                If ($group -like "OP_*") {
                    Write-Verbose "adding $group to group OP_ALL-GroupsTest"
                    Add-ADGroupMember -Identity "OP_ALL-GroupsTest" -Members $group
                } elseif ($group -like "HM_*") {
                    Write-Verbose "adding $group to group HM_ALL-GroupsTest"
                    Add-ADGroupMember -Identity "HM_ALL-GroupsTest" -Members $group
                }
            }
        }
        
    }
    
    end {
        
    }
}