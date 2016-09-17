$xmltest = [xml]@"
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2011/08/nuspec.xsd">
  <metadata>
    <id>Microsoft.AspNet.WebApi</id>
    <tags>Microsoft AspNet WebApi AspNetWebApi</tags>
    <dependencies>
      <dependency id="Microsoft.AspNet.WebApi.WebHost" version="[5.2.3, 5.3.0)" />
      <dependency id="Microsoft.AspNet.WebApi.WebHost2" version="[25.2.3, 25.3.0)" />
      <hejsan>
        <svejsan djur="kossa" torktumlare="whirlpool">tjena</svejsan>
        <tjohej>wahoo!</tjohej>
        <fisk>
            <haj>blubb</haj>
        </fisk>
      </hejsan>
    </dependencies>
    <duplicate>handle this</duplicate>
    <duplicate>handle this too</duplicate>
    <nothingness></nothingness>
    <emptiness/>
  </metadata>
</package>
"@

#
function Convert-XmlToObjectTest {
    [CmdletBinding()]
    Param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true)]
        [System.Xml.XmlElement]$XmlElement,
        [int]$Level
    )
    BEGIN {}
    PROCESS {
        $Element = $XmlElement
        $node = [ordered]@{} #hashtabell = d�ligt, arrayer med key-value-par?
        $attr = [ordered]@{}
        
        $childnodes = @($Element.ChildNodes | Where-Object { $_.NodeType -ne 'Text' })
        $textnodes = @($Element.ChildNodes | Where-Object { $_.NodeType -eq 'Text' })
        
        $value = $textnodes[0].InnerText
        Write-Verbose "$Level $(" " * 4 * $Level)<$($Element.Name)>$($value)"
        
        $Element.Attributes | ForEach-Object {
            Write-Verbose "$Level $(" " * 4 * $Level) attrib: $($_.Name)=$($Element.GetAttribute($_.Name))"
            $attr[$_.Name] = $Element.GetAttribute($_.Name)
        }
        
        if (!$childnodes) {
            if ($attr.Count -gt 0) {
                $obj = @{}
                if ($value) {
                    $obj['Value'] = $value
                }
                $obj['Attributes'] = $attr
                return $obj
            }
            return $value
        }
        else {
            $childnodes | ForEach-Object {
                $node[$_.Name] = Convert-XmlToObjectTest -XmlElement $_ -Level ($Level + 1) -Verbose
            }
        }
        Write-Verbose "$Level $(" " * 4 * $Level)</$($Element.Name)>"
        return $node
    }
    END {}
}
$result = $xmltest.package.metadata | Convert-XmlToObjectTest -Verbose -Level 0
#>

<#
function Convert-XmlToObject {
    [CmdletBinding()]
    Param(
        [System.Xml.XmlElement]$element
    )
    if ($element.Name -eq "dependency") {
        return $element.GetAttribute('version')
    }
    if (!$element.HasChildNodes -or $element.FirstChild.Name -eq '#text'){
        return $element.InnerText
    }
    $children = [ordered]@{}
    foreach ($child in $element.GetEnumerator() | ? { $_.Name -ne '#text' } ) {
        $prop = $child.Name
        if ($child.Name -eq "dependency") {
            $prop = $child.GetAttribute('id')
        }
        $children[$prop] = Convert-XmlToObject $child
    }
    $children
}
$result = Convert-XmlToObject -element $xmltest.package
#>
