#assemblies loaded in manifest:
Add-Type -AssemblyName "System.IO.Compression"
Add-Type -AssemblyName "System.IO.Compression.FileSystem"

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
    BEGIN {
        #moved to manifest
        #Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    }
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
