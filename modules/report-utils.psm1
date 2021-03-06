

Function Report-CSV {
    <#
    .SYNOPSIS 
    Outputs/Appends DataObjects to a CSV file. 

    .DESCRIPTION
    Outputs/Appends DataObjects to a CSV file. 

    .PARAMETER FileOut
    Required. Specifies the file to write to. 
    Ex. "C:\Temp\SomeFile.csv"
    
    .PARAMETER ScriptName
    Required. Specifies the name of the script which generated the output. 
    Ex. "SomeAwesomeScript.ps1"
    
    .PARAMETER ComputerName
    Required. Specifies which computer the output is for. 
    Ex. "LOCALHOST"

    .PARAMETER DataObject
    Required. Specifies the data to write out.
        
    .INPUTS
    This script does not support pipeline inputs.

    .OUTPUTS
    This function returns the result or the error back to the calling script.

    .NOTES
    Author: Dan Anderson (danderson@nexidia.com)

    .EXAMPLE
    
    #>

    [CmdletBinding()]
    param(
    
    [Parameter(Mandatory=$False)]
    [string]$FileOut,
        
    [Parameter(Mandatory=$False)]
    [string]$ScriptName,
    
    [Parameter(Mandatory=$False)]
    [string]$ComputerName,
   
    [Parameter(Mandatory=$False)]
    $DataObject = @{}

    )

    Process {
                   
        #Default File:
        If(-not $FileOut){
            $DateFormat = (Get-Date -Format "dd-MMM-yyyy")
            $FileOut = "C:\Users\$($env:UserName)\Desktop\ScriptLibrary\$($env:ComputerName)-$($DateFormat)-LibraryOutput.csv"
        }
        
        
        #Make sure $DataObject has data:
        If( ($DataObject.Keys | Measure-Object).Count -gt 0 ) {
    
        
            #Check if file exists, if not, create it.
            If(-not (Test-Path -Path $FileOut)){
                New-Item -Path $FileOut -ItemType File -Force | Out-Null
            }
            Else {
                $ExistingCSV = [PSObject[]](Import-Csv -Path $FileOut)
            }
            
            
            #Create array for CSV:
            $CSVArray = @()       

            Try {
            
                #Loop the reporting object to extract Property/Values.
                ForEach ($Key in $DataObject.Keys){                   
                    
                    #Create a new object for each iteration:
                    $CSVObject = New-Object PSObject
                    
                    #Add all properties with values to the object
                    $CSVObject | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
                    $CSVObject | Add-Member -MemberType NoteProperty -Name "ScriptName" -Value $ScriptName
                    $CSVObject | Add-Member -MemberType NoteProperty -Name "PropertyName" -Value $Key
                    $CSVObject | Add-Member -MemberType NoteProperty -Name "PropertyValue" -Value ($DataObject.Get_Item($Key))
                    $CSVObject | Add-Member -MemberType NoteProperty -Name "DateAdded" -Value $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                    
                    #Add the object to the array:
                    $CSVArray += $CSVObject
                    
                } #ForEach Key in DataObject.Keys
                
                #Export:
                If(($ExistingCSV|Measure-Object).Count -gt 0){
                
                    #If we have rows for the existing object:
                    $CSVArray += $ExistingCSV
                    
                }
                
                #Write the file out:
                $CSVArray | Export-Csv -Path $FileOut -Force -Encoding "utf8" -NoTypeInformation
                

            }
            Catch {
                
                Return $_.Exception.Message
                
            } #Try/Catch
        
        
        } #If DataObject has data

    } #Process

} #end function




Function Report-CustomCSV {
    <#
    .SYNOPSIS 
    Outputs/Appends DataObjects to a CSV file. 

    .DESCRIPTION
    Outputs/Appends DataObjects to a CSV file. 

    .PARAMETER FileOut
    Required. Specifies the file to write to. 
    Ex. "C:\Temp\SomeFile.csv"
    
    .PARAMETER ScriptName
    Required. Specifies the name of the script which generated the output. 
    Ex. "SomeAwesomeScript.ps1"
    
    .PARAMETER ComputerName
    Required. Specifies which computer the output is for. 
    Ex. "LOCALHOST"

    .PARAMETER DataObject
    Required. Specifies the data to write out.
        
    .INPUTS
    This script does not support pipeline inputs.

    .OUTPUTS
    This function returns the result or the error back to the calling script.

    .NOTES
    Author: Dan Anderson (danderson@nexidia.com)

    .EXAMPLE
    
    #>

    [CmdletBinding()]
    param(
    
    [Parameter(Mandatory=$False)]
    [string]$FileOut,
        
    [Parameter(Mandatory=$False)]
    [string]$ScriptName,
    
    [Parameter(Mandatory=$False)]
    [string]$ComputerName,
    
    [Parameter(Mandatory=$False)]
    [bool]$AddDate = $False,
   
    [Parameter(Mandatory=$False)]
    $DataObject = @{}

    )

    Process {
                          
        #Default File:
        If(-not $FileOut){
            $DateFormat = (Get-Date -Format "dd-MMM-yyyy")
            $FileOut = "C:\Users\$($env:UserName)\Desktop\ScriptLibrary\$($env:ComputerName)-$($DateFormat)-LibraryOutput.csv"
        }
        
        
        #Make sure $DataObject has data:
        If( ($DataObject.Keys | Measure-Object).Count -gt 0 ) {
    
            Write-Host "Passed Key Check"
        
            #Check if file exists, if not, create it.
            If(-not (Test-Path -Path $FileOut)){
                New-Item -Path $FileOut -ItemType File -Force | Out-Null
                
                Write-Host "Passed File Creation Check"
            }
            Else {
                $ExistingCSV = [PSObject[]](Import-Csv -Path $FileOut)
            }
            
            
            #Create array for CSV:
            $CSVArray = @()       

            Try {
            
                #Create a new object:
                $CSVObject = New-Object PSObject
            
                #Add all static properties to the object if present.
                If($ComputerName){
                    $CSVObject | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $ComputerName
                }
                If($ScriptName){
                    $CSVObject | Add-Member -MemberType NoteProperty -Name "ScriptName" -Value $ScriptName
                }
                If($AddDate){
                    $CSVObject | Add-Member -MemberType NoteProperty -Name "DateAdded" -Value $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                }
                
                #Loop the reporting object to extract Property/Values.
                ForEach ($Key in $DataObject.Keys){                   

                    $CSVObject | Add-Member -MemberType NoteProperty -Name "$($Key)" -Value ($DataObject.Get_Item($Key))
                    
                } #ForEach Key in DataObject.Keys
                
                
                #Add the object to the array:
                $CSVArray += $CSVObject
                
                #Export:
                If(($ExistingCSV|Measure-Object).Count -gt 0){
                
                    #If we have rows for the existing object:
                    $CSVArray += $ExistingCSV
                    
                }
                
                #Write the file out:
                $CSVArray | Export-Csv -Path $FileOut -Force -Encoding "utf8" -NoTypeInformation
                

            }
            Catch {
                
                Return $_.Exception.Message
                
            } #Try/Catch
        
        
        } #If DataObject has data

    } #Process

} #end function




Export-ModuleMember -Function Report-CSV, Report-CustomCSV

