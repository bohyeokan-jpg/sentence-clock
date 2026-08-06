class Quote {
  final String text;
  final String book;
  final String author;

  const Quote({required this.text, required this.book, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        text: json['text'] as String,
        book: json['book'] as String,
        author: json['author'] as String,
      );

  /// `『책』 — 저자` for literary quotes, `— 저자` for proverbs/sayings with
  /// no book, or null for unattributed original lines (감성문구).
  String? get attribution {
    if (book.isNotEmpty) return '『$book』 — $author';
    if (author.isNotEmpty) return '— $author';
    return null;
  }
}
