import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../firebase_config.dart';
import '../models/app_user.dart';
import '../models/history_entry.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../models/song_comment.dart';
import 'api_service.dart';

class FirebaseBackendService {
  FirebaseBackendService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const List<Map<String, dynamic>> _seedSongs = [
    {
      'id': 1,
      'title': 'Prisoner',
      'artist': 'Secrets',
      'description':
          'Lagu ini menggambarkan perasaan terkurung oleh pikiran dan rahasia yang selama ini dipendam.',
      'cover_path': 'assets/img/c5.jpg',
      'file_path': 'assets/songs/Prisoner.wav',
      'plays': 120,
      'likes': 45,
      'comments_count': 0,
    },
    {
      'id': 2,
      'title': 'Strangled',
      'artist': 'Dystopia',
      'description':
          'Sebuah lagu bernuansa intens tentang tekanan, kekacauan, dan rasa tercekik oleh keadaan.',
      'cover_path': 'assets/img/c3.jpg',
      'file_path': 'assets/songs/Dystopia.wav',
      'plays': 200,
      'likes': 90,
      'comments_count': 0,
    },
    {
      'id': 3,
      'title': 'New World',
      'artist': 'The Overtrain',
      'description':
          'Lagu ini bercerita tentang perjalanan menuju perubahan dan awal yang baru.',
      'cover_path': 'assets/img/c7.jpg',
      'file_path': 'assets/songs/The Overtrain.wav',
      'plays': 180,
      'likes': 75,
      'comments_count': 0,
    },
    {
      'id': 4,
      'title': 'Langit Kelabu',
      'artist': 'The Harper',
      'description':
          'Lagu ini membawa suasana sendu dan melankolis, seperti langit mendung yang mencerminkan hati.',
      'cover_path': 'assets/img/c6.jpg',
      'file_path': 'assets/songs/The Harper.wav',
      'plays': 110,
      'likes': 55,
      'comments_count': 0,
    },
    {
      'id': 5,
      'title': 'Form',
      'artist': 'Coral',
      'description':
          'Sebuah lagu reflektif tentang pencarian jati diri dan proses perubahan dalam hidup.',
      'cover_path': 'assets/img/c2.jpg',
      'file_path': 'assets/songs/Coral.wav',
      'plays': 85,
      'likes': 30,
      'comments_count': 0,
    },
    {
      'id': 6,
      'title': 'Au Revoir',
      'artist': 'Elisya',
      'description':
          'Lagu ini menggambarkan perpisahan yang lembut namun penuh makna.',
      'cover_path': 'assets/img/c4.jpg',
      'file_path': 'assets/songs/Elisya.wav',
      'plays': 150,
      'likes': 60,
      'comments_count': 0,
    },
    {
      'id': 7,
      'title': 'Lust',
      'artist': "Bachelor's Thrill",
      'description':
          'Lagu penuh energi tentang hasrat, ketertarikan, dan dorongan emosi yang kuat.',
      'cover_path': 'assets/img/c1.jpg',
      'file_path': 'assets/songs/Lust.wav',
      'plays': 120,
      'likes': 45,
      'comments_count': 0,
    },
  ];

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _songs =>
      _firestore.collection('songs');
  CollectionReference<Map<String, dynamic>> get _playlists =>
      _firestore.collection('playlists');
  CollectionReference<Map<String, dynamic>> get _histories =>
      _firestore.collection('histories');
  CollectionReference<Map<String, dynamic>> get _likes =>
      _firestore.collection('likes');
  CollectionReference<Map<String, dynamic>> get _comments =>
      _firestore.collection('comments');

  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw ApiException(
        'Sesi Firebase tidak tersedia. Silakan login kembali.',
      );
    }
    return user;
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (password != passwordConfirmation) {
      throw ApiException('Konfirmasi kata sandi tidak cocok.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name.trim());
      final appUser = await _upsertUser(user, name: name.trim());
      return AuthResult(token: _tokenFor(user.uid), user: appUser);
    } on FirebaseAuthException catch (error) {
      throw ApiException(_authMessage(error));
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      final appUser = await _upsertUser(user);
      return AuthResult(token: _tokenFor(user.uid), user: appUser);
    } on FirebaseAuthException catch (error) {
      throw ApiException(_authMessage(error));
    }
  }

  Future<AuthResult> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb && FirebaseConfig.googleClientId.isNotEmpty
            ? FirebaseConfig.googleClientId
            : null,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw ApiException('Login dengan Google dibatalkan.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      final appUser = await _upsertUser(user);
      return AuthResult(token: _tokenFor(user.uid), user: appUser);
    } on FirebaseAuthException catch (error) {
      throw ApiException(_authMessage(error));
    } catch (error) {
      if (error.toString().contains('canceled') || error.toString().contains('cancelled')) {
        throw ApiException('Login dengan Google dibatalkan.');
      }
      throw ApiException('Gagal login dengan Google: $error');
    }
  }

  Future<AppUser> fetchMe() async {
    return _upsertUser(_currentUser);
  }

  Future<List<AppUser>> fetchUsers({String? query}) async {
    final snapshot = await _users.orderBy('name').get();
    final q = query?.trim().toLowerCase();

    return snapshot.docs
        .map(_userFromDoc)
        .where((user) {
          if (q == null || q.isEmpty) return true;
          return user.name.toLowerCase().contains(q) ||
              user.email.toLowerCase().contains(q);
        })
        .toList();
  }

  Future<void> logout() {
    return _auth.signOut();
  }

  Future<AppUser> updateProfile({
    required String name,
    required String email,
    String? avatarPath,
  }) async {
    final user = _currentUser;

    try {
      if (email.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(email.trim());
      }
      if (name.trim() != user.displayName) {
        await user.updateDisplayName(name.trim());
      }

      final doc = _users.doc(user.uid);
      final updates = {
        'id': _stableIntId(user.uid),
        'uid': user.uid,
        'name': name.trim(),
        'email': email.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      await doc.set(updates, SetOptions(merge: true));

      return _userFromDoc(await doc.get());
    } on FirebaseAuthException catch (error) {
      throw ApiException(_authMessage(error));
    }
  }

  Future<List<Song>> fetchSongs({String? query}) async {
    await _ensureSeedSongs();
    final snapshot = await _songs.orderBy('id').get();
    final likedIds = await _likedSongIds();
    final q = query?.trim().toLowerCase();

    return snapshot.docs
        .map((doc) => _songFromDoc(doc, likedIds: likedIds))
        .where((song) {
          if (q == null || q.isEmpty) {
            return true;
          }
          return song.title.toLowerCase().contains(q) ||
              song.artist.toLowerCase().contains(q);
        })
        .toList();
  }

  Future<List<Playlist>> fetchPlaylists() async {
    final user = _currentUser;
    final songsById = await _songsById();
    final snapshot = await _playlists
        .where('user_uid', isEqualTo: user.uid)
        .get();
    final playlists = snapshot.docs
        .map((doc) => _playlistFromDoc(doc, songsById: songsById))
        .toList();

    playlists.sort((a, b) => b.id.compareTo(a.id));
    return playlists;
  }

  Future<Playlist> createPlaylist(String name) async {
    final user = _currentUser;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ApiException('Nama playlist tidak boleh kosong.');
    }

    final id = _newIntId();
    final doc = _playlists.doc(id.toString());
    await doc.set({
      'id': id,
      'user_uid': user.uid,
      'user_id': _stableIntId(user.uid),
      'name': trimmed,
      'song_ids': <int>[],
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return (await fetchPlaylists()).firstWhere((item) => item.id == id);
  }

  Future<Playlist> renamePlaylist({
    required int playlistId,
    required String name,
  }) async {
    await _playlistDoc(
      playlistId,
    ).update({'name': name.trim(), 'updated_at': FieldValue.serverTimestamp()});
    return (await fetchPlaylists()).firstWhere((item) => item.id == playlistId);
  }

  Future<Playlist> togglePlaylistSong({
    required int playlistId,
    required int songId,
  }) async {
    final doc = _playlistDoc(playlistId);
    final snapshot = await doc.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw ApiException('Playlist Firebase tidak ditemukan.');
    }

    final songIds = _intList(data['song_ids']);
    if (songIds.contains(songId)) {
      songIds.remove(songId);
    } else {
      songIds.add(songId);
    }

    await doc.update({
      'song_ids': songIds,
      'updated_at': FieldValue.serverTimestamp(),
    });
    return (await fetchPlaylists()).firstWhere((item) => item.id == playlistId);
  }

  Future<Playlist> removePlaylistSong({
    required int playlistId,
    required int songId,
  }) async {
    await _playlistDoc(playlistId).update({
      'song_ids': FieldValue.arrayRemove([songId]),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return (await fetchPlaylists()).firstWhere((item) => item.id == playlistId);
  }

  Future<void> deletePlaylist(int playlistId) {
    return _playlistDoc(playlistId).delete();
  }

  Future<List<HistoryEntry>> fetchHistory() async {
    final user = _currentUser;
    final songsById = await _songsById();
    final snapshot = await _histories
        .where('user_uid', isEqualTo: user.uid)
        .get();
    final entries = snapshot.docs.map((doc) {
      final data = _normalized(doc.data());
      final songId = _intValue(data['song_id']);
      return HistoryEntry.fromJson({...data, 'song': songsById[songId]});
    }).toList();

    entries.sort((a, b) {
      final left = a.playedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.playedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return entries;
  }

  Future<void> recordPlay(int songId) async {
    final user = _currentUser;
    await _histories.doc('${user.uid}_$songId').set({
      'id': _stableIntId('${user.uid}_$songId'),
      'user_uid': user.uid,
      'user_id': _stableIntId(user.uid),
      'song_id': songId,
      'played_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _songs.doc(songId.toString()).set({
      'plays': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<LikeResult> toggleLike(int songId) async {
    final user = _currentUser;
    final likeDoc = _likes.doc('${user.uid}_$songId');
    final songDoc = _songs.doc(songId.toString());
    var status = 'liked';

    await _firestore.runTransaction((transaction) async {
      final likeSnapshot = await transaction.get(likeDoc);
      if (likeSnapshot.exists) {
        transaction.delete(likeDoc);
        transaction.update(songDoc, {'likes': FieldValue.increment(-1)});
        status = 'unliked';
      } else {
        transaction.set(likeDoc, {
          'user_uid': user.uid,
          'user_id': _stableIntId(user.uid),
          'song_id': songId,
          'created_at': FieldValue.serverTimestamp(),
        });
        transaction.set(songDoc, {
          'likes': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    });

    final songSnapshot = await songDoc.get();
    final likes = _intValue(songSnapshot.data()?['likes']);
    return LikeResult(status: status, likes: likes);
  }

  Future<List<SongComment>> fetchComments(int songId) async {
    final snapshot = await _comments.where('song_id', isEqualTo: songId).get();
    final rows = snapshot.docs
        .map(
          (doc) =>
              _normalized({'id': _intValue(doc.data()['id']), ...doc.data()}),
        )
        .toList();
    final parents = rows.where((row) => row['parent_id'] == null).toList()
      ..sort(
        (a, b) =>
            b['created_at'].toString().compareTo(a['created_at'].toString()),
      );

    return parents.map((parent) {
      final replies =
          rows.where((row) => row['parent_id'] == parent['id']).toList()..sort(
            (a, b) => a['created_at'].toString().compareTo(
              b['created_at'].toString(),
            ),
          );
      return SongComment.fromJson({...parent, 'replies': replies});
    }).toList();
  }

  Future<SongComment> storeComment({
    required int songId,
    required String content,
    int? parentId,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ApiException('Komentar tidak boleh kosong.');
    }

    final user = await fetchMe();
    final id = _newIntId();
    final doc = _comments.doc(id.toString());
    final payload = {
      'id': id,
      'user_uid': _currentUser.uid,
      'user_id': user.id,
      'song_id': songId,
      'parent_id': parentId,
      'user_name': user.name,
      'content': trimmed,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    await doc.set(payload);
    await _songs.doc(songId.toString()).set({
      'comments_count': FieldValue.increment(1),
    }, SetOptions(merge: true));

    return SongComment.fromJson({
      ..._normalized(payload),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'replies': <Map<String, dynamic>>[],
    });
  }

  Future<SongComment> updateComment({
    required int commentId,
    required String content,
  }) async {
    final doc = _comments.doc(commentId.toString());
    final snapshot = await doc.get();
    final data = snapshot.data();
    if (data == null) {
      throw ApiException('Komentar Firebase tidak ditemukan.');
    }
    _assertCommentOwner(data);
    await doc.update({
      'content': content.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return SongComment.fromJson({
      ..._normalized(data),
      'content': content.trim(),
      'replies': <Map<String, dynamic>>[],
    });
  }

  Future<void> deleteComment(int commentId) async {
    final doc = _comments.doc(commentId.toString());
    final snapshot = await doc.get();
    final data = snapshot.data();
    if (data == null) {
      return;
    }
    _assertCommentOwner(data);
    final songId = _intValue(data['song_id']);

    final replies = await _comments
        .where('parent_id', isEqualTo: commentId)
        .get();
    final batch = _firestore.batch();
    batch.delete(doc);
    for (final reply in replies.docs) {
      batch.delete(reply.reference);
    }
    batch.set(_songs.doc(songId.toString()), {
      'comments_count': FieldValue.increment(-(replies.docs.length + 1)),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<Map<String, dynamic>> fetchAdminStats() async {
    await _ensureSeedSongs();
    final songs = await _songs.get();
    final users = await _users.get();

    var totalPlays = 0;
    var totalLikes = 0;
    for (final doc in songs.docs) {
      totalPlays += _intValue(doc.data()['plays']);
      totalLikes += _intValue(doc.data()['likes']);
    }

    return {
      'total_listeners': totalPlays,
      'total_likes': totalLikes,
      'total_songs': songs.docs.length,
      'total_users': users.docs.length,
    };
  }

  Future<Song> createSong({
    required String title,
    required String artist,
    required String description,
    String? coverPath,
    String? filePath,
  }) async {
    final id = _newIntId();
    final payload = {
      'id': id,
      'title': title.trim(),
      'artist': artist.trim(),
      'description': description.trim(),
      'cover_path': coverPath ?? 'assets/img/c1.jpg',
      'file_path': filePath ?? 'assets/songs/Prisoner.wav',
      'plays': 0,
      'likes': 0,
      'comments_count': 0,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    await _songs.doc(id.toString()).set(payload);
    return Song.fromJson(_normalized(payload));
  }

  Future<Song> updateSong({
    required int id,
    String? title,
    String? artist,
    String? description,
    String? coverPath,
    String? filePath,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (title != null) updates['title'] = title.trim();
    if (artist != null) updates['artist'] = artist.trim();
    if (description != null) updates['description'] = description.trim();
    if (coverPath != null) updates['cover_path'] = coverPath;
    if (filePath != null) updates['file_path'] = filePath;
    await _songs.doc(id.toString()).update(updates);
    return _songFromDoc(await _songs.doc(id.toString()).get());
  }

  Future<void> deleteSong(int id) async {
    await _songs.doc(id.toString()).delete();
  }

  Future<AppUser> _upsertUser(User user, {String? name}) async {
    final doc = _users.doc(user.uid);
    final snapshot = await doc.get();
    final resolvedName = name?.trim().isNotEmpty == true
        ? name!.trim()
        : user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.email?.split('@').first ?? 'Anggota UKM';

    if (!snapshot.exists) {
      await doc.set({
        'id': _stableIntId(user.uid),
        'uid': user.uid,
        'name': resolvedName,
        'email': user.email ?? '',
        'role': user.email == 'admin@ukmband.telkom' ? 'admin' : 'user',
        'avatar_url': user.photoURL,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return _userFromDoc(await doc.get());
    }

    final updates = {
      'name': resolvedName,
      'email': user.email ?? '',
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (user.email == 'admin@ukmband.telkom') {
      updates['role'] = 'admin';
    }
    if (user.photoURL != null) {
      updates['avatar_url'] = user.photoURL!;
    }
    await doc.set(updates, SetOptions(merge: true));
    return _userFromDoc(await doc.get());
  }

  AppUser _userFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw ApiException('User Firebase tidak ditemukan.');
    }
    return AppUser.fromJson(_normalized(data));
  }

  Song _songFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    Set<int> likedIds = const {},
  }) {
    final data = doc.data();
    if (data == null) {
      throw ApiException('Lagu Firebase tidak ditemukan.');
    }
    final normalized = _normalized(data);
    normalized['is_liked'] = likedIds.contains(_intValue(normalized['id']));
    return Song.fromJson(normalized);
  }

  Playlist _playlistFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required Map<int, Map<String, dynamic>> songsById,
  }) {
    final data = _normalized(doc.data() ?? {});
    final songIds = _intList(data['song_ids']);
    return Playlist.fromJson({
      ...data,
      'songs': songIds
          .where((songId) => songsById.containsKey(songId))
          .map((songId) => songsById[songId]!)
          .toList(),
    });
  }

  DocumentReference<Map<String, dynamic>> _playlistDoc(int playlistId) {
    return _playlists.doc(playlistId.toString());
  }

  Future<Map<int, Map<String, dynamic>>> _songsById() async {
    await _ensureSeedSongs();
    final likedIds = await _likedSongIds();
    final snapshot = await _songs.get();
    return {
      for (final doc in snapshot.docs)
        _intValue(doc.data()['id']): _normalized({
          ...doc.data(),
          'is_liked': likedIds.contains(_intValue(doc.data()['id'])),
        }),
    };
  }

  Future<Set<int>> _likedSongIds() async {
    final user = _currentUser;
    final snapshot = await _likes.where('user_uid', isEqualTo: user.uid).get();
    return snapshot.docs.map((doc) => _intValue(doc.data()['song_id'])).toSet();
  }

  Future<void> _ensureSeedSongs() async {
    final existing = await _songs.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }
    final batch = _firestore.batch();
    for (final song in _seedSongs) {
      batch.set(_songs.doc(song['id'].toString()), {
        ...song,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  void _assertCommentOwner(Map<String, dynamic> data) {
    if (data['user_uid'] != _currentUser.uid) {
      throw ApiException('Tidak diizinkan mengubah komentar ini.');
    }
  }

  Map<String, dynamic> _normalized(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      return MapEntry(key, value);
    });
  }

  List<int> _intList(dynamic value) {
    if (value is! List) {
      return [];
    }
    return value.map(_intValue).where((id) => id > 0).toList();
  }

  int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _stableIntId(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = 0x1fffffff & (hash + codeUnit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash == 0 ? 1 : hash;
  }

  int _newIntId() => DateTime.now().microsecondsSinceEpoch;

  String _tokenFor(String uid) => 'firebase:$uid';

  String _authMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'requires-recent-login':
        return 'Silakan login ulang sebelum mengubah email.';
      default:
        return error.message ?? 'Terjadi kesalahan Firebase.';
    }
  }
}
