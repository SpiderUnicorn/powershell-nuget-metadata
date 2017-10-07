#assemblies loaded in manifest:
Add-Type -AssemblyName "System.IO.Compression"
Add-Type -AssemblyName "System.IO.Compression.FileSystem"

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
