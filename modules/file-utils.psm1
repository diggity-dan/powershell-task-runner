
Function Find-Files {

    <#
    .SYNOPSIS
    Queries the system for files which fall into the size, type, and age given.

    .DESCRIPTION
    Runs recursively on the path given. A very large number of files
    will take time to complete. Ouptuts an array of PS objects.

    .PARAMETER RootPath
    Required. Path to start looking for the files. 
    Ex. "C:\Program Files"

    .PARAMETER MinSize
    Required. Minimum size for a file to be included in the results. 
    Ex. 20KB
    
    .PARAMETER MaxSize
    Optional. Maximum size for a file to be included in the results. 
    Ex. 1GB
    Default = 1TB
       
    .PARAMETER FileType
    Optional. Specifies the filter for the file type. If $null, all
    files are searched.
    Ex. *.bak
    Default = $null
    
    .PARAMETER FileAge
    Optional. Specifies the age in days the file should be greater or equal to relative to current date.
    Ex. 15
    Default = 0
    
    .INPUTS
    This function does not support pipeline inputs.

    .OUTPUTS
    This function returns an array of PS objects to the calling script.    

    .NOTES
    Author: Dan Anderson (danderson@nexidia.com)

    .EXAMPLE
    Find-Files -RootPath "C:\Program Files" -MinSize 5MB
    
    .EXAMPLE
    Find-Files -RootPath "C:\Program Files" -MinSize 5MB -MaxSize 20MB
    
    .EXAMPLE
    Find-Files -RootPath "C:\Program Files" -MinSize 5MB -MaxSize 20MB -FileType "*.bak"
    
    .EXAMPLE
    Find-Files -RootPath "C:\Program Files" -MinSize 5MB -MaxSize 20MB -FileType "*.bak" -FileAge 15
    #>

    [CmdletBinding()]
      
    Param (
    [Parameter(Mandatory=$True)]
    [string]$RootPath = "C:\",
      
    [Parameter(Mandatory=$True)]
    [long]$MinSize = 15KB,
    
    [Parameter(Mandatory=$False)]
    [long]$MaxSize = 1TB,
    
    [Parameter(Mandatory=$False)]
    [string]$FileType = $null,
    
    [Parameter(Mandatory=$False)]
    [int]$FileAge = 0
    
    )  


    Process {

        #Setup Runtime Params:
        $Results = New-Object System.Collections.ArrayList
        $PropHash = @{}
        
        #Find matching files:
        #Determine if FileType has been specified:
        If($FileType) {
            $Files = (Get-ChildItem -Path $RootPath -Filter $FileType -Recurse -Force -ErrorAction SilentlyContinue |  `
            Where-Object {(-not $_.PSIsContainer) -and $_.Length -ge $MinSize -and $_.Length -le $MaxSize -and $_.LastWriteTime -le (Get-Date).AddDays(-$FileAge)}) 
        } 
        Else {
            $Files = (Get-ChildItem -Path $RootPath -Recurse -Force -ErrorAction SilentlyContinue | `
            Where-Object {(-not $_.PSIsContainer) -and $_.Length -ge $MinSize -and $_.Length -le $MaxSize -and $_.LastWriteTime -le (Get-Date).AddDays(-$FileAge)})
        }
        
        #Count files found:
        $FileCount = ($Files | Measure-Object).Count
        
        If ($FileCount -gt 0) {
        
            ForEach($File in $Files){
            
                #Store the results into the hash:
                $PropHash.DirPath = $File.Directory.FullName
                $PropHash.FullName = $File.FullName
                $PropHash.File = $File.Name
                $PropHash.LastWriteTime = $File.LastWriteTime
                $PropHash.SizeInB = ($File.Length)
                #$PropHash.SizeInKB = [float]::Parse("{0:N2}" -f ($File.Length/1KB))
                #$PropHash.SizeInMB = [float]::Parse("{0:N2}" -f ($File.Length/1MB))
                #$PropHash.SizeInGB = [float]::Parse("{0:N2}" -f ($File.Length/1GB))
                
                #Push the hash onto the array:
                #New object syntax is for outputting to built-in PS methods.
                $Results.Add((New-Object PSObject -Property $PropHash)) | Out-Null
                
                #Reset the prop hash:
                $PropHash = @{}
            
            } #End ForEach($File in $Files)
        
        } #If $FileCount -gt 0
    
        Return $Results

    } #End Process

} #End Function



