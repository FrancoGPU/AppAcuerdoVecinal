/// Role assigned to an authenticated or demo user inside a condominium.
enum RolUsuario {
  vecino,
  administrador;

  static RolUsuario fromName(String? value) {
    return RolUsuario.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RolUsuario.vecino,
    );
  }
}

/// Profile representing either a Neighbor (associated with an apartment)
/// or an Administrator managing the building bylaws and residents.
class PerfilUsuario {
  const PerfilUsuario({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.departamento,
    required this.condominioId,
    this.esModoDemo = false,
  });

  final String id;
  final String email;
  final String nombre;
  final RolUsuario rol;
  final String departamento;
  final String condominioId;
  final bool esModoDemo;

  bool get esAdmin => rol == RolUsuario.administrador;

  String get etiquetaVisible => esAdmin
      ? '$nombre (Administración)'
      : departamento.isNotEmpty
          ? '$departamento • $nombre'
          : nombre;

  PerfilUsuario copyWith({
    String? id,
    String? email,
    String? nombre,
    RolUsuario? rol,
    String? departamento,
    String? condominioId,
    bool? esModoDemo,
  }) {
    return PerfilUsuario(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      departamento: departamento ?? this.departamento,
      condominioId: condominioId ?? this.condominioId,
      esModoDemo: esModoDemo ?? this.esModoDemo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nombre': nombre,
        'rol': rol.name,
        'departamento': departamento,
        'condominioId': condominioId,
        'esModoDemo': esModoDemo,
      };

  factory PerfilUsuario.fromJson(Map<String, dynamic> json) {
    return PerfilUsuario(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      rol: RolUsuario.fromName(json['rol'] as String?),
      departamento: json['departamento'] as String? ?? '',
      condominioId: json['condominioId'] as String? ?? '',
      esModoDemo: json['esModoDemo'] as bool? ?? false,
    );
  }

  factory PerfilUsuario.fromSupabaseMap(Map<String, dynamic> map) {
    return PerfilUsuario(
      id: map['id']?.toString() ?? '',
      email: map['email'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      rol: RolUsuario.fromName(map['rol'] as String?),
      departamento: map['departamento'] as String? ?? '',
      condominioId: map['condominio_id']?.toString() ?? '',
      esModoDemo: false,
    );
  }
}
