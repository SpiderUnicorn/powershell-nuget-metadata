#assemblies loaded in the manifest:
Add-Type -AssemblyName "System.IO.Compression"

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
            GetXmlPackageReference |
            GetNuGetPackagePath |
            Get-NuGetPackageMetadata
    }
    END {}
}

#::string -> XmlDocument
function Get-NuGetPackageMetadata {
    <#
    .SYNOPSIS
    Gets metadata from all NuGet packages in a folder, or from a single package.

    .DESCRIPTION
    NuGet stores metadata in .nuspec files within .nupkg files. 
    This cmdlet extracts all metadata information as XML from a single package, every package in
    a folder, or every package in a folder structure (such as every package on a drive/in a folder).

    .PARAMETER Path
    The directory path containing .nupkg files, or a file path.
    Can also take a comma-separated list of directories/files to search.

    .PARAMETER NoRecurse
    Only search for .nupkg files in the current directory, excluding subfolders. 

    .EXAMPLE
    Read all metadata from all packages in the folder you are in, including all subfolders
    Get-NuGetPackageMetadata

    .EXAMPLE
    You can provide both folders and files
    Get-NuGetPackageMetadata C:\Project\
    Get-NuGetPackageMetadata .\example.nupkg

    Or a combination of both
    Get-NuGetPackageMetadata .\example.nupkg, C:\Project\

    .EXAMPLE
    Export output as comma separated values (.csv)
    Get-NuGetPackageMetadata | Export-Csv -NoTypeInformation ./my-metadata-file.csv

    .EXAMPLE
    Export output as json. To make conversion from XML to json simple, use select-object to
    pluck parts of the output before converting.
    Get-NuGetPackageMetadata | Select-Object id, version, licenseUrl | ConvertTo-Json | Out-File ./my-metadata-file.csv

    .EXAMPLE
    Exlude all standard Microsoft packages
    Get-NuGetPackageMetadata | ? { $_.id -notlike 'Microsoft*' }

    .EXAMPLE
    You can use the metadata to download license information. This is a simple example
    that downloads licenseUrls as html pages in a folder called "Licenses".

    Get-NuGetPackageMetadata | select id, licenseUrl | % { (Invoke-WebRequest $_.licenseUrl).Content |
    Out-File -FilePath "./Licenses/$($_.id).html" }

    .LINK
    Contributions are welcome at https://github.com/SpiderUnicorn/powershell-nuget-metadata
    #>

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
            Write-Verbose "Get-NuGetPackageMetadata path: $p"
            if (Test-Path $p) {
                Get-ChildItem @GCIParam -Path $p |
                    SelectMatchingFullName -Pattern $FilePattern |
                    Get-ZipFileEntry |
                    SelectMatchingFullName -Pattern $EntryPattern |
                    Get-ZipFileEntryContent |
                    GetXmlMetadata
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
        Write-Verbose "GetProjectFromSolution input: '$Path'"
        $directory = Split-Path $Path
        Get-Content $Path |
            Select-String $projectPattern |
            ForEach-Object {
                $projectPath = ($_ -split '[=,]')[$filenameIndex].Trim(' "')
                $output = Join-Path $directory $projectPath
                Write-Verbose "GetProjectFromSolution project file: $output"
                if ($output -match '\.csproj$') {
                    [PSCustomObject]@{
                        Path = $output
                    }
                }
            }
    }
    END {}
}

function GetXmlPackageReference {
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
        Write-Verbose "GetXmlPackageReference input: $Path"
        if (Test-Path $Path) {
            $xml = [xml](Get-Content $Path)
            Select-Xml -Xml $xml -XPath '//PackageReference' |
                Select-Object -ExpandProperty Node |
                ForEach-Object {
                    $output = [PSCustomObject]@{
                        Name    = $_.Include
                        Version = $_.Version
                    }
                    Write-Verbose "GetXmlPackageReference output: $output"
                    $output
                }
        }
    }
    END {}
}

function GetNuGetPackagePath {
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
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$Name,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$Version
    )

    BEGIN {
        #todo: add logic here, for NuGet.config n stuff
        $NuGetDefaultFolder = "$HOME\.NuGet\packages"
    }
    PROCESS {
        Write-Verbose "GetNuGetPackagePath input: $Path"
        $output = [PSCustomObject]@{
            Path = "$NuGetDefaultFolder\$Name\$Version"
        }
        Write-Verbose "GetNuGetPackagePath output: $output"
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
function GetXmlMetadata {
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
