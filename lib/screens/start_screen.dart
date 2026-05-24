import 'package:flutter/material.dart';
import 'player_setup_screen.dart';
import 'api_settings_screen.dart';
import '../services/language_service.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (LanguageService.instance.isFirstStart) {
        _showLanguageDialog(dismissible: false);
      }
    });
  }

  void _showLanguageDialog({required bool dismissible}) {
    showDialog(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) {
        return PopScope(
          canPop: dismissible,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(LanguageService.instance.t('choose_language'), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Text("🇩🇪", style: TextStyle(fontSize: 28)),
                  title: const Text("Deutsch", style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    await LanguageService.instance.setLanguage('de');
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Text("🇬🇧", style: TextStyle(fontSize: 28)),
                  title: const Text("English", style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    await LanguageService.instance.setLanguage('en');
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListenableBuilder(
          listenable: LanguageService.instance,
          builder: (context, _) {
            final t = LanguageService.instance.t;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.language, color: Colors.deepPurple),
                      title: Text(t('language'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _showLanguageDialog(dismissible: true);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_input_component, color: Colors.deepPurple),
                      title: Text(t('api_setup'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ApiSettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final t = LanguageService.instance.t;

        return Scaffold(
          backgroundColor: Colors.deepPurple,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                onPressed: _showSettingsMenu,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.headphones, size: 100, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  t('app_title'),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 60),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayerSetupScreen()));
                  },
                  icon: const Icon(Icons.people),
                  label: Text(t('pass_and_play')),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('coming_soon'))));
                  },
                  icon: const Icon(Icons.wifi),
                  label: Text(t('wlan_party')),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}