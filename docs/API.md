# UniSum API Entegrasyonu

Bu dokümantasyon, UniSum iOS uygulamasının backend API'si ile nasıl iletişim kurduğunu açıklar.

## API URL

Varsayılan olarak, uygulama şu API endpoint'ini kullanır:

```
https://unisum.duckdns.org
```

## Kimlik Doğrulama

### Giriş

```
POST /auth/login
```

**İstek:**
```json
{
  "email": "kullanici@example.com",
  "password": "sifre123"
}
```

**Yanıt:**
```json
{
  "token": "jwt_token_here",
  "refreshToken": "refresh_token_here",
  "user": {
    "id": 1,
    "email": "kullanici@example.com",
    "university": "Örnek Üniversite",
    "department": "Bilgisayar Mühendisliği"
  }
}
```

### Kayıt

```
POST /auth/signup
```

**İstek:**
```json
{
  "email": "yeni_kullanici@example.com",
  "password": "guclu_sifre123",
  "university": "Örnek Üniversite",
  "department": "Bilgisayar Mühendisliği"
}
```

**Yanıt:**
```json
{
  "success": true,
  "message": "verification_email_sent",
  "verificationLink": "https://example.com/verify?token=token_here"
}
```

## Dönemler

### Dönemler Listesi

```
GET /terms/my-terms
```

**Header:**
```
Authorization: Bearer jwt_token_here
```

**Yanıt:**
```json
[
  {
    "id": 1,
    "user_id": 1,
    "class_level": "3",
    "term_number": 1,
    "gpa": 3.5,
    "createdAt": "2024-01-01T12:00:00.000Z",
    "updatedAt": "2024-01-01T12:00:00.000Z"
  }
]
```

### Yeni Dönem

```
POST /terms
```

**Header:**
```
Authorization: Bearer jwt_token_here
```

**İstek:**
```json
{
  "user_id": 1,
  "class_level": "3",
  "term_number": 2
}
```

## Dersler

### Dersler Listesi

```
GET /terms/:termId/courses
```

**Header:**
```
Authorization: Bearer jwt_token_here
```

**Yanıt:**
```json
[
  {
    "id": 1,
    "term_id": 1,
    "user_id": 1,
    "name": "Veri Yapıları",
    "credits": 4,
    "average": 85.5,
    "gpa": 3.5,
    "letterGrade": "BA",
    "createdAt": "2024-01-01T12:00:00.000Z",
    "updatedAt": "2024-01-01T12:00:00.000Z"
  }
]
```

### Yeni Ders

```
POST /terms/:termId/courses
```

**Header:**
```
Authorization: Bearer jwt_token_here
```

**İstek:**
```json
{
  "name": "Algoritma Analizi",
  "credits": 3,
  "term_id": 1,
  "user_id": 1
}
```

## Notlar

### Ders Notları Listesi

```
GET /grades/courses/:courseId
```

**Header:**
```
Authorization: Bearer jwt_token_here
```

**Yanıt:**
```json
[
  {
    "id": 1,
    "course_id": 1,
    "grade_type": "Exam",
    "score": 90,
    "weight": 40,
    "createdAt": "2024-01-01T12:00:00.000Z",
    "updatedAt": "2024-01-01T12:00:00.000Z"
  }
]
```

### Yeni Not

```
POST /grades
```

**Header:**
```
Authorization: Bearer jwt_token_here
```

**İstek:**
```json
{
  "course_id": 1,
  "grade_type": "Exam",
  "score": 85,
  "weight": 30
}
```

## GPA Hesaplama

### Genel GPA

```
GET /gpa
```

**Header:**
```
Authorization: Bearer jwt_token_here
```

**Yanıt:**
```json
{
  "gpa": 3.42
}
```

### Dönem GPA

```
GET /gpa/terms/:termId
```

**Header:**
```
Authorization: Bearer jwt_token_here
```

**Yanıt:**
```json
{
  "gpa": 3.5,
  "totalCredits": 16,
  "courseDetails": [
    {
      "courseId": 1,
      "credits": 4,
      "average": 85.5,
      "gpa": 3.5
    }
  ]
}
```

## Hata Yanıtları

API hata durumunda aşağıdaki formatta yanıt döndürür:

```json
{
  "success": false,
  "message": "error_message_code",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

Yaygın hata kodları:
- `error_invalid_credentials`: Geçersiz kimlik bilgileri
- `error_email_not_verified`: E-posta doğrulanmamış
- `error_token_expired`: Token süresi dolmuş
- `error_weak_password`: Zayıf şifre
- `error_invalid_email_format`: Geçersiz e-posta formatı 