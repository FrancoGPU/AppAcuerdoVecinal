/// Phase 2 stub model prepared for the AI Mediator chatbot integration.
class MensajeChatModel {
  const MensajeChatModel({
    required this.id,
    required this.negociacionId,
    required this.texto,
    required this.esUsuario,
    required this.fecha,
  });

  final String id;
  final String negociacionId;
  final String texto;
  final bool esUsuario;
  final DateTime fecha;

  Map<String, dynamic> toJson() => {
        'id': id,
        'negociacionId': negociacionId,
        'texto': texto,
        'esUsuario': esUsuario,
        'fecha': fecha.toIso8601String(),
      };

  factory MensajeChatModel.fromJson(Map<String, dynamic> json) {
    return MensajeChatModel(
      id: json['id'] as String? ?? '',
      negociacionId: json['negociacionId'] as String? ?? '',
      texto: json['texto'] as String? ?? '',
      esUsuario: json['esUsuario'] as bool? ?? true,
      fecha: DateTime.tryParse(json['fecha'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
