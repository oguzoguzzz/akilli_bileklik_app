# Akıllı Bileklik Uygulaması

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![BLE](https://img.shields.io/badge/Bluetooth%20Low%20Energy-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white)
![ESP32](https://img.shields.io/badge/ESP32-E7352C?style=for-the-badge&logo=espressif&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active-success?style=for-the-badge)

Flutter ile geliştirilmiş, ESP32 tabanlı giyilebilir cihazdan BLE ile veri alarak sağlık takibi ve alarm uyarısı yapan mobil uygulama.

## Özellikler
- BLE cihaz tarama ve bağlanma
- Gerçek zamanlı veri gösterimi (BPM, SpO2, hareket durumu)
- Alarm uyarıları (düşme, hareketsizlik, nabız, SpO2)
- Bildirim gönderimi (yerel bildirim)
- SMS uyarısı (Android, izinlere bağlı)
- Rapor paylaşımı (metin olarak)
- Eşik ayarları ve ESP32'ye yazma

## BLE Protokolü
Uygulama, sadece belirli servis UUID'sini taşıyan cihazları listeler ve bağlanır.

### UUID'ler
- Service UUID: e56bca45-34f6-40df-b3eb-56e1977168b5
- Data Characteristic UUID (Notify): 0976d181-f522-45c1-b181-5d3bdfeba757
- Config Characteristic UUID (Write/Read/Notify): 43b2c861-c4f8-45df-ae11-7d363fd94c3c

### Veri Paketi Formatı
ESP32 -> Uygulama, tek satır CSV paket gönderir:

BPM,HAREKET,BPM_ALARM,SPO2,MPU,MAX,BUTTON,SPO2_ALARM

Örnek:
72,GUVENLI,NORMAL,97,OK,OK,OK,NORMAL

Alanlar:
- BPM: Nabız (int)
- HAREKET: GUVENLI, DUSME_TESPIT, HAREKETSIZ, ACIL_BUTON
- BPM_ALARM: NORMAL, YUKSEK_NABIZ, DUSUK_NABIZ, PARMAK_YOK
- SPO2: Oksijen yüzdesi (int, -1 ise veri yok)
- MPU/MAX/BUTTON: OK, ERR, UNKNOWN
- SPO2_ALARM: NORMAL, SPO2_DUSUK, SPO2_YUKSEK, BILINMIYOR

Uygulama paketi 8 alan olarak bekler. Daha kısa paket gelirse sensör durumları "Bilinmiyor"a çekilir.

## Eşik Ayarları (Config Write)
Uygulama, config characteristic üzerinden şu formatta yazar:

bpm_low=40,bpm_high=120,spo2_low=80,spo2_high=100,immobile_sec=3600,fall_g=25.0,motion_th=1.0

ESP32 bu değerleri okuyup dinamik eşik olarak kullanır.

## Bildirim ve SMS
- Yerel bildirim: flutter_local_notifications
- SMS: telephony (Android) + SMS izni

## Çalıştırma
- Proje dizinine gir:
  - cd akilli_bileklik_app
- Bağımlılıkları indir:
  - flutter pub get
- Çalıştır:
  - flutter run

## APK Üretimi
- flutter build apk --release

## Test
- Gerçek cihaz üzerinde BLE testi yapın (emülatör BLE taramayı desteklemeyebilir).
- nRF Connect / LightBlue ile servis UUID'si yayıp paket gönderebilirsiniz.

## Dizin Yapısı
- lib/main.dart: Uygulama kodu (BLE, UI, alarm mantığı)
- esp32.cpp: Örnek ESP32 BLE veri ve config yazma kodu (referans)

## Notlar
- BLE tarama servis UUID filtresi ile yapılır.
- SpO2 ve BPM alarmları aynı anda üretilebilir.
- Uygulama metinleri UTF-8 Türkçe karakterlerle güncellenmiştir.
