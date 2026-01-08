import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
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
      title: 'Akilli Bileklik',
      theme: theme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      DashboardScreen(),
      AlertsScreen(),
      SettingsScreen(),
      DeviceScreen(),
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
            label: 'Uyarilar',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Esikler',
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
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
              children: const [
                Expanded(
                  child: StatusCard(
                    label: 'Baglanti',
                    value: 'BLE - Hazir',
                    icon: Icons.bluetooth_connected,
                    tone: StatusTone.ok,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatusCard(
                    label: 'Pil Seviyesi',
                    value: '%82',
                    icon: Icons.battery_charging_full,
                    tone: StatusTone.info,
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Son durum: Stabil',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text('Son guncelleme: 12 saniye once'),
                        ],
                      ),
                    ),
                    Text(
                      'ID: ESP32-WROOM',
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
              children: const [
                Expanded(
                  child: MetricCard(
                    title: 'Nabiz',
                    value: '72',
                    unit: 'BPM',
                    icon: Icons.favorite,
                    color: Color(0xFFE35D5D),
                    min: 40,
                    max: 120,
                    current: 72,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'Oksijen',
                    value: '97',
                    unit: '%SpO2',
                    icon: Icons.water_drop,
                    color: Color(0xFF3C7EA6),
                    min: 80,
                    max: 100,
                    current: 97,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: MetricCard(
                    title: 'Aktivite',
                    value: 'Hareketsiz',
                    unit: '43 dk',
                    icon: Icons.directions_walk,
                    color: Color(0xFFF08A4B),
                    min: 0,
                    max: 60,
                    current: 43,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    title: 'Dusme Riski',
                    value: 'Dusuk',
                    unit: 'Ivme 0.12g',
                    icon: Icons.warning_amber_rounded,
                    color: Color(0xFF8B6CBF),
                    min: 0,
                    max: 1,
                    current: 0.12,
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
                    const Text(
                      'Son 5 dakika (simulasyon)',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: CustomPaint(
                        painter: PulseChartPainter(),
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
                    onPressed: () {},
                    icon: const Icon(Icons.sos),
                    label: const Text('Test Uyarisi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
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
  }
}

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final alerts = [
      AlertItem(
        title: 'Dusme Alarmi',
        description: 'Ani ivme + 2 dk hareketsizlik',
        time: 'Bugun 09:42',
        severity: AlertSeverity.high,
      ),
      AlertItem(
        title: 'Nabiz Esigi Asildi',
        description: 'Nabiz 128 BPM algilandi',
        time: 'Bugun 08:31',
        severity: AlertSeverity.medium,
      ),
      AlertItem(
        title: 'Uzun Hareketsizlik',
        description: 'Hareketsizlik 60 dk uzerinde',
        time: 'Dun 22:10',
        severity: AlertSeverity.low,
      ),
    ];

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
          const SectionTitle(
            title: 'Gonderim Durumu',
            actionText: 'Log',
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: StatusCard(
                  label: 'SMS',
                  value: 'Basarili',
                  icon: Icons.sms_outlined,
                  tone: StatusTone.ok,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatusCard(
                  label: 'Bildirim',
                  value: 'Basarili',
                  icon: Icons.notifications_active_outlined,
                  tone: StatusTone.ok,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const StatusCard(
            label: 'Cagri',
            value: 'Yedek listesi aktif',
            icon: Icons.call_outlined,
            tone: StatusTone.info,
          ),
          const SizedBox(height: 16),
          const SectionTitle(title: 'Son Alarmlar'),
          const SizedBox(height: 12),
          ...alerts.map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AlertCard(item: alert),
              )),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                    children: const [
                      Expanded(
                        child: ThresholdField(label: 'Alt Limit', value: '40'),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ThresholdField(label: 'Ust Limit', value: '120'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Oksijen Sat. Limitleri (%)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(
                        child: ThresholdField(label: 'Alt Limit', value: '80'),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ThresholdField(label: 'Ust Limit', value: '100'),
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
                  const ThresholdField(label: 'Dakika', value: '60'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Dusme hassasiyeti'),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Yuksek',
                          style: TextStyle(
                            color: colors.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
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
          const PreferenceTile(
            title: 'SMS uyarisi',
            subtitle: 'Yedek SMS kanalini aktif tut',
            value: true,
          ),
          const SizedBox(height: 8),
          const PreferenceTile(
            title: 'Acil cagri',
            subtitle: 'Cagri listesine otomatik arama yap',
            value: false,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {},
            child: const Text('Kaydet ve Bileklige Gonder'),
          ),
        ],
      ),
    );
  }
}

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const HeaderRow(
            title: 'Cihaz Yonetimi',
            subtitle: 'ESP32, sensore baglanti ve servisler',
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
                      const Text(
                        'ESP32 WROOM',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Durum: Baglanti bekleniyor'),
                  const SizedBox(height: 6),
                  const Text('Son tarama: 2 dakika once'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      InfoChip(label: 'MPU6050', value: 'Aktif'),
                      InfoChip(label: 'MAX30102', value: 'Aktif'),
                      InfoChip(label: 'Acil Buton', value: 'Hazir'),
                      InfoChip(label: 'TP4056', value: 'Sarjda'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.search),
                          label: const Text('Cihaz Tara'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.link),
                          label: const Text('Baglan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle(title: 'Servis Durumu'),
          const SizedBox(height: 12),
          const StatusCard(
            label: 'Veri Akisi',
            value: 'BLE paketi bekleniyor',
            icon: Icons.sensors,
            tone: StatusTone.info,
          ),
          const SizedBox(height: 12),
          const StatusCard(
            label: 'Uyari Motoru',
            value: 'Hazir',
            icon: Icons.campaign_outlined,
            tone: StatusTone.ok,
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
                    'Test Senaryolari',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dusme, uzun sure hareketsizlik ve manuel alarm icin '
                    'mobilden tetikleme planlanmistir.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
                  style: TextStyle(
                    color: colors.outline,
                    fontSize: 14,
                  ),
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
                    style: TextStyle(
                      color: colors.outline,
                      fontSize: 12,
                    ),
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
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final double min;
  final double max;
  final double current;

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
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                    style: TextStyle(
                      color: colors.outline,
                      fontSize: 12,
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

class ThresholdField extends StatelessWidget {
  const ThresholdField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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
