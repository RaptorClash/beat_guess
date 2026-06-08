import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._internal();
  LanguageService._internal();

  String _currentLanguage = 'de';
  bool _isFirstStart = false;

  String get currentLanguage => _currentLanguage;
  bool get isFirstStart => _isFirstStart;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('app_language')) {
      _isFirstStart = true;
      _currentLanguage = 'de'; // Standard-Fallback
    } else {
      _currentLanguage = prefs.getString('app_language')!;
    }
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    _isFirstStart = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
    notifyListeners();
  }

  static const Map<String, Map<String, String>> _dict = {
    'de': {
      'app_title': 'BeatGuess',
      'pass_and_play': 'Pass & Play (1 Handy)',
      'wlan_party': 'WLAN Party (Mehrere Handys)',
      'coming_soon': 'Kommt bald!',
      'language': 'Spracheinstellungen',
      'api_setup': 'Spotify API Setup',
      'choose_language': 'Wähle deine Sprache',

      //player_setup_screen.dart
      'whos_in': 'Wer spielt mit?',
      'no_players_added':
          'Noch keine Spieler hinzugefügt.\n(Startest du jetzt, spielst du alleine!)',
      'game_rules': 'Spielregeln',
      'points_to_win': 'Punkte zum Sieg:',
      'cards': 'Karten',
      'player_name': 'Spielername',
      'game_mode': 'Spielmodus',
      'first_one_wins': 'Bis der Erste gewinnt',
      'everyone_done': 'Bis alle fertig sind',
      'playlist': 'Playlist:',
      'insert_spotify_link': 'Spotify Playlist-Link einfügen',
      'playlist_library': 'Playlist Bibliothek:',
      'start_game': 'SPIEL STARTEN',
      'error_loading_player_setup_screen':
          'Fehler beim laden der player_setup_screen.dart',
      'username_already_exists': "Dieser Spielername existiert bereits!",
      'error_adding_player': "Fehler beim hinzufügen eines Spielers",
      'solo_player': "Solo-Spieler",
      'error_starting_game': "Fehler beim starten des Spiels.",
      'new_game': "Neues Spiel",

      //api_settings_screen.dart
      'error_loading_api_settings_screens':
          "Fehler beim laden der api_settings_screen.dart",
      'enterClientAndSecret': "Bitte Client ID UND Secret eingeben!",
      'error_cannot_open_browser': "Fehler: Konnte den Browser nicht öffnen!",
      'error_login_spotify': "Fehler beima einloggen mit Spotify",
      'logout_spotify':
          "Abgemeldet! Du kannst dich jetzt mit einem anderen Account einloggen.",
      'error_logout_spotify': "Fehler beim ausloggen mit Spotify",
      'copy_to_clipboard': "In die Zwischenablage kopiert!",
      'set_up_link': "Verknüpfung einrichten",
      'create_developer_app':
          "Erstelle eine eigene Entwickler-App im Spotify Dashboard.",
      'api_tutorial_step1': "Zum Spotify Dasboard",
      'api_tutorial_step2':
          "Gehe zu 'User Management' und füge deinen Namen sowie die E-Mail-Adresse deines Spotify-Accounts hinzu.",
      'api_tutorial_step3':
          "Fülle die 'Basic Information' aus (z.B. App Name und Beschreibung).",
      'api_tutorial_step4':
          "Trage unter 'Redirect URIs' die folgenden Links exakt so ein (du kannst beide eintragen):",
      'api_tutorial_step5':
          "Kopiere die 'Client ID' und das 'Client Secret' aus dem Dashboard und füge sie hier unten ein.",
      'spotify_client_id': "Spotify Client ID",
      'spotify_client_secret': "Spotify Client Secret",
      'connected_to_spotify': "VERBUNDEN (Klick zum Erneuern)",
      'signin_with_spotify': "MIT SPOTIFY EINLOGGEN",
      'signout_spotify': "Von Spotify abmelden",

      //game_screen.dart
      'playlist_couuld_not_loaded':
          "Playlist konnte nicht geladen werden. Nutze Standard-Songs.",
      'error_initializing_game_screen':
          "Fehler beim initialisieren der game_screen.dart",
      'error_closing': "Fehler beim beenden",
      'mistake_on_next_move': "Fehler beim nächsten Zug machen.",
      'error_placing_card': "Fehler beim Karten platzieren",
      'won': "GEWINNT!",
      'win_all_finish':
          'Alle Spieler haben {cards} Karten gesammelt!\n{winner} war am schnellsten.',
      'win_first': '{winner} hat als Erstes {cards} Karten gesammelt!',
      'rankings': 'Rangliste',
      'main_menu': "Hauptmenü",
      'error_displaying_victory_screen':
          "Fehler beim anzeigen des Siegesbildschirms",
      'error_displaying_snackbar': "Fehler beim anzeigen der Snackbar.",
      'drag_card_to_right_spot': "Zieh die Karte an die richtige Stelle!",
      'loading_audio': "Lade Audio...",
      'song_playing': "Song wird abgespielt...",
      'play_song': "Song abspielen (30s)",
      'points': "Punkte",

      //game_controller.dart:
      'error_initializing _game': "Fehler beim Initialisieren des Spiels",
      'error_playing_next_song': "Fehler beim nächsten Song abspielen",
      'error_check_ig_game_ended':
          "Fehler beim Nachschauen, ob das Spiel zu ende ist.",
      'error_next_player_turn': "Fehler nächster Spieler am Zug.",
      'error_adding_song': "Fehler beim eintragen des Songs",
      'error_playing_music': "Fehler beim abspielen der Musik",
      'error_opening_leaderboard': "Fehler beim öffnen der Rangliste",
      'cant_create_lobby': 'Konnte Lobby nicht erstellen',
      'no_host_found': 'Keinen Host in der Nähe gefunden',
      'error_wlan_connection': 'WLAN Verbindung fehlgeschlagen',
      'error_init': 'Fehler beim Initialisieren',

      //music_service.dart
      'error_no_active_device_found':
          "FEHLER: Kein aktives Gerät gefunden! Bitte Spotify kurz am PC/Handy antippen.",
      'error_during_spotify_playback':
          "FEHLER bei Spotify Playback: Code {statusCode}",
      'error_in_musicservice': "Fehler im MusicService: {error}",
      'error_while_playing_song': "Fehler beim abspielen eines Songtitels",
      'token_expired': "Token abgelaufen, bitte neu einloggen.",
      'error_stopping_music': "Fehler beim stoppen der Musik",

      //playlist_service.dart
      'unknown_title': "Unbekannter Titel",
      'unknown_artist': "Unbekannter Künstler",
      'error_parsing_song': "Fehler beim parsen eines Songs: {error}",
      'loading_next_page':
          "LOG: Lade nächste Seite... (Bisher {totalsongs} Songs geladen)",
      'all_songs_loaded': "--- ERFOLG: ALLE {totalsongs} Songs geladen ---",
      'error_rading_spotify_playlist':
          "Fehler beim auslesen der Spotifyplaylist",
      'error_saving_playlist': "Fehler beim Speichern der Playlist",
      'unknown_playlist': "Unbekannte Playlist",
      'error_retrieving_playlist_details':
          "Fehler beim Abrufen der Playlist-Details: {error}",
      'my_playlist': "Eigene Playlist",
      'error_deleting_playlist': "Fehler beim Löschen der Playlist",

      //spotify_auth_service.dart
      'error_client_or_secret_missing':
          "FEHLER: Client ID oder Secret fehlen in den SharedPreferences!",
      'send_token_request_to_spotify': "Sende Token-Anfrage an Spotify...",
      'spotify_token_saved': "Spotify Token wurde gespeichert!",
      'error_spotify_server': "Fehler vom Spotify-Server: Code {error}",
      'error_processing_login': "Fehler beim Verarbeiten des Logins: {error}",
      'erro_updating_login': "Fehler beim aktualisieren des Logins",
      'error_updating_refresh_token':
          "Fehler beim aktualisieren des Refresh Tokens",

      //language_service.dart
      'total': "Gesamt",
      'remaining': "Übrig",
      'error': "Fehler",

      //player_switch_dialog.dart
      'pass_device_to': "Gerät weitergeben an:",
      'im_ready': "Bin bereit!",

      //song_card.dart
      'what_year_is_song_from': "In welches Jahr gehört dieser Song?",

      //timeline_slot.dart
      'drop_here': "HIER LOSLASSEN",
      'insert_here': "+ Hier einfügen +",

      //player_queue_list.dart
      'next_move': "Am Zug:",

      // Dialoge
      'warning': 'Achtung!',
      'exit_setup_warning':
          'Willst du wirklich zurück? Deine Einstellungen für das Spiel gehen verloren.',
      'exit_game_warning':
          'Willst du das Spiel wirklich abbrechen? Der aktuelle Fortschritt geht verloren.',
      'cancel': 'Abbrechen',
      'yes_leave': 'Ja, verlassen',

      //update_service.dart
      'error_github_update_check': "Fehler beim GitHub Update-Check: {error}",
      'download_update':
          '\n\nDas Update wird im Browser heruntergeladen. Bitte schließe die App vor der Installation.',
      'newVersionAvailable_iOS':
          "Eine neue Version ist auf GitHub verfügbar. Unter iOS musst du Updates manuell über deinen Bereitstellungsweg beziehen.",
      'downloadLatestVersion':
          "Möchtest du die neueste Version jetzt herunterladen und installieren?",
      'close': "Schließen",
      'later': "Später",
      'update': "Aktualisieren",
      'error_android_update': "Fehler beim Android-Update: {error}",
      'unable_open_url': "Konnte URL nicht öffnen:",

      // start_screen.dart
      'multiplayer': 'Multiplayer',
      'network': 'Im eigenen Netzwerk',
      'same_router': 'Alle Spieler sind mit demselben Router verbunden.',
      'offline_bluetooth': 'Offline / Bluetooth',
      'without_internet': 'Unterwegs spielen, ganz ohne Internet oder Router.',
      'bluetooth_party': 'Bluetooth Party',
      'info_bluetooth':
          'Info: Stellt sicher, dass Bluetooth & Standort an euren Geräten aktiviert sind!',
      'host_game': 'Spiel hosten',
      'open_room_choose_playlist':
          'Du wählst die Playlist und eröffnest den Raum',
      'join_game': 'Spiel beitreten',
      'search_for_near_host': 'Suche nach einem Host in der Nähe',
      'connect_with_host_code': 'Verbinde dich mit dem Code des Hosts',
      'whats_your_name': 'Wie heißt du?',
      'your_playertag': 'Dein Spielername',
      'open_lobby': 'Lobby eröffnen',
      'search_lobby': 'Suche Lobby...',
      'search_nearby_host':
          'Suche nach Host in der Nähe... (kann etwas dauern)',
      'search_and_join': 'Suchen & Beitreten',
      'join_lobby': 'Lobby beitreten',
      'room_code': 'Raum-Code',
      'join': 'Beitreten',
    },
    'en': {
      'app_title': 'BeatGuess',
      'pass_and_play': 'Pass & Play (1 Device)',
      'coming_soon': 'Coming soon!',
      'language': 'Language Settings',
      'api_setup': 'Spotify API Setup',
      'choose_language': 'Choose your language',

      //player_setup_screen.dart
      'whos_in': "Who's in?",
      'no_players_added':
          "No players have been added yet.\n(If you start now, you'll be playing alone!)",
      'game_rules': "Rules of the Game",
      'points_to_win': "Points for the win:",
      'cards': "cards",
      'player_name': "Player name",
      'game_mode': "Game Mode",
      'first_one_wins': "Until the first one wins",
      'everyone_done': "Until everyone is done",
      'playlist': "Playlist:",
      'insert_spotify_link': "Insert Spotify playlist link",
      'playlist_library': "Playlist Library:",
      "start_game": "START THE GAME",
      'error_loading_player_setup_screen':
          'Error loading player_setup_screen.dart',
      'username_already_exists': 'This username already exists!',
      'error_adding_player': "Error adding a player",
      'solo_player': "Solo players",
      'error_starting_game': "Error starting the game.",
      'new_game': "New Game",
      'playlist_error': 'Playlist Fehler',
      'bluetooth_radar_active': 'Bluetooth Radar aktiv 📡',
      'code_for_friends': 'Raum-Code für Freunde:',
      'friends_can_join': 'Freunde können nun beitreten!',

      //api_settings_screen.dart
      'error_loading_api_settings_screens':
          "Error loading api_settings_screen.dart",
      'enterClientAndSecret': "Please enter your Client ID AND Secret!",
      'error_cannot_open_browser': "Error: Unable to open the browser!",
      'error_login_spotify': "Error logging in with Spotify",
      'logout_spotify':
          "Logged out! You can now log in with a different account.",
      'error_logout_spotify': "Error logging out with Spotify",
      'copy_to_clipboard': "Copied to clipboard!",
      'set_up_link': "Set up link",
      'create_developer_app':
          "Create your own developer app in the Spotify Dashboard.",
      'api_tutorial_step1': "Go to the Spotify Dashboard",
      'api_tutorial_step2':
          "Go to 'User Management' and add your name and the email address of your Spotify account.",
      'api_tutorial_step3':
          "Fill out the 'Basic Information' (e.g., app name and description).",
      'api_tutorial_step4':
          "Under 'Redirect URIs', enter the following links exactly as shown (you can enter both):",
      'api_tutorial_step5':
          "Copy the 'Client ID' and 'Client Secret' from the Dashboard and paste them below.",
      'spotify_client_id': "Spotify Client ID",
      'spotify_client_secret': "Spotify Client Secret",
      'connected_to_spotify': "CONNECTED (Click to Refresh)",
      'signin_with_spotify': "SIGN IN WITH SPOTIFY",
      'signout_spotify': "Sign out of Spotify",

      //game_screen.dart
      'playlist_could_not_be_loaded':
          "Could not load the playlist. Use default songs.",
      'error_initializing_game_screen': "Error initializing game_screen.dart",
      'error_closing': "Error closing",
      'mistake_on_next_move': "Mistake on next move.",
      'error_placing_card': "Error placing cards",
      'won': "WON!",
      'win_all_finish':
          'All players have collected {cards} cards!\n{winner} was the fastest.',
      'win_first': '{winner} was the first to collect {cards} cards!',
      'rankings': 'Leaderboard',
      'main_menu': "Main Menu",
      'error_displaying_victory_screen': "Error displaying the victory screen",
      'error_displaying_snackbar': "Error displaying the snackbar.",
      'drag_card_to_right_spot': "Drag the card to the right spot!",
      'loading_audio': "Loading audio...",
      'song_playing': "Song playing...",
      'play_song': "Play song (30s)",
      'points': 'Points',

      //game_controller.dart
      'error_initializing_game': "Error initializing the game",
      'error_playing_next_song': "Error playing the next song",
      'error_check_ig_game_ended': "Error checking if the game has ended.",
      'error_next_player_turn': "Error: Next player's turn.",
      'error_adding_song': "Error adding song",
      'error_playing_music': "Error playing music",
      'error_opening_leaderboard': "Error opening leaderboard",

      //music_service.dart
      'error_no_active_device_found':
          "ERROR: No active device found! Please tap Spotify briefly on your PC or phone.",
      'error_during_spotify_playback':
          "ERROR during Spotify playback: Code {statusCode}",
      'error_in_musicservice': "Error in MusicService: {error}",
      'error_while_playing_song': "Error while playing a song",
      'token_expired': "Token expired, please log in again.",
      'error_stopping_music': "Error while stopping the music",

      //playlist_service.dart
      'unknown_title': "Unknown title",
      'unknown_artist': "Unknown artist",
      'error_parsing_song': "Error parsing a song: {error}",
      'loading_next_page':
          "LOG: Loading next page... ({totalsongs} songs loaded so far)",
      'all_songs_loaded': "-- - SUCCESS: ALL {totalsongs} songs loaded ---",
      'error_reading_spotify_playlist': "Error reading the Spotify playlist",
      'error_saving_playlist': "Error saving the playlist",
      'unknown_playlist': "Unknown playlist",
      'error_retrieving_playlist_details':
          "Error retrieving playlist details: {error}",
      'my_playlist': "My playlist",
      'error_deleting_playlist': "Error deleting the playlist",

      //spotify_auth_service.dart
      'error_client_or_secret_missing':
          "ERROR: Client ID or secret is missing from SharedPreferences!",
      'send_token_request_to_spotify': "Sending token request to Spotify...",
      'spotify_token_saved': "Spotify token saved!",
      'error_spotify_server': "Error from the Spotify server: Code {error}",
      'error_processing_login': "Error processing login: {error}",
      'error_updating_login': "Error updating the login",
      'error_updating_refresh_token': "Error updating the refresh token",

      //language_service.dart
      'total': "Total",
      'remaining': "Remaining",
      'error': "Error",

      //player_switch_dialog.dart
      'pass_device_to': "Pass device to:",
      'im_ready': "I'm ready!",

      //song_card.dart
      'what_year_is_song_from': "What year is this song from?",

      //timeline_slot.dart
      'drop_here': "DROP HERE",
      'insert_here': "+ Insert here +",

      //player_queue_list.dart
      'next_move': "Next move:",

      // Dialoge
      'warning': 'Warning!',
      'exit_setup_warning':
          'Do you really want to go back? Your game settings will be lost.',
      'exit_game_warning':
          'Do you really want to quit the game? Your current progress will be lost.',
      'cancel': 'Cancel',
      'yes_leave': 'Yes, leave',

      // update_service.dart
      'error_github_update_check': 'Error checking for GitHub updates: {error}',
      'download_update':
          '\n\nThe update is being downloaded in the browser. Please close the app before installing.',
      'newVersionAvailable_iOS':
          'A new version is available on GitHub. On iOS, you must manually retrieve updates via your distribution channel.',
      'downloadLatestVersion':
          'Would you like to download and install the latest version now?',
      'close': 'Close',
      'later': 'Later',
      'update': 'Update',
      'error_android_update': 'Android update error: {error}',
      'unable_open_url': 'Could not open URL:',
    },
  };

  String t(String key, [Map<String, String>? args]) {
    // 1. Text aus dem Wörterbuch holen
    String text = _dict[_currentLanguage]?[key] ?? _dict['en']?[key] ?? key;

    if (args != null) {
      args.forEach((placeholder, value) {
        text = text.replaceAll('{$placeholder}', value);
      });
    }

    return text;
  }
}

// Die globale Funktion ganz unten ersetzen:
String t(String key, [Map<String, String>? args]) =>
    LanguageService.instance.t(key, args);
