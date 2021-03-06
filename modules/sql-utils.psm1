

Function Sql-Select {
    <#
    .SYNOPSIS 
    Connects to a SQL Server and Database. Executes the select query provided. 

    .DESCRIPTION
    Connects to a SQL Server and Database. Executes the select query provided.

    .PARAMETER Server
    Required. Specifies the server containing the databases. 
    Ex. "localhost"

    .PARAMETER Database
    Required. Specifies the database to run the query against. 
    Ex. "AdventureWorks"

    .PARAMETER Query
    Required. Specifies the query to run. 
    Ex. "SELECT TOP 100 * FROM person.person"
    
    .PARAMETER UserName
    Optional. Username for db user. Default is integrated security.
    Leave this parameter null if using Windows Authentication.
    
    .PARAMETER Password
    Optional. Password for db user. Default is integrated security.
    Leave this parameter null if using Windows Authentication.

    .INPUTS
    This script does not support pipeline inputs.

    .OUTPUTS
    This function returns the result or the error back to the calling script.

    .NOTES
    Author: Dan Anderson (danderson@nexidia.com)

    .EXAMPLE
    C:\PS> Sql-Select -Server "localhost" -Database "AdventureWorks" -Query "SELECT TOP 100 * FROM person.person"
    
    .EXAMPLE
    C:\PS> Sql-Select -Server "localhost" -Database "AdventureWorks" -UserName "JohnDoe" -Password "MySecretPassword" -Query "SELECT TOP 100 * FROM person.person"
    #>

    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [string]$Server,

    [Parameter(Mandatory=$true)]
    [string]$Database,
    
    [Parameter(Mandatory=$true)]
    [string]$Query,
    
    [Parameter(Mandatory=$false)]
    [string]$UserName = $null,
    
    [Parameter(Mandatory=$false)]
    [string]$Password = $null

    )

    Process {
    
        #Determine connection method:
        If((!$UserName) -and (!$Password)){
            $ConnectionString = "Server=$Server;Database=$Database;Application Name='Sql-Utils.psm1';Trusted_Connection=True;"
        } 
        Else {
            $ConnectionString = "Server=$Server;Database=$Database;Application Name='Sql-Utils.psm1';User Id=$UserName;Password=$Password;"
        } 
    
        #Create new sql connection:
        $SqlConn = New-Object System.Data.SqlClient.SqlConnection
        $SqlConn.ConnectionString = $ConnectionString
        
        #Get instance of SqlCommand, feed it the query and connection.
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.CommandText = $Query
        $SqlCmd.Connection = $SqlConn
        $SqlCmd.CommandTimeout = 65535

        #Get instance of new data adaptor/data set:
        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $SqlAdapter.SelectCommand = $SqlCmd
        $DataSet = New-Object System.Data.DataSet
        
        
        Try {
            #Execute query and fill dataset:
            $SqlAdapter.Fill($DataSet) | Out-Null
            $Result = $DataSet.Tables[0]
            Return $Result
        }
        Catch {
            Return $_.Exception.Message
        }
        Finally {
            #Close and dispose:
            $SqlConn.Close()
            $SqlConn.Dispose()
            $SqlCmd.Dispose()
            $SqlAdapter.Dispose()
            $DataSet.Dispose()
        }      

    }

} #end function


Function Sql-Iud {
    <#
    .SYNOPSIS
    Inserts/Updates/Deletes data in the specified database.

    .DESCRIPTION
    Inserts/Updates/Deletes data in the specified database using the specified query.
    Automatically wraps query in a transaction. Rolls transaction back automatically if an error occurs.

    .PARAMETER Server
    Required. Name of the server. Example: "Localhost"

    .PARAMETER Database
    Required. Name of the database. Example: "Logging_DB"

    .PARAMETER Query
    Required. The insert/update/delete statement. 
    Example: "INSERT INTO Table (Date, FileName, NumRows) SELECT Date='2016-09-20', FileName='someFile.txt', NumRows='400'"

    .PARAMETER UserName
    Optional. Username for db user. Default is integrated security.
    Leave this parameter null if using Windows Authentication.
    
    .PARAMETER Password
    Optional. Password for db user. Default is integrated security.
    Leave this parameter null if using Windows Authentication.
      
    .NOTES
    Author: Dan Anderson (danderson@nexidia.com)

    .EXAMPLE
    Sql-Iud -Server "Localhost" -Database "Logging_DB" -Query "INSERT INTO Table (Date, FileName, NumRows) SELECT Date='2016-09-20', FileName='someFile.txt', NumRows='400'"
    
    .EXAMPLE
    Sql-Iud -Server "Localhost" -Database "Logging_DB" -UserName "JohnDoe" -Password "MySecretPassword" -Query "INSERT INTO Table (Date, FileName, NumRows) SELECT Date='2016-09-20', FileName='someFile.txt', NumRows='400'" 
    #>
  
    [CmdletBinding()]
      
    Param (
    [Parameter(Mandatory=$true)]
    [string]$Server, 
      
    [Parameter(Mandatory=$true)]
    [string]$Database,
      
    [Parameter(Mandatory=$true)]
    [string]$Query,
    
    [Parameter(Mandatory=$false)]
    [string]$UserName = $null,
    
    [Parameter(Mandatory=$false)]
    [string]$Password = $null
      
    )
  
    Process {

        #Determine connection method:
        If((!$UserName) -and (!$Password)){
            $ConnectionString = "Server=$Server;Database=$Database;Application Name='Sql-Utils.psm1';Trusted_Connection=True;"
        } 
        Else {
            $ConnectionString = "Server=$Server;Database=$Database;Application Name='Sql-Utils.psm1';User Id=$UserName;Password=$Password;"
        }    
      
        #Create new sql connection:
        $SqlConn = New-Object System.Data.SqlClient.SqlConnection
        $SqlConn.ConnectionString = $ConnectionString
        
        #Open the connection
        $SqlConn.Open()
        
        #Create a transaction context:
        $SqlTran = $SqlConn.BeginTransaction()
                       
        #Get instance of SqlCommand, pass connection, transaction, and query:
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.Connection = $SqlConn
        $SqlCmd.Transaction = $SqlTran
        $SqlCmd.CommandText = $Query
        $SqlCmd.CommandTimeout = 65535
        
        Try {           
            #Execute and catch the result.
            $Result = $SqlCmd.ExecuteNonQuery()
            $SqlTran.Commit()
            Return $Result
        }
        Catch {
            $SqlTran.Rollback()
            Return $_.Exception.Message
        }
        Finally {
            #Close and dispose:
            $SqlConn.Close()
            $SqlTran.Dispose()
            $SqlCmd.Dispose()
            $SqlConn.Dispose()
        }
      
    }

} #End Function


Export-ModuleMember -Function Sql-Select, Sql-Iud