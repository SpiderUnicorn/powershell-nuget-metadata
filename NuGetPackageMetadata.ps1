#Get-NuGetPackageMetadata::string -> XmlDocument
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

#Get-ZipFileEntry::string -> System.IO.Compression.ZipArchiveEntry
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
        Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    }
    PROCESS {
        foreach ($file in $FilePath) {
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

#Get-ZipFileEntryContent::System.IO.Compression.ZipArchiveEntry -> string
function Get-ZipFileEntryContent {
    [CmdletBinding()]
    Param(
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        $FileName
    )
    BEGIN {}
    PROCESS {
        foreach ($file in $FileName) {
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

#Get-NuGetMetadata::XmlDocument -> XmlDocument
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

#internal functions = no dashes
#Export-ModuleMember *-*
