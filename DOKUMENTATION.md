# CMB Projekt-Cockpit – Dokumentation

**Live-Adresse:** https://hans6688.github.io/cmb-cockpit/
**Repository:** https://github.com/Hans6688/cmb-cockpit
**Stand:** 25.08.2026

Diese Dokumentation beschreibt alles, was im Projekt-Cockpit gebaut wurde: was es kann,
wie es technisch funktioniert und wo im Code die einzelnen Teile liegen. Sie wird bei
**jeder Änderung am Projekt mitgepflegt** – das Änderungsprotokoll am Ende zeigt die
Historie.

---

## 1. Was das Cockpit ist

Das CMB Projekt-Cockpit ist das persönliche Dashboard von Hans-Jörg Joost (CMB Digital)
für Kundenprojekte und die eigene Tagesorganisation. Es läuft als Web-App im Browser,
lässt sich auf dem iPhone wie eine App installieren und speichert alle Daten zentral –
derselbe Stand auf allen Geräten.

**Grundprinzip:** bewusst einfach gehalten. Eine einzige Seite, keine Untermenüs,
alles Wichtige auf einen Blick.

---

## 2. Architektur – wie alles zusammenspielt

```
┌─────────────────────┐        ┌──────────────────────────┐
│  Browser / iPhone   │  lädt  │  GitHub Pages (Hosting)  │
│  (App-Oberfläche)   │◄───────│  index.html + Icons      │
└─────────┬───────────┘        └──────────────────────────┘
          │ liest & schreibt Daten (verschlüsselt, mit Login)
          ▼
┌──────────────────────────────────────────────┐
│  Supabase (Projekt „content-pipeline“)       │
│  - Anmeldung (E-Mail + Passwort)             │
│  - Tabellen: cockpit_projects,               │
│    cockpit_extras, cockpit_inbox             │
└──────────────────────────────────────────────┘
          ▲
          │ wirft Notizen ein (mit Geheimcode)
┌─────────┴───────────┐
│  Apple-Kurzbefehl   │  „Hey Siri, Ans Cockpit“ oder
│  „Ans Cockpit“      │  Teilen-Menü (iPhone & Mac)
└─────────────────────┘
```

- **Oberfläche:** eine einzige statische Datei [`index.html`](index.html) – HTML, CSS
  und JavaScript in einem. Kein Framework, kein Build-Schritt (bewusste Entscheidung
  für Einfachheit und Wartbarkeit).
- **Hosting:** kostenlos über GitHub Pages, Branch `main`. Jeder Push auf `main`
  veröffentlicht automatisch die neue Version (dauert ca. 1–2 Minuten).
- **Daten:** Supabase (PostgreSQL-Datenbank in Frankfurt), mitgenutzt wird das
  bestehende Supabase-Projekt der Content-Pipeline (`aklglucdxeactfkczmtb`).
- **Login:** Supabase Auth mit E-Mail + Passwort. „Passwort vergessen“ ist eingebaut
  (E-Mail-Link). Row-Level-Security (Abschnitt 6) stellt sicher, dass jeder Nutzer
  ausschließlich seine eigenen Daten sieht.
- **App-Gefühl (PWA):** [`manifest.webmanifest`](manifest.webmanifest) +
  [`sw.js`](sw.js) machen die Seite installierbar („Zum Home-Bildschirm“) und halten
  die Oberfläche offline vorrätig. Daten kommen immer live aus Supabase.
- **Icons:** [`icons/`](icons/) enthält die App-Icons im CMB-Logo-Stil
  (2×2 gerundete Quadrate, Diamant mit Markengradient), erzeugt per Python/PIL.

---

## 3. Design – das CMB-Markenkit

Alle Farben und Schriften folgen dem CMB-Digital-Markenkit:

| Element | Wert | Verwendung |
|---|---|---|
| Petrol | `#2c5163` | Primärfarbe, Texte, Flächen |
| Petrol Dunkel | `#1e3a48` | Dark Mode, Text auf Hell |
| Orange | `#ff6a3f` | Akzente, sparsam |
| Markengradient | `#ff863e → #ff4732` | Logo-Diamant, Buttons, Projekt-Avatare |
| Moos-Grün | `#4d7a5e` | Erfolg, „Aktiv“, Priorität Niedrig |
| Warmer Sand | `#c4a882` | Hinweise, Badges, Priorität Mittel |
| Cream | `#f0eee6` | Seitenhintergrund |
| Instrument Serif | Google Fonts | Überschriften, Zahlen |
| Inter | Google Fonts | Fließtext, Bedienelemente |

