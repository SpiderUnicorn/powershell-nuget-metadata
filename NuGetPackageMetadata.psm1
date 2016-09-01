function Get-NuGetPackageMetadata {
    [CmdLetBinding()]
    Param(
        [string]$Path = ".\packages\"
    )

    Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    #try-catcha!
    Get-ChildItem -Path $Path -Recurse |
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
}
