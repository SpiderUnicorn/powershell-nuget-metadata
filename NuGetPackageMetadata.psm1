#
function Get-NuGetPackageMetadata {
    [CmdLetBinding()]
    Param(
        [Parameter(Position = 1, ValueFromPipeline = $true)]
        [string[]]$Path = "."
    )
    BEGIN {
        Add-Type -AssemblyName "System.IO.Compression.FileSystem"
        $GCIParam = @{
            'Recurse' = $true
        }
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
        [string[]]$FilePath
    )
    BEGIN {
        Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    }
    PROCESS {
        foreach ($file in $FilePath) {
            try {
                $fullName = (Resolve-Path -ErrorAction Stop $file).Path
                [IO.Compression.ZipFile]::OpenRead($fullName).Entries
            }
            catch {
                #todo: implementera felhantering
                $exc = $_.Exception
                $exci = $exc.Exception.InnerException
                write-host "exc" $exc.GetType().FullName
                write-host "exci" $exci.GetType().FullName
            }
        }
    }
    END {}
}

#get-childitem *.nupkg |
#get-zipfileentry *.nuspec |
#get-zipfileentrycontent |
#$_.package.metadata

#Export-ModuleMember Get-NuGetPackageMetadata
