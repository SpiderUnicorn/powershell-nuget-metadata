#function Get-NuGetPackageMetadata {
    [CmdLetBinding()]
    Param(
        [Parameter(Position = 1, ValueFromPipeline = $true)]
        [string]$Path = "."
    )

    Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    
    $GCIParam = @{
        'Path'    = $Path
        'Recurse' = $true
    }
    <#
    function ConvertFrom-Xml {
        Param(
        )
    }
    #>
    Get-ChildItem @GCIParam |
    Where-Object { $_.Extension -eq '.`nupkg' } |
    ForEach-Object {
        Write-Host $_.FullName
        [IO.Compression.ZipFile]::OpenRead($_.FullName).Entries |
        Where-Object { $_.Name -match '\.nuspec$' } |
        ForEach-Object {
            $deflateStream = $_.Open()
            $streamReader = New-Object System.IO.StreamReader($deflateStream)
            [System.Xml.XmlDocument]$fileContent = $streamReader.ReadToEnd()
            $deflateStream.Dispose()
            #$streamReader = New-Object System.IO.StreamReader($_.Open())    #shorter, but memory leak?
            $streamReader.Dispose()
            Write-Verbose "fileContent.GetType() $($fileContent.GetType())"
            
            Write-Output $fileContent.package.metadata
        }
    }
#}
#Export-ModuleMember Get-NuGetPackageMetadata
