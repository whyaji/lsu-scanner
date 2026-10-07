enum FormCompletionSuggestionType {
  email('email'),
  whatsapp('whatsapp');

  const FormCompletionSuggestionType(this.value);

  final String value;

  String get label => switch (this) {
    email => 'Email',
    whatsapp => 'Nomor WhatsApp',
  };
}

class FormCompletionSuggestion {
  const FormCompletionSuggestion({
    required this.id,
    required this.type,
    required this.value,
    required this.updatedAt,
  });

  final int id;
  final FormCompletionSuggestionType type;
  final String value;
  final DateTime updatedAt;

  factory FormCompletionSuggestion.fromRow(Map<String, Object?> row) {
    final type = FormCompletionSuggestionType.values.firstWhere(
      (item) => item.value == row['type'],
    );
    return FormCompletionSuggestion(
      id: row['id'] as int,
      type: type,
      value: row['value'] as String,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
