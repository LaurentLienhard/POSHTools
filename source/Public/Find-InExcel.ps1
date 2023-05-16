function Find-InExcel
{
    <#
.SYNOPSIS
Find information in a excel file

.DESCRIPTION
This function return any informations from any Excel File. This function is based on the headers present in Excel file

.PARAMETER FilePath
Full path from de Excel file

.PARAMETER WorkSheetName
Name of the worksheet- where i was looking for the information. "Sheet1" by default

.PARAMETER HeaderRow
Number of the header row. "1" by defaults

.PARAMETER SearchRow
Column name used to filter the search

.PARAMETER DataRow
Column name return after the search. Can be on or more column

.PARAMETER SearchValue
The value tos search for in the column SearchRow

.EXAMPLE
Find-InExcel -FilePath "C:\PathToMyFile\MyFile.xlsx" -WorksheetName "Worksheet1" -HeaderRow "1" -SearchRow "Column1" -SearchValue "MyValue" -DataRow "Column3"

.EXAMPLE
Find-InExcel -FilePath "C:\PathToMyFile\MyFile.xlsx" -WorksheetName "Worksheet1" -HeaderRow "1" -SearchRow "Column1" -SearchValue "MyValue" -DataRow "Column3","Column1","Column2"

.NOTES
General notes
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateScript({
                if (-Not ($_ | Test-Path) )
                {
                    throw "File or folder does not exist"
                }
                if (-Not ($_ | Test-Path -PathType Leaf) )
                {
                    throw "The Path argument must be a file. Folder paths are not allowed."
                }
                if ($_ -notmatch "(\.xlsx)")
                {
                    throw "The file specified in the path argument must be either of type xlsx"
                }
                return $true
            })]
        [System.IO.FileInfo]$FilePath,
        [Parameter()]
        [ArgumentCompleter( {
            param (
                $Command,
                $Parameter,
                $WordToComplete,
                $CommandAst,
                $FakeBoundParams
                )
                Get-ExcelSheetInfo -Path $Fakeboundparams.FilePath | Where-Object { $_.Name -like "*$WordToComplete*" } | Select-Object -ExpandProperty Name
        })]
        [System.String]$WorkSheetName = "Sheet1",
        [Parameter()]
        [System.String]$HeaderRow = "1",
        [Parameter()]
        [ArgumentCompleter( {
            param (
                $Command,
                $Parameter,
                $WordToComplete,
                $CommandAst,
                $FakeBoundParams
                )

                Import-Excel -Path $Fakeboundparams.FilePath -WorksheetName $Fakeboundparams.WorkSheetName -HeaderRow $Fakeboundparams.HeaderRow | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -like "*$WordToComplete*" } | Select-Object -ExpandProperty Name
        })]
        [System.String]$SearchRow,
        [Parameter()]
        [ArgumentCompleter( {
            param (
                $Command,
                $Parameter,
                $WordToComplete,
                $CommandAst,
                $FakeBoundParams
                )
                Import-Excel -Path $Fakeboundparams.FilePath -WorksheetName $Fakeboundparams.WorkSheetName -HeaderRow $Fakeboundparams.HeaderRow | Select-Object -exp $Fakeboundparams.SearchRow
        })]
        [System.string[]]$SearchValue = '*',
        [Parameter()]
        [ArgumentCompleter( {
            param (
                $Command,
                $Parameter,
                $WordToComplete,
                $CommandAst,
                $FakeBoundParams
                )
                Import-Excel -Path $Fakeboundparams.FilePath -WorksheetName $Fakeboundparams.WorkSheetName -HeaderRow $Fakeboundparams.HeaderRow | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -like "*$WordToComplete*" } | Select-Object -ExpandProperty Name
        })]
        [System.String[]]$DataRow
    )

    begin
    {
        Import-Module ImportExcel -Verbose:$false
        Write-Verbose ('[{0:O}] Importing data from {1}' -f (get-date), $FilePath)
        $Data = Import-Excel -Path $FilePath -WorksheetName $WorkSheetName -HeaderRow $HeaderRow

        Write-Verbose ('[{0:O}] Headers validation' -f (get-date))
        $FileHeaders = $data | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        foreach ($header in ($DataRow + $SearchRow))
        {
            if ($header -notin $FileHeaders)
            {
                throw "Header $($Header) not found"
            }
            else
            {
                Write-Verbose ('[{0:O}] Header "{1}" validate' -f (get-date), $Header)
            }
        }
    }

    process
    {

        $Result = @()
        if ($SearchValue -eq "*")
        {
            $Result = $data | Select-Object -Property $DataRow
        }
        else
        {
            foreach ($Value in $SearchValue)
            {
                Write-Verbose ('[{0:O}] Searching {1} in column {2}' -f (get-date), $Value, $SearchRow)
                $Result += $data | Where-Object { $_.$SearchRow -eq $Value } | Select-Object -Property $DataRow
            }
        }
    }

    end
    {
        $Result
    }
}
