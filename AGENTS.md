# Briefing für KI-Assistenten

Du arbeitest am **CMB Projekt-Cockpit** – dem persönlichen Projekt-Dashboard von
Hans-Jörg Joost (CMB Digital). **Lies zuerst [DOKUMENTATION.md](DOKUMENTATION.md)** –
dort stehen Architektur, alle Funktionen, das Datenmodell und das Änderungsprotokoll.
Diese Datei hier ergänzt die Arbeitsregeln.

## Über den Nutzer

- Hans-Jörg ist Unternehmer und Jurist, **kein Programmierer**. Kommuniziere in
  Alltagssprache, erkläre Wirkung statt Technik, gib Klick-Schritte statt Fachjargon.
- Er arbeitet auf Deutsch. Die gesamte Oberfläche der App ist deutsch.

## Technik-Regeln (bewusste Entscheidungen – nicht ändern ohne Rücksprache)

- **Eine einzige statische Datei:** Die komplette App lebt in `index.html`
  (HTML + CSS + JavaScript). Kein Framework, kein Build-Schritt, kein npm.
  Supabase wird per CDN-Script eingebunden (`window.supabase`).
- **Design streng nach CMB-Markenkit** (Farben/Schriften siehe DOKUMENTATION.md
  Abschnitt 3). CSS-Token am Anfang des `<style>`-Blocks; Dark Mode über
  `prefers-color-scheme` – neue Farben immer als Token in beiden Modi definieren.
- **Priorität Einfachheit:** keine neuen Abhängigkeiten, keine Komplexität, die
  der Nutzer nicht braucht.
- **Daten:** Supabase-Projekt `aklglucdxeactfkczmtb` (wird mit einem anderen Projekt
  geteilt – Tabellen mit Präfix `cockpit_`). Fremde Tabellen niemals anfassen.

## Arbeitsablauf bei jeder Änderung

1. Code in `index.html` (bzw. `sw.js`, Icons …) ändern.
2. Bei Datenbank-Änderungen: `supabase/schema.sql` aktuell halten (wiederholbar
   ausführbar, Platzhalter statt Geheimnissen) **und** die Änderung im Supabase-
   SQL-Editor ausführen – dafür braucht es den eingeloggten Nutzer (er hilft dir,
   z. B. indem er sich bei supabase.com anmeldet).
3. **`DOKUMENTATION.md` mitpflegen:** betroffene Abschnitte anpassen, neue Zeile
   im Änderungsprotokoll (Abschnitt 9), „Stand:“-Datum oben aktualisieren.
4. Committen (Autor-E-Mail `mail@cmb-seo.com`) und auf `main` pushen –
   GitHub Pages veröffentlicht automatisch (1–2 Min.). Danach die Live-Seite
   prüfen: https://hans6688.github.io/cmb-cockpit/ (Service Worker cached –
   ggf. Cache leeren / hart neu laden).

## Sicherheit – unbedingt beachten

- Das Repository ist **öffentlich**. Niemals committen: Passwörter, service_role-
  Schlüssel, den Geheimcode der Eingangs-Funktion `cockpit_add_note`, private Daten.
- Der `sb_publishable_…`-Schlüssel in `index.html` ist öffentlich-by-design (OK).
- Der Geheimcode des Eingangs existiert nur in der Supabase-Funktion und im
  Apple-Kurzbefehl „Ans Cockpit“ des Nutzers. Bei Bedarf rotieren
  (`create or replace function`), nie aufschreiben.
- Row-Level-Security ist auf allen `cockpit_`-Tabellen aktiv und muss es bleiben.

## Was du ohne den Nutzer NICHT kannst

- Supabase-Dashboard (SQL-Editor, Auth-Einstellungen): braucht seinen Login.
- GitHub-Push: braucht seinen GitHub-Zugang (Konto `Hans6688`).
- Apple-Kurzbefehl ändern: liegt auf seinen Geräten.

Frag ihn in diesen Fällen um Mithilfe und gib ihm einfache Klick-Anweisungen.
