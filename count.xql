xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

declare variable $local:pageLength := 1600;
declare variable $local:price := map {"normal" : 3.50, "simple": 1.50, "complex": 6.00, "extended": 4.50};
declare variable $local:fnmult := 3;
declare variable $local:project := normalize-space(request:get-parameter('key', ''));

declare function local:table ($fileName as xs:string, $len as xs:int, $fn as xs:int, $ca as xs:int, $co) {
    let $fnC := $local:fnmult * $fn
    let $caC := $local:fnmult * $ca
    let $total := ($len + $fnC) + $ca
    let $pages := round($total div $local:pageLength)
    
    let $type := if ($co) then "complex"
        else if ($ca > 0) then "extended"
        else if ($fn > 0) then "normal"
        else "simple"
    
    return
    <table>
        <tr>
            <td>Zeichenzahl Text</td>
            <td> </td>
            <td style="text-align:right;">{$len}</td>
        </tr>
        <tr>
            <td>Sachanmerkungen</td>
            <td>{$fn} zu {$local:fnmult} FN-Zeichen</td>
            <td style="text-align:right;">{$fnC}</td>
        </tr>
        <tr>
            <td>kritische Anmerkungen</td>
            <td>{$ca} zu {$local:fnmult} FN-Zeichen</td>
            <td style="text-align:right;">{$caC}</td>
        </tr>
        <tr>
            <td>Zeichenzahl:</td>
            <td> </td>
            <td style="text-align:right;">{$total}</td>
        </tr>
        <tr style="border-top: 1px solid;">
            <td>Normseiten zu</td>
            <td>{$local:pageLength} Zeichen:</td>
            <td>{$pages}</td>
        </tr>
        <tr>
            <td>Seitentyp</td>
            <td>{$type} zu {$local:price($type)}€</td>
            <td>{$local:price($type) * $pages} €</td>
        </tr>
    </table>
};

declare function local:save($origFileName, $len, $fn, $ca, $co) {
    let $fnC := $local:fnmult * $fn
    let $caC := $local:fnmult * $ca
    let $total := ($len + $fnC) + $ca
    let $pages := round($total div $local:pageLength)
    
    let $type := if ($co) then "complex"
        else if ($ca > 0) then "extended"
        else if ($fn > 0) then "normal"
        else "simple"
    
    let $entry :=
    <file name="{$origFileName}" type="{$type}" len="{$total}" pages="{$pages}" price="{$local:price($type) * $pages}" />
    let $project := doc('/db/apps/pageCount/'||$local:project||'.xml')/*:project

    return if ($project/*:file[@name=$origFileName])
        then update replace $project/*:file[@name=$origFileName] with $entry
        else update insert $entry into $project
};

declare function local:get() {
    let $files := doc('/db/apps/pageCount/'||$local:project||'.xml')//*:file
    
    return
        <table>
            {for $file in $files return
                <tr>
                    <td>{$file/@name||':'}</td>
                    <td>{$file/@type||''}</td>
                    <td>{$file/@pages||' Seiten'}</td>
                    <td style="text-align: right;">{format-number($file/@price, '0.00')} €</td>
                </tr>
            }
            <tr style="border-top: 1px solid;">
                <td>Gesamt</td>
                <td> </td>
                <td>{sum($files//@pages)}</td>
                <td style="text-align: right;">{format-number(sum($files//@price), '0.00')} €</td>
            </tr>
        </table>
};

let $origFileName := request:get-uploaded-file-name('file')
let $type := substring($origFileName, string-length($origFileName)-2)

return
<html>
    <head>
        <title>Seitenzähler</title>
        <link rel="stylesheet" href="style.css" />
    </head>
    <body>{
        if (string-length($origFileName) = 0) then
            (<header>bau|ka|st</header>,
                <div><h1>keine Datei übermittelt</h1></div>,
                <div><h1>Projekt insgesamt</h1>{local:get()}</div>,
                <footer><p>Diese Werte dienen ausschließlich der Information und stellen weder ein Angebot noch eine Rechnung seitens der
                    Firma baukast Baumgarten, Kampkaspar, Steyer GbR dar.
                </p></footer>)
        else
        let $origFileData := util:base64-decode(string(request:get-uploaded-file-data('file')))
        return if ($type = 'xml') then
            let $text := util:parse($origFileData)
            let $len := string-length(normalize-space($text//tei:text))
            let $fn := count($text//tei:note[@type='footnote'] | $text//tei:note[@type='annotation'])
            let $ca := count($text//tei:note[@type='crit_app'] | $text//tei:span[@type='crit_app'] | $text//tei:app | $text//tei:choice)
            let $co := request:get-parameter("complex", "")
            
            let $saveValues := local:save($origFileName, $len, $fn, $ca, $co)
            let $allValues := local:get()
            
            return (<header>bau|ka|st</header>,
                <div><h1>aktuelle Datei</h1><h2>{$origFileName}</h2>
                {local:table($origFileName, $len, $fn, $ca, $co)}</div>,
                <div><h1>Projekt insgesamt</h1>{$allValues}</div>,
                <footer><p>Diese Werte dienen ausschließlich der Information und stellen weder ein Angebot noch eine Rechnung seitens der
                    Firma baukast Baumgarten, Kampkaspar, Steyer GbR dar.
                </p></footer>)
                
        else if ($type = 'tex') then
            string-length(normalize-space($origFileData))
        else (<h1>Falscher Dateityp: {$type}</h1>,
            <p>{$origFileName}</p>)
    }</body>
</html>