#assemblies loaded in the manifest:
Add-Type -AssemblyName "System.IO.Compression"
Add-Type -AssemblyName "System.IO.Compression.FileSystem"

<<<<<<< HEAD
<#
.SYNOPSIS
Gets metadata from NuGet packages in a project or folder.

.DESCRIPTION
NuGet stores metada in .nuspec files within .nupkg files which aren't easily accessable. 
This cmdlet extracts all metadata information as XML from a single package, every package in
a folder or every package in a folder structure recursively (such as every package on a drive).

.PARAMETER Path
The directory or file path of a .nupkg file, or directory containing .nupkg files. 
Can also take a comma-separated list of files or directories to search.

.PARAMETER NoRecurse
When set, subfolders won't be included in the search for .nupkg files. 

.EXAMPLE
Read all metadata from all packages in the folder you are in, including all subfolders
Get-NuGetMetadata

.EXAMPLE
You can provide both folders and files
Get-NuGetMetadata C:\Project\
Get-NuGetMetadata .\example.nupkg

Or a combination of both
Get-NuGetMetadata .\example.nupkg, C:\Project\

.EXAMPLE
Export output as comma separated values (.csv)
Get-NuGetMetadata | Export-Csv -NoTypeInformation ./my-metadata-file.csv

.EXAMPLE
Export output as json. To make conversion from XML to json simple, use slect-object to
pluck parts of the  output before converting. 
Get-NuGetMetadata | Select-Object id, version, licenseUrl | ConvertTo-Json | Out-File ./my-metadata-file.csv

.EXAMPLE
Exlude all standard Microsoft packages
Get-NuGetMetadata | ? { $_.id -notlike 'Microsoft*' }

.EXAMPLE
You can use the metadata to download license information. This is a simple example
that downloads licenseUrls as html pages ina folder called "Licenses" (needs to created first).

Get-NuGetMetadata | select id, licenseUrl | % { (Invoke-WebRequest $_.licenseUrl).Content |
Out-File -FilePath "./Licenses/$($_.id).html" }

.LINK
Contributions are welcome at https://github.com/SpiderUnicorn/powershell-nuget-metadata
#>

#::string -> XmlDocument
function Get-NuGetMetadata {
    <#
    .SYNOPSIS
    Gets metadata from NuGet packages in a project directory.

    .DESCRIPTION
    NuGet stores metada in .nuspec files within .nupkg files which aren't easily accessable. 
    This cmdlet extracts all metadata information as XML from a single package, every package in
    a folder or every package in a folder structure recursively (such as every package on a drive).

    .PARAMETER Path
    The directory or file path of a .nupkg file, or directory containing .nupkg files. 
    Can also take a comma-separated list of files or directories to search.

    .PARAMETER NoRecurse
    When set, subfolders won't be included in the search for .nupkg files. 

    .EXAMPLE
    Get-NuGetMetadata

    Read all metadata from all packages in the folder you are in, including all subfolders

    .EXAMPLE
    Get-NuGetMetadata C:\Project\

    Specify a folder to search for .nupkg files in

    .EXAMPLE
    Get-NuGetMetadata .\example.nupkg

    Specify a .nupkg file

    .EXAMPLE
    Get-NuGetMetadata .\example.nupkg, C:\Project\

    Specify a list of files and or folders

    .EXAMPLE
    Get-NuGetMetadata | Export-Csv -NoTypeInformation ./my-metadata-file.csv

    Export output as comma separated values (.csv)

    .EXAMPLE
    Get-NuGetMetadata | Select-Object id, version, licenseUrl | ConvertTo-Json | Out-File ./my-metadata-file.csv

    Export output as json. To make conversion from XML to json simple, use slect-object to
    pluck parts of the output before converting. 

    .EXAMPLE
    Get-NuGetMetadata | ? { $_.id -notlike 'Microsoft*' }
    
    Exlude all standard Microsoft packages
    
    .EXAMPLE
    Get-NuGetMetadata | select id, licenseUrl | % { (Invoke-WebRequest $_.licenseUrl).Content |
    Out-File -FilePath "./Licenses/$($_.id).html" }

    You can use the metadata to download license information. This is a simple example
    that downloads licenseUrls as html pages ina folder called "Licenses" (needs to created first).

    .LINK
    Contributions are welcome at https://github.com/SpiderUnicorn/powershell-nuget-metadata
    #>
=======
function Get-NuGetMetadata {
    [CmdletBinding(
        DefaultParameterSetName = 'Path'
    )]
    Param(
        [Parameter(ParameterSetName = 'Path')]
        [string]$Path,

        [Parameter(ParameterSetName = 'ConfigPath')]
        [string]$ConfigPath
    )
    BEGIN {
        $GCIparam = @{
            Path = $Path
        }

        $sln = Get-ChildItem -Filter '*.sln' @GCIparam
        if (!$sln) {
            $csproj = Get-ChildItem -Filter '*.csproj' @GCIparam
        }
    }
    PROCESS {
        if (!$csproj -and $sln) {
            $csproj = $sln | GetProjectFromSolution
        }

        $csproj |
            GetPackageNameVersion |
            GetNuGetPackageDirectory |
            Get-NupkgMetadata
    }
    END {}
}

#::string -> XmlDocument
function Get-NupkgMetadata {
>>>>>>> dd01c2feb4cb0076c1fdcd6997b220b9a190b996
    [CmdLetBinding()]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path = ".",

        [Parameter(Position = 1)]
        [string[]]$FilePattern = '*.nupkg',

        [Parameter(Position = 2)]
        [string[]]$EntryPattern = '*.nuspec',

        [switch]$NoRecurse
    )
    BEGIN {
        $GCIParam = @{
            'Recurse' = !$NoRecurse
            'File'    = $true
        }
    }
    PROCESS {
        foreach ($p in $Path) {
            Write-Verbose "Get-NupkgMetadata path: $p"
            if (Test-Path $p) {
                Get-ChildItem @GCIParam -Path $p |
                    SelectMatchingFullName -Pattern $FilePattern |
                    Get-ZipFileEntry |
                    SelectMatchingFullName -Pattern $EntryPattern |
                    Get-ZipFileEntryContent |
                    GetNuGetPackageMetadata
            }
            else {
                Write-Error -Message "Path '$p' not found"
            }
        }
    }
    END {}
}

