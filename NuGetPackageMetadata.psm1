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
            Where-Object { $_.Extension -eq '.nupkg' } |
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
    END {
    }
}

Export-ModuleMember Get-NuGetPackageMetadata
