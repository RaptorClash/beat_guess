import 'package:flutter/material.dart';
import 'player_setup_screen.dart';
import 'api_settings_screen.dart';
import '../services/language_service.dart';
import '../controllers/game_controller.dart';
import 'client_waiting_screen.dart';
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              LanguageService.instance.t('choose_language'),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Text("🇩🇪", style: TextStyle(fontSize: 28)),
                  title: const Text(
                    "Deutsch",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () async {
                    await LanguageService.instance.setLanguage('de');
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Text("🇬🇧", style: TextStyle(fontSize: 28)),
                  title: const Text(
                    "English",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.language,
                        color: Colors.deepPurple,
                      ),
                      title: Text(
                        t('language'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _showLanguageDialog(dismissible: true);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.settings_input_component,
                        color: Colors.deepPurple,
                      ),
                      title: Text(
                        t('api_setup'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ApiSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showConnectionMethodMenu() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Wie möchtet ihr spielen?",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.router,
                  color: Colors.deepPurple,
                  size: 36,
                ),
                title: Text(
                  t('network'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(
                  t('same_router'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showHostOrJoinMenu(isBluetooth: false);
                },
              ),
              const Divider(height: 30),
              ListTile(
                leading: const Icon(
                  Icons.bluetooth,
                  color: Colors.blue,
                  size: 36,
                ),
                title: Text(
                  t('offline_bluetooth'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text(
                  t('without_internet'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showHostOrJoinMenu(isBluetooth: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHostOrJoinMenu({required bool isBluetooth}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isBluetooth ? t('bluetooth_party') : t('wlan_party')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBluetooth)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    t('info_bluetooth'),
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ListTile(
                leading: const Icon(
                  Icons.wifi_tethering,
                  color: Colors.deepPurple,
                ),
                title: Text(t('host_game')),
                subtitle: Text(
                  t('open_room_choose_playlist'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showHostSetupDialog(isBluetooth: isBluetooth);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.login, color: Colors.deepPurple),
                title: Text(t('join_game')),
                subtitle: Text(
                  isBluetooth
                      ? t('search_for_near_host')
                      : t('connect_with_host_code'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isBluetooth) {
                    _showBluetoothJoinDialog();
                  } else {
                    _showWlanJoinDialog();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHostSetupDialog({required bool isBluetooth}) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('whats_your_name')),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: t('your_playertag'),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerSetupScreen(
                      isHost: true,
                      hostName: nameController.text.trim(),
                      isBluetooth: isBluetooth,
                    ),
                  ),
                );
              }
            },
            child: Text(t('open_lobby')),
          ),
        ],
      ),
    );
  }

  void _showBluetoothJoinDialog() {
    final nameController = TextEditingController();
    bool isConnecting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(t('search_lobby')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: t('your_playertag'),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  if (isConnecting)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (isConnecting)
                    Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        t('search_nearby_host'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isConnecting ? null : () => Navigator.pop(context),
                  child: Text(t('cancel')),
                ),
                ElevatedButton(
                  onPressed: isConnecting
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) return;
                          setState(() => isConnecting = true);

                          final clientController = GameController();
                          bool success = await clientController
                              .joinAsClientBluetooth(
                                nameController.text.trim(),
                              );

                          if (context.mounted) {
                            setState(() => isConnecting = false);
                            if (success) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClientWaitingScreen(
                                    controller: clientController,
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: Text(t('search_and_join')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showWlanJoinDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    bool isConnecting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(t('join_lobby')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: t('room_code'),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: t('your_gamertag'),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  if (isConnecting)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isConnecting ? null : () => Navigator.pop(context),
                  child: Text(t('cancel')),
                ),
                ElevatedButton(
                  onPressed: isConnecting
                      ? null
                      : () async {
                          if (codeController.text.trim().isEmpty ||
                              nameController.text.trim().isEmpty)
                            return;
                          setState(() => isConnecting = true);

                          final clientController = GameController();
                          bool success = await clientController.joinAsClient(
                            codeController.text.trim(),
                            nameController.text.trim(),
                          );

                          if (context.mounted) {
                            setState(() => isConnecting = false);
                            if (success) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClientWaitingScreen(
                                    controller: clientController,
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: Text(t('join')),
                ),
              ],
            );
          },
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
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 60),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PlayerSetupScreen(isHost: false),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people),
                  label: Text(t('pass_and_play')),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 20),
                  ),
                  onPressed: _showConnectionMethodMenu,
                  icon: const Icon(Icons.sensors),
                  label: Text(t('multiplayer')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