Ein **Dark Mode** ist eingebaut und folgt automatisch der Systemeinstellung
(CSS `prefers-color-scheme`, Token-basiert am Anfang des `<style>`-Blocks).

---

## 4. Die Elemente der Oberfläche

### 4.1 Kopfbereich
Logo, Begrüßung, Tagline „Klar denken, besser handeln.“, die Kennzahlen
(Projekte, offene To-dos, aktiv, Geld-Aktionen), Abmelden-Knopf und der Button
**„+ Neues Projekt“**. Rechts oben außerdem:

- **Datums-Stempel:** das heutige Datum als gedrehter Diamant im Logo-Stil
  (Tag groß, Monat klein), darunter Wochentag und Jahr – immer aktuell.
- **Merker:** frei anlegbare Countdown-Kärtchen („+ Merker“) mit Bezeichnung
  und Datum, z. B. Geburtstage, Ferien, Urlaube oder Fristen. Sie zeigen
  „in N Tagen“ (ab 7 Tagen vorher orange, „heute!“/„morgen“ hervorgehoben),
  sind nach Nähe sortiert und per Klick editier- oder löschbar
  (Spalte `header_items` in `cockpit_extras`). Jeder Merker kann optional ein
  **kleines Bild** tragen – entweder aus der eingebauten **Motiv-Bibliothek**
  (12 einheitliche Illustrationen im Marken-Stil: Geburtstag, Urlaub, Ferien,
  Flug, Termin, Frist, Padel, Kinder, Vertrag, Rechnung, Auto, Blumen –
  einmalig mit Magnific generiert, Pfade `lib-<key>.jpg`) oder als eigenes
  Foto („Eigenes Foto wählen“, Pfad `merker-<id>.jpg`). Bibliotheks-Motive
  werden geteilt genutzt und beim Löschen eines Merkers nie mitgelöscht.

### 4.2 Drei Aufklapp-Buttons: Tagesroutine · Meine Ziele · Eingang
Kompakte Buttons mit Stand-Anzeige, die Karten erst auf Klick ausklappen
(beim Start immer eingeklappt, damit die Seite ruhig bleibt):

- **Tagesroutine** – tägliche Gewohnheiten zum Abhaken (z. B. Morgenroutine mit
  Sport, Marketing-Zeit, Padeltraining, Kontaktpflege). Setzt sich **jeden Tag
  automatisch zurück**; die Historie bleibt gespeichert. Ab 2 Tagen in Folge
  erscheint ein **„Serie N“-Zähler**. Button-Badge: „2 / 4 heute“ (grün, wenn alles
  geschafft). Routinen lassen sich hinzufügen und löschen.
- **Meine Ziele** – einfache editierbare Liste zur Orientierung. Eintragen, abhaken
  (bleibt durchgestrichen sichtbar), löschen. Button-Badge: Anzahl offener Ziele.
  **Vision-Board:** Über „Bild“ bekommt ein Ziel ein eigenes Foto; Ziele mit Bild
  erscheinen oben in der Karte als Bild-Mosaik mit dem Zieltext über dem Foto.
  Ein Klick öffnet das Bild bildschirmfüllend mit dem Ziel als Leitsatz.
  Die Tagesroutine-Karte trägt zusätzlich eine **Visionsbild-Rotation**: mehrere
  Bilder (eigene Fotos oder generierte Motive, Spalte `routine_imgs`), von denen
  **jeden Tag automatisch ein anderes** als Kopfbild erscheint.
  Bilder werden beim Hochladen automatisch verkleinert und liegen **privat** im
  Supabase-Storage-Bucket `cockpit-vision` (nur nach Login über kurzlebige,
  signierte Links abrufbar; Zugriffsregeln pro Nutzerordner).
