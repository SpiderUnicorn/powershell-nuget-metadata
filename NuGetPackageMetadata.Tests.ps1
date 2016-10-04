. ".\NuGetPackageMetadata.ps1"

$testFile = "./test/test.zip"
$relativePath = "./test/test.zip"
$absolutePath = (Resolve-Path $relativePath).Path
$nonExistentPath = "./non-existent.file"
$directoryPath = "."
$notZipFilePath = "./test/test.txt"

Describe "Get-ZipFileEntry" {
    Context "Given no file (null)" {
        It "Via parameter: Returns null" {
            Get-ZipFileEntry $null | Should be $null
        }
        It "Via pipe: Returns null" {
            $null | Get-ZipFileEntry | Should be $null
        }
    }
    Context "Given no file (empty string)" {
        It "Via parameter: Has errors" {
            Get-ZipFileEntry "" -ErrorVariable err 2>$null
            $err | Should not BeNullOrEmpty
        }
        It "Via pipe: Has errors" {
            "" | Get-ZipFileEntry -ErrorVariable err 2>$null
            $err | Should not BeNullOrEmpty
        }
    }
    Context "Given different types of paths" {
        It "Resolves absolute paths" {
            { Get-ZipFileEntry $absolutePath } | Should not be $null
        }
        It "Resolves relative paths" {
            { Get-ZipFileEntry $relativePath } | Should not be $null
        }
    }
    Context "Given non-existent file path" {
        It "Has errors" {
            Get-ZipFileEntry $nonExistentPath -ErrorVariable err 2>$null
            $err | Should not BeNullOrEmpty
        }
    }
    Context "Given a directory" {
        It "Has errors" {
            Get-ZipFileEntry $directoryPath -ErrorVariable err 2>$null
            $err | Should not BeNullOrEmpty
        }
    }
    Context "Given example zip file path with one file" {
        $result = Get-ZipFileEntry (Resolve-Path $testFile).Path
        It "Return a non-empty collection" {
            $result.Count | Should BeGreaterThan 0
        }
        It "Return a ZipArchiveEntry" {
            $result | Should BeOfType System.IO.Compression.ZipArchiveEntry
        }
    }
    Context "Given a non zip file" {
        It "something" {
            Get-ZipFileEntry $notZipFilePath 2>$null -ErrorVariable err
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
        It "Should not throw" {
            { Get-ZipFileEntry $testFile |
            Get-ZipFileEntryContent } |
            Should not throw
        }
        It "Gets the contents of the file" {
            { Get-ZipFileEntry $testFile |
            Get-ZipFileEntryContent } |
            Should not BeNullOrEmpty
        }
    }
    Context "When file couldn't be opened" {
        It "Should throw" {
            #Pester cannot mock .Open()
            #so we make a stub that always throw
            $obj = @{}
            $obj | Add-Member -MemberType ScriptMethod -Name Open -Value { throw "couldn't open" }
            Get-ZipFileEntryContent $obj -ErrorVariable err 2>$null
            $err | Should not BeNullOrEmpty
        }
    }
}
