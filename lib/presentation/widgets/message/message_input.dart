import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../data/models/message_model.dart';
import '../../../data/services/storage_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import 'reply_preview.dart';

class MessageInput extends StatefulWidget {
  final Function(String, String?) onSendMessage;
  final Function(bool) onTypingChanged;
  final MessageModel? replyTo;
  final VoidCallback? onCancelReply;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    required this.onTypingChanged,
    this.replyTo,
    this.onCancelReply,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
  bool _isTyping = false;
  bool _isUploading = false;
  Timer? _typingTimer;

  void _handleTyping() {
    if (!_isTyping) {
      _isTyping = true;
      widget.onTypingChanged(true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingChanged(false);
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text, widget.replyTo?.id);
      _controller.clear();
      widget.onCancelReply?.call();
      
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingChanged(false);
        _typingTimer?.cancel();
      }
    }
  }

  Future<void> _pickAndSendMedia(ImageSource source) async {
    final picked = await _imagePicker.pickImage(source: source);
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final file = File(picked.path);
      final url = await StorageService.uploadImage(file, 'messages');
      
      final messageProvider = context.read<MessageProvider>();
      await messageProvider.sendMessage(
        senderId: context.read<AuthProvider>().currentUser!.uid,
        type: MessageType.image,
        mediaUrls: [url],
        replyToId: widget.replyTo?.id,
      );
      widget.onCancelReply?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendMedia(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendMedia(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.replyTo != null)
          ReplyPreview(
            replyTo: widget.replyTo!,
            onCancel: widget.onCancelReply!,
          ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: _isUploading 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                onPressed: _isUploading ? null : _showMediaOptions,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (_) => _handleTyping(),
                  decoration: const InputDecoration(
                    hintText: 'Mesaj yaz...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}