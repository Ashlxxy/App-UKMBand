import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/song_artwork.dart';
import 'admin_song_editor_screen.dart';

class AdminSongsScreen extends StatefulWidget {
  const AdminSongsScreen({super.key});

  @override
  State<AdminSongsScreen> createState() => _AdminSongsScreenState();
}

class _AdminSongsScreenState extends State<AdminSongsScreen> {
  List<Song>? _songs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      final api = context.read<ApiService>();
      final songs = await api.fetchSongs();
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _deleteSong(Song song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Lagu'),
        content: Text('Apakah Anda yakin ingin menghapus lagu "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.accentHot)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      setState(() => _isLoading = true);
      await context.read<ApiService>().deleteSong(song.id);
      await _loadSongs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lagu berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _openEditor([Song? song]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminSongEditorScreen(song: song)),
    ).then((_) => _loadSongs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Lagu'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        child: const Icon(Icons.add_rounded),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs == null || _songs!.isEmpty
              ? const Center(child: Text('Belum ada lagu', style: TextStyle(color: AppColors.muted)))
              : RefreshIndicator(
                  onRefresh: _loadSongs,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _songs!.length,
                    separatorBuilder: (context, index) => const Divider(color: AppColors.line, height: 1),
                    itemBuilder: (context, index) {
                      final song = _songs![index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: SongArtwork(
                          source: song.displayCover,
                          size: 48,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(song.artist, style: const TextStyle(color: AppColors.muted)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: AppColors.muted),
                              onPressed: () => _openEditor(song),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: AppColors.accentHot),
                              onPressed: () => _deleteSong(song),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