- **Notizen** (früher „Eingang“) – Sammelkorb für schnelle Notizen: per
  Apple-Kurzbefehl (Abschnitt 7) **oder direkt in der Karte** über das
  Eingabefeld. Jede Notiz kann per Dropdown **„→ als Aufgabe zu …“** in ein
  Projekt verschoben (wird dort ein To-do mit Priorität Mittel) oder über ×
  gelöscht werden. Button-Badge: „N neu“.

### 4.3 Projektbereiche mit Kacheln
Drei aktive Bereiche – **Kundenprojekte** (alles, was Kunden zahlen),
**CMB intern** (eigenes Unternehmen: Marketing, Produkte, Website) und
**Privat** – plus die **Warteschleife** ganz unten: ein bewusst ausgegrauter,
standardmäßig eingeklappter Parkplatz für alles, was gerade nicht dran ist
(Klick auf die Überschrift klappt ihn auf). Für die laufenden
Marketing-Aktivitäten gibt es ein **Dauerprojekt „CMB Marketing“** in
CMB intern – To-dos, Ideen-Notizen und die Verknüpfung zum
LinkedIn-Claude-Projekt an einem Ort.

**WIP-Limit:** Maximal **3 Projekte pro Bereich** (Kunden / CMB intern / Privat).
Ein viertes im selben Bereich lässt die App nicht zu (per Drag-and-drop,
Bereichs-Auswahl oder Neuanlage) – erst muss dort ein Projekt in die
Warteschleife. Liegt ein Bereich über dem Limit, mahnt ein Hinweis-Banner
über den Bereichen, das die betroffenen Bereiche benennt.

**Geld-Aktionen-Zähler:** Vierte Kennzahl im Kopfbereich („Geld-Aktionen
Woche“). Über den +-Knopf werden umsatzwirksame Handlungen erfasst – *Angebot
gesendet, Nachgefasst, Rechnung gestellt, Livegang, Content veröffentlicht*
(plus Rückgängig-Funktion).
Gezählt wird pro Kalenderwoche (`money_log` in `cockpit_extras`), die Vorwoche
bleibt zum Vergleich sichtbar; bei 0 färbt sich die Zahl warnend orange.

- **Drag-and-drop:** Kacheln lassen sich mit der Maus innerhalb eines Bereichs
  umsortieren und zwischen Bereichen verschieben; die Reihenfolge wird gespeichert.
  Auf dem Handy übernimmt das Auswahlfeld „Bereich“ in der Detailansicht diese Aufgabe.
- **Jede Kachel zeigt:** Avatar-Diamant mit Initialen, Projektname, Kurzbeschreibung,
  Status-Pille (Aktiv / In Abstimmung / Wartet auf Kunde / Fertig), einen
  **Teaser der drei dringendsten offenen Aufgaben** (mit Prio-Punkt und
  Termin-Countdown, „+ N weitere“ bei mehr), Fortschrittsbalken und Zähler
  („2 / 5 erledigt“).
- **Prioritäts-Ampel:** Der **Farbstreifen links** an der Kachel zeigt die
  dringendste offene Aufgabe des Projekts: Rot-Orange = Hoch, Sand = Mittel,
  Moos-Grün = Niedrig. Ohne offene Aufgaben bleibt die Kachel neutral.
  Der **Termin-Chip** zeigt den nächsten anstehenden Aufgaben-Termin mit Countdown.

### 4.4 Detailansicht (Klick auf eine Kachel)
Seitliches Panel mit:

- **Status** und **Bereich** als Auswahlfelder, „Projekt löschen“ (mit Rückfrage).
- **To-dos:** Jede Aufgabe hat eine eigene **Priorität** (farbiger Punkt – Klick
  schaltet Niedrig → Mittel → Hoch) und optional ein **Erledigungsdatum**
  (Klick auf „Termin“ bzw. den Termin-Chip öffnet den Kalender). Sortierung
  automatisch: Dringendstes oben, Erledigtes unten.
  **Automatische Hochstufung:** ≤ 7 Tage vor dem Termin steigt „Niedrig“ auf
  „Mittel“, ≤ 3 Tage vorher wird jede Aufgabe „Hoch“ – rein optisch, die von Hand
  gesetzte Stufe bleibt gespeichert. Erledigte Aufgaben und Projekte mit Status
  „Fertig“ werden nicht hochgestuft.
