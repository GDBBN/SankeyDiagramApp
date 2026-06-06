# Sankey Studio

Eine native SwiftUI-App für iPhone und iPad zum Visualisieren persönlicher
Finanzflüsse.

## Funktionen

- Einnahmen und Ausgaben komfortabel erfassen
- Ausgaben in Gruppen und Unterkategorien strukturieren
- Automatisches Sankey-Layout mit proportionalen Flussbreiten
- Restbudget, Summen und Prozentanteile direkt erkennen
- Projekte als bearbeitbare JSON-Datei speichern und wieder laden
- Diagramme als PNG speichern oder über das iOS-Teilen-Menü teilen

## Projekt öffnen

Das Repository enthält eine `project.yml` für
[XcodeGen](https://github.com/yonaskolb/XcodeGen). Auf einem Mac:

```sh
brew install xcodegen
xcodegen generate
open SankeyStudio.xcodeproj
```

Danach das Ziel `SankeyStudio` in Xcode ausführen. Erforderlich sind Xcode 15
oder neuer und iOS 17 oder neuer.

## Vorschau unter Windows

Für eine direkt nutzbare PC-Vorschau die Datei `preview/index.html` im Browser
öffnen. Diese Vorschau bildet den Editor und das Sankey-Diagramm nach, ist aber
nicht die eigentliche SwiftUI-App.
