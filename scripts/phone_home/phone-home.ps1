


<#
Help Section

#Add instructions for each script.

#>



[CmdletBinding()]
  
Param (

[Parameter(Mandatory=$False)]
[string]$MyDirectory = $null,

[Parameter(Mandatory=$False)]
[string]$ModuleDir = $null,

[Parameter(Mandatory=$False)]
[string]$LogFile = $null,

[Parameter(Mandatory=$False)]
[string]$SourceDir = $null,

[Parameter(Mandatory=$False)]
[string]$DestinationDir = $null,

[Parameter(Mandatory=$False)]
[string]$IncludedFiles = $null

) 


#################################################
# Ensure we have a MyDirectory context:
#################################################

If(-not $MyDirectory){

    #For running in the ISE - $MyInvocation works only from command line:
    If($psISE.CurrentFile.FullPath.Length -gt 0){
        $MyDirectory = (Split-Path -Parent -Path $psISE.CurrentFile.FullPath)
    }
    Else {
        $MyDirectory = (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)
    }

}

#################################################
# Import required modules:
#################################################

#Make sure we have a ModuleDir value:
If(-not $ModuleDir){
    $ModuleDir = Resolve-Path "$($MyDirectory)\..\..\modules\"
}

#log-utils:
If(-not (Get-Module -Name "log-utils")){
    Import-Module -Name $ModuleDir\log-utils.psm1 -DisableNameChecking -Force
}

#################################################
# Ensure we have a logfile:
#################################################

#Get formatted date:
$FormattedDate = (Get-Date -Format "dd-MMM-yyyy")

#Make sure we have a logfile:
If(-not $LogFile){
    $LogFile = "$($MyDirectory)\log\Phone-Home-$($FormattedDate).log"
    Log-Start -LogFile $LogFile -JobName "Phone-Home.ps1"
}

#################################################
# Ensure we have a SourceDir:
#################################################

If(-not $SourceDir){
    #$SourceDir = Resolve-Path "$($MyDirectory)\..\..\updates\"
    Log-Write -LogFile $LogFile -LineValue "SourceDir parameter has not been specified. Exiting."
    Exit
}

#################################################
# Ensure we have a DestinationDir:
#################################################

If(-not $DestinationDir){
    #$DestinationDir = Resolve-Path "$($MyDirectory)\..\..\destination\"
    Log-Write -LogFile $LogFile -LineValue "DestinationDir parameter has not been specified. Exiting."
    Exit
}

#################################################
# Ensure we have included file types:
#################################################

$IncludeFilter = @()

If(-not $IncludedFiles){
    $IncludeFilter = "*.ps1", "*.psm1", "*.sql", "*.cmd"
    #Log-Write -LogFile $LogFile -LineValue "IncludedFiles parameter has not been specified. Exiting."
    #Exit
}
Else {
    #When splitting from command line, the delimiter must be exact.
    #Even include the space if using item, item2, etc
    $IncludeFilter = $IncludedFiles -Split ', '
}

#################################################
# Get list of files to move:
#################################################

Log-Write -LogFile $LogFile -LineValue "Checking for files in $($SourceDir) ..."

$FileCollection = Get-ChildItem -Path $SourceDir -Include $IncludeFilter -Recurse -Force -ErrorAction SilentlyContinue `
| Where-Object {-not $_.PSIsContainer} | Select-Object -Property FullName, DirectoryName, Name

$FileCount = ($FileCollection | Measure-Object).Count

Log-Write -LogFile $LogFile -LineValue "Found $($FileCount) files to move."
Log-Write -LogFile $LogFile -LineValue ("-" * 50)

#################################################
# Move files:
#################################################

If($FileCount -gt 0){

    ForEach($File in $FileCollection){
        
        Try {
        
            #Build the directory, and full path from the source:
            $TargetDir = $File.DirectoryName.Replace($SourceDir, $DestinationDir)
            $Target = $File.FullName.Replace($SourceDir, $DestinationDir)
            
            Log-Write -LogFile $LogFile -LineValue "Moving file: $($File.FullName)"
            Log-Write -LogFile $LogFile -LineValue "To: $($Target)"
            
            #Create target directory if it doesn't exist:
            If(-not (Test-Path -Path $TargetDir) ) {
                New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
            }
            
            #Copy the file:
            Copy-Item -Path $File.FullName -Destination $Target -Recurse -Force
            Log-Write -LogFile $LogFile -LineValue "Complete. `r`n"
            
        }
        Catch {
        
            Log-Write -LogFile $LogFile -LineValue "$($_.Exception.Message)"
            Continue
        }
        
    } #ForEach $File in $FileCollection

} #If $FileCount -gt 0


#Log-Write -LogFile $LogFile -LineValue ("-" * 50)