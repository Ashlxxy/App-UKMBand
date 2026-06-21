import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/song.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminSongEditorScreen extends StatefulWidget {
  final Song? song;

  const AdminSongEditorScreen({super.key, this.song});

  @override
  State<AdminSongEditorScreen> createState() => _AdminSongEditorScreenState();
}

class _AdminSongEditorScreenState extends State<AdminSongEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _artistCtrl;
  late TextEditingController _descCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.song?.title ?? '');
    _artistCtrl = TextEditingController(text: widget.song?.artist ?? '');
    _descCtrl = TextEditingController(text: widget.song?.description ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      if (widget.song == null) {
        await api.createSong(
          title: _titleCtrl.text,
          artist: _artistCtrl.text,
          description: _descCtrl.text,
        );
      } else {
        await api.updateSong(
          id: widget.song!.id,
          title: _titleCtrl.text,
          artist: _artistCtrl.text,
          description: _descCtrl.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.song == null ? 'Lagu berhasil ditambahkan' : 'Lagu berhasil diperbarui',
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.song != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Lagu' : 'Tambah Lagu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Judul Lagu',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Judul tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _artistCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Artis / Band',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Artis tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentHot,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
