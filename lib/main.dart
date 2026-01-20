import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';

const String kServiceUuid = 'e56bca45-34f6-40df-b3eb-56e1977168b5';
const String kDataCharUuid = '0976d181-f522-45c1-b181-5d3bdfeba757';
const String kConfigCharUuid = '43b2c861-c4f8-45df-ae11-7d363fd94c3c';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const SmartBandApp());
}

class SmartBandApp extends StatelessWidget {
  const SmartBandApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E5D6F),
      brightness: Brightness.light,
    );
    final theme = ThemeData(
      useMaterial3: true,
      textTheme: GoogleFonts.rubikTextTheme(),
      colorScheme: baseScheme.copyWith(
        primary: const Color(0xFF0E5D6F),
        onPrimary: Colors.white,
        secondary: const Color(0xFFF08A4B),
        onSecondary: Colors.white,
        surface: const Color(0xFFF6F2ED),
        onSurface: const Color(0xFF1C2426),
        error: const Color(0xFFD64550),
        onError: Colors.white,
        primaryContainer: const Color(0xFFCEDFE3),
        onPrimaryContainer: const Color(0xFF0B3743),
        secondaryContainer: const Color(0xFFFFD4B8),
        onSecondaryContainer: const Color(0xFF5E2D14),
        outline: const Color(0xFF8B9A9E),
      ),
      scaffoldBackgroundColor: const Color(0xFFF6F2ED),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Akıllı Bileklik',
      theme: theme,
      home: const AppShell(),
    );
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'alert_channel';

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
  }

  Future<void> showNotification(String title, String body) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Uyarı Bildirimleri',
      channelDescription: 'Akıllı bileklik uyarıları',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(0, title, body, details);
  }
}

class SmsService {
  SmsService._();

  static final SmsService instance = SmsService._();
  final Telephony _telephony = Telephony.instance;

  Future<void> sendSms(String number, String message) async {
    final status = await Permission.sms.request();
    if (!status.isGranted) return;
    await _telephony.sendSms(to: number, message: message);
  }
}

class SensorStore extends ChangeNotifier {
  int bpm = 0;
  String hareketDurumu = 'GUVENLI';
  String nabizDurumu = 'NORMAL';
  String bpmAlarmStatus = 'NORMAL';
  BluetoothConnectionState connectionState =
      BluetoothConnectionState.disconnected;
  DateTime? lastUpdate;
  final List<int> bpmHistory = [];
  final List<AlertItem> alerts = [];
  Set<String> _lastAlertKeys = {};
  String? deviceName;
  String? deviceId;
  BluetoothDevice? connectedDevice;
  String mpuStatus = 'Bilinmiyor';
  String maxStatus = 'Bilinmiyor';
  String buttonStatus = 'Bilinmiyor';
  bool smsEnabled = false;
  String smsNumber = '';

  void setConnectionState(BluetoothConnectionState state) {
    connectionState = state;
    notifyListeners();
  }

  void setDeviceInfo({String? name, String? id}) {
    if (name != null && name.isNotEmpty) {
      deviceName = name;
    }
    if (id != null && id.isNotEmpty) {
      deviceId = id;
    }
    notifyListeners();
  }

  void setConnectedDevice(BluetoothDevice? device) {
    connectedDevice = device;
    notifyListeners();
  }

  void updateSmsSettings({required String number, required bool enabled}) {
    smsNumber = number;
    smsEnabled = enabled;
    notifyListeners();
  }

  void addTestAlert() {
    final alert = AlertItem(
      title: 'Test Uyarısı',
      description: 'Mobil uygulama üzerinden tetiklendi',
      time: _formatTime(DateTime.now()),
      severity: AlertSeverity.low,
    );
    alerts.insert(0, alert);
    if (alerts.length > 20) {
      alerts.removeRange(20, alerts.length);
    }
    NotificationService.instance.showNotification(
      alert.title,
      alert.description,
    );
    _sendSmsIfNeeded(alert);
    notifyListeners();
  }

