# Değişiklik Günlüğü

Tüm önemli değişiklikler bu dosyada belgelenecektir.

## [1.1.0] - 2024-04-04

### Eklenenler
- Token yenileme mekanizması uygulandı
- E-posta doğrulama durumunu kontrol etme ve yeniden gönderme özellikleri eklendi
- Ağ yanıtları için standart API yanıt yapısı eklendi
- Yeni Açılış Ekranı (SplashView) ile uygulama başlangıcı geliştirildi
- Tüm giriş formlarına şifre gösterme/gizleme özelliği eklendi
- Backend'de dönem kredilerini otomatik hesaplama özelliği eklendi

### Değişenler
- LoginView, SignupView ve ForgotPasswordView modernleştirildi
- TermListView kart tasarımına güncellendi
- SideBar menu tasarımı geliştirildi
- NetworkManager zaman aşımı (timeout) yönetimi iyileştirildi

### Düzeltilenler
- Backend/Frontend arasındaki veri yapısı uyumsuzlukları giderildi
- User modelinde 'verified' alanı eksikliği düzeltildi
- Daha güvenli token işleme yöntemleri uygulandı
- Term modeli Hashable protokolüne uyumlu hale getirildi
- totalCredits özelliği dönem verilerine doğru şekilde entegre edildi
- Bellek erişim hataları (EXC_BAD_ACCESS) çözüldü

## [1.0.0] - 2024-04-01

### Eklenenler
- Temel kullanıcı kimlik doğrulama sistemi
- Dönem, ders ve not yönetimi özellikleri
- Türkçe ve İngilizce dil desteği
- Otomatik not ortalama hesaplama
- Özelleştirilebilir not ölçeği
- Çevrimdışı not hesaplama aracı

### Değişenler
- İlk resmi sürüm

### Düzeltilenler
- İlk sürüm 