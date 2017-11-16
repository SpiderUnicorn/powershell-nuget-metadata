<h1>
  <img src="logo.png" align="bottom" /> Powershell NuGet Metadata Cmdlet
</h1> 

[![Build status](https://ci.appveyor.com/api/projects/status/o2t3tprh7avi8d0i?svg=true)](https://ci.appveyor.com/project/SpiderUnicorn/powershell-nuget-metadata)


Ever wanted to get metadata from your NuGet packages, such as author or license information? 
Ever wanted to get metadata from your NuGet packages, such as author or license information? 
Got lost looking for it in Visual Studio? Are you looking for a simple script that is able to 
output all metadata information from a single command?
Look no further!

## Table of contents
1. [Installation](#installation)
2. [Examples](#examples)
  * [Simple usage](#simple-usage)
  * [Exporting output](#exporting-output)
  * [Excluding packages](#excluding-packages)
  * [Downloading license information](#downloading-license-information)
3. [Release History](#release-history)
4. [License](#license)

This cmdlet is easy to use and simple to integrate with your build / continuous integration process. If you don't have any previous experience with scripting or PowerShell, follow the examples below.


## Installation
Open powershell and run
```
$ Install-Module NuGetMetadata
```
This cmdlet is publicly distributed through [PowerShell gallery](https://www.powershellgallery.com/packages/NuGetMetadata/). To install, simply open a powershell window (run as administrator) and run the following:

``
PS> Install-Module NuGetMetadata
``

## Examples
### Simple usage
Open a PowerShell prompt in your project directory and run:
```sh
PS> Get-NuGetMetadata
```
It will output the metadata contents of every NuGet package within the project.
It does this by searching for .nupkg files in the folder you're in, open them, and output the contents of the .nuspec files it finds.

You can provide both folders and files:
```sh
PS> Get-NuGetMetadata C:\Project\
```
```sh
PS> Get-NuGetMetadata .\example.nupkg
```
Or a combination of both:
```sh
PS> Get-NuGetMetadata .\example.nupkg, C:\Project\
```
## Exporting output
With powershell it's easy to save the data to file.
### To CSV
```sh
PS> Get-NuGetMetadata | Export-Csv -NoTypeInformation ./my-metadata-file.csv
```
This produces a file named my-metadata-file.csv in the directory you are in.
### To JSON
Since the Get-NugetMetadata cmdlet produces xml objects, it can't be easily converted to Json using ConvertTo-Json.
One workaround is to pipe via select, which then creates a PSObject that can be converted:
```sh
PS> Get-NuGetMetadata | Select-Object id, version, licenseUrl | ConvertTo-Json | Out-File ./my-metadata-file.csv
```
## Excluding packages
To exclude, for example, Microsoft packages:
```sh
PS> Get-NuGetMetadata | ? { $_.id -notlike 'Microsoft*' }
```
## Downloading license information
> This is just a simple example. One caveat is that it doesn't clean the output folder on each invocation.

In your project directory, create a folder called "Licenses".
```
PS> mkdir Licenses
```

The line below downloads the license url contents, and saves them as separate html files (named after the identifier).
```sh
PS> Get-NuGetMetadata | select id, licenseUrl | % { (Invoke-WebRequest $_.licenseUrl).Content |
Out-File -FilePath "./Licenses/$($_.id).html" }
```

## Release History

* 1.0.0
    * Released and published on [PowerShell Gallery](https://www.powershellgallery.com/)

## License

Distributed under the MIT license. See ``LICENSE`` for more information.
