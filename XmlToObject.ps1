function XmlToObject ([System.Xml.XmlElement]$element) {
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
        $children[$prop] = XmlToObject($child)
    }
    $children
}

XmlToObject($xml)