- **Notizen:** freie Projektnotizen mit Datum.
- **Google Drive & Dokumente:** Links einfügen – die App erkennt automatisch
  Drive-Ordner, Google Docs/Sheets/Präsentationen und benennt die Verknüpfung.
- **KI & Repository:** Pro Projekt lassen sich der Link zum GitHub-Repository und
  zu einem festen Claude-Chat/-Projekt speichern. Der Knopf **„Mit Claude
  besprechen“** öffnet einen neuen Claude-Chat und übergibt automatisch den
  Kontext: Projektname, Status, die fünf dringendsten offenen Aufgaben (mit
  Priorität und Termin) sowie den Repository-Link mit dem Hinweis, zuerst
  AGENTS.md und DOKUMENTATION.md zu lesen.
- **Transkripte:** längere Texte (z. B. Gesprächsprotokolle) mit Titel und Datum,
  platzsparend eingeklappt, per Klick aufklappbar.

---

## 5. Datenmodell (Supabase)

Alle Tabellen liegen im Schema `public` des Supabase-Projekts. Die vollständige,
ausführbare Vorlage steht in [`supabase/schema.sql`](supabase/schema.sql).

### `cockpit_projects` – ein Datensatz pro Projekt
| Spalte | Typ | Bedeutung |
|---|---|---|
| `id` | uuid | eindeutige Kennung |
| `user_id` | uuid | Besitzer (Verweis auf den Login) |
| `name`, `sub` | text | Projektname, Kurzbeschreibung |
| `status` | text | `aktiv` · `abstimmung` · `wartet` · `fertig` |
| `category` | text | Bereich: `sprint` · `cmb` · `privat` |
| `sort_order` | integer | Position innerhalb des Bereichs (Drag-and-drop) |
| `data` | jsonb | Inhalt: `todos` (mit `prio`, `due`), `notes`, `docs`, `transcripts` |
| `created_at`, `updated_at` | timestamptz | Zeitstempel |

*Hinweis:* Die Spalten `priority` und `due_date` auf Projektebene existieren noch
aus einer früheren Version, werden aber nicht mehr verwendet – Priorität und Termin
leben seit dem 25.08.2026 pro To-do im `data`-JSON.

### `cockpit_extras` – eine Zeile pro Nutzer
| Spalte | Typ | Bedeutung |
|---|---|---|
| `routines` | jsonb | Tagesroutinen; je Routine eine Datums-Landkarte `done` (`{"2026-08-25": true}`) – daraus werden Tageshaken und Serien berechnet; Einträge älter als 90 Tage werden automatisch aufgeräumt |
| `goals` | jsonb | Ziele mit `done`-Kennzeichen |

### `cockpit_inbox` – eine Zeile pro Eingangs-Notiz
| Spalte | Typ | Bedeutung |
|---|---|---|
| `content` | text | Notiztext (max. 4000 Zeichen) |
| `created_at` | timestamptz | Eingangszeitpunkt |

### Funktion `cockpit_add_note(secret, note)`
Der Einwurf-Kanal für den Apple-Kurzbefehl (Abschnitt 7): prüft einen Geheimcode
und legt die Notiz für das Konto `mail@cmb-seo.com` im Eingang ab. Nur diese
Funktion darf ohne Login schreiben – und nur mit korrektem Code.

---

## 6. Sicherheit

- **Row-Level-Security (RLS):** Auf allen drei Tabellen aktiv. Jede Zeile gehört
  einem Nutzer (`user_id`); lesen, ändern und löschen kann nur der Besitzer.
  Selbst wenn jemand die öffentliche App-Adresse und den öffentlichen Schlüssel
  kennt, sieht er ohne Login nichts.
- **Öffentlicher Schlüssel:** In `index.html` steht nur der Supabase
  „publishable key“ – der ist dafür gemacht, im Browser zu liegen. Geheime
  Schlüssel (service_role) sind **nicht** im Repository und dürfen es nie sein.
- **Geheimcode des Eingangs:** Der Code für `cockpit_add_note` steht **nur** in der
  Supabase-Funktion und im Apple-Kurzbefehl – bewusst nicht in diesem (öffentlichen)
  Repository. In `supabase/schema.sql` steht ein Platzhalter. Falls der Code
  kompromittiert wird: in Supabase per `create or replace function` einfach einen
  neuen setzen und den Kurzbefehl anpassen.
