import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../model/quote.dart';

/// Loads the local quote pool and picks one quote per minute for the given
/// time-of-day category. Unlike a "stays the same all day" pick, this pool
/// is meant to refresh every minute (see the main screen's "1분마다 새
/// 문장" copy) — [quoteFor] should only be called again once the minute
/// (or category) actually changes, which the view model is responsible for.
class MessageRepository {
  static const _assetPath = 'assets/messages/messages.json';

  Map<String, List<Quote>>? _byCategory;
  final _random = Random();

  Future<Map<String, List<Quote>>> _loadPool() async {
    final cached = _byCategory;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final categories = decoded['categories'] as Map<String, dynamic>;

    final grouped = <String, List<Quote>>{};
    categories.forEach((category, entries) {
      grouped[category] = (entries as List)
          .map((e) => Quote.fromJson(e as Map<String, dynamic>))
          .toList();
    });
    _byCategory = grouped;
    return grouped;
  }

  /// Returns a quote for [category], avoiding an immediate repeat of
  /// [previous] when the pool has more than one candidate.
  Future<Quote?> quoteFor(String category, {Quote? previous}) async {
    final pool = await _loadPool();
    final candidates = pool[category];
    if (candidates == null || candidates.isEmpty) return null;
    if (candidates.length == 1) return candidates.first;

    Quote chosen;
    do {
      chosen = candidates[_random.nextInt(candidates.length)];
    } while (chosen.text == previous?.text);
    return chosen;
  }
}
