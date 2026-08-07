// Regenerates the app's launcher icon (legacy + Android 12+ adaptive
// foreground, both size sets) from a single composition: a small clock
// above two short "lines of text" — the app's own layout (clock, then a
// quote) distilled into a mark, using the same bold ink/background swap as
// AppThemePalette.clockFace / clockDialInk in lib/model/app_theme.dart, so
// the icon and the in-app clock face read as the same idea.
//
// Run with: dart run tool/generate_icon.dart
// Writes directly into android/app/src/main/res/mipmap-*/ — there's no
// separate "install" step, this *is* the source of truth for those PNGs.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

typedef Rgb = ({int r, int g, int b});

// Cream theme palette (the app's default), from lib/model/app_theme.dart.
const _cream = (r: 0xF6, g: 0xF1, b: 0xE7); // background / dial ink
const _ink = (r: 0x2B, g: 0x26, b: 0x20); // clock face fill
const _gold = (r: 0x8A, g: 0x64, b: 0x38); // accent, darkened for small-size contrast

const _resRoot = 'android/app/src/main/res';

const _legacySizes = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

const _foregroundSizes = {
  'mipmap-mdpi': 108,
  'mipmap-hdpi': 162,
  'mipmap-xhdpi': 216,
  'mipmap-xxhdpi': 324,
  'mipmap-xxxhdpi': 432,
};

// Rendered at 4x and downsampled on the way out, since this package draws
// with hard pixel edges (no built-in anti-aliasing) — supersampling is what
// keeps the disc and rounded corners smooth instead of jagged.
const _supersample = 4;

void main() {
  const legacyScale = 1.7; // fills most of the square (opaque background)
  const foregroundScale = 1.15; // stays inside the ~66/108dp adaptive-icon safe zone

  for (final entry in _legacySizes.entries) {
    final icon = _render(entry.value, legacyScale, transparent: false);
    _write(icon, entry.key, 'ic_launcher.png');
  }
  for (final entry in _foregroundSizes.entries) {
    final icon = _render(entry.value, foregroundScale, transparent: true);
    _write(icon, entry.key, 'ic_launcher_foreground.png');
  }

  // ignore: avoid_print
  print('Wrote launcher icons to $_resRoot/mipmap-*/');
}

img.Image _render(int sizePx, double scale, {required bool transparent}) {
  final size = sizePx * _supersample;
  final icon = img.Image(width: size, height: size, numChannels: 4);
  if (transparent) {
    img.fill(icon, color: img.ColorRgba8(0, 0, 0, 0));
  } else {
    img.fill(icon, color: img.ColorRgba8(_cream.r, _cream.g, _cream.b, 255));
  }
  _drawComposition(icon, size / 2, size / 2, size.toDouble(), scale);
  return img.copyResize(icon, width: sizePx, height: sizePx, interpolation: img.Interpolation.average);
}

void _write(img.Image icon, String densityDir, String fileName) {
  final dir = Directory('$_resRoot/$densityDir')..createSync(recursive: true);
  File('${dir.path}/$fileName').writeAsBytesSync(img.encodePng(icon));
}

/// A small clock above two short "lines of text". The whole group is
/// centered so its vertical midpoint sits exactly at 50% of the canvas
/// (`cy`); `cx` is untouched, so the horizontal position is always the
/// canvas's own center.
void _drawComposition(img.Image icon, double cx, double cy, double canvas, double scale) {
  final s = canvas * scale;

  final clockR = s * 0.135;
  final gapToBars = s * 0.075;
  final barH = s * 0.042;
  final barGap = s * 0.032;
  const widths = [0.28, 0.16];

  final totalH = clockR * 2 + gapToBars + widths.length * barH + (widths.length - 1) * barGap;
  final top = cy - totalH / 2;
  final clockCy = top + clockR;

  // Clock: a solid ink disc so the face reads as its own shape against the
  // cream background, with cream hands cut into it.
  _fillCircle(icon, cx, clockCy, clockR, _ink);

  void hand(double angleDeg, double lengthFrac, double widthFrac, Rgb color) {
    final a = angleDeg * math.pi / 180;
    final length = clockR * lengthFrac;
    final ex = cx + length * math.sin(a);
    final ey = clockCy - length * math.cos(a);
    _thickLine(icon, cx, clockCy, ex, ey, math.max(1, s * widthFrac), color);
  }

  hand(305.0, 0.50, 0.058, _cream); // hour -> 10
  hand(60.0, 0.70, 0.040, _cream); // minute -> 2
  _fillCircle(icon, cx, clockCy, s * 0.044, _gold);

  // Two lines of "text" (a quote), below the clock.
  var y = clockCy + clockR + gapToBars;
  for (final wFrac in widths) {
    final bw = s * wFrac;
    _fillRoundedRect(icon, cx, y + barH / 2, bw, barH, barH / 2, _gold);
    y += barH + barGap;
  }
}

void _setPx(img.Image icon, int x, int y, Rgb c) {
  if (x < 0 || y < 0 || x >= icon.width || y >= icon.height) return;
  icon.setPixelRgba(x, y, c.r, c.g, c.b, 255);
}

void _fillCircle(img.Image icon, double cx, double cy, double r, Rgb color) {
  final x0 = (cx - r).floor(), x1 = (cx + r).ceil();
  final y0 = (cy - r).floor(), y1 = (cy + r).ceil();
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final dx = x - cx, dy = y - cy;
      if (dx * dx + dy * dy <= r * r) _setPx(icon, x, y, color);
    }
  }
}

void _fillRoundedRect(img.Image icon, double cx, double cy, double w, double h, double radius, Rgb color) {
  final x0 = (cx - w / 2).floor(), x1 = (cx + w / 2).ceil();
  final y0 = (cy - h / 2).floor(), y1 = (cy + h / 2).ceil();
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final dx = (x - cx).abs(), dy = (y - cy).abs();
      if (dx > w / 2 || dy > h / 2) continue;
      final ax = math.max(dx - (w / 2 - radius), 0.0);
      final ay = math.max(dy - (h / 2 - radius), 0.0);
      if (ax * ax + ay * ay <= radius * radius) _setPx(icon, x, y, color);
    }
  }
}

void _thickLine(img.Image icon, double x0, double y0, double x1, double y1, double width, Rgb color) {
  final steps = (math.max((x1 - x0).abs(), (y1 - y0).abs()) * 2).ceil().clamp(1, 4000);
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    _fillCircle(icon, x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, width / 2, color);
  }
}
