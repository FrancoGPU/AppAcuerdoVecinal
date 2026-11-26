/// Residential building or condominium entity owning bylaws and neighbors.
class CondominioModel {
  const CondominioModel({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.codigoInvitacion,
    required this.adminId,
    required this.fechaCreacion,
  });

  final String id;
  final String nombre;
  final String direccion;
  final String codigoInvitacion;
  final String adminId;
  final DateTime fechaCreacion;

  CondominioModel copyWith({
    String? id,
    String? nombre,
    String? direccion,
    String? codigoInvitacion,
    String? adminId,
    DateTime? fechaCreacion,
  }) {
    return CondominioModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      codigoInvitacion: codigoInvitacion ?? this.codigoInvitacion,
      adminId: adminId ?? this.adminId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'direccion': direccion,
        'codigoInvitacion': codigoInvitacion,
        'adminId': adminId,
        'fechaCreacion': fechaCreacion.toIso8601String(),
      };

  factory CondominioModel.fromJson(Map<String, dynamic> json) {
    return CondominioModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      codigoInvitacion: json['codigoInvitacion'] as String? ?? '',
      adminId: json['adminId'] as String? ?? '',
      fechaCreacion:
          DateTime.tryParse(json['fechaCreacion'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  factory CondominioModel.fromSupabaseMap(Map<String, dynamic> map) {
    return CondominioModel(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      codigoInvitacion: map['codigo_invitacion'] as String? ?? '',
      adminId: map['admin_id']?.toString() ?? '',
      fechaCreacion:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
