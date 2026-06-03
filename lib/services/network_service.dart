import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:nearby_connections/nearby_connections.dart';

class NetworkService {
  // === WLAN (TCP) ===
  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];
  Socket? _clientSocket;
  final Map<Socket, String> _socketToName = {};

  // === BLUETOOTH (NEARBY) ===
  bool isBluetooth = false;
  bool _isAdvertising = false;
  final List<String> _nearbyClients = [];
  String? _nearbyHostEndpoint;
  final Map<String, String> _endpointToName = {};

  Function(Map<String, dynamic>)? onStateReceived;
  Function(Map<String, dynamic>)? onActionReceived;
  Function(String playerName)? onPlayerDisconnected;
  VoidCallback? onHostDisconnected;

  bool get isHost => _serverSocket != null || _isAdvertising;
  bool get isClient => _clientSocket != null || _nearbyHostEndpoint != null;

  // ==========================================
  // HOST LOGIK (WLAN & BLUETOOTH)
  // ==========================================
  Future<String?> startHosting({
    required bool bluetooth,
    required String name,
  }) async {
    isBluetooth = bluetooth;
    try {
      if (!isBluetooth) {
        // --- WLAN HOST ---
        final info = NetworkInfo();
        String? ip = await info.getWifiIP();
        if (ip == null) return null;

        _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 4040);
        _serverSocket!.listen((Socket socket) {
          _clients.add(socket);
          socket.listen(
            (data) =>
                _handleIncomingData(data, isHost: true, senderSocket: socket),
            onDone: () => _handleClientDisconnect(socket: socket),
            onError: (e) => _handleClientDisconnect(socket: socket),
          );
        });

        List<String> parts = ip.split('.');
        if (parts.length == 4) return "${parts[2]}.${parts[3]}";
        return ip;
      } else {
        // --- BLUETOOTH HOST ---
        _isAdvertising = true;
        bool advertising = await Nearby().startAdvertising(
          name,
          Strategy.P2P_STAR,
          onConnectionInitiated: (id, info) async {
            // Nimmt jede eintreffende Verbindung automatisch an
            await Nearby().acceptConnection(
              id,
              onPayLoadRecieved: (endId, payload) {
                if (payload.bytes != null) {
                  _handleIncomingData(
                    payload.bytes!.toList(),
                    isHost: true,
                    endpointId: endId,
                  );
                }
              },
            );
          },
          onConnectionResult: (id, status) {
            if (status == Status.CONNECTED) {
              _nearbyClients.add(id);
            }
          },
          onDisconnected: (id) => _handleClientDisconnect(endpointId: id),
        );
        return advertising ? "BLUETOOTH" : null;
      }
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // CLIENT LOGIK (WLAN & BLUETOOTH)
  // ==========================================
  Future<bool> joinGame(String shortCode) async {
    isBluetooth = false;
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
        (data) => _handleIncomingData(data, isHost: false),
        onDone: () => _handleHostDisconnect(),
        onError: (e) => _handleHostDisconnect(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> joinBluetoothGame(String hostId, String myName) async {
    isBluetooth = true;
    bool isConnected = false;
    bool hasResult = false;

    try {
      await Nearby().requestConnection(
        myName,
        hostId,
        onConnectionInitiated: (id, info) async {
          await Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endId, payload) {
              if (payload.bytes != null) {
                _handleIncomingData(payload.bytes!.toList(), isHost: false);
              }
            },
          );
        },
        onConnectionResult: (id, status) {
          hasResult = true;
          if (status == Status.CONNECTED) {
            _nearbyHostEndpoint = id;
            isConnected = true;
          }
        },
        onDisconnected: (id) => _handleHostDisconnect(),
      );

      // Warten, bis die Verbindung bestätigt wurde (max 5 Sekunden)
      for (int i = 0; i < 50; i++) {
        if (hasResult) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return isConnected;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // BLUETOOTH RADAR FUNKTIONEN
  // ==========================================
  // ==========================================
  // BLUETOOTH RADAR FUNKTIONEN
  // ==========================================
  Future<void> startScanning({
    required String myName,
    required Function(String id, String name) onDeviceFound,
    required Function(String id) onDeviceLost,
  }) async {
    await Nearby().startDiscovery(
      myName,
      Strategy.P2P_STAR,
      onEndpointFound: (id, name, serviceId) {
        // NEU: Null-Sicherheits-Check
        if (id != null && name != null) {
          onDeviceFound(id, name);
        }
      },
      onEndpointLost: (id) {
        // NEU: Null-Sicherheits-Check
        if (id != null) {
          onDeviceLost(id);
        }
      },
    );
  }

  void stopScanning() {
    Nearby().stopDiscovery();
  }

  // ==========================================
  // GEMEINSAME LOGIK (SENDEN & EMPFANGEN)
  // ==========================================
  void broadcastState(Map<String, dynamic> state) {
    String message = jsonEncode(state) + '\n';
    if (!isBluetooth) {
      if (_serverSocket == null) return;
      for (var client in _clients) {
        client.write(message);
      }
    } else {
      Uint8List bytes = Uint8List.fromList(utf8.encode(message));
      for (var id in _nearbyClients) {
        Nearby().sendBytesPayload(id, bytes);
      }
    }
  }

  void sendAction(Map<String, dynamic> action) {
    String message = jsonEncode(action) + '\n';
    if (!isBluetooth) {
      if (_clientSocket == null) return;
      _clientSocket!.write(message);
    } else {
      if (_nearbyHostEndpoint == null) return;
      Nearby().sendBytesPayload(
        _nearbyHostEndpoint!,
        Uint8List.fromList(utf8.encode(message)),
      );
    }
  }

  void _handleIncomingData(
    List<int> data, {
    required bool isHost,
    Socket? senderSocket,
    String? endpointId,
  }) {
    try {
      String message = utf8.decode(data);
      for (var line in message.split('\n')) {
        if (line.trim().isNotEmpty) {
          var json = jsonDecode(line);

          if (isHost && json['type'] == 'JOIN') {
            if (!isBluetooth && senderSocket != null) {
              _socketToName[senderSocket] = json['name'];
            } else if (isBluetooth && endpointId != null) {
              _endpointToName[endpointId] = json['name'];
            }
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

  void _handleClientDisconnect({Socket? socket, String? endpointId}) {
    if (!isBluetooth && socket != null) {
      _clients.remove(socket);
      String? name = _socketToName[socket];
      if (name != null) {
        _socketToName.remove(socket);
        onPlayerDisconnected?.call(name);
      }
      socket.close();
    } else if (isBluetooth && endpointId != null) {
      _nearbyClients.remove(endpointId);
      String? name = _endpointToName[endpointId];
      if (name != null) {
        _endpointToName.remove(endpointId);
        onPlayerDisconnected?.call(name);
      }
    }
  }

  void _handleHostDisconnect() {
    onHostDisconnected?.call();
    closeConnections();
  }

  void closeConnections() {
    _serverSocket?.close();
    _clientSocket?.close();
    for (var c in _clients) c.close();
    _clients.clear();
    _socketToName.clear();

    if (isBluetooth) {
      Nearby().stopAdvertising();
      Nearby().stopDiscovery();
      Nearby().stopAllEndpoints();
      _nearbyClients.clear();
      _endpointToName.clear();
      _nearbyHostEndpoint = null;
      _isAdvertising = false;
    }
  }
}