function GetProjectFromSolution {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        [string]$Path
    )
    BEGIN {
        $projectPattern = '^Project\('
        $filenameIndex = 2
    }
    PROCESS {
        Write-Verbose "GetCsprojPath input: '$Path'"
        $directory = Split-Path $Path
        Get-Content $Path |
            Select-String $projectPattern |
            ForEach-Object {
                $projectPath = ($_ -split '[=,]')[$filenameIndex].Trim(' "')
                $output = Join-Path $directory $projectPath
                Write-Verbose "GetCsprojPath project file: $output"
                if ($output -match '\.csproj$') {
                    [PSCustomObject]@{
                        Path = $output
                    }
                }
            }
    }
    END {}
}

function GetPackageNameVersion {
    <#
    .SYNOPSIS
    Receives a .csproj file.
    Outputs name and version of the package references.
    
    .PARAMETER Path
    A .csproj file.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        [string]$Path
    )
    BEGIN {}
    PROCESS {
        Write-Verbose "GetPackageNameVersion input: $Path"
        if (Test-Path $Path) {
            $xml = [xml](Get-Content $Path)
            Select-Xml -Xml $xml -XPath '//PackageReference' |
                select -ExpandProperty Node |
                ForEach-Object {
                    $output = [PSCustomObject]@{
                        Name    = $_.Include
                        Version = $_.Version
                    }
                    Write-Verbose "GetPackageNameVersion output: $output"
                    $output
                }
        }
    }
    END {}
}

function GetNuGetPackageDirectory {
    <#
    .SYNOPSIS
    Find NuGet packages when they aren't stored in the project directory.
    Receives an object with Name and Version of a NuGet package.
    Outputs the NuGet package directory.
    
    .PARAMETER NameVersion
    Parameter description
    Name
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [PSCustomObject]$NameVersion
    )
    BEGIN {
        #todo: add logic here, for NuGet.config n stuff
        $NuGetDefaultFolder = "$HOME\.NuGet\packages"
    }
    PROCESS {
        Write-Verbose "GetNuGetPackageDirectory input: $Path"
        $output = [PSCustomObject]@{
            Path = "$NuGetDefaultFolder\$($NameVersion.Name)\$($NameVersion.Version)"
        }
        Write-Verbose "GetNuGetPackageDirectory output: $output"
        $output
    }
    END {}
}

#::string -> System.IO.Compression.ZipArchiveEntry
function Get-ZipFileEntry {
    [CmdletBinding()]
    Param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        [string[]]$FilePath
    )
    BEGIN {}
    PROCESS {
        foreach ($file in $FilePath) {
            Write-Verbose "Get-ZipFileEntry file: $file"
            try {
                $fullName = (Resolve-Path -Path $file -ErrorAction Stop).Path
                if (!(Test-Path -Path $fullName -PathType Leaf)) {
                    throw "'$fullName' is not a file"
                }
                $zipFile = [System.IO.Compression.ZipFile]::OpenRead($fullName)
                $zipFile.Entries
            }
            catch [System.IO.InvalidDataException] {
                Write-Error "'$fullName' is not a zip file"
            }
            catch {
                WriteExceptionAsError $_
            }
            finally {
                if ($zipFile) { $zipFile.Dispose() }
            }
        }
    }
    END {}
}

#::System.IO.Compression.ZipArchiveEntry -> string
function Get-ZipFileEntryContent {
    [CmdletBinding()]
    Param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        [System.IO.Compression.ZipArchiveEntry]$FileName
    )
    BEGIN {}
    PROCESS {
        foreach ($file in $FileName) {
            Write-Verbose "Get-ZipFileEntryContent entry: $file"
            try {
                $deflateStream = $file.Open()
                $streamReader = New-Object System.IO.StreamReader($deflateStream)
                $fileContent = $streamReader.ReadToEnd()
                $fileContent
            }
            catch {
                WriteExceptionAsError $_
            }
            finally {
                if ($deflateStream) { $deflateStream.Dispose() }
                if ($streamReader) { $streamReader.Dispose() }
            }
        }
    }
    END {}
}

#::XmlDocument -> XmlDocument
function GetNuGetPackageMetadata {
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string[]]$Xml,

        [switch]$IncludeFullXml
    )
    BEGIN {}
    PROCESS {
        if ($IncludeFullXml) {
            [xml]$Xml
        }
        else {
            ([xml]$Xml).package.metadata
        }
    }
    END {}
}

function SelectMatchingFullName {
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,

        [string[]]$Pattern = '*'
    )
    BEGIN {}
    PROCESS {
        foreach ($obj in $InputObject) {
            foreach ($pat in $Pattern) {
                if ($obj.FullName -like $pat) {
                    $obj
                    break
                }
            }
        }
    }
    END {}
}

function WriteExceptionAsError {
    Param(
        $Exception
    )
    if (-not ($ex = $Exception.Exception.InnerException)) {
        $ex = $Exception.Exception
    }
    $exName = $ex.GetType().FullName
    $exMsg = $ex.Message
    Write-Error -Message "[$exName] : $exMsg"
}

#internal functions have no dashes
Export-ModuleMember *-*
