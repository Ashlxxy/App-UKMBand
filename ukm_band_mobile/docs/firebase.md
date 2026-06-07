# Firebase Mobile Backend

Flutter app dapat memakai Firebase sebagai backend alternatif selain mode lokal
dan Laravel API. Mode Firebase aktif hanya jika app dijalankan dengan
`--dart-define=USE_FIREBASE=true`.

## Layanan Firebase yang Dipakai

- Firebase Auth: login, register, logout, dan sesi user.
- Cloud Firestore: data user, lagu, playlist, riwayat putar, like, dan komentar.
- Firebase Storage tidak dipakai karena layanan tersebut berbayar.

## Bentuk Source Implementasi

Source Firebase dibuat terpisah supaya backend Laravel dan mode lokal tetap
aman. File yang berhubungan langsung dengan Firebase:

- `lib/firebase_config.dart`: membaca konfigurasi Firebase dari `dart-define`.
- `lib/main.dart`: menjalankan `Firebase.initializeApp()` hanya saat
  `USE_FIREBASE=true`.
- `lib/services/api_service.dart`: memilih backend aktif, antara mode lokal,
  Laravel REST API, atau Firebase.
- `lib/services/firebase_backend_service.dart`: operasi Firebase Auth dan
  Firestore.
- `pubspec.yaml`: dependency `firebase_core`, `firebase_auth`,
  dan `cloud_firestore`.

Visual source dan struktur Firebase juga tersedia di:

- `docs/firebase/source_map.svg`
- `docs/firebase/mobile_firebase_flow.svg`
- `docs/firebase/firestore_structure.svg`

## Menjalankan dengan Firebase

Isi nilai Firebase dari project Firebase kamu:

```bash
flutter run ^
  --dart-define=USE_FIREBASE=true ^
  --dart-define=FIREBASE_API_KEY=your-api-key ^
  --dart-define=FIREBASE_APP_ID=your-app-id ^
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id ^
  --dart-define=FIREBASE_PROJECT_ID=your-project-id
```

Kalau `USE_FIREBASE` tidak diaktifkan, app tetap memakai mode lama:
`LOCAL_FIRST=true` dan data lokal `SharedPreferences`.

## Struktur Data Firestore

## Status Integrasi Data Mobile

| Area Data | Status Firebase | Collection / Layanan |
| :--- | :--- | :--- |
| Akun dan sesi user | Terintegrasi | Firebase Auth |
| Profil user mobile | Terintegrasi | Cloud Firestore `users` |
| Data lagu mobile | Terintegrasi | Cloud Firestore `songs` |
| Playlist user | Terintegrasi | Cloud Firestore `playlists` |
| Riwayat lagu diputar | Terintegrasi | Cloud Firestore `histories` |
| Like lagu | Terintegrasi | Cloud Firestore `likes` |
| Komentar dan reply | Terintegrasi | Cloud Firestore `comments` |
| Upload file avatar, cover, audio | Tidak memakai Firebase | Storage sengaja tidak dipakai karena berbayar |
| Web portal dan backend Laravel | Tidak dipindahkan ke Firebase | Tetap memakai Laravel dan database backend |

Visual contoh Firebase Console tersedia di
`docs/firebase/firebase_console_collections.svg`.

### `users/{uid}`

Data profil user yang terhubung ke Firebase Auth.

```json
{
  "id": 123,
  "uid": "firebase-auth-uid",
  "name": "Nama User",
  "email": "user@email.com",
  "role": "user",
  "created_at": "serverTimestamp",
  "updated_at": "serverTimestamp"
}
```

### `songs/{songId}`

Data lagu yang tampil di home, search, detail, admin, like, history, dan playlist.

```json
{
  "id": 1,
  "title": "Prisoner",
  "artist": "Secrets",
  "description": "Deskripsi lagu",
  "cover_path": "assets/img/c5.jpg",
  "file_path": "assets/songs/Prisoner.wav",
  "plays": 120,
  "likes": 45,
  "comments_count": 0
}
```

Jika collection `songs` masih kosong, app otomatis seed lagu bawaan dari asset.

### `playlists/{playlistId}`

Playlist milik user.

```json
{
  "id": 123,
  "user_uid": "firebase-auth-uid",
  "user_id": 456,
  "name": "Latihan",
  "song_ids": [1, 2, 3],
  "created_at": "serverTimestamp",
  "updated_at": "serverTimestamp"
}
```

### `histories/{uid_songId}`

Riwayat lagu yang pernah diputar user. Saat lagu diputar, `plays` di `songs`
juga bertambah.

```json
{
  "id": 123,
  "user_uid": "firebase-auth-uid",
  "user_id": 456,
  "song_id": 1,
  "played_at": "serverTimestamp"
}
```

### `likes/{uid_songId}`

Status like per user per lagu. Saat user like atau unlike, angka `likes` di
`songs` ikut di-update.

```json
{
  "user_uid": "firebase-auth-uid",
  "user_id": 456,
  "song_id": 1,
  "created_at": "serverTimestamp"
}
```

### `comments/{commentId}`

Komentar dan reply lagu. Reply memakai `parent_id`.

```json
{
  "id": 123,
  "user_uid": "firebase-auth-uid",
  "user_id": 456,
  "song_id": 1,
  "parent_id": null,
  "user_name": "Nama User",
  "content": "Komentar",
  "created_at": "serverTimestamp",
  "updated_at": "serverTimestamp"
}
```

## Alur Data

1. User register/login lewat Firebase Auth.
2. App membuat atau memperbarui dokumen `users/{uid}`.
3. Home/search mengambil lagu dari `songs`.
4. Saat lagu diputar, app menulis `histories/{uid_songId}` dan menaikkan
   `songs.plays`.
5. Saat like, app membuat atau menghapus `likes/{uid_songId}` dan mengubah
   `songs.likes`.
6. Playlist menyimpan daftar `song_ids` di `playlists`.
7. Komentar tersimpan di `comments`, sedangkan jumlah komentar tersimpan di
   `songs.comments_count`.
8. File upload tidak dikirim ke Firebase Storage. Cover dan audio tetap memakai
   path lokal atau asset path yang disimpan sebagai metadata di Firestore.

## Catatan Query

Query Firestore dibuat sederhana supaya setup awal tidak perlu composite index
manual. Data playlist, history, dan komentar difilter dari Firestore, lalu
diurutkan di aplikasi Flutter. Kalau data sudah sangat besar, bagian ini bisa
diubah lagi ke query `orderBy` dengan composite index Firestore.
