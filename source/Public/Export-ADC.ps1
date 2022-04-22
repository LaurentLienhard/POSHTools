function Export-ADC {
    [CmdletBinding()]
    param (
        [ValidateScript(
            {
                [System.IO.Path]::GetExtension($_.Name) -eq ".csv"
            }
            )]
        [System.IO.FileInfo]$CSVFile = "$env:temp\Export-ADC.csv"
    )
    
    begin {
        if ([System.IO.File]::Exists($CSVFile)) {
            Write-Verbose ('[{0:O}] file {1} exist => remove' -f (get-date),$CSVFile.Name)
            Remove-Item -Path $CSVFile -Force -Confirm:$false
        } 
        Write-Verbose ('[{0:O}] Create file {1}' -f (get-date),$CSVFile.Name)
        New-Item -Path $CSVFile -ItemType File -Force -Confirm:$false
    }
    
    process {

        Write-Verbose ('[{0:O}] Treatment of OPHEA users' -f (get-date))
        $OpheaGroups = "CH-Licences O365-E5","CH-Licences 0365-F1"
        ForEach($Group in $OpheaGroups) {
             Get-ADGroupMember -Identity $Group | ForEach-Object {
                        $User = Get-ADUser -Identity $_.SamAccountName -Properties * | Select-Object SamAccountName,GivenName, SurName, Mail, Company, extensionAttribute6, Enabled | Where-Object {$_.Company -notin "ADMINISTRATEURS","PRESTATAIRE","TEST","SERVICES","SUPPORT"}
                        if ($user.Enabled) {
                            if ($null -eq $User.Mail) { 
                                Set-ADUser -Identity $user.SamAccountName -Replace @{Mail=$user.UserPrincipalName}
                                $User = Get-ADUser -Identity $_.SamAccountName -Properties * | Select-Object SamAccountName,GivenName, SurName, UserPrincipalName, Mail, Company, Department,Enabled
                            }
                            if (($user.company -eq "OPHEA") -or ($user.company -eq "GIP")) {
                                Write-Verbose ('[{0:O}] Treatment of {1}' -f (get-date),$_.SamAccountName)
                                $Mail = $user.Mail
                                $GivenName = (Get-Culture).TextInfo.ToTitleCase($User.GivenName)
                                $SurName = $User.SurName.ToUpper()
                                $Service = "[CH] $($User.extensionAttribute6)"
                                $Company = "OPHEA"
        
                                Add-content -Path $CSVFile -Value "$Mail,personal,$GivenName,$SurName,$Company,$Service,video,FR,Europe/Paris"
                            }
                        }
            }
        }
        

        Write-Verbose ('[{0:O}] Treatment of HABITATION MODERNE users' -f (get-date))
        $HMGroups = "HM-Licences O365-E5","HM-Licences O365-F1"
        ForEach($Group in $HMGroups) {
             Get-ADGroupMember -Identity $Group | ForEach-Object {
                        $User = Get-ADUser -Identity $_.SamAccountName -Properties * | Select-Object SamAccountName,GivenName, SurName, UserPrincipalName, Mail, Company, Department,Enabled | Where-Object {$_.Company -notin "ADMINISTRATEURS","PRESTATAIRE","TEST","SERVICES","SUPPORT"}
                        if ($user.Enabled){
                            if ($null -eq $User.Mail) { 
                                Set-ADUser -Identity $user.SamAccountName -Replace @{Mail=$user.UserPrincipalName}
                                $User = Get-ADUser -Identity $_.SamAccountName -Properties * | Select-Object SamAccountName,GivenName, SurName, UserPrincipalName, Mail, Company, Department,Enabled
                            }
                            if (($user.company -eq "HABITATION MODERNE") -or ($user.company -eq "GIP")) {
                                Write-Verbose ('[{0:O}] Treatment of {1}' -f (get-date),$_.SamAccountName)
                                $Mail = $user.Mail
                                $GivenName = (Get-Culture).TextInfo.ToTitleCase($User.GivenName)
                                $SurName = $User.SurName.ToUpper()
                                $Service = "[HM] $($User.Department)"
                                $Company = "HABITATION MODERNE"
        
                                Add-content -Path $CSVFile -Value "$Mail,personal,$GivenName,$SurName,$Company,$Service,video,FR,Europe/Paris"
                            }
                        }
            }
        }   
    }
    
    end {
        
    }
}