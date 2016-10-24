# ![logo](https://github.com/SpiderUnicorn/nuget-license-information/blob/master/logo.png) <span style="margin-bottom:10px">Get NuGet Package Metadata</span>
Ever wanted to get metadata from your NuGet packages, such as author or license information? 
Got lost looking for it in Visual Studio? Are you looking for a simple script that is able to 
output all metadata information from a single command?
Look no further!

This cmdlet is easy to use and simple to integrate with your build / continuous integration process.

If you don't have any previous experience with scripting or PowerShell, follow the examples below.

## Installation

## Examples
### Simple usage
By default, the cmdlet recursively searches for .nupkg files in the folder you're in.
Open a PowerShell prompt in your project directory and run:
```sh
$ Get-NuGetMetadata
```
It should output the metadata contents of every NuGet package within the project.
## Exporting output
With powershell it's easy to save the data to file.
### To CSV
```sh
$ Get-NuGetMetadata | Export-Csv -NoTypeInformation ./my-metadata-file.csv
```
This produces a file named my-metadata-file.csv in the directory you are in.
### To JSON
Since the Get-NugetMetadata cmdlet produces xml, it can't be easily converted to Json using ConvertTo-Json.
One workaround is to pipe via select, which then creates a PSObject that can be converted:
```sh
$ Get-NuGetMetadata | Select-Object id, version, licenseUrl | ConvertTo-Json | Out-File ./my-metadata-file.csv
```


## Release History

* 1.0.0
    * Released and published on [PowerShell Gallery](https://www.powershellgallery.com/)

## License

Distributed under the MIT license. See ``LICENSE`` for more information.
