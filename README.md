# Get NuGet Package Metadata
Ever wanted to get metadata from your NuGet packages, such as author or license information? 
Got lost looking for it in Visual Studio? Are you looking for a simple script that is able to 
output all metadata information from a single command? This cmdlet is easy to use and
simple to integrate with your build / continuous integration process. If you don't have any
previous experience with scripting or PowerShell, follow the examples below.

## Installation



## Simple usage
By default, the cmdlet recursively searches for .nuspec files relative to the folder you're in.
```sh
Get-NuGetPackageMetadata
```

## Release History

* 1.0.0
    * Released and published on [PowerShell Gallery](https://www.powershellgallery.com/)

## License

Distributed under the MIT license. See ``LICENSE`` for more information.


