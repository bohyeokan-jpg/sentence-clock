// Regenerates the app's launcher icon (legacy + Android 12+ adaptive
// foreground, both size sets) from a single composition: a clean analog
// clock face — hands set to 10:10, the conventional "clock icon" pose —
// filling most of the icon, using the same bold ink/background swap as
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
  const legacyScale = 0.82; // clock diameter as a fraction of the canvas (opaque background)
  const foregroundScale = 0.54; // stays inside the ~66/108dp adaptive-icon safe zone

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

/// One clean analog clock face, centered on the canvas. `scale` sets the
/// clock's diameter as a fraction of the canvas.
void _drawComposition(img.Image icon, double cx, double cy, double canvas, double scale) {
  final clockR = canvas * scale / 2;

  // Face: a solid ink rounded square (matching ClockShape.square — the
  // shape currently applied on the main screen — rather than a circle) so
  // the face reads as its own shape against the cream background, with
  // cream hands cut into it. Corner radius follows the same 0.22-of-half-
  // width ratio AnalogClockPainter uses for ClockShape.square.
  _fillRoundedRect(icon, cx, cy, clockR * 2, clockR * 2, clockR * 0.22, _ink);

  // Four cardinal tick marks (12/3/6/9) for a classic clock-face read,
  // rather than a bare disc with just two hands. Deliberately much bolder
  // than the in-app dial's ticks — those are tuned for a ~260px on-screen
  // face, this has to still register at a 48px launcher icon.
  for (final tickAngle in [0.0, 90.0, 180.0, 270.0]) {
    final a = tickAngle * math.pi / 180;
    final outer = clockR * 0.86;
    final inner = clockR * 0.62;
    final x0 = cx + inner * math.sin(a), y0 = cy - inner * math.cos(a);
    final x1 = cx + outer * math.sin(a), y1 = cy - outer * math.cos(a);
    _thickLine(icon, x0, y0, x1, y1, clockR * 0.10, _cream);
  }

  void hand(double angleDeg, double lengthFrac, double widthFrac, Rgb color) {
    final a = angleDeg * math.pi / 180;
    final length = clockR * lengthFrac;
    final ex = cx + length * math.sin(a);
    final ey = cy - length * math.cos(a);
    _thickLine(icon, cx, cy, ex, ey, math.max(1, clockR * widthFrac), color);
  }

  // Hands set to 10:10 — the conventional "clock icon" pose, symmetric and
  // legible even at launcher-icon size.
  hand(305.0, 0.54, 0.075, _cream); // hour -> 10
  hand(60.0, 0.74, 0.052, _cream); // minute -> 2
  _fillCircle(icon, cx, cy, clockR * 0.09, _gold);
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