- **Öffentliches Repository:** nötig für kostenloses GitHub-Pages-Hosting. Es
  enthält nur Programmcode – keine Passwörter, keine Projektdaten.

---

## 7. Apple-Kurzbefehl „Ans Cockpit“

Schnelle Notizen wandern ohne Umweg ins Cockpit:

- **iPhone:** „Hey Siri, Ans Cockpit“ → diktieren. Oder aus jeder App (auch Apple
  Notizen): Text markieren → Teilen → „Ans Cockpit“.
- **Mac:** Teilen-Menü in Apple Notizen (ggf. einmalig unter „Erweiterungen
  bearbeiten …“ aktivieren).
- Nach dem Versand erscheint die Bestätigung „Im Cockpit ✓“; die Notiz liegt dann
  im Bereich **Notizen** der App.

**Technik:** Der Kurzbefehl schickt eine POST-Anfrage an
`…/rest/v1/rpc/cockpit_add_note` mit dem öffentlichen Schlüssel als Header und
`{secret, note}` als Inhalt. Er wurde als signierte `.shortcut`-Datei erzeugt und
installiert; über iCloud synchronisiert er sich auf alle Apple-Geräte.
Bei Verlust lässt er sich anhand von Abschnitt 5/7 und dem Geheimcode neu anlegen.

---

## 8. Betrieb & Wiederherstellung

- **Änderung veröffentlichen:** Commit auf `main` pushen → GitHub Pages baut
  automatisch. Browser-Hinweis: Die App hält die Oberfläche im Zwischenspeicher;
  nach einem Update ggf. einmal neu laden.
- **Neues Gerät:** einfach https://hans6688.github.io/cmb-cockpit/ öffnen und
  anmelden. iPhone: Teilen → „Zum Home-Bildschirm“.
- **Komplett-Wiederaufbau der Datenbank:** [`supabase/schema.sql`](supabase/schema.sql)
  im Supabase-SQL-Editor ausführen (Platzhalter für Geheimcode und E-Mail ersetzen).
  Das Skript ist wiederholbar ausführbar („if not exists“ / „drop policy if exists“).
- **Konto:** Registrierung und Passwort-Zurücksetzen laufen über die App selbst.

---

## 9. Änderungsprotokoll

