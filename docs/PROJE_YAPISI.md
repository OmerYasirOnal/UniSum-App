# UniSum iOS - Proje Yapısı

Bu belge, UniSum iOS projesinin klasör ve dosya yapısını açıklar.

## Kök Dizin

```
UniSum/
├── Assets.xcassets/         # Görsel kaynaklar
├── Preview Content/         # SwiftUI önizleme içerikleri
├── Models/                  # Veri modelleri
├── Views/                   # Kullanıcı arayüzü bileşenleri
├── ViewModels/              # Görünüm modelleri
├── Networking/              # API iletişimi
├── docs/                    # Dokümantasyon dosyaları
├── tr.lproj/                # Türkçe dil dosyaları
├── en.lproj/                # İngilizce dil dosyaları
├── UniSumApp.swift          # Uygulama başlangıç noktası
├── ContentView.swift        # Ana içerik görünümü
├── LanguageManager.swift    # Dil yönetimi
├── Helpers.swift            # Yardımcı fonksiyonlar
├── CustomTextFieldStyle.swift # Özel UI bileşenleri
├── Secrets.plist            # Gizli anahtarlar
├── Info.plist               # Uygulama bilgileri
├── README.md                # Proje genel bilgileri
├── LICENSE                  # Lisans bilgileri
└── CHANGELOG.md             # Sürüm geçmişi
```

## Models Dizini

Uygulama veri modellerini içerir:

```
Models/
├── User.swift               # Kullanıcı modeli
├── Term.swift               # Dönem modeli
├── Course.swift             # Ders modeli
├── Grade.swift              # Not modeli
└── GradeScale.swift         # Not ölçeği modeli
```

## Views Dizini

Kullanıcı arayüzü bileşenlerini içerir:

```
Views/
├── Auth/                    # Kimlik doğrulama görünümleri
│   ├── LoginView.swift      # Giriş ekranı
│   ├── SignupView.swift     # Kayıt ekranı
│   ├── ForgotPasswordView.swift # Şifre sıfırlama ekranı
│   └── ToastView.swift      # Bildirim arayüzü
├── TermListView.swift       # Dönem listesi
├── AddTermPanel.swift       # Dönem ekleme paneli
├── CourseListView.swift     # Ders listesi
├── AddCourseView.swift      # Ders ekleme görünümü
├── CourseDetailView.swift   # Ders detayları
├── GradeFormView.swift      # Not giriş formu
├── ProfileView.swift        # Profil sayfası
├── GradeScaleEditorView.swift # Not ölçeği düzenleyici
├── EditGradeScaleView.swift # Not ölçeği düzenleme
├── SideBarView.swift        # Yan menü
└── OfflineGradeCalculatorView.swift # Çevrimdışı hesaplayıcı
```

## ViewModels Dizini

Görünüm modellerini içerir:

```
ViewModels/
├── AuthViewModel.swift       # Kimlik doğrulama işlemleri
├── TermViewModel.swift       # Dönem yönetimi 
├── CourseViewModel.swift     # Ders yönetimi
├── GradeViewModel.swift      # Not yönetimi
└── GradeScaleViewModel.swift # Not ölçeği yönetimi
```

## Networking Dizini

API iletişimi ile ilgili dosyaları içerir:

```
Networking/
└── NetworkManager.swift     # API istekleri yönetimi
```

## Dokümantasyon Dizini

Proje ile ilgili belgeleri içerir:

```
docs/
├── README.md                # Dokümantasyon ana sayfası
├── API.md                   # API entegrasyonu belgeleri
├── MODELS.md                # Veri modelleri belgeleri
├── KULLANIM_KILAVUZU.md     # Kullanım kılavuzu
├── CONTRIBUTING.md          # Katkıda bulunma rehberi
└── PROJE_YAPISI.md          # Bu belge
``` 