Function Find-Folders {

    <#
    .SYNOPSIS
    Queries the system for Folders which fall into the size range given.

    .DESCRIPTION
    Runs recursively on the path given. A very large number of files
    will take time to complete. Ouptuts an array of PS objects.

    .PARAMETER RootPath
    Required. Path to look in for the folders. 
    Ex. "C:\Windows\Temp"

    .PARAMETER MinSize
    Required. Minimum size for a folder to be included in the results. 
    Ex. 20KB
    
    .PARAMETER MaxSize
    Optional. Maximum size for a folder to be included in the results. 
    Ex. 1GB
    Default = 1TB
    
    .PARAMETER Inclusive
    Optional. Also checks the RootPath size, instead of only sub-folders.
    Valid inputs = $True or $False
    Ex. $False
    Default = $True    

    .INPUTS
    This function does not support pipeline inputs.

    .OUTPUTS
    This function returns an array of PS objects to the calling script.    

    .NOTES
    Author: Dan Anderson (danderson@nexidia.com)

    .EXAMPLE
    Find-Folders -RootPath "C:\Program Files" -MinSize 5MB
    
    .EXAMPLE
    Find-Folders -RootPath "C:\Program Files" -MinSize 5MB -MaxSize 20MB
    
    .EXAMPLE
    Find-Folders -RootPath "C:\Program Files" -MinSize 5MB -MaxSize 20MB -Inclusive $False
    #>

    [CmdletBinding()]
      
    Param (
    [Parameter(Mandatory=$True)]
    [string]$RootPath = "C:\Windows\Temp",
      
    [Parameter(Mandatory=$True)]
    [long]$MinSize = 100MB,
    
    [Parameter(Mandatory=$False)]
    [long]$MaxSize = 1TB,
    
    [Parameter(Mandatory=$False)]
    [bool]$Inclusive = $True
    
    )  


    Process {

        #Setup Runtime Params:
        $Results = New-Object System.Collections.ArrayList
        $PropHash = @{}
        $DirList = (Get-ChildItem -Path $RootPath -Force -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer})
        
        #Find files in $RootPath to remove matching criteria:
        If($Inclusive -eq $True) {
        
            #Grab summary info:
            $Files = (Get-ChildItem -Path $RootPath -Force -ErrorAction SilentlyContinue | Where-Object {(-not $_.PSIsContainer)})
            $FileCount = ($Files | Measure-Object).Count
            $CurrentDirSize = ($Files | Measure-Object -Property Length -Sum)
            
            If($CurrentDirSize.sum -ge $MinSize -and $CurrentDirSize.sum -le $MaxSize) {
                #Create the hash:
                $PropHash.DirPath = $RootPath
                $PropHash.NumFiles = $FileCount
                $PropHash.SizeInB = [float]::Parse("{0:N2}" -f ($CurrentDirSize.sum -as [float]))
                #$PropHash.SizeInKB = [float]::Parse("{0:N2}" -f ($CurrentDirSize.sum/1KB))
                #$PropHash.SizeInMB = [float]::Parse("{0:N2}" -f ($CurrentDirSize.sum/1MB))
                #$PropHash.SizeInGB = [float]::Parse("{0:N2}" -f ($CurrentDirSize.sum/1GB))
                
                #Push the hash onto the array:
                #New object syntax is for outputting to built-in PS methods.
                $Results.Add((New-Object PSObject -Property $PropHash)) | Out-Null

                #Reset hash and counters:
                $PropHash = @{}
                
            } #If CurrentDirSize
        
        } #If $Inclusive
        
        
        #Iterate through each sub-directory.
        ForEach($Dir in $DirList) {
        
            #Grab summary info:
            $Files = (Get-ChildItem -Path $Dir.FullName -Force -ErrorAction SilentlyContinue | Where-Object {(-not $_.PSIsContainer)})
            $FileCount = ($Files | Measure-Object).Count
            $CurrentDirSize = ($Files | Measure-Object -Property Length -Sum)
            
            If($CurrentDirSize.sum -ge $MinSize -and $CurrentDirSize.sum -le $MaxSize) {
                #Create the hash:
                $PropHash.DirPath = $Dir.Fullname
                $PropHash.NumFiles = $FileCount
                $PropHash.SizeInB = [float]::Parse("{0:N2}" -f ($CurrentDirSize.sum -as [float]))
                #$PropHash.SizeInKB = [float]::Parse("{0:N2}" -f ($CurrentDirSize.sum/1KB))
                #$PropHash.SizeInMB = [float]::Parse("{0:N2}" -f ($CurrentDirSize.sum/1MB))
                #$PropHash.SizeInGB = [float]::Parse("{0:N2}" -f ($CurrentDirSize.sum/1GB))
                
                #Push the hash onto the array:
                #New object syntax is for outputting to built-in PS methods.
                $Results.Add((New-Object PSObject -Property $PropHash)) | Out-Null

                #Reset hash and counters:
                $PropHash = @{}
                
            } #If $CurrentDirSize
            
        } #ForEach Sub-Directory    
    
        Return $Results

    } #End Process


} #End Function


