import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AppBluetoothService {
  // Singleton
  static final AppBluetoothService _instance = AppBluetoothService._internal();
  factory AppBluetoothService() => _instance;
  AppBluetoothService._internal();

  // State
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _rxCharacteristic;
  StreamSubscription? _scanSubscription;
  
  // Stream for NMEA data (raw bytes or string)
  final _dataController = StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataController.stream;

  // Stream for Connection State
  Stream<BluetoothConnectionState> get connectionStateStream => 
      _connectedDevice?.connectionState ?? Stream.value(BluetoothConnectionState.disconnected);
      
  bool get isConnected => _connectedDevice != null;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<void> init() async {
    // Check permissions
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> startScan() async {
    if (FlutterBluePlus.isScanningNow) return;
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> connect(BluetoothDevice device) async {
    await stopScan();
    
    await device.connect(autoConnect: false);
    _connectedDevice = device;
    
    // Discover Services
    final services = await device.discoverServices();
    
    // Look for common Serial/GNSS services
    // Note: NMEA usually comes over a Serial Port Profile (SPP) like service
    // or a custom GNSS service. For now, we'll listen to NOTIFY characteristics.
    
    for (var service in services) {
       for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
             await characteristic.setNotifyValue(true);
             characteristic.lastValueStream.listen((value) {
                // Determine if it's NMEA (starts with $)
                try {
                   final String data = String.fromCharCodes(value);
                   // Simple check for now, can be more robust
                   _dataController.add(data);
                } catch (e) {
                   // ignore
                }
             });
             _rxCharacteristic = characteristic; // Assume the first notify is the one we want for now
             print('Listening to ${characteristic.uuid}');
          }
       }
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _rxCharacteristic = null;
    }
  }
}
