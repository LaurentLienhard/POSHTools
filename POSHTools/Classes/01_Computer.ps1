class COMPUTER {
    #region <Properties>
    [System.String]$Name
    [System.Boolean]$Alive
    [System.String]$Type
    #endregion <Properties>

    #region <Constructor>
    COMPUTER() {
    }

    COMPUTER([System.String]$Name) {
        $This.Name = $Name
        $this.Alive = [COMPUTER]::TestIfAlive($this.Name)
        $this.Type = [COMPUTER]::TestIfServer($this.Name)
    }
    #endregion <Constructor>

    #region <Method>
    #region <Static>
    STATIC [System.Boolean] TestIfAlive ([System.String]$Name) {
       Return (Test-Connection -Ping -IPv4 -Count 1 -Quiet -TargetName $Name)
    }

    STATIC [System.String] TestIfServer ([System.String]$Name) {
        if ((Get-ADComputer -Identity $Name -Properties OperatingSystem | Select-Object OperatingSystem) -like "*Windows*Server*") {
            Return "SERVER"
        } else {
            Return "COMPUTER"
        }
     }
    #endregion <Static>

    #endregion <Method>
}
