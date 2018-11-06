# ar-platformer

Platformer ist eine Processing-Applikation, die in Zusammenarbeit mit einer PS3-Eye Kamera und einem Projektor ein Mixed-Reality "Mario"-Spiel implementiert.

## Setup
- Es muss eine PS3 Eye Kamera an USB angeschlossen und von keinem anderen Videotreiber blockiert sein.
- Der Sketch Platformer.pde soll mit der `processing-java` CLI ausgeführt werden.
- Die Datei `settings.json` im data-Ordner gibt die perspektivische Verzerrung vor.

## Implementationsdetails
- Der Sketch versucht sich mit einem MQTT Server an der Adresse 192.168.100.40 zu verbinden.
- Zur Steuerung werden die MQTT-Topics `/argame/state` und `/argame/command` verwendet.
- Je nach Spielstatus werden die Signale `PASSWORD`, `STARTSCREEN`, `INGAME`, `EDIT`, `ENDSCREEN` gesendet.
- Die Signale `RESET`, `START` und `ACTIVATE` steuern das Spiel.