  String buildReport() {
    final last = lastUpdate == null
        ? 'Son paket: yok'
        : 'Son paket: ${lastUpdate!.hour.toString().padLeft(2, '0')}:'
              '${lastUpdate!.minute.toString().padLeft(2, '0')}:'
              '${lastUpdate!.second.toString().padLeft(2, '0')}';
    final device = deviceName ?? deviceId ?? 'ESP32';
    final bpmText = bpm == 0 ? 'Nabız: yok' : 'Nabız: $bpm BPM';
    final hareketText = 'Hareket: $hareketDurumu';
    final nabizDurumText = 'Nabız Durumu: $nabizDurumu';
    final alertText = alerts.isEmpty
        ? 'Uyarı: yok'
        : 'Uyarı: ${alerts.first.title}';
    return [
      'Akıllı Bileklik Raporu',
      'Cihaz: $device',
      last,
      bpmText,
      hareketText,
      nabizDurumText,
      alertText,
    ].join('\n');
  }

  void updateFromPacket(String packet) {
    final parts = packet.trim().split(',');
    if (parts.length < 3) return;

    bpm = int.tryParse(parts[0]) ?? 0;
    hareketDurumu = parts[1].trim();
    nabizDurumu = parts[2].trim();
    bpmAlarmStatus = nabizDurumu;
    if (parts.length >= 6) {
      mpuStatus = _mapStatus(parts[3].trim());
      maxStatus = _mapStatus(parts[4].trim());
      buttonStatus = _mapStatus(parts[5].trim());
    } else {
      mpuStatus = 'Bilinmiyor';
      maxStatus = 'Bilinmiyor';
      buttonStatus = 'Bilinmiyor';
    }
    lastUpdate = DateTime.now();

    if (bpm > 0) {
      bpmHistory.add(bpm);
      if (bpmHistory.length > 60) {
        bpmHistory.removeRange(0, bpmHistory.length - 60);
      }
    }

    final newAlerts = _buildAlertsFromStatus();
    if (newAlerts.isEmpty) {
      _lastAlertKeys = {};
    } else {
      final currentKeys = <String>{};
      for (final alert in newAlerts) {
        final key = '${alert.title}:${alert.description}';
        currentKeys.add(key);
        if (_lastAlertKeys.contains(key)) {
          continue;
        }
        alerts.insert(0, alert);
        if (alerts.length > 20) {
          alerts.removeRange(20, alerts.length);
        }
        NotificationService.instance.showNotification(
          alert.title,
          alert.description,
        );
        _sendSmsIfNeeded(alert);
      }
      _lastAlertKeys = currentKeys;
    }

    notifyListeners();
  }

  String _mapStatus(String value) {
    switch (value) {
      case 'OK':
        return 'Aktif';
      case 'ERR':
        return 'Hata';
      default:
        return 'Bilinmiyor';
    }
  }


  void _sendSmsIfNeeded(AlertItem alert) {
    if (!smsEnabled) return;
    final number = smsNumber.trim();
    if (number.isEmpty) return;
    unawaited(
      SmsService.instance.sendSms(
        number,
        '${alert.title}: ${alert.description}',
      ),
    );
  }

  List<AlertItem> _buildAlertsFromStatus() {
    final result = <AlertItem>[];

    switch (hareketDurumu) {
      case 'DUSME_TESPIT':
        result.add(
          _makeAlert('Düşme Alarmı', 'Düşme tespit edildi', AlertSeverity.high),
        );
        break;
      case 'ACIL_BUTON':
        result.add(
          _makeAlert(
            'Acil Yardim',
            'Manuel buton tetiklendi',
            AlertSeverity.high,
          ),
        );
        break;
      case 'HAREKETSIZ':
        result.add(
          _makeAlert(
            'Hareketsizlik',
            'Uzun sureli hareketsizlik',
            AlertSeverity.medium,
          ),
        );
        break;
    }

    switch (bpmAlarmStatus) {
      case 'YUKSEK_NABIZ':
        result.add(
          _makeAlert(
            'Nabiz Alarmi',
            'Yuksek nabiz algilandi',
            AlertSeverity.medium,
          ),
        );
        break;
      case 'DUSUK_NABIZ':
        result.add(
          _makeAlert(
            'Nabiz Alarmi',
            'Dusuk nabiz algilandi',
            AlertSeverity.medium,
          ),
        );
        break;
    }

    return result;
  }

