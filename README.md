# 🎧 BeatGuess

**BeatGuess** ist ein in Flutter programmierter Musik-Quiz-Klon, inspiriert vom beliebten Brettspiel "Hitster". Spieler hören sich Song-Ausschnitte über Spotify an und müssen erraten, in welches Jahr der Song gehört, um so ihren eigenen chronologischen Zeitstrahl aufzubauen.

🤖 **Transparenz-Hinweis:** *Dieses Projekt wurde zu großen Teilen mit KI "vibe-coded". Der Code entstand in Zusammenarbeit mit Künstlicher Intelligenz, um Ideen schnell zum Leben zu erwecken, State-Management zu strukturieren und das UI/UX-Design iterativ aufzubauen.*

---

## ✨ Features

* **Pass & Play Multiplayer:** Spiele mit deinen Freunden an einem einzigen Gerät.
* **Spotify Integration:** Spiele echte Song-Ausschnitte (30 Sekunden) direkt über die Spotify API ab.
* **Eigene Playlists:** Füge beliebige öffentliche Spotify-Playlists über ihren Link ein, um dein eigenes Musik-Thema zu spielen.
* **Anpassbare Regeln:** Wähle selbst, wie viele Karten (Punkte) zum Sieg benötigt werden.
* **Cross-Platform:** Unterstützt Mobile (iOS/Android) und Web-Builds.

---

## 🛠 Voraussetzungen

Um dieses Projekt lokal auszuführen oder weiterzuentwickeln, benötigst du:

1. **[Flutter SDK](https://docs.flutter.dev/get-started/install)** installiert.
2. Einen **Spotify Account** mit **Spotify Premium**.
3. Eine eigene **Spotify Developer App** (siehe Setup).

---

## 🚀 Setup & Installation (Tutorial)

### 1. Repository klonen
Klone das Repository auf deinen lokalen Rechner und installiere die Abhängigkeiten:
```bash
git clone https://github.com/raptorclash/beat_guess.git
cd beat_guess
flutter pub get
```

### 2. Spotify API einrichten 
Damit die App Musik abspielen und Playlists laden kann, musst du deine eigene Spotify Developer App erstellen. Die App speichert deine Zugangsdaten lokal und sicher auf deinem Gerät.

1. Gehe zum Spotify Developer Dashboard und logge dich ein.
2. Klicke auf "Create App".
3. Fülle die `Basic Information` aus (`App name`, `App description`).
4. Füge unter `Redirect URIs` zwingend folgende zwei Links ein:
   - http://127.0.0.1:8080/ (Für Web-Testing)
   - beatguess://callback (Für Mobile)
5. Füge unter `User Management` deinen eigenen Namen und die E-Mail deines Spotify-Accounts hinzu, um die App im Development-Modus nutzen zu können.
6. Speichere die App ab und kopiere dir die `Client ID` und das `Client Secret`.

### 3. App starten
Starte die App auf deinem gewünschten Emulator oder Gerät
```bash
flutter run -d chrome --web-port 8080
```
---
## 🎮 Wie man spielt
1. Spieler & Einstellungen: Starte die App, klicke auf "Pass & Play" und trage die Spielernamen ein.

2. API Verknüpfen: Klicke oben rechts auf das Zahnrad ⚙️ und trage deine Client ID und dein Client Secret ein. Klicke auf Login, um BeatGuess mit deinem Spotify-Account zu verknüpfen.

3. Playlist wählen: Wähle deine eigene Playlist. Du musst die Playlist entweder selber erstellt haben oder Mitwirkender der Playlist sein, damit diese abgespielt werden kann.

4. Starte einmal Spotify und spiele ein Lied ab, damit die App im Hintergrund offen ist.

5. Das Spiel:
   - Es ist abwechselnd der aufgerufene Spieler dran.
   - Klicke auf "Song abspielen".
   - Ziehe die verdeckte Karte an die korrekte Stelle in deiner Timeline (vor, hinter oder zwischen deine bereits gesammelten Karten).
   - Bei einer richtigen Antwort behältst du die Karte. Liegst du falsch, wird sie abgelegt und der Nächste ist dran.
   - Wer zuerst die vereinbarte Menge an Karten sammelt, gewinnt!

---

## 📂 Projektstruktur
- models/ - Datenmodelle
- screens/ - Die Benutzeroberflächen
- services/ - Logik für API-Calls und Spotify-Playback
- widgets/ - Wiederverwendbare UI-Komponenten

> [!NOTE]
> Projekt ist Vibe-Coded mit Google Gemini