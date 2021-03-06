


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
[string]$ConfigFile = $null,

[Parameter(Mandatory=$False)]
[string]$QueryDir = $null,

[Parameter(Mandatory=$False)]
[string]$OutputDir = $null


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

#sql-utils:
If(-not (Get-Module -Name "sql-utils")){
    Import-Module -Name $ModuleDir\sql-utils.psm1 -DisableNameChecking -Force
}


#################################################
# Ensure we have a logfile:
#################################################

#Get formatted date:
$FormattedDate = (Get-Date -Format "dd-MMM-yyyy")

#Make sure we have a logfile:
If(-not $LogFile){
    $LogFile = "$($MyDirectory)\log\Query-Runner-$($FormattedDate).log"
    Log-Start -LogFile $LogFile -JobName "Query-Runner.ps1"
}

#################################################
# Ensure we have a ConfigFile:
#################################################

If(-not $ConfigFile){
    $ConfigFile = "$($MyDirectory)\config\script.config"
}

#################################################
# Ensure we have a QueryDir:
#################################################

If(-not $QueryDir){
    $QueryDir = "$($MyDirectory)\queries"
}

#################################################
# Ensure we have an OutputDir:
#################################################

If(-not $OutputDir){
    $OutputDir = "$($MyDirectory)\output"
}

###################################################
#Read config:
###################################################

#Set Default Config Tokens:

#Read in file
$TempFile = [IO.File]::ReadAllText($ConfigFile)

#CurrentUserProfile:
$TempFile = $TempFile.Replace("{{USERPROFILE}}", $($env:UserProfile))

#CurrentDate:
$TempFile = $TempFile.Replace("{{DATE}}", $(Get-Date -Format "dd-MMM-yyyy"))

#HostName:
$TempFile = $TempFile.Replace("{{HOSTNAME}}", $($env:ComputerName))

#Database Server:
$TempFile = $TempFile.Replace("{{DBSERVER}}", $($env:ComputerName))

#Output Directory:
$TempFile = $TempFile.Replace("{{OUTPUTDIR}}", $($OutputDir))

#Set configuration:
[XML]$Configuration = $TempFile

###################################################
#Loop config:
###################################################

ForEach($Script in $Configuration.root.script) {

    #Get query:
    $QueryFile = (Get-Item -Path ($QueryDir + $Script.Name) -Force)
    
    #Get DBServer
    If($Script.DbServer){
        $DBServer = $Script.DbServer
    }
    Else {
        $DBServer = $Configuration.root.globals.dbserver 
    }
    
    #Get DBName:
    If($Script.DbName){
        $DBName = $Script.DbName
    }
    Else {
        $DBName = $Configuration.root.globals.dbname
    }
    
    #Get Frequency:
    If($Script.Frequency){
        $Freq = $Script.Frequency
    }
    Else {
        $Freq = $Configuration.root.globals.frequency
    }
    
    #Get OutputDir:
    If($Script.OutputDir){
        $OutputDir = $Script.OutputDir
    }
    Else {
        $OutputDir = $Configuration.root.globals.outputdir
    }
    
    #Get FileExtension:
    If($Script.FileExtension){
        $FileExtension = $Script.FileExtension
    }
    Else {
        $FileExtension = $Configuration.root.globals.fileExtension
    }
    
    #Ensure OutputDir exists:
    If(-not (Test-Path $OutputDir) ){
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    #Get/Create the runcontrol file for this script:
    $RunControlFile = (Join-Path $($QueryFile.Directory) "\runcontrol.txt")

    #Create RunControlFile if it doesn't exist:
    If(-not (Test-Path -Path $RunControlFile) ) {
    
        New-Item -Path $RunControlFile -ItemType File -Force | Out-Null
        #Write current date/time to file:
        Get-Date | Set-Content $RunControlFile
        
        #Set RunControl time for current run.
        [datetime]$RunControlTemp = (Get-Date)
        
    }
    Else {
        #Get previous execution time:
        [datetime]$RunControlTemp = [IO.File]::ReadAllText($RunControlFile)
    }
    
    #Set the time difference from last run:
    $TimeDiff = (New-TimeSpan -Start $RunControlTemp -End $(Get-Date) ).Minutes
    
    #Ensure script should executed according to frequency:
    If($TimeDiff -ge $Freq){
    
        Log-Write -LogFile $LogFile -LineValue "Executing: $($QueryFile)"
            
        #Read in the contents of the query:
        $QueryText = [IO.File]::ReadAllText($QueryFile)
        
        #Execute the query:
        $ReportObj = (Sql-Select -Server $DBServer -Database $DBName -Query $QueryText)
        
        #Create the output file:
        $OutputFile = ($OutputDir + "\" + $QueryFile.BaseName + "-" + $FormattedDate + $FileExtension)
        
        #Write the output file:
        
        #If the extension is not csv, write each row from the data object:
        If($FileExtension -ne ".csv"){
            
            If(-not (Test-Path $OutputFile) ){
                New-Item -Path $OutputFile -ItemType File -Force | Out-Null
            }
            
            For($i=0; $i -lt ($ReportObj | Measure-Object).Count; $i++){
                $ReportObj[$i] | Add-Content $OutputFile
            }
            
        }
        #Extension is csv, so use built-in powershell to create the file:
        Else {
            $ReportObj | Export-Csv -Path $OutputFile -Force -Encoding "utf8" -NoTypeInformation
        }
        
        Log-Write -LogFile $LogFile -LineValue "Created output file: $($OutputFile)"
        Log-Write -LogFile $LogFile -LineValue ("-" * 50)
        
        #Update execution time for next run:
        Get-Date | Set-Content $RunControlFile
    
    }
    

} #ForEach $Script in $Configuration.Root.Script