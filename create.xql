xquery version "3.1";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

let $key := util:uuid()

let $coll := xmldb:create-collection('/db/apps/pageCount', $key)

return
    <html>
        <head>
            <title>Projekt erstellt</title>
        </head>
        <body>
            <h1>Ein neues Projekt</h1>
            <p>Projekt {$coll} (Key: {$key}) erstellt. Diesen Key für alle Uploads zu diesem Projekt aufbewahren!
        <br/><a href="index.html">zurück zur Startseite</a></p></body>
    </html>