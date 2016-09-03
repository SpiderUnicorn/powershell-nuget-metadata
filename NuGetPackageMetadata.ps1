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
    
    Get-ChildItem @GCIParam |
    Where-Object { $_.Extension -eq '.nupkg' } |
    ForEach-Object {
        [IO.Compression.ZipFile]::OpenRead($_.FullName).Entries |
        Where-Object { $_.Name -match '\.nuspec$' } |
        ForEach-Object {
            $memoryStream = New-Object System.IO.MemoryStream
            $file = $_.Open()
            $file.CopyTo($memoryStream)
            $file.Dispose()
            $memoryStream.Position = 0
            $reader = New-Object System.IO.StreamReader($memoryStream)
            [xml]$fileContent = $reader.ReadToEnd()
            $reader.Dispose()
            $memoryStream.Dispose()
            $fileContent.package.metadata
        }
    }
#}
#Export-ModuleMember Get-NuGetPackageMetadata

