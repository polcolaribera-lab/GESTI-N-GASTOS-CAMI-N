class ExpenseAttachment {
  const ExpenseAttachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.size,
  });

  final String id;
  final String name;
  final String mimeType;
  final int size;

  bool get isImage => mimeType.startsWith('image/');

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'mimeType': mimeType,
    'size': size,
  };

  factory ExpenseAttachment.fromJson(Map<String, dynamic> json) {
    return ExpenseAttachment(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Documento',
      mimeType: json['mimeType'] as String? ?? 'application/octet-stream',
      size: (json['size'] as num? ?? 0).toInt(),
    );
  }
}