| Datum | Änderung |
|---|---|
| 24.08.2026 | **Erstversion:** Dashboard mit Projekt-Kacheln, To-dos, Notizen, Drive-Links, Transkripten; Supabase-Login mit Registrierung und Passwort-Reset; zentrale Speicherung (`cockpit_projects`); PWA (Manifest, Service Worker, Icons im CMB-Logo-Stil); GitHub-Pages-Hosting. Zuvor als klickbarer Prototyp mit lokaler Speicherung (Claude-Artifact) entworfen. |
| 25.08.2026 | Startseite in drei **Bereiche** unterteilt (Sprintprojekte / Sonstige CMB-Projekte / Private Projekte) mit **Drag-and-drop**-Sortierung (`category`, `sort_order`); Bereich-Auswahl in der Detailansicht als Handy-Alternative. |
| 25.08.2026 | **Prioritäten & Termine** eingeführt – zunächst auf Projektebene (Farbstreifen, Countdown-Chip, automatische Hochstufung ≤ 7 / ≤ 3 Tage). |
| 25.08.2026 | Prioritäten & Termine **auf To-do-Ebene verlagert** (fachlich korrekter): Prio-Punkt und Termin pro Aufgabe, Kachel erbt die dringendste offene Aufgabe, automatische Sortierung; Projekt-Felder dafür entfernt. |
| 25.08.2026 | **Tagesroutine** (täglicher Reset, Serien-Zähler, `cockpit_extras`) und **Meine Ziele** als Karten über den Projektbereichen. |
| 25.08.2026 | Routine & Ziele zu **kompakten Aufklapp-Buttons** umgebaut (Startseite ruhiger); Badges mit Tagesstand bzw. offenen Zielen. |
| 25.08.2026 | Kachel-**Teaser**: die drei dringendsten offenen Aufgaben mit Prio-Punkt und Termin direkt auf der Kachel („+ N weitere“). |
| 25.08.2026 | **Eingang** für schnelle Notizen (`cockpit_inbox`, RPC `cockpit_add_note` mit Geheimcode); Zuordnung zu Projekten per Dropdown; **Apple-Kurzbefehl „Ans Cockpit“** gebaut, signiert, installiert und Ende-zu-Ende getestet (Siri, Teilen-Menü, iCloud-Sync). |
| 25.08.2026 | Diese Dokumentation angelegt; wird ab jetzt bei jeder Änderung mitgepflegt. |
| 25.08.2026 | [`AGENTS.md`](AGENTS.md) und [`CLAUDE.md`](CLAUDE.md) angelegt: Briefing und Arbeitsregeln, damit jeder KI-Assistent (auch ohne diese Gesprächshistorie) sofort weiterarbeiten kann. |
| 25.08.2026 | Abschnitt **„KI & Repository“** in der Detailansicht: Repository- und Claude-Chat-Link pro Projekt speicherbar; Knopf „Mit Claude besprechen“ startet einen neuen Claude-Chat mit automatisch übergebenem Projektkontext. |
| 25.08.2026 | **Vision-Board**: Bilder pro Ziel (Mosaik + Vollbild-Ansicht mit Leitsatz) und Visionsbild für die Tagesroutine; privater Storage-Bucket `cockpit-vision` mit nutzerbezogenen Zugriffsregeln. |
| 25.08.2026 | Tagesroutine: **Visionsbild-Rotation** – mehrere Bilder (`routine_imgs`), täglich wechselndes Kopfbild; Verwaltung über „Bild hinzufügen“ / „heutiges Bild entfernen“. |
| 25.08.2026 | **Fokus-Werkzeuge**: Wochenzähler „Geld-Aktionen“ (Angebot/Nachfassen/Rechnung/Livegang, `money_log`) und **WIP-Limit 3** mit neuem Bereich „Warteschleife“ (eingeklappt, ausgegraut); Limit wird bei Drag-and-drop, Bereichswechsel und Neuanlage durchgesetzt. |
| 25.08.2026 | Fünfte Geld-Aktion **„Content veröffentlicht“** (Start des LinkedIn-Rhythmus Mo/Mi/Fr). |
| 25.08.2026 | WIP-Limit angepasst: **3 pro Bereich** statt 3 insgesamt (private Kleinaufgaben blockieren so nicht das Geschäftliche). |
| 25.08.2026 | „Eingang“ in **„Notizen“** umbenannt; Notizen lassen sich jetzt auch direkt in der Karte erstellen (neue Insert-Regel `inbox_insert_own`). |
| 31.08.2026 | Bereiche umbenannt: **Kundenprojekte** (statt Sprintprojekte) und **CMB intern** (statt Sonstige CMB-Projekte); Dauerprojekt **„CMB Marketing“** als fester Ort für Marketing-Aufgaben und -Ideen eingeführt. |
| 31.08.2026 | **Bearbeiten überall**: Klick auf einen Text öffnet den Bearbeiten-Dialog – bei Aufgaben, Projekt-Notizen, Notizen, Zielen und Routinen; Projekte bekommen „Name/Beschreibung bearbeiten“ in der Detailansicht (neue Regel `inbox_update_own`). |
| 31.08.2026 | **Kopfbereich gestaltbar**: Datums-Stempel im Logo-Stil (immer aktuelles Datum) und frei anlegbare **Merker-Kärtchen** mit Countdown (Geburtstage, Ferien, Fristen; `header_items`). |
| 01.09.2026 | **Schnell-Erfassung** oben („Was möchtest du festhalten?“): Eintippen + Enter legt die Notiz direkt im Notizen-Bereich ab – Zuordnung zu Projekten wie gewohnt per Dropdown. |
| 01.09.2026 | **Merker-Bilder**: Jeder Merker kann ein kleines Foto/Motiv tragen (links im Kärtchen, „Bild wählen“ im Dialog). |
| 01.09.2026 | **Motiv-Bibliothek**: 12 einheitliche Illustrationen im Marken-Stil zum Antippen im Merker-Dialog (mit Magnific generiert); eigenes Foto weiterhin möglich. |
