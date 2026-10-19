# Konuşan Cüzdan

Çocuklar için sesli para hesaplama uygulaması (Flutter / Dart).
YAZ305 Mobil Yazılım Geliştirme – Proje 13.

## VS Code'da açma

1. Zip'i bir klasöre çıkarın (yolunda Türkçe karakter ve boşluk olmaması önerilir, ör. `C:\projeler\konusan_cuzdan`).
2. VS Code → **File → Open Folder** → `konusan_cuzdan` klasörünü seçin.
3. Önerilen **Flutter** eklentisini kurun (VS Code sağ altta soracak).
4. Terminali açın (**Ctrl + `**) ve sırayla çalıştırın:

   ```
   flutter create . --org com.konusancuzdan --project-name konusan_cuzdan
   flutter pub get
   flutter run
   ```

   `flutter create .` mevcut `lib/` kodunuza dokunmaz; sadece eksik `android/`, `ios/` vb. platform klasörlerini oluşturur.
   Not: `flutter create` yeni bir `test/widget_test.dart` ekleyebilir; hata verirse o dosyayı silin.

Gereken sürüm: Flutter 3.35 veya üstü (`flutter --version` ile kontrol edin, gerekirse `flutter upgrade`).

## Eksik varlıklar (assets)

Kod aşağıdaki dosyaları bekliyor. Yoksa uygulama çalışır ama o yerlerde resim/ses görünmez:

| Klasör | Dosyalar |
|---|---|
| `assets/images/` | `maskot_selam.png`, `maskot_alisveris.png`, `maskot_goster.png`, `maskot_tebrik.png`, `ikon_cuzdan.png`, `ikon_alisveris.png`, `ikon_oyun.png`, `ikon_gecmis.png`, `kasa.png`, `urun_elma.png`, `urun_su.png`, `urun_ekmek.png`, `urun_meyve_suyu.png` |
| `assets/sounds/` | `tap.wav`, `coin.wav`, `success.wav`, `try_again.wav` |
| `assets/voice/` | (isteğe bağlı) gönüllü ses kayıtları, ör. `cuzdaninda.mp3` |
| `assets/video/` | (isteğe bağlı) `tanitim.mp4` |
| `assets/fonts/` | `Baloo2-VariableFont_wght.ttf` (Google Fonts'tan indirin, sonra `pubspec.yaml` içindeki `fonts:` bölümünü açın) |

## Klasör yapısı

```
lib/
  main.dart
  models/      Para, ürün, alışveriş kaydı
  data/        SQLite veritabanı
  services/    Ödeme algoritması, ses, metin okuma
  state/       Uygulama durumu (Provider)
  utils/       Tema, geçişler
  widgets/     Ortak bileşenler
  screens/     10 ekran
test/          Birim testleri (flutter test)
```

## Test

```
flutter test
```
