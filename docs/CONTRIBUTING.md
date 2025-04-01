# Katkıda Bulunma Rehberi

UniSum iOS projesine katkıda bulunmak istediğiniz için teşekkür ederiz! Bu dosya, projeye katkıda bulunmak isteyenler için yönlendirme sağlar.

## Geliştirme Ortamı

Projeyi geliştirmek için aşağıdaki araçlara ihtiyacınız olacaktır:

- Xcode 13.0 veya daha yeni
- Swift 5.5 veya daha yeni
- iOS 15.0 veya daha yeni bir simülatör/cihaz
- Git

## Kurulum Adımları

1. Projeyi forklayın
2. Yerel makinenize klonlayın:
   ```
   git clone https://github.com/KULLANICI_ADI/UniSum-iOS.git
   ```
3. Xcode ile `UniSum.xcodeproj` dosyasını açın
4. Gerekli bağımlılıkları kurun (eğer varsa)
5. Uygulamayı simülatörde çalıştırın ve her şeyin düzgün çalıştığından emin olun

## Geliştirme İş Akışı

1. Yeni bir özellik veya düzeltme üzerinde çalışmaya başlamadan önce ana repodaki en son değişiklikleri alın:
   ```
   git fetch upstream
   git merge upstream/main
   ```

2. Özellik veya düzeltme için yeni bir dal oluşturun:
   ```
   git checkout -b özellik/özellik-adı
   ```
   veya
   ```
   git checkout -b düzeltme/hata-adı
   ```

3. Değişikliklerinizi yapın ve düzenli aralıklarla commit edin:
   ```
   git add .
   git commit -m "Değişiklik açıklaması"
   ```

4. Değişikliklerinizi kendi fork'unuza (origin) iteleyip, sonra Pull Request (PR) açın:
   ```
   git push origin özellik/özellik-adı
   ```

## Kod Stili

- [Apple'ın Swift Stil Rehberi](https://swift.org/documentation/api-design-guidelines/)'ni takip edin
- Anlamlı değişken, fonksiyon ve sınıf isimleri kullanın
- Karmaşık kod bloklarını yorum satırlarıyla açıklayın
- UI bileşenlerini programatik olarak değil, SwiftUI veya Storyboard kullanarak oluşturun
- Döngüsel bağımlılıklardan kaçının

## Test Etme

- Yeni bir özellik eklerken uygun unit testler de ekleyin
- Mevcut testlerin başarıyla geçtiğinden emin olun
- UI testlerinin de geçtiğinden emin olun

## Pull Request (PR) Gönderme

1. PR açmadan önce değişikliklerinizi test edin
2. PR'nizde ne değiştirdiğinizi açıklayın
3. Eğer bir hata düzeltiyorsanız, ilgili issue numarasını belirtin
4. PR'nizin incelenmesi için bekleyin, yorumları dikkate alın ve gerekirse değişiklikler yapın

## Sürüm Numaralandırma

Proje [Anlamsal Sürüm Numaralandırma](https://semver.org/lang/tr/) sistemini kullanır:

- **MAJOR**: Geriye uyumlu olmayan API değişiklikleri
- **MINOR**: Geriye uyumlu yeni işlevler
- **PATCH**: Geriye uyumlu hata düzeltmeleri

## İletişim

Herhangi bir sorunuz veya öneriniz varsa, GitHub Issues kullanabilir veya doğrudan proje sorumlusuyla iletişime geçebilirsiniz. 