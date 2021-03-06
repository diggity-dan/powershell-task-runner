<#
Help section.

All scripts must accept LogFile parameter.
All scripts must accept MyDirectory parameter.
All scripts must accept ModuleDir parameter.
#>


[CmdletBinding()]
  
Param (

[Parameter(Mandatory=$False)]
[string]$ConfigFile = $null,

[Parameter(Mandatory=$False)]
[string]$ScriptDir = $null,

[Parameter(Mandatory=$False)]
[string]$ModuleDir = $null,

[Parameter(Mandatory=$False)]
[string]$OutputDir = $null,

[Parameter(Mandatory=$False)]
[string]$DestinationDir = $null,

[Parameter(Mandatory=$False)]
[string]$LogFile = $null,

[Parameter(Mandatory=$False)]
[int]$LogDays = 5

) 


#################################################
# Get relative path for execution/loading modules:
#################################################

#For running in the ISE - $MyInvocation works only from command line:
If($psISE.CurrentFile.FullPath.Length -gt 0){
    $ThisScriptPath = (Split-Path -Parent -Path $psISE.CurrentFile.FullPath)
}
Else {
    $ThisScriptPath = (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)
}

#If params are null, load defaults using relative paths.
If(-not $ConfigFile){
    $ConfigFile = $ThisScriptPath + "\config\script.config"
}

If(-not $ModuleDir) {
    $ModuleDir = $ThisScriptPath + "\modules"
}

If(-not $ScriptDir){
    $ScriptDir = $ThisScriptPath + "\scripts"
}

If(-not $OutputDir){
    $OutputDir = $ThisScriptPath + "\output"
}

If(-not $DestinationDir){
    $DestinationDir = $ThisScriptPath + "\destination"
}

#################################################
# Import all modules:
#################################################

$ModuleList = (Get-ChildItem -Path $ModuleDir -Filter "*.psm1" -Recurse -Force)

ForEach($Module in $ModuleList) {
    Import-Module -Name $Module.FullName -DisableNameChecking -Force
}

###################################################
#Read config:
###################################################

#Set Default Config Tokens:

#Read in file
$TempFile = [IO.File]::ReadAllText($ConfigFile)

#Current Script Location:
$TempFile = $TempFile.Replace("{{MYLOCATION}}", $($ThisScriptPath))

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

#Destination Directory:
$TempFile = $TempFile.Replace("{{DESTINATIONDIR}}", $($DestinationDir))

#Set configuration:
[XML]$Configuration = $TempFile


###################################################
#Setup Logging:
###################################################

#Check for configured logfile:
If($Configuration.root.globals.logfile){

    $LogFile = $Configuration.root.globals.logfile
    
}
#Set default log if command line option not set:
ElseIf (-not $LogFile) {

    $Date = (Get-Date -Format "dd-MMM-yyyy")
    $LogFile = $ThisScriptPath + "\logs\Task-Runner-$($Date).log"
}


#Clean up old log files:
$LogDir = $(Split-Path $LogFile -leaf)

If((Test-Path $LogDir)) {
    Remove-Generic -RootPath $LogDir -FileAge $LogDays | Out-Null
}


#################################################
# Create hash table of scripts:
# Add Common Runtime Params
#################################################

$ScriptList = (Get-ChildItem -Path $ScriptDir -Filter "*.ps1" -Recurse -Force)
$CommandHash = @{}

#Load all the scripts into the CommandHash:
ForEach($Script in $ScriptList) {

    $CommandArgs = @{}
    
    #Add standard params for all scripts:

    #LogFile:
    $CommandArgs.Add("LogFile", $LogFile)

    #Module Directory:
    $CommandArgs.Add("ModuleDir", $ModuleDir)

    #Set parent directory for each individual script:
    $CommandArgs.Add("MyDirectory", (Split-Path -Parent -Path $Script.FullName))
    
    #Tie script and args:
    $CommandHash.Add($Script.FullName, $CommandArgs)
}

#################################################
# Integrate script configuration with standard params:
#################################################

#Build Persistent Execution Frequency Hash:
$FreqHash = @{}

#Iterate the configuration:
ForEach($Script in $Configuration.root.script) {

    $ConfigItemName = $ScriptDir + $Script.name
    $ArgsHash = @{}
    
    #Add item + frequency to the FreqHash:
    If($Script.frequency){
        $FreqHash.Add($ConfigItemName, $Script.frequency)
    }
    
    #Ensure the script has params:
    If($Script.param){
    
        #Cycle through all params in the configuration:
        ($Script.param | % {
            #Load config file if PassConfig = True
            If($_.name -eq "PassConfig" -and ($_.'#text') -eq "True"){
                $ArgsHash.Add("Config", $Configuration)
            }
            Else {
                $ArgsHash.Add($_.name, ($_.'#text'))
            }
        })
    
    } #If $Script.param
    
    #Add the configured parameters to the command script:
    ForEach($Key in $ArgsHash.Keys){
        
        #Update the configuration value:
        If($CommandHash.ContainsKey($ConfigItemName) ){
        
            $CommandHash.$ConfigItemName.Add($Key, $ArgsHash[$Key])
            
        } #If $CommandHash.ContainsKey
        
    } #ForEach $Key in $ArgsHash
    
} #ForEach $Script in $Configuration


###################################################
#Execute Scripts:
###################################################

#Iterate all scripts:
ForEach($Key in $CommandHash.Keys){

    #Get/Create the runcontrol file for this script:
    $RunControlFile = $CommandHash[$Key].MyDirectory + "\runcontrol.txt"

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
    
    
    #Check for override frequency in FreqHash,
    #Else use global value:
    If($FreqHash.ContainsKey($Key)){
        $Freq = $FreqHash[$Key]
    }
    Else {
        $Freq = $Configuration.root.globals.frequency
    } #If $FreqHash.ContainsKey

    #Ensure script should executed according to frequency:
    If($TimeDiff -ge $Freq){
    
        #Clone the configured parameters for the script
        $ParamClone = $CommandHash[$Key].Clone()
    
        #Start logging:
        Log-Start -LogFile $LogFile -JobName "$(Split-Path $Key -leaf)"
        Log-Write -LogFile $LogFile -LineValue ("-" * 50)
        Log-Write -LogFile $LogFile -LineValue "User: $($env:UserDomain)\$($env:UserName)"
        Log-Write -LogFile $LogFile -LineValue "Executing: $(Split-Path $Key -leaf)"
        Log-Write -LogFile $LogFile -LineValue ("-" * 50)

        #Log Arguments too:
        Log-Write -LogFile $LogFile -LineValue "Script Arguments: `r`n"
        ForEach($Arg in $CommandHash[$Key].Keys){
            Log-Write -LogFile $LogFile -LineValue "$($Arg) = $($CommandHash.$Key.$Arg)"
        }

        Log-Write -LogFile $LogFile -LineValue ("-" * 50)

        #Run script:
        Try{
            [void](. $Key @ParamClone)
        }
        Catch {
            Log-Write -LogFile $LogFile -LineValue "Error:"
            Log-Write -LogFile $LogFile -LineValue "$($_.Exception)"
            Continue
        }
        
        #Update execution time for next run:
        Get-Date | Set-Content $RunControlFile

        #End Logging:
        Log-Finish -LogFile $LogFile -JobName "$(Split-Path $Key -leaf)"
    
    } #If $TimeDiff -gt $Freq
    
    
} #ForEach $Key in $CommandHash



