# CMB Projekt-Cockpit

Persönliches Kundenprojekt-Dashboard von CMB Digital: Projekt-Kacheln mit Status,
To-dos, Notizen, Google-Drive-Verknüpfungen und Transkripten – im CMB-Markendesign
(Petrol, Orange-Gradient, Instrument Serif / Inter).

**Live:** https://hans6688.github.io/cmb-cockpit/

**➜ Ausführliche Dokumentation aller Funktionen, der Architektur und des Datenmodells:
[DOKUMENTATION.md](DOKUMENTATION.md)** (wird bei jeder Änderung mitgepflegt, inkl. Änderungsprotokoll)

## Wie es funktioniert

- **Oberfläche:** eine einzige statische Seite (`index.html`), gehostet kostenlos über GitHub Pages.
- **Daten:** liegen zentral in Supabase (Projekt „content-pipeline“, Tabelle `cockpit_projects`) –
  dadurch ist der Stand auf allen Geräten gleich.
- **Login:** E-Mail + Passwort über Supabase Auth. Row-Level-Security stellt sicher,
  dass jeder Nutzer nur seine eigenen Projekte sieht.
- **App-Gefühl:** Dank Manifest + Service Worker lässt sich das Cockpit auf dem
  Handy „zum Home-Bildschirm hinzufügen“ und startet dann wie eine App.

## Einmalige Einrichtung

1. **Datenbank:** Inhalt von [`supabase/schema.sql`](supabase/schema.sql) im
   Supabase SQL-Editor ausführen (einmalig).
2. **Konto:** Auf der Live-Seite „Konto anlegen“ wählen, E-Mail + Passwort eintragen,
   Bestätigungslink in der E-Mail anklicken, anmelden.
3. **Aufs Handy:** Seite in Safari/Chrome öffnen → Teilen → „Zum Home-Bildschirm“.

## Sicherheit

In `index.html` steht nur der **öffentliche** Supabase-Schlüssel (`sb_publishable_…`) –
der ist dafür gemacht, im Browser zu liegen. Der Datenzugriff wird von den
Row-Level-Security-Regeln in der Datenbank geschützt. Geheime Schlüssel
(service_role) gehören niemals in dieses Repository.
