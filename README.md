# Get NuGet Package Metadata
Ever wanted to get metadata from your NuGet packages, such as author or license information? 
Got lost looking for it in Visual Studio? Are you looking for a simple script that is able to 
output all metadata information from a single command? This cmdlet is easy to use and
simple to integrate with your build / continuous integration process. If you don't have any
previous experience with scripting or PowerShell, follow the examples below.

## Installation

## Examples
### Simple usage
By default, the cmdlet recursively searches for .nupkg files relative to the folder you're in.
If you're using visual studio, open a PowerShell prompt on your project directory and run:
```sh
$ Get-NuGetMetadata
```
It should output the metadata contents of every NuGet package within the project.
## Exporting output
### To CSV
With powershell, saving information is as simple as piping the output of the GetNugetMetadata command
to a different command, which writes data to file.
```sh
$ Get-NuGetMetadata | Export-Csv -NoTypeInformation ./my-metadata-file.csv
```
This produces a file named my-metadata-file.csv in the directory you are in.
### To JSON
Since the Get-NugetMetadata cmdlet produces xml, it can't be easily converted to Json using ConvertTo-Json.
One workaround is to construct a custom PSObject by filtering properties of the metadata as such:
```sh
$ Get-NuGetMetadata | Select-Object id, version, licenseUrl | ConvertTo-Json | Out-File ./my-metadata-file.csv
```


### Converting output to JSON




## Release History

* 1.0.0
    * Released and published on [PowerShell Gallery](https://www.powershellgallery.com/)

## License

Distributed under the MIT license. See ``LICENSE`` for more information.


