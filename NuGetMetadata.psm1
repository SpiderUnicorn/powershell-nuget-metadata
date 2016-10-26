#assemblies loaded in the manifest:
Add-Type -AssemblyName "System.IO.Compression"
Add-Type -AssemblyName "System.IO.Compression.FileSystem"

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
    [CmdLetBinding()]
    Param(
        [Parameter(
            Position = 1,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path = ".",

        [Parameter(Position = 2)]
        [string[]]$PatternFile = '*.nupkg',

        [Parameter(Position = 3)]
        [string[]]$PatternEntry = '*.nuspec',

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
            Write-Verbose "Get-NuGetMetadata path: $p"
            if (Test-Path $p) {
                Get-ChildItem @GCIParam -Path $p |
                    SelectMatchingFullName -Pattern $PatternFile |
                    Get-ZipFileEntry |
                    SelectMatchingFullName -Pattern $PatternEntry |
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
