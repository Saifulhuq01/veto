import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/veto_colors.dart';
import '../../../core/widgets/glass_button.dart';

/// Generates a shareable focus card image and shares via system share sheet.
class ShareCardGenerator extends ConsumerStatefulWidget {
  const ShareCardGenerator({
    super.key,
    required this.focusMinutes,
    required this.streakCount,
    required this.profileName,
  });

  final int focusMinutes;
  final int streakCount;
  final String profileName;

  static Future<void> show(
    BuildContext context, {
    required int focusMinutes,
    required int streakCount,
    required String profileName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => ShareCardGenerator(
        focusMinutes: focusMinutes,
        streakCount: streakCount,
        profileName: profileName,
      ),
    );
  }

  @override
  ConsumerState<ShareCardGenerator> createState() =>
      _ShareCardGeneratorState();
}

class _ShareCardGeneratorState extends ConsumerState<ShareCardGenerator> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareCard() async {
    setState(() => _isSharing = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/veto_focus_card.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'I completed ${widget.focusMinutes} minutes of deep focus with Veto! 🔥 ${widget.streakCount}-day streak.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: VetoColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFA05050A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: VetoColors.glassBorder, width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'SHARE YOUR FOCUS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 20),

          // Preview card
          Center(
            child: RepaintBoundary(
              key: _cardKey,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A0A14),
                      Color(0xFF131328),
                      Color(0xFF0A0A14),
                    ],
                  ),
                  border: Border.all(
                    color: VetoColors.secondary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          VetoColors.orbIndigo.withValues(alpha: 0.2),
                      blurRadius: 32,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            VetoColors.secondary,
                            VetoColors.orbIndigo,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: VetoColors.secondary
                                .withValues(alpha: 0.3),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'VETO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: VetoColors.secondary,
                        letterSpacing: 4.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${widget.focusMinutes}',
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Text(
                      'MINUTES OF DEEP FOCUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MiniStat(
                            label: 'PROFILE',
                            value: widget.profileName),
                        const SizedBox(width: 24),
                        _MiniStat(
                            label: 'STREAK',
                            value: '${widget.streakCount} days'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Focus. Protect. Achieve.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.3),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          GlassButton(
            label: _isSharing ? 'Sharing...' : 'Share Card',
            icon: Icons.share,
            onPressed: _isSharing ? null : _shareCard,
            isExpanded: true,
          ),
          const SizedBox(height: 12),
          GlassButton(
            label: 'Close',
            variant: GlassButtonVariant.secondary,
            onPressed: () => Navigator.pop(context),
            isExpanded: true,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
