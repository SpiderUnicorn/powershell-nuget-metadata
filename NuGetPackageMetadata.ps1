function Get-NuGetPackageMetadata {
    [CmdLetBinding()]
    Param(
        [Parameter(Position = 1, ValueFromPipeline = $true)]
        [string[]]$Path = "."
    )
    BEGIN {
        Add-Type -AssemblyName "System.IO.Compression.FileSystem"
        $GCIParam = @{
            'Recurse' = $true #!$NoRecurse
            'File'    = $true
            #'Filter' = '*.nupkg' #doesn't handle multiple filters
        }
        #$Pattern = '*.nupkg', '*.zip' #todo: parameter?
    }
    PROCESS {
        foreach ($p in $Path) {
            Get-ChildItem @GCIParam -Path $p |
            Where-Object { $_.Extension -eq '.nupkg' } | #doesn't handle .nuspec-files not in .nupkg-files, add cmdlet/-switch?
            ForEach-Object {
                [IO.Compression.ZipFile]::OpenRead($_.FullName).Entries |
                Where-Object { $_.Name -match '\.nuspec$' } |
                ForEach-Object {
                    $deflateStream = $_.Open()
                    $streamReader = New-Object System.IO.StreamReader($deflateStream)
                    [System.Xml.XmlDocument]$fileContent = $streamReader.ReadToEnd()
                    $deflateStream.Dispose()
                    #$streamReader = New-Object System.IO.StreamReader($_.Open()) #shorter, but possible memory leak?
                    $streamReader.Dispose()
                    $fileContent.package.metadata
                }
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
        #todo: $Pattern = '*.nuspec', '*.txt'
        Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    }
    PROCESS {
       foreach ($file in $FilePath) {
            try {
                $fullName = (Resolve-Path -Path $file -ErrorAction Stop).Path
                if (!(Test-Path -Path $fullName -PathType Leaf)) {
                    throw "'$fullName' is not a file"
                }
                $zipFile = [IO.Compression.ZipFile]::OpenRead($fullName)
                $zipFile.Entries
            }
            catch [System.IO.InvalidDataException] {
                Write-Error "'$fullName' is not a zip file"
            }
            catch {
                #pokemon exception handling
                $eName = $_.Exception.GetType().FullName
                $eMsg = $_.Exception.Message
                if ($_.Exception.InnerException) {
                    $eInnerName = $_.Exception.InnerException.GetType().FullName
                    $eInnerMsg = $_.Exception.InnerException.Message
                }
                Write-Error -Message "[$eName] : $eMsg"
                Write-Error -Message "[$eInnerName] : $eInnerMsg"
            }
            finally {
                if ($zipFile) { $zipFile.Dispose() }
            }
        }
    }
    END {}
}

#Get-ZipFileEntry -FilePath "stuff"

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
        #filter on filename, like '\.nuspec$'
        foreach ($file in $FileName) {
            try {
                $deflateStream = $file.Open() #mocka lite
                $streamReader = New-Object System.IO.StreamReader($deflateStream)
                $fileContent = $streamReader.ReadToEnd()
                $fileContent
            }
            catch {
                Write-Error -Message "'$file' could not be read"
            }
            finally {
                if ($deflateStream) { $deflateStream.Dispose() }
                if ($streamReader) { $streamReader.Dispose() }
            }
        }
    }
    END {}
}

<#
function Get-NuGetMetadata {
    [System.Xml.XmlDocument]$stuff
}
#>

#get-childitem *.nupkg |
#get-zipfileentry *.nuspec |
#get-zipfileentrycontent |
#get-nugetmetadata |
#$_.package.metadata

#Export-ModuleMember Get-NuGetPackageMetadata
