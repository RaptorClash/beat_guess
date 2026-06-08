import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

enum ConnectionType { wifi, bluetooth }

class NetworkService {
  ConnectionType currentType = ConnectionType.wifi;

  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];
  Socket? _clientSocket;
  final Map<Socket, String> _socketToName = {};

  final Strategy strategy = Strategy.P2P_STAR;
  bool _isNearbyAdvertising = false;
  final List<String> _nearbyClients = [];
  String? _nearbyHostId;
  final Map<String, String> _nearbyIdToName = {};

  Function(Map<String, dynamic>)? onStateReceived;
  Function(Map<String, dynamic>)? onActionReceived;
  Function(String playerName)? onPlayerDisconnected;
  VoidCallback? onHostDisconnected;

  bool get isHost => _serverSocket != null || _isNearbyAdvertising;
  bool get isClient => _clientSocket != null || _nearbyHostId != null;
  bool get isClientBluetooth =>
      currentType == ConnectionType.bluetooth && isClient;

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.location,
        Permission.bluetooth,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.nearbyWifiDevices,
      ].request();

      var location = await Permission.location.status;
      var btConnect = await Permission.bluetoothConnect.status;

      return location.isGranted || btConnect.isGranted;
    }
    return true;
  }

  Future<String?> startHosting({String? name}) async {
    currentType = ConnectionType.wifi;
    try {
      final info = NetworkInfo();
      String? ip = await info.getWifiIP();
      if (ip == null) return null;

      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 4040);
      _serverSocket!.listen((Socket socket) {
        _clients.add(socket);
        socket.listen(
          (data) {
            String message = utf8.decode(data);
            _processMessageString(
              message,
              isHost: true,
              senderIdOrSocket: socket,
            );
          },
          onDone: () => _handleClientDisconnect(socket),
          onError: (e) => _handleClientDisconnect(socket),
        );
      });

      List<String> parts = ip.split('.');
      if (parts.length == 4) return "${parts[2]}.${parts[3]}";
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

  Future<String?> startHostingBluetooth(String name) async {
    currentType = ConnectionType.bluetooth;
    bool hasPerms = await requestPermissions();
    if (!hasPerms) return null;

    try {
      bool success = await Nearby().startAdvertising(
        name,
        strategy,
        onConnectionInitiated: (id, info) async {
          await Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endId, payload) {
              if (payload.type == PayloadType.BYTES) {
                String message = utf8.decode(payload.bytes!);
                _processMessageString(
                  message,
                  isHost: true,
                  senderIdOrSocket: endId,
                );
              }
            },
          );
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) _nearbyClients.add(id);
        },
        onDisconnected: (id) {
          _nearbyClients.remove(id);
          String? pName = _nearbyIdToName[id];
          if (pName != null) {
            _nearbyIdToName.remove(id);
            onPlayerDisconnected?.call(pName);
          }
        },
      );

      if (success) {
        _isNearbyAdvertising = true;
        return "BLUETOOTH_LOBBY";
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> joinGame(String shortCode) async {
    currentType = ConnectionType.wifi;
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
          String message = utf8.decode(data);
          _processMessageString(message, isHost: false, senderIdOrSocket: null);
        },
        onDone: () => _handleHostDisconnect(),
        onError: (e) => _handleHostDisconnect(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> joinBluetoothGame(String clientName) async {
    currentType = ConnectionType.bluetooth;
    bool hasPerms = await requestPermissions();
    if (!hasPerms) return false;

    Completer<bool> completer = Completer<bool>();

    try {
      await Nearby().startDiscovery(
        clientName,
        strategy,
        onEndpointFound: (id, name, serviceId) async {
          await Nearby().stopDiscovery();
          await Nearby().requestConnection(
            clientName,
            id,
            onConnectionInitiated: (endId, info) async {
              await Nearby().acceptConnection(
                endId,
                onPayLoadRecieved: (endId, payload) {
                  if (payload.type == PayloadType.BYTES) {
                    String message = utf8.decode(payload.bytes!);
                    _processMessageString(
                      message,
                      isHost: false,
                      senderIdOrSocket: null,
                    );
                  }
                },
              );
            },
            onConnectionResult: (endId, status) {
              if (status == Status.CONNECTED) {
                _nearbyHostId = endId;
                if (!completer.isCompleted) completer.complete(true);
              } else {
                if (!completer.isCompleted) completer.complete(false);
              }
            },
            onDisconnected: (endId) {
              _nearbyHostId = null;
              _handleHostDisconnect();
            },
          );
        },
        onEndpointLost: (id) {},
      );

      Future.delayed(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          Nearby().stopDiscovery();
          completer.complete(false);
        }
      });
    } catch (e) {
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future;
  }

  void _processMessageString(
    String message, {
    required bool isHost,
    dynamic senderIdOrSocket,
  }) {
    try {
      for (var line in message.split('\n')) {
        if (line.trim().isNotEmpty) {
          var json = jsonDecode(line);

          if (isHost && json['type'] == 'JOIN' && senderIdOrSocket != null) {
            if (senderIdOrSocket is Socket) {
              _socketToName[senderIdOrSocket] = json['name'];
            } else {
              _nearbyIdToName[senderIdOrSocket] = json['name'];
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
      print("JSON Parse Fehler: $e");
    }
  }

  void _handleHostDisconnect() {
    onHostDisconnected?.call();
    closeConnections();
  }

  void broadcastState(Map<String, dynamic> state) {
    String message = jsonEncode(state) + '\n';
    if (currentType == ConnectionType.wifi && _serverSocket != null) {
      for (var client in _clients) client.write(message);
    } else if (currentType == ConnectionType.bluetooth &&
        _isNearbyAdvertising) {
      for (var clientId in _nearbyClients) {
        Nearby().sendBytesPayload(
          clientId,
          Uint8List.fromList(utf8.encode(message)),
        );
      }
    }
  }

  void sendAction(Map<String, dynamic> action) {
    String message = jsonEncode(action) + '\n';
    if (currentType == ConnectionType.wifi && _clientSocket != null) {
      _clientSocket!.write(message);
    } else if (currentType == ConnectionType.bluetooth &&
        _nearbyHostId != null) {
      Nearby().sendBytesPayload(
        _nearbyHostId!,
        Uint8List.fromList(utf8.encode(message)),
      );
    }
  }

  void closeConnections() {
    _serverSocket?.close();
    _clientSocket?.close();
    for (var c in _clients) c.close();
    _clients.clear();
    _socketToName.clear();

    if (_isNearbyAdvertising) {
      Nearby().stopAdvertising();
      _isNearbyAdvertising = false;
    }
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
    _nearbyClients.clear();
    _nearbyIdToName.clear();
    _nearbyHostId = null;
  }
}
