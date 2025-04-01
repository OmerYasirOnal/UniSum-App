# Veri Modelleri Dokümantasyonu

Bu dosya, UniSum iOS uygulamasında kullanılan veri modellerinin belgelendirmesini içerir.

## User (Kullanıcı)

Kullanıcı bilgilerini tutan model.

```swift
struct User {
    var id: Int
    var email: String
    var university: String?
    var department: String?
}
```

## Term (Dönem)

Akademik dönem bilgilerini içeren model.

```swift
struct Term: Identifiable, Decodable, Encodable {
    var id: Int
    var user_id: Int
    var class_level: String
    var term_number: Int
    var gpa: Double?
    var createdAt: String?
    var updatedAt: String?
}
```

## Course (Ders)

Ders bilgilerini içeren model.

```swift
struct Course: Identifiable, Decodable, Encodable {
    var id: Int
    var term_id: Int
    var user_id: Int
    var name: String
    var credits: Int
    var average: Double?
    var gpa: Double?
    var letterGrade: String?
    var createdAt: String?
    var updatedAt: String?
}
```

## Grade (Not)

Ders notlarını içeren model.

```swift
struct Grade: Identifiable, Decodable, Encodable {
    var id: Int
    var course_id: Int
    var grade_type: String
    var score: Double
    var weight: Double
    var createdAt: String?
    var updatedAt: String?
}
```

## GradeScale (Not Ölçeği)

Özelleştirilebilir not ölçeği modelidir. Harf notlarının puan aralıklarını tanımlar.

```swift
struct GradeScale: Identifiable, Decodable, Encodable {
    var id: Int
    var user_id: Int
    var name: String
    var scale: [GradePoint]
    var is_default: Bool
    var createdAt: String?
    var updatedAt: String?
}

struct GradePoint: Identifiable, Decodable, Encodable {
    var id: UUID = UUID()
    var letterGrade: String
    var minScore: Double
    var maxScore: Double
    var gradePoint: Double
}
```

## Model İlişkileri

Modeller arasında şu ilişkiler bulunmaktadır:

1. Her **Kullanıcı** (User) birden fazla **Dönem** (Term) oluşturabilir
2. Her **Dönem** (Term) birden fazla **Ders** (Course) içerebilir
3. Her **Ders** (Course) birden fazla **Not** (Grade) içerebilir
4. Her **Kullanıcı** (User) birden fazla **Not Ölçeği** (GradeScale) tanımlayabilir

## Veri Akışı

Uygulama içerisinde veriler şu şekilde akar:

1. Kullanıcı giriş yaptığında **User** bilgileri alınır
2. Ana sayfada **Term** listesi gösterilir
3. Bir dönem seçildiğinde, o döneme ait **Course** listesi gösterilir
4. Bir ders seçildiğinde, o derse ait **Grade** listesi gösterilir
5. **GradeScale** not hesaplamalarında kullanılır ve ayarlar kısmından yönetilebilir 