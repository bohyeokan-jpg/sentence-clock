import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/time_state.dart';
import '../model/quote.dart';
import '../repository/message_repository.dart';

class QuoteState {
  final String category;
  final Quote quote;
  const QuoteState({required this.category, required this.quote});
}

/// Picks a quote for the current time-of-day category and re-picks whenever
/// the minute changes, matching the main screen's "1분마다 새 문장" promise.
class QuoteNotifier extends AsyncNotifier<QuoteState> {
  final _repo = MessageRepository();
  Timer? _timer;
  int? _lastMinute;

  @override
  Future<QuoteState> build() async {
    ref.onDispose(() => _timer?.cancel());
    final initial = await _pick();
    _scheduleTicker();
    return initial;
  }

  Future<QuoteState> _pick({Quote? previous}) async {
    final now = DateTime.now();
    final category = TimeState.categoryFor(now);
    _lastMinute = now.minute;
    final quote = await _repo.quoteFor(category, previous: previous) ??
        const Quote(text: '오늘의 문장을 준비하고 있어요.', book: '', author: '');
    return QuoteState(category: category, quote: quote);
  }

  void _scheduleTicker() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final now = DateTime.now();
      if (_lastMinute != now.minute) {
        final previous = state.value?.quote;
        state = AsyncData(await _pick(previous: previous));
      }
    });
  }
}

final quoteProvider = AsyncNotifierProvider<QuoteNotifier, QuoteState>(QuoteNotifier.new);
