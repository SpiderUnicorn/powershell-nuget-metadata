. ".\NuGetPackageMetadata.ps1"

#warning: in the middle of a rewrite

$filePath = @{
    test     = "./test/test.zip"
    relative = "./test/test.zip"
    nonExistent = "./non-existent.file"
    notZipFile = "./test/test.txt"
}
$filePath['absolute'] = (Resolve-Path $filePath.relative).Path

$dirPath = @{
    currentFolder = "."
}

Describe "Get-NuGetPackageMetadata" {
    Context "Given no path (null/empty string)" {
        It "It throws non-terminating exception" {
            { Get-NuGetPackageMetadata $null } | Should throw
            { Get-NuGetPackageMetadata "" } | Should throw
        }
    }
    Context "Given different types of paths" {
        It "works with absolute paths" {
            { Get-NuGetPackageMetadata $filePath.absolute } | Should not be $null
        }
        It "works with relative paths" {
            { Get-NuGetPackageMetadata $filePath.relative } | Should not be $null
        }
    }
    Context "Given non-existent file path" {
        It "Has errors" {
            Get-NuGetPackageMetadata $filePath.nonExistent -ErrorVariable err 2>$null
            $err.Count | Should BeGreaterThan 0
        }
    }
    Context "Given existing file path" {
        It "works" {
            #todo
        }
    }
    Context "Given existing directory path" {
        It "works" {
            #todo
        }
    }
}

Describe "Get-ZipFileEntry" {
    Context "Given a directory path" {
        It "Has errors" {
            Get-ZipFileEntry $dirPath.currentFolder -ErrorVariable err 2>$null
            $err | Should not BeNullOrEmpty
        }
    }
    Context "Given example zip file with some files" {
        $result = Get-ZipFileEntry (Resolve-Path $filePath.test).Path
        It "Return a non-empty collection" {
            $result.Count | Should BeGreaterThan 0
        }
        It "Return a ZipArchiveEntry" {
            $result | Should BeOfType System.IO.Compression.ZipArchiveEntry
        }
    }
    Context "Given a non zip file" {
        It "Has errors" {
            Get-ZipFileEntry $filePath.notZipFile 2>$null -ErrorVariable err
            $err | Should not BeNullOrEmpty
        }
    }
}

Describe "Get-ZipFileEntryContent" {
    Context "Given no zip file entry (null)" {
        It "Returns null" {
            Get-ZipFileEntryContent | Should be $null
        }
    }
    Context "Given a zip file entry" {
        It "Should not throw" { #actually never throws :)
            { Get-ZipFileEntry $filePath.test |
            Get-ZipFileEntryContent } |
            Should not throw
        }
        It "Gets the contents of the file" {
            { Get-ZipFileEntry $filePath.test |
            Get-ZipFileEntryContent } |
            Should not BeNullOrEmpty
        }
    }
    Context "When file couldn't be opened" {
        It "Should have errors" {
            #Pester cannot mock .Open()
            #so we make a stub that always throw
            #todo: mock gettype()?
            $obj = @{}
            $obj | Add-Member -MemberType ScriptMethod -Name Open -Value { throw "this method always throw an exception" }
            Get-ZipFileEntryContent $obj -ErrorVariable err 2>$null
            $err | Should not BeNullOrEmpty
        }
    }
}

