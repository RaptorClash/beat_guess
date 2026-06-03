import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];
  Socket? _clientSocket;

  final Map<Socket, String> _socketToName = {};

  Function(Map<String, dynamic>)? onStateReceived;
  Function(Map<String, dynamic>)? onActionReceived;

  Function(String playerName)? onPlayerDisconnected;
  VoidCallback? onHostDisconnected;

  bool get isHost => _serverSocket != null;
  bool get isClient => _clientSocket != null;

  Future<String?> startHosting() async {
    try {
      final info = NetworkInfo();
      String? ip = await info.getWifiIP();
      if (ip == null) return null;

      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 4040);
      _serverSocket!.listen((Socket socket) {
        _clients.add(socket);

        socket.listen(
          (data) {
            _handleIncomingData(data, isHost: true, sender: socket);
          },
          onDone: () => _handleClientDisconnect(socket),
          onError: (e) => _handleClientDisconnect(socket),
        );
      });

      List<String> parts = ip.split('.');
      if (parts.length == 4) {
        return "${parts[2]}.${parts[3]}";
      }
      return ip;
    } catch (e) {
      return null;
    }
  }

  void _handleClientDisconnect(Socket socket) {
    _clients.remove(socket);
    String? name = _socketToName[socket];
    if (name != null) {
      _socketToName.remove(socket);
      onPlayerDisconnected?.call(name);
    }
    socket.close();
  }

  void broadcastState(Map<String, dynamic> state) {
    if (_serverSocket == null) return;
    String message = jsonEncode(state) + '\n';
    for (var client in _clients) {
      client.write(message);
    }
  }

  Future<bool> joinGame(String shortCode) async {
    try {
      final info = NetworkInfo();
      String? myIp = await info.getWifiIP();
      if (myIp == null) return false;

      List<String> parts = myIp.split('.');
      String hostIp = "${parts[0]}.${parts[1]}.$shortCode";

      _clientSocket = await Socket.connect(
        hostIp,
        4040,
        timeout: const Duration(seconds: 5),
      );
      _clientSocket!.listen(
        (data) {
          _handleIncomingData(data, isHost: false);
        },
        onDone: () => _handleHostDisconnect(),
        onError: (e) => _handleHostDisconnect(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void _handleHostDisconnect() {
    onHostDisconnected?.call();
    closeConnections();
  }

  void sendAction(Map<String, dynamic> action) {
    if (_clientSocket == null) return;
    String message = jsonEncode(action) + '\n';
    _clientSocket!.write(message);
  }

  void _handleIncomingData(
    List<int> data, {
    required bool isHost,
    Socket? sender,
  }) {
    try {
      String message = utf8.decode(data);
      for (var line in message.split('\n')) {
        if (line.trim().isNotEmpty) {
          var json = jsonDecode(line);

          if (isHost && json['type'] == 'JOIN' && sender != null) {
            _socketToName[sender] = json['name'];
          }

          if (isHost) {
            onActionReceived?.call(json);
          } else {
            onStateReceived?.call(json);
          }
        }
      }
    } catch (e) {
      print("Netzwerkfehler: $e");
    }
  }

  void closeConnections() {
    _serverSocket?.close();
    _clientSocket?.close();
    for (var c in _clients) {
      c.close();
    }
    _clients.clear();
    _socketToName.clear();
  }
}
