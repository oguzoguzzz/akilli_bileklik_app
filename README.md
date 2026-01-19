# Akilli Bileklik Uygulamasi

Flutter ile gelistirilmis, ESP32 tabanli giyilebilir cihazdan BLE ile veri alarak saglik takibi ve alarm uyarisi yapan mobil uygulama.

## Ozellikler
- BLE cihaz tarama ve baglanma
- Gercek zamanli veri gosterimi (BPM, SpO2, pil, hareket durumu)
- Alarm uyarilari (dusme, hareketsizlik, nabiz, SpO2)
- Bildirim gonderimi (yerel bildirim)
- SMS uyarisi (Android, izinlere bagli)
- Rapor paylasimi (metin olarak)
- Esik ayarlari ve ESP32'ye yazma

## BLE Protokolu
Uygulama, sadece belirli servis UUID'sini tasiyan cihazlari listeler ve baglanir.

### UUID'ler
- Service UUID: a7891ebe-a10f-479b-924c-a908c4a7cbca
- Data Characteristic UUID (Notify): beb5483e-36e1-4688-b7f5-ea07361b26a8
- Config Characteristic UUID (Write/Read/Notify): 6a9c0001-1fb5-459e-8fcc-c5c9c331914b

### Veri Paketi Formati
ESP32 -> Uygulama, tek satir CSV paket gonderir:

BPM,HAREKET,BPM_ALARM,SPO2,BATTERY,MPU,MAX,BUTTON,CHARGE,SPO2_ALARM

Ornek:
72,GUVENLI,NORMAL,97,82,OK,OK,OK,CHARGING,NORMAL

Alanlar:
- BPM: Nabiz (int)
- HAREKET: GUVENLI, DUSME_TESPIT, HAREKETSIZ, ACIL_BUTON
- BPM_ALARM: NORMAL, YUKSEK_NABIZ, DUSUK_NABIZ, PARMAK_YOK
- SPO2: Oksijen yuzdesi (int, -1 ise veri yok)
- BATTERY: Pil yuzdesi (int)
- MPU/MAX/BUTTON: OK, ERR, UNKNOWN
- CHARGE: CHARGING, DISCHARGING, UNKNOWN (tahmini)
- SPO2_ALARM: NORMAL, SPO2_DUSUK, SPO2_YUKSEK, BILINMIYOR

Uygulama paketi 10 alan olarak bekler. Daha kisa paket gelirse sensor durumlari "Bilinmiyor"a cekilir.

## Esik Ayarlari (Config Write)
Uygulama, config characteristic uzerinden su formatta yazar:

bpm_low=40,bpm_high=120,spo2_low=80,spo2_high=100,immobile_sec=3600,fall_g=25.0,motion_th=1.0

ESP32 bu degerleri okuyup dinamik esik olarak kullanir.

## Bildirim ve SMS
- Yerel bildirim: flutter_local_notifications
- SMS: telephony (Android) + SMS izni

## Calistirma
- Proje dizinine gir:
  - cd akilli_bileklik_app
- Bagimliliklari indir:
  - flutter pub get
- Calistir:
  - flutter run

## APK Uretimi
- flutter build apk --release

## Test
- Gercek cihaz uzerinde BLE testi yapin (emulator BLE taramayi desteklemeyebilir).
- nRF Connect / LightBlue ile servis UUID'si yayip paket gonderebilirsiniz.

## Dizin Yapisi
- lib/main.dart: Uygulama kodu (BLE, UI, alarm mantigi)
- esp32.cpp: Ornek ESP32 BLE veri ve config yazma kodu (referans)

## Notlar
- BLE tarama servis UUID filtresi ile yapilir.
- SpO2 ve BPM alarmlari ayni anda uretilebilir.
- Uygulama metinleri ASCII tutulmustur.