  AlertItem _makeAlert(
    String title,
    String description,
    AlertSeverity severity,
  ) {
    final time = _formatTime(DateTime.now());
    return AlertItem(
      title: title,
      description: description,
      time: time,
      severity: severity,
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return 'Bugun $hour:$minute';
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final SensorStore _store = SensorStore();

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(store: _store),
      AlertsScreen(store: _store),
      SettingsScreen(store: _store),
      DeviceScreen(store: _store),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) {
          setState(() => _selectedIndex = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Durum',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Uyarılar',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Eşikler',
          ),
          NavigationDestination(
            icon: Icon(Icons.watch_outlined),
            selectedIcon: Icon(Icons.watch),
            label: 'Cihaz',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.store});

  final SensorStore store;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: store,
      builder: (context, child) {
        final connectionText = switch (store.connectionState) {
          BluetoothConnectionState.connected => 'BLE - Baglandi',
          _ => 'BLE - Hazir',
        };
        final lastUpdateText = store.lastUpdate == null
            ? 'Son guncelleme: --'
            : 'Son guncelleme: ${store.lastUpdate!.hour.toString().padLeft(2, '0')}:${store.lastUpdate!.minute.toString().padLeft(2, '0')}';
        final hareketLabel = switch (store.hareketDurumu) {
          'DUSME_TESPIT' => 'Dusme',
          'ACIL_BUTON' => 'Acil Buton',
          'HAREKETSIZ' => 'Hareketsiz',
          _ => 'Guvenli',
        };
        final nabizLabel = store.bpm == 0 ? '--' : '${store.bpm}';
        final deviceLabel = store.deviceId ?? store.deviceName ?? 'ESP32';
        final bpmAlarm = store.bpmAlarmStatus;
        final (nabizStatusText, nabizTone) = switch (bpmAlarm) {
          'YUKSEK_NABIZ' => ('Yuksek', const Color(0xFFD64550)),
          'DUSUK_NABIZ' => ('Dusuk', const Color(0xFFF08A4B)),
          'PARMAK_YOK' => ('Parmak yok', colors.outline),
          'BILINMIYOR' => ('Bilinmiyor', colors.outline),
          _ => ('Normal', const Color(0xFF2E9C6B)),
        };
        final nabizCardTone =
            nabizStatusText == 'Normal' ? const Color(0xFF8B6CBF) : nabizTone;
        final statusTitle = switch (store.hareketDurumu) {
          'DUSME_TESPIT' => 'Son durum: Dusme alarmi',
          'ACIL_BUTON' => 'Son durum: Acil buton',
          'HAREKETSIZ' => 'Son durum: Hareketsiz',
          _ => switch (bpmAlarm) {
            'YUKSEK_NABIZ' => 'Son durum: Yuksek nabiz',
            'DUSUK_NABIZ' => 'Son durum: Dusuk nabiz',
            'PARMAK_YOK' => 'Son durum: Sensor temas yok',
            _ => 'Son durum: Stabil',
          },
        };
        final graphLabel = store.bpmHistory.isEmpty
            ? 'Veri bekleniyor'
            : 'Son ${store.bpmHistory.length} okuma';
        final activityProgress = switch (store.hareketDurumu) {
          'HAREKETSIZ' => 60.0,
          'DUSME_TESPIT' => 60.0,
          'ACIL_BUTON' => 60.0,
          _ => 0.0,
        };
        final nabizProgress =
            (bpmAlarm == 'NORMAL' || bpmAlarm == 'PARMAK_YOK') ? 0.0 : 1.0;

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF6F2ED), Color(0xFFE5F0F3)],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                const HeaderRow(
                  title: 'Akilli Bileklik',
                  subtitle: 'Gercek zamanli saglik takibi',
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: StatusCard(
                        label: 'Baglanti',
                        value: connectionText,
                        icon: Icons.bluetooth_connected,
                        tone: StatusTone.ok,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  color: colors.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.local_hospital, color: colors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(lastUpdateText),
                            ],
                          ),
                        ),
                        Text(
                          'ID: $deviceLabel',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Nabiz',
                        value: nabizLabel,
                        unit: 'BPM',
                        icon: Icons.favorite,
                        color: const Color(0xFFE35D5D),
                        min: 40,
                        max: 120,
                        current: store.bpm.toDouble().clamp(0, 120),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MetricCard(
                        title: 'Aktivite',
                        value: hareketLabel,
                        unit: store.hareketDurumu,
                        icon: Icons.directions_walk,
                        color: const Color(0xFFF08A4B),
                        min: 0,
                        max: 60,
                        current: activityProgress,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Nabiz Durumu',
                        value: store.bpmAlarmStatus,
                        unit: 'Durum',
                        icon: Icons.warning_amber_rounded,
                        color: nabizCardTone,
                        min: 0,
                        max: 1,
                        current: nabizProgress,
                        statusText: nabizStatusText,
                        statusColor: nabizTone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const SectionTitle(
                  title: 'Canli Nabiz Grafigi',
                  actionText: 'Detay',
                ),
                const SizedBox(height: 12),
                Card(
                  child: Container(
                    height: 160,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF1F4F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          graphLabel,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: CustomPaint(
                            painter: BpmChartPainter(store.bpmHistory),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SectionTitle(title: 'Hizli Islemler'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: store.addTestAlert,
                        icon: const Icon(Icons.sos),
                        label: const Text('Test Uyarisi'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final report = store.buildReport();
                          await Share.share(report, subject: 'Akilli bileklik raporu');
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Rapor Paylas'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, required this.store});

  final SensorStore store;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: store,
      builder: (context, child) {
        final alerts = store.alerts;
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              const HeaderRow(
                title: 'Uyari Merkezi',
                subtitle: 'Son alarmlar ve bildirim durumu',
              ),
              const SizedBox(height: 16),
              Card(
                color: colors.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.sms, size: 30),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Uyarilar SMS, anlik bildirim ve cagri olarak gonderilir.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        'Aktif',
                        style: TextStyle(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle(title: 'Son Alarmlar'),
              const SizedBox(height: 12),
              if (alerts.isEmpty) const Text('Henuz bir alarm yok.'),
              ...alerts.map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AlertCard(item: alert),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final SensorStore store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _bpmLowController;
  late final TextEditingController _bpmHighController;
  late final TextEditingController _immobileController;
  late final TextEditingController _fallGController;
  late final TextEditingController _motionController;
  late final TextEditingController _smsController;
  bool _smsEnabled = false;

  @override
  void initState() {
    super.initState();
    _bpmLowController = TextEditingController(text: '40');
    _bpmHighController = TextEditingController(text: '120');
    _immobileController = TextEditingController(text: '60');
    _fallGController = TextEditingController(text: '25.0');
    _motionController = TextEditingController(text: '1.0');
    _smsController = TextEditingController(text: widget.store.smsNumber);
    _smsEnabled = widget.store.smsEnabled;
  }

  @override
  void dispose() {
    _bpmLowController.dispose();
    _bpmHighController.dispose();
    _immobileController.dispose();
    _fallGController.dispose();
    _motionController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _sendThresholds() async {
    final device = widget.store.connectedDevice;
    if (device == null) {
      return 'Cihaz bagli degil. Esik gonderilemedi.';
    }

    final bpmLow = int.tryParse(_bpmLowController.text) ?? 40;
    final bpmHigh = int.tryParse(_bpmHighController.text) ?? 120;
    final immobileMinutes = int.tryParse(_immobileController.text) ?? 60;
    final immobileSeconds = immobileMinutes * 60;
    final fallG = double.tryParse(_fallGController.text) ?? 25.0;
    final motionThreshold = double.tryParse(_motionController.text) ?? 1.0;

    final payload =
        'bpm_low=$bpmLow,'
        'bpm_high=$bpmHigh,'
        'immobile_sec=$immobileSeconds,'
        'fall_g=$fallG,'
        'motion_th=$motionThreshold';

    final serviceGuid = Guid(kServiceUuid);
    final configGuid = Guid(kConfigCharUuid);
    final services = await device.discoverServices();
    for (final service in services) {
      if (service.uuid != serviceGuid) continue;
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == configGuid) {
          await characteristic.write(
            utf8.encode(payload),
            withoutResponse: true,
          );
          return null;
        }
      }
    }

    return 'Esik karakteristigi bulunamadi.';
  }

  Future<void> _callEmergency() async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const HeaderRow(
            title: 'Esik Ayarlari',
            subtitle: 'Alarm parametrelerini ozellestir',
          ),
          const SizedBox(height: 16),
          Card(
            color: colors.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nabiz Limitleri (BPM)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ThresholdField(
                          label: 'Alt Limit',
                          controller: _bpmLowController,
                          value: '40',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ThresholdField(
                          label: 'Ust Limit',
                          controller: _bpmHighController,
                          value: '120',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hareketsizlik Suresi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ThresholdField(
                    label: 'Dakika',
                    controller: _immobileController,
                    value: '60',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ThresholdField(
                          label: 'Dusme esigi (g)',
                          controller: _fallGController,
                          value: '25.0',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ThresholdField(
                          label: 'Hareket esigi',
                          controller: _motionController,
                          value: '1.0',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Not: Algoritma, ani ivme + hareketsizlik kriterlerini kullanir.',
                    style: TextStyle(color: Color(0xFF6F7D80)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle(title: 'Bildirim Tercihleri'),
          const SizedBox(height: 12),
          const PreferenceTile(
            title: 'Anlik bildirim',
            subtitle: 'Mobil cihaz uzerine bildirim gonder',
            value: true,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SMS Uyari Ayari',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _smsEnabled,
                    onChanged: (value) {
                      setState(() => _smsEnabled = value);
                    },
                    title: const Text('SMS uyarisi'),
                    subtitle: const Text(
                      'Sorun algilaninca otomatik SMS gonder',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _smsController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Telefon numarasi',
                      hintText: '+90...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Acil Cagri (112)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _callEmergency,
                    icon: const Icon(Icons.call),
                    label: const Text('112 Ara'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () async {
              widget.store.updateSmsSettings(
                number: _smsController.text.trim(),
                enabled: _smsEnabled,
              );
              final error = await _sendThresholds();
              if (!mounted) return;
              final message = error == null
                  ? 'SMS ayarlari kaydedildi ve esikler bileklige gonderildi.'
                  : 'SMS ayarlari kaydedildi. $error';
              _showSnack(message);
            },
            child: const Text('Kaydet ve Bileklige Gonder'),
          ),
        ],
      ),
    );
  }
}

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key, required this.store});

  final SensorStore store;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  static const _serviceUuid = kServiceUuid;
  static const _dataCharUuid = kDataCharUuid;
  final Guid _serviceGuid = Guid(_serviceUuid);
  final Guid _dataCharGuid = Guid(_dataCharUuid);
  final List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _dataSub;
  bool _isScanning = false;
  BluetoothDevice? _selectedDevice;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  DateTime? _lastScan;
  String? _scanHint;

  @override
  void dispose() {
    _scanSub?.cancel();
    _connSub?.cancel();
    _dataSub?.cancel();
    super.dispose();
  }

  Future<bool> _ensurePermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final requests = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    final statuses = await requests.request();
    return statuses.values.every((status) => status.isGranted);
  }

  void _showHint(String message) {
    setState(() => _scanHint = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startScan() async {
    final hasPerms = await _ensurePermissions();
    if (!hasPerms) {
      return;
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      _showHint('Bluetooth kapalı. Lütfen açın.');
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResults.clear();
      _scanHint = null;
    });

    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults
          ..clear()
          ..addAll(results);
      });
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));

    _lastScan = DateTime.now();
    setState(() => _isScanning = false);
  }

  Future<void> _connectSelected() async {
    final device = _selectedDevice;
    if (device == null) return;

    try {
      await device.connect(timeout: const Duration(seconds: 12));
    } on Exception {
      // ignore: avoid_print
      print('Bağlantı zaten açık olabilir.');
    }
    widget.store.setConnectedDevice(device);
    widget.store.setDeviceInfo(
      name: device.platformName,
      id: device.remoteId.str,
    );
    _connSub?.cancel();
    _connSub = device.connectionState.listen((state) {
      setState(() => _connectionState = state);
      widget.store.setConnectionState(state);
      if (state == BluetoothConnectionState.disconnected) {
        widget.store.setConnectedDevice(null);
      }
    });
    await _subscribeToData(device);
  }

  Future<void> _disconnect() async {
    final device = _selectedDevice;
    if (device == null) return;
    await _dataSub?.cancel();
    await device.disconnect();
    widget.store.setConnectedDevice(null);
  }

  Future<void> _subscribeToData(BluetoothDevice device) async {
    final services = await device.discoverServices();
    for (final service in services) {
      if (service.uuid != _serviceGuid) continue;
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == _dataCharGuid) {
          await characteristic.setNotifyValue(true);
          _dataSub?.cancel();
          _dataSub = characteristic.onValueReceived.listen((data) {
            final text = utf8.decode(data);
            widget.store.updateFromPacket(text);
          });
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isConnected = _connectionState == BluetoothConnectionState.connected;
    final statusText = switch (_connectionState) {
      BluetoothConnectionState.connected => 'Bağlandı',
      BluetoothConnectionState.disconnected => 'Bağlantı bekleniyor',
      _ => 'Bağlantı bekleniyor',
    };
    final lastScanText = _lastScan == null
        ? 'Henüz tarama yapılmadı'
        : 'Son tarama: ${_lastScan!.hour.toString().padLeft(2, '0')}:${_lastScan!.minute.toString().padLeft(2, '0')}';

    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, child) {
        final lastUpdate = widget.store.lastUpdate;
        final packetText = lastUpdate == null
            ? 'Paket bekleniyor'
            : 'Son paket: ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}:${lastUpdate.second.toString().padLeft(2, '0')}';
        final dataFlowText = isConnected ? packetText : 'Bağlı değil';
        final alertActive =
            widget.store.hareketDurumu != 'GUVENLI' ||
            (widget.store.bpmAlarmStatus != 'NORMAL' &&
                widget.store.bpmAlarmStatus != 'PARMAK_YOK');
        final alertText = alertActive ? 'Aktif' : 'Hazır';
        final alertTone = alertActive ? StatusTone.warning : StatusTone.ok;
        final deviceLabel =
            widget.store.deviceName ??
            (_selectedDevice?.platformName.isNotEmpty == true
                ? _selectedDevice!.platformName
                : 'ESP32');

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              const HeaderRow(
                title: 'Cihaz Yönetimi',
                subtitle: 'ESP32, sensöre bağlantı ve servisler',
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.watch, color: colors.primary),
                          const SizedBox(width: 10),
                          Text(
                            deviceLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Durum: $statusText'),
                      const SizedBox(height: 6),
                      Text(lastScanText),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InfoChip(
                            label: 'MPU6050',
                            value: widget.store.mpuStatus,
                          ),
                          InfoChip(
                            label: 'MAX30102',
                            value: widget.store.maxStatus,
                          ),
                          InfoChip(
                            label: 'Acil Buton',
                            value: widget.store.buttonStatus,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isScanning ? null : _startScan,
                              icon: const Icon(Icons.search),
                              label: Text(
                                _isScanning ? 'Taranıyor' : 'Cihaz Tara',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: isConnected
                                  ? _disconnect
                                  : _connectSelected,
                              icon: Icon(
                                isConnected ? Icons.link_off : Icons.link,
                              ),
                              label: Text(
                                isConnected ? 'Bağlantıyı Kes' : 'Bağlan',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Bulunan Cihazlar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (_scanResults.isEmpty)
                        Text(
                          _scanHint ?? 'Eşleşme yok. Cihaz taramayı deneyin.',
                        ),
                      ..._scanResults.map((result) {
                        final name = result.device.platformName.isEmpty
                            ? 'Bilinmeyen Cihaz'
                            : result.device.platformName;
                        final isSelected =
                            _selectedDevice?.remoteId == result.device.remoteId;
                        return Card(
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text(result.device.remoteId.str),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle)
                                : const Icon(Icons.circle_outlined),
                            onTap: () {
                              setState(() {
                                _selectedDevice = result.device;
                              });
                              widget.store.setDeviceInfo(
                                name: name,
                                id: result.device.remoteId.str,
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle(title: 'Servis Durumu'),
              const SizedBox(height: 12),
              StatusCard(
                label: 'Veri Akışı',
                value: dataFlowText,
                icon: Icons.sensors,
                tone: isConnected ? StatusTone.info : StatusTone.warning,
              ),
              const SizedBox(height: 12),
              StatusCard(
                label: 'Uyarı Motoru',
                value: alertText,
                icon: Icons.campaign_outlined,
                tone: alertTone,
              ),
              const SizedBox(height: 12),
              Card(
                color: colors.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Test Senaryoları',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Düşme, uzun süre hareketsizlik ve manuel alarm için '
                        'mobilden tetikleme planlanmıştır.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HeaderRow extends StatelessWidget {
  const HeaderRow({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: 1),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.outline, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: colors.primaryContainer,
          child: Text(
            'BK',
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.actionText});

  final String title;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        if (actionText != null)
          Text(
            actionText!,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

enum StatusTone { ok, info, warning }

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  final String label;
  final String value;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final toneColor = switch (tone) {
      StatusTone.ok => const Color(0xFF2E9C6B),
      StatusTone.info => colors.primary,
      StatusTone.warning => const Color(0xFFF08A4B),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: toneColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: toneColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: colors.outline, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.min,
    required this.max,
    required this.current,
    this.statusText,
    this.statusColor,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double min;
  final double max;
  final double current;
  final String? statusText;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final progress = ((current - min) / (max - min)).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            Text(
              unit,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (statusText != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (statusColor ?? color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText!,
                  style: TextStyle(
                    color: statusColor ?? color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AlertItem {
  AlertItem({
    required this.title,
    required this.description,
    required this.time,
    required this.severity,
  });

  final String title;
  final String description;
  final String time;
  final AlertSeverity severity;
}

enum AlertSeverity { high, medium, low }

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.item});

  final AlertItem item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = switch (item.severity) {
      AlertSeverity.high => colors.error,
      AlertSeverity.medium => colors.secondary,
      AlertSeverity.low => colors.primary,
    };
    final label = switch (item.severity) {
      AlertSeverity.high => 'Kritik',
      AlertSeverity.medium => 'Dikkat',
      AlertSeverity.low => 'Bilgi',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.warning, color: tone, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: tone,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.description),
                  const SizedBox(height: 6),
                  Text(
                    item.time,
                    style: TextStyle(color: colors.outline, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThresholdField extends StatelessWidget {
  const ThresholdField({
    super.key,
    required this.label,
    this.value = '',
    this.controller,
  });

  final String label;
  final String value;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller;
    return TextFormField(
      controller: effectiveController,
      initialValue: effectiveController == null ? value : null,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

class PreferenceTile extends StatefulWidget {
  const PreferenceTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final bool value;

  @override
  State<PreferenceTile> createState() => _PreferenceTileState();
}

class _PreferenceTileState extends State<PreferenceTile> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        value: _enabled,
        onChanged: (value) => setState(() => _enabled = value),
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(widget.subtitle),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colors.primaryContainer,
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class BpmChartPainter extends CustomPainter {
  BpmChartPainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFFE35D5D)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    if (values.isEmpty) {
      final y = size.height * 0.6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), strokePaint);
      return;
    }

    final minValue = values.reduce(math.min).toDouble();
    final maxValue = values.reduce(math.max).toDouble();
    final range = (maxValue - minValue).abs() < 1 ? 1.0 : maxValue - minValue;
    final step = values.length == 1 ? 0.0 : size.width / (values.length - 1);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final normalized = (values[i] - minValue) / range;
      final x = step * i;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant BpmChartPainter oldDelegate) => true;
}

class PulseChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE35D5D)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.6),
      Offset(size.width * 0.12, size.height * 0.62),
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.28, size.height * 0.7),
      Offset(size.width * 0.35, size.height * 0.4),
      Offset(size.width * 0.45, size.height * 0.58),
      Offset(size.width * 0.55, size.height * 0.35),
      Offset(size.width * 0.65, size.height * 0.66),
      Offset(size.width * 0.78, size.height * 0.42),
      Offset(size.width * 0.9, size.height * 0.58),
      Offset(size.width, size.height * 0.55),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