Function Remove-Generic {
    <#
    .SYNOPSIS
    Removes all files in a directory path based on age and file type.

    .DESCRIPTION
    Removes all files in a directory path based on age and file type.
    Defaults are log files older than or equal to 30 days.
    Returns count of files per directory removed and additional metadata.
    
    .PARAMETER RootPath
    Required. Specifies in which directory path to start looking for files.
    Ex. C:\Windows\Temp

    .PARAMETER FileAge
    Optional. Specifies how many days to keep. 
    Ex. 10
    Default = 30
    
    .PARAMETER FileType
    Optional. Specifies the filter for the file type. To remove all file types
    this parameter must be set explicitly to $null.
    Ex. *.txt
    Ex. $null
    Default = *.log
    
    .PARAMETER Inclusive
    Optional. Also removes criteria-matching loose files within the RootPath
    Valid inputs = $True or $False
    Ex. $False
    Default = $True 

    .INPUTS
    This function does not support pipeline inputs.

    .OUTPUTS
    This function returns an array of PS objects to the calling script.    

    .NOTES
    Author: Dan Anderson (danderson@nexidia.com)

    .EXAMPLE
    Remove-Generic -RootPath "C:\Windows\Temp"
    
    .EXAMPLE
    Remove-Generic -RootPath "C:\Windows\Temp" -Inclusive $False
    
    .EXAMPLE
    Remove-Generic -RootPath "C:\Windows\Temp" -Inclusive $False -FileAge 10
    
    .EXAMPLE
    Remove-Generic -RootPath "C:\Windows\Temp" -Inclusive $False -FileAge 10 -FileType "*.txt"

    .EXAMPLE
    Remove-Generic -RootPath "C:\Windows\Temp" -Inclusive $False -FileAge 10 -FileType $null
    
    #>

    [CmdletBinding()]
      
    Param (
    [Parameter(Mandatory=$True)]
    [string]$RootPath = "C:\Windows\Temp",
    
    [Parameter(Mandatory=$False)]
    [bool]$DeleteMode = $True,
    
    [Parameter(Mandatory=$False)]
    [int]$FileAge = 30,
    
    [Parameter(Mandatory=$False)]
    [string]$FileType = "*.log",
    
    [Parameter(Mandatory=$False)]
    [bool]$Inclusive = $True
    
    )
    
    Process {
        
        #Setup Runtime Params:
        $Results = New-Object System.Collections.ArrayList
        $PropHash = @{}
        $DeletedCount = 0
        
        #List of directories:
        $DirList = (Get-ChildItem -Path $RootPath -Force -Recurse -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer})
        $DirCount = ($DirList | Measure-Object).Count
        
        #Failures:
        $FailedFiles = New-Object System.Collections.ArrayList
        $FailedHash = @{}
        $FailedCount = 0
        
        #Find files in $RootPath to remove matching criteria:
        If($Inclusive -eq $True) {
        
            #Grab summary info:
            #Before getting files, test for null file filter:
            If($FileType){
                $Files = (Get-ChildItem -Path $RootPath -Filter $FileType -Force -ErrorAction SilentlyContinue | Where-Object {(-not $_.PSIsContainer) -and $_.LastWriteTime -le (Get-Date).AddDays(-$FileAge)})
            }
            Else {
                $Files = (Get-ChildItem -Path $RootPath -Force -ErrorAction SilentlyContinue | Where-Object {(-not $_.PSIsContainer) -and $_.LastWriteTime -le (Get-Date).AddDays(-$FileAge)})
            }
            
            #Count items:
            $FileCount = ($Files | Measure-Object).Count
                                   
            #Operate if we have items:
            If($FileCount -gt 0) {
            
                #Measure Items:
                $OriginalDirSize = ($Files | Measure-Object -Property Length -Sum).Sum
                $DeletedFileSize = 0
            
                #Remove Items:
                ForEach($File in $Files){
                    Try {
                    
                        #Control delete mode:
                        If($DeleteMode){
                            Remove-Item -Path $File.FullName -Force -ErrorAction Stop
                            $DeletedCount++
                        }
                        
                        $DeletedFileSize += $($File.Length)
                    }
                    Catch{
                        $FailedCount++
                        $FailedHash.FilePath = $File.FullName
                        $FailedHash.Message = $_.Exception.Message
                        $FailedFiles.Add((New-Object PSObject -Property $FailedHash)) | Out-Null
                        $FailedHash = @{}
                    }
                } #ForEach File
                
            } #If $FileCount -gt 0
            
            #Build results if actions were taken:
            If($DeletedCount -gt 0 -or $FailedCount -gt 0) {
            
                #Get directory size change:
                $CurrentDirSize = $($OriginalDirSize - $DeletedFileSize)
                
                #Create the hash:
                $PropHash.DirPath = $RootPath
                $PropHash.DeleteMode = $DeleteMode
                $PropHash.NumFiles = $FileCount
                $PropHash.NumDeleted = $DeletedCount
                $PropHash.NumFailed = $FailedCount
                $PropHash.Failures = $FailedFiles.Clone()
                $PropHash.OrigSizeInB = ($OriginalDirSize -as [float])
                $PropHash.DiffInB = ($DeletedFileSize -as [float])
                $PropHash.SizeInB = ($CurrentDirSize -as [float])
                #$PropHash.SizeInKB = [float]::Parse("{0:N2}" -f (($CurrentDirSize)/1KB))
                #$PropHash.SizeInMB = [float]::Parse("{0:N2}" -f (($CurrentDirSize)/1MB))
                #$PropHash.SizeInGB = [float]::Parse("{0:N2}" -f (($CurrentDirSize)/1GB))
                
                #Push the hash onto the array:
                #New object syntax is for outputting to built-in PS methods.
                $Results.Add((New-Object PSObject -Property $PropHash)) | Out-Null
            
            } #If $DeletedCount or $FailedCount > 0
            

            #Reset hash and counters:
            $PropHash = @{}
            $DeletedCount = 0
            $FailedFiles.Clear()
            $FailedCount = 0
            $Files = $null
            $FileCount = 0
            $CurrentDirSize = 0
        
        } #If $Inclusive
        
        #If we have sub-directories, execute:
        If($DirCount -gt 0) {
        
            #Iterate through each sub-directory.
            ForEach($Dir in $DirList) {
                
                #Grab summary info:
                #Before getting files, test for null file filter:
                If($FileType){
                    $Files = (Get-ChildItem -Path $Dir.FullName -Filter $FileType -Force -ErrorAction SilentlyContinue | Where-Object {(-not $_.PSIsContainer) -and $_.LastWriteTime -le (Get-Date).AddDays(-$FileAge)})
                }
                Else {
                    $Files = (Get-ChildItem -Path $Dir.FullName -Force -ErrorAction SilentlyContinue | Where-Object {(-not $_.PSIsContainer) -and $_.LastWriteTime -le (Get-Date).AddDays(-$FileAge)})
                }
                
                #Count items:
                $FileCount = ($Files | Measure-Object).Count

                #Operate if we have files:
                If($FileCount -gt 0){
                    
                    #Measure items
                    $OriginalDirSize = ($Files | Measure-Object -Property Length -Sum).Sum
                    $DeletedFileSize = 0
                
                    #Remove Items:
                    ForEach($File in $Files){
                        Try {
                            
                            #Control Delete Mode:
                            If($DeleteMode){
                                Remove-Item -Path $File.FullName -Force -ErrorAction Stop
                                $DeletedCount++
                            }

                            $DeletedFileSize += $($File.Length)
                        }
                        Catch{
                            $FailedCount++
                            $FailedHash.FilePath = $File.FullName
                            $FailedHash.Message = $_.Exception.Message
                            $FailedFiles.Add((New-Object PSObject -Property $FailedHash)) | Out-Null
                            $FailedHash = @{}
                        }
                    }#ForEach $File
                    
                } #If $FileCount -gt 0
                
                #Build results if actions were taken:
                If($DeletedCount -gt 0 -or $FailedCount -gt 0) {
                
                    #Get directory size change:
                    $CurrentDirSize = $($OriginalDirSize - $DeletedFileSize)
                    
                    #Create the hash:
                    $PropHash.DirPath = $Dir.Fullname
                    $PropHash.DeleteMode = $DeleteMode
                    $PropHash.NumFiles = $FileCount
                    $PropHash.NumDeleted = $DeletedCount
                    $PropHash.NumFailed = $FailedCount
                    $PropHash.Failures = $FailedFiles.Clone()
                    $PropHash.OrigSizeInB = ($OriginalDirSize -as [float])
                    $PropHash.DiffInB = ($DeletedFileSize -as [float])
                    $PropHash.SizeInB = ($CurrentDirSize -as [float])
                    #$PropHash.SizeInKB = [float]::Parse("{0:N2}" -f (($CurrentDirSize)/1KB))
                    #$PropHash.SizeInMB = [float]::Parse("{0:N2}" -f (($CurrentDirSize)/1MB))
                    #$PropHash.SizeInGB = [float]::Parse("{0:N2}" -f (($CurrentDirSize)/1GB))
                    
                    #Push the hash onto the array:
                    #New object syntax is for outputting to built-in PS methods.
                    $Results.Add((New-Object PSObject -Property $PropHash)) | Out-Null
                
                } #If $DeletedCount or $FailedCount > 0
                
                
                #Reset hash and counters:
                $PropHash = @{}
                $DeletedCount = 0
                $FailedFiles.Clear()
                $FailedCount = 0
                $Files = $null
                $FileCount = 0
                $CurrentDirSize = 0
                
            }#ForEach Sub-Directory
            
        } #If $DirCount -gt 0
            
        Return $Results
    
    } #End Process
    
} #End Function


