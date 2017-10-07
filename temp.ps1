#todo: can has resolve? restore needed?

function GetCsprojPath {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            #ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        [string]$Path
    )
    BEGIN {
        $projectPattern = '^Project\('
        $filenameIndex = 2
    }
    PROCESS {
        Write-Verbose "GetCsprojPath input: '$Path'"
        $directory = Split-Path $Path
        Get-Content $Path |
            Select-String $projectPattern |
            ForEach-Object {
                $projectPath = ($_ -split '[=,]')[$filenameIndex].Trim(' "')
                $output = Join-Path $directory $projectPath
                Write-Verbose "GetCsprojPath project file: $output"
                if ($output -match '\.csproj$') {
                    [PSCustomObject]@{
                        Path = $output
                    }
                }
            }
    }
    END {}
}

function GetPackageNameVersion {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('FullName')]
        [string]$Path
    )
    BEGIN {}
    PROCESS {
        Write-Verbose "GetPackageNameVersion input: $Path"
        if (Test-Path $Path) {
            $xml = [xml](Get-Content $Path)
            Select-Xml -Xml $xml -XPath '//PackageReference' |
            select -ExpandProperty Node |
            ForEach-Object {
                $output = [PSCustomObject]@{
                    Name    = $_.Include
                    Version = $_.Version
                }
                Write-Verbose "GetPackageNameVersion output: $output"
                $output
            }
        }
    }
    END {}
}

function GetNuGetPackageDirectory {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [PSCustomObject]$NameVersion
    )
    BEGIN {
        #todo: add logic here, for nuget.config n stuff
        $nugetDefaultFolder = "$HOME\.nuget\packages"
    }
    PROCESS {
        Write-Verbose "GetNugetPackageDirectory input: $Path"
        $output = [PSCustomObject]@{
            Path = "$nugetDefaultFolder\$($NameVersion.Name)\$($NameVersion.Version)"
        }
        Write-Verbose "GetNugetPackageDirectory output: $output"
        $output
    }
    END {}
}

Get-ChildItem -File -Recurse -Filter '*.sln' -ErrorAction SilentlyContinue |
    GetCsprojPath -Verbose |
    GetPackageNameVersion -Verbose |
    GetNuGetPackageDirectory -Verbose
#
