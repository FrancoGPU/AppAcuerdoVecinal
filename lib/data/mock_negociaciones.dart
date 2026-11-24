import '../core/constants/reglamento_data.dart';
import '../models/condicion_model.dart';
import '../models/negociacion_model.dart';

/// Generates initial realistic seed cases for first launch and demo reset.
List<NegociacionModel> generarNegociacionesDemo() {
  final ahora = DateTime.now();

  return [
    NegociacionModel(
      id: 'demo-caso-1',
      titulo: 'Volumen de música y ensayos nocturnos',
      categoria: 'Ruido',
      descripcionProblema:
          'Durante las últimas dos semanas se han escuchado ensayos musicales después de las 10:30 p.m., afectando el descanso en los dormitorios colindantes.',
      dptoSolicitante: kDpto301,
      dptoReceptor: kDpto402,
      esAnonimo: false,
      interesSolicitante:
          'Descansar adecuadamente porque inicio turno laboral a las 5:30 a.m.',
      interesReceptor:
          'Practicar guitarra acústica sin perder mi espacio recreativo los fines de semana.',
      estadoGeneral: EstadoNegociacion.enNegociacion,
      fechaCreacion: ahora.subtract(const Duration(days: 2)),
      condiciones: const [
        CondicionModel(
          id: 'demo-1-cond-1',
          tituloClausula: 'Horario de silencio entre semana',
          descripcionPropuesta:
              'Reducir el volumen y suspender ensayos musicales de lunes a viernes a partir de las 10:00 p.m.',
          criterioObjetivo: 'Art. 14 - Reglamento Interno (Ruidos Molestos)',
          argumentoPersuasivo:
              'Respetar el horario de descanso entre semana protege la salud laboral sin impedir que ensayes en horas de la tarde.',
          autorUltimaOferta: kDpto301,
          estado: EstadoCondicion.pendiente,
        ),
        CondicionModel(
          id: 'demo-1-cond-2',
          tituloClausula: 'Ensayos musicales los sábados',
          descripcionPropuesta:
              'Prohibir totalmente cualquier práctica de guitarra o música durante todo el día sábado.',
          criterioObjetivo:
              'Criterio de Beneficio Mutuo / Buena Convivencia',
          argumentoPersuasivo:
              'Contar con un sábado silencioso ayudaría a recuperar el sueño acumulado de la jornada laboral.',
          autorUltimaOferta: kDpto301,
          estado: EstadoCondicion.rechazada,
          motivoRechazo:
              'Los sábados por la tarde es mi único horario libre para practicar guitarra acústica; puedo comprometerme a terminar antes de las 9:30 p.m.',
        ),
      ],
    ),
    NegociacionModel(
      id: 'demo-caso-2',
      titulo: 'Uso del límite de cochera sótano 1',
      categoria: 'Cochera',
      descripcionProblema:
          'El estacionamiento contiguo presenta espacio reducido al abrir las puertas cuando uno de los vehículos queda cerca de la línea divisoria.',
      dptoSolicitante: kDpto402,
      dptoReceptor: kDpto301,
      esAnonimo: false,
      interesSolicitante:
          'Estacionar mi camioneta sin riesgo de rozar las puertas al subir con mis hijos.',
      interesReceptor:
          'Mantener un acceso cómodo para mi vehículo respetando el espacio asignado.',
      estadoGeneral: EstadoNegociacion.listoParaFirmar,
      fechaCreacion: ahora.subtract(const Duration(days: 4)),
      condiciones: [
        CondicionModel(
          id: 'demo-2-cond-1',
          tituloClausula: 'Centrado dentro de líneas amarillas',
          descripcionPropuesta:
              'Estacionar ambos vehículos dejando al menos 15 cm libres respecto a la línea divisoria central.',
          criterioObjetivo: 'Art. 22 - Reglamento Interno (Estacionamientos)',
          argumentoPersuasivo:
              'Mantener un margen fijo evita golpes accidentales de puerta y cuida la pintura de ambos autos.',
          autorUltimaOferta: kDpto402,
          estado: EstadoCondicion.aceptada,
          historial: [
            RondaHistorial(
              propuestaAnterior:
                  'Estacionar en reversa siempre pegado a la columna derecha.',
              argumentoAnterior:
                  'Dejaría más espacio al centro, aunque dificulta abrir el maletero.',
              autor: kDpto402,
              fecha: ahora.subtract(const Duration(days: 3)),
            ),
          ],
        ),
        const CondicionModel(
          id: 'demo-2-cond-2',
          tituloClausula: 'Aviso previo ante visitas temporales',
          descripcionPropuesta:
              'Comunicar con anticipación si algún vehículo de visita usará la plaza por menos de 2 horas.',
          criterioObjetivo:
              'Criterio de Beneficio Mutuo / Buena Convivencia',
          argumentoPersuasivo:
              'Una coordinación rápida evita malentendidos con conserjería y mantiene la buena relación entre vecinos.',
          autorUltimaOferta: kDpto301,
          estado: EstadoCondicion.aceptada,
        ),
      ],
    ),
  ];
}