Function Zip-File {

    <#
    .SYNOPSIS 
    Zips a file using 7Zip. 7Zip must be installed on the machine. 

    .DESCRIPTION
    Zips a file using 7Zip. 7Zip must be installed on the machine.
    Function will throw an error if 7z.exe can't be found.

    .PARAMETER TargetFile
    Required. Specifies the desired name of the compressed file. 
    Ex. "C:\Temp\someFile.zip"

    .PARAMETER SourceFile
    Required. Specifies what file to add to the compressed file. 
    Ex. "C:\Temp\someFile.txt"

    .PARAMETER CompType
    Optional. Specifies the type of compression. 
    Ex. "-tzip"
    Default = "-tzip" Options("-tzip", or "-t7z")
    
    .PARAMETER ProgramLocation
    Optional. Specifies the location of the 7zip program. 
    Ex. "D:\Programs\7-Zip\7z.exe"
    Default = "C:\Program Files\7-Zip\7z.exe"

    .INPUTS
    This script does not support pipeline inputs.

    .OUTPUTS
    This function returns exceptions back to the calling script.

    .NOTES
    Author: Dan Anderson (danderson@nexidia.com)

    .EXAMPLE
    C:\PS> Zip-File -TargetFile "C:\Temp\someFile.zip" -SourceFile "C:\Temp\someFile.txt"
    
    .EXAMPLE
    C:\PS> Zip-File -TargetFile "C:\Temp\someFile.7z" -SourceFile "C:\Temp\someFile.txt" -CompType "-t7z"
    
    .EXAMPLE
    C:\PS> Zip-File -TargetFile "C:\Temp\someFile.7z" -SourceFile "C:\Temp\someFile.txt" -CompType "-t7z" -ProgramLocation "D:\Programs\7-Zip\7z.exe"
    #>
    
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [string]$TargetFile,

    [Parameter(Mandatory=$true)]
    [string]$SourceFile,
    
    [Parameter(Mandatory=$false)]
    [string]$CompType = "-tzip",
    
    [Parameter(Mandatory=$false)]
    [string]$ProgramLocation = "$($env:ProgramFiles)\7-Zip\7z.exe"
    
    )
    
    Process {
        
        #Zip file:
        Try {
            Set-Alias szip $($ProgramLocation)
            szip a $CompType $TargetFile $SourceFile | out-null
            Return "OK"
        }
        Catch {
            Return $_.Exception.Message
        }
           
    } #End Process
    
} #End Function


Export-ModuleMember -Function Find-Files, Find-Folders, Remove-Generic, Zip-File