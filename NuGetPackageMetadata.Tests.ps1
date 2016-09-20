Import-Module ".\NuGetPackageMetadata.psm1"

Describe "Get-ZipFileEntry" {
    Context "Given no file" {
        It "Returns null" {
            $result = Get-ZipFileEntry
            $result | Should be $null 
        }
    }
    Context "Given different types of paths" {
        It "Resolves absolute paths" {
            { Get-ZipFileEntry (Resolve-Path "./test/test.zip").Path } | Should not throw
        }
        It "Resolves relative paths" {
            { Get-ZipFileEntry "./test/test.zip" } | Should not throw
        }
    }
    Context "Given non-existent file path" {
        It "Throws an error" {
            { Get-ZipFileEntry "./non-existant.file" } | Should throw
        }
    }
    Context "Given a zip file path with one file" {
        $result = Get-ZipFileEntry (Resolve-Path "./test/test.zip").Path
        It "Return an entry collection with length 1" {
            $result.Count | Should be 1 
        }
        It "Returns a ZipFileEntry" {
            $result.GetType().Name | Should be "ZipArchiveEntry"
        }
    }
}
