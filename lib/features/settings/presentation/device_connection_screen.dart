import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/bluetooth_service.dart';

class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  final AppBluetoothService _ble = AppBluetoothService();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _ble.init();
    // Listen to scan state if exposed or just manage locally
  }
  
  void _toggleScan() {
    setState(() => _isScanning = !_isScanning);
    if (_isScanning) {
       _ble.startScan();
    } else {
       _ble.stopScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hardware Connection'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: Column(
        children: [
          // Header / Status
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status', style: TextStyle(color: Colors.grey)),
                    StreamBuilder<BluetoothConnectionState>(
                      stream: _ble.connectionStateStream,
                      builder: (c, snapshot) {
                        final state = snapshot.data ?? BluetoothConnectionState.disconnected;
                        final color = state == BluetoothConnectionState.connected ? Colors.green : Colors.red;
                        return Text(state.toString().split('.').last.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold));
                      },
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _toggleScan,
                  icon: Icon(_isScanning ? Icons.stop : Icons.search),
                  label: Text(_isScanning ? 'Stop Scan' : 'Scan Devices'),
                  style: ElevatedButton.styleFrom(backgroundColor: _isScanning ? Colors.red : AppColors.primary),
                ),
              ],
            ),
          ),
          
          // Device List
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: _ble.scanResults,
              builder: (c, snapshot) {
                final results = snapshot.data ?? [];
                if (results.isEmpty) {
                   return Center(child: Text('No devices found', style: TextStyle(color: Colors.grey[600])));
                }
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final r = results[index];
                    final name = r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown Device';
                    return ListTile(
                      leading: const Icon(Icons.bluetooth, color: Colors.white),
                      title: Text(name, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(r.device.remoteId.toString(), style: TextStyle(color: Colors.grey[500])),
                      trailing: ElevatedButton(
                        child: const Text('Connect'),
                        onPressed: () {
                           _ble.connect(r.device);
                           _toggleScan(); // Stop scanning on connect
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Data Terminal Preview
          Container(
            height: 150,
            padding: const EdgeInsets.all(12),
            color: Colors.black,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NMEA DATA STREAM', style: TextStyle(color: Colors.greenAccent, fontSize: 10)),
                const Divider(color: Colors.greenAccent, height: 4),
                Expanded(
                  child: StreamBuilder<String>(
                    stream: _ble.dataStream,
                    builder: (context, snapshot) {
                       if (!snapshot.hasData) return const Text('Waiting for data...', style: TextStyle(color: Colors.grey));
                       // Just show last line for now
                       return Text(snapshot.data!, style: const TextStyle(color: Colors.green, fontFamily: 'Courier'));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
