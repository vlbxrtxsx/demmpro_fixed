import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'firebase_options.dart';

// Definir los colores de la marca
class AppColors {
  static const Color primary = Color(0xFF105890);
  static const Color secondary = Color(0xFF0A68AA);
  static const Color dark = Color(0xFF0A3559);
  static const Color darkBlue = Color(0xFF07396B);
  static const Color success = Color(0xFF28a745);
  static const Color danger = Color(0xFFdc3545);
  static const Color warning = Color(0xFFffc107);
  static const Color info = Color(0xFF17a2b8);
}

// Modelos de datos actualizados para Firebase
class Usuario {
  final String? id; // Cambiar a String para Firebase
  final String dni;
  final String nombres;
  final String? password;
  final DateTime? createdAt;

  Usuario({
    this.id,
    required this.dni,
    required this.nombres,
    this.password,
    this.createdAt,
  });

  bool get isAdmin => password != null && password!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'dni': dni,
      'nombres': nombres,
      'password': password,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Usuario(
      id: docId ?? map['id'],
      dni: map['dni'] ?? '',
      nombres: map['nombres'] ?? '',
      password: map['password'],
      createdAt: map['created_at'] != null
          ? (map['created_at'] is Timestamp
              ? (map['created_at'] as Timestamp).toDate()
              : DateTime.tryParse(map['created_at']))
          : null,
    );
  }
}

class Planta {
  final String? id;
  final String nombre;
  final DateTime? createdAt;

  Planta({
    this.id,
    required this.nombre,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Planta.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Planta(
      id: docId ?? map['id'],
      nombre: map['nombre'] ?? '',
      createdAt: map['created_at'] != null
          ? (map['created_at'] is Timestamp
              ? (map['created_at'] as Timestamp).toDate()
              : DateTime.tryParse(map['created_at']))
          : null,
    );
  }
}

class Supervisor {
  final String? id;
  final String dni;
  final String nombre;
  final String? password;
  final DateTime? createdAt;

  Supervisor({
    this.id,
    required this.dni,
    required this.nombre,
    this.password,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'dni': dni,
      'nombre': nombre,
      'password': password,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Supervisor.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Supervisor(
      id: docId ?? map['id'],
      dni: map['dni'] ?? '',
      nombre: map['nombre'] ?? '',
      password: map['password'],
      createdAt: map['created_at'] != null
          ? (map['created_at'] is Timestamp
              ? (map['created_at'] as Timestamp).toDate()
              : DateTime.tryParse(map['created_at']))
          : null,
    );
  }
}

class Asistencia {
  final String? id;
  final String usuarioId;
  final String plantaId;
  final String supervisorId;
  final String fecha;
  final String? horaIngreso;
  final String? horaSalida;
  final double? ubicacionEntradaLat;
  final double? ubicacionEntradaLng;
  final String? direccionEntrada;
  final double? ubicacionSalidaLat;
  final double? ubicacionSalidaLng;
  final String? direccionSalida;
  final String? batchId;
  final DateTime? createdAt;

  Asistencia({
    this.id,
    required this.usuarioId,
    required this.plantaId,
    required this.supervisorId,
    required this.fecha,
    this.horaIngreso,
    this.horaSalida,
    this.ubicacionEntradaLat,
    this.ubicacionEntradaLng,
    this.direccionEntrada,
    this.ubicacionSalidaLat,
    this.ubicacionSalidaLng,
    this.direccionSalida,
    this.batchId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'usuario_id': usuarioId,
      'planta_id': plantaId,
      'supervisor_id': supervisorId,
      'fecha': fecha,
      'hora_ingreso': horaIngreso,
      'hora_salida': horaSalida,
      'ubicacion_entrada_lat': ubicacionEntradaLat,
      'ubicacion_entrada_lng': ubicacionEntradaLng,
      'direccion_entrada': direccionEntrada,
      'ubicacion_salida_lat': ubicacionSalidaLat,
      'ubicacion_salida_lng': ubicacionSalidaLng,
      'direccion_salida': direccionSalida,
      'batch_id': batchId,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory Asistencia.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Asistencia(
      id: docId ?? map['id'],
      usuarioId: map['usuario_id'] ?? '',
      plantaId: map['planta_id'] ?? '',
      supervisorId: map['supervisor_id'] ?? '',
      fecha: map['fecha'] ?? '',
      horaIngreso: map['hora_ingreso'],
      horaSalida: map['hora_salida'],
      ubicacionEntradaLat: map['ubicacion_entrada_lat']?.toDouble(),
      ubicacionEntradaLng: map['ubicacion_entrada_lng']?.toDouble(),
      direccionEntrada: map['direccion_entrada'],
      ubicacionSalidaLat: map['ubicacion_salida_lat']?.toDouble(),
      ubicacionSalidaLng: map['ubicacion_salida_lng']?.toDouble(),
      direccionSalida: map['direccion_salida'],
      batchId: map['batch_id'],
      createdAt: map['created_at'] != null
          ? (map['created_at'] is Timestamp
              ? (map['created_at'] as Timestamp).toDate()
              : DateTime.tryParse(map['created_at']))
          : null,
    );
  }
}

// Servicio de ubicación
class LocationService {
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Los servicios de ubicación están deshabilitados');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Permisos de ubicación denegados');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Permisos de ubicación denegados permanentemente');
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Los servicios de ubicación están deshabilitados');
        return null;
      }

      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('No se tienen permisos de ubicación');
        return null;
      }

      print('Intentando obtener ubicación...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      print('Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error obteniendo ubicación: $e');

      try {
        print('Intentando con menor precisión...');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 15),
        );
        print(
            'Ubicación con menor precisión: ${position.latitude}, ${position.longitude}');
        return position;
      } catch (e2) {
        print('Error con menor precisión: $e2');
        return null;
      }
    }
  }

  static Future<String> getAddressFromCoordinates(
      double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
      }
    } catch (e) {
      print('Error obteniendo dirección: $e');
    }
    return 'Ubicación no disponible';
  }
}

// Servicio Firebase para base de datos compartida
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      // No inicializamos Firebase aquí, solo verificamos si ya está inicializado
      try {
        // Simplemente verificamos si Firebase ya está inicializado
        Firebase.app();
        print('Firebase ya estaba inicializado');
      } catch (e) {
        print('Error verificando Firebase: $e');
        // Si no está inicializado, no hacemos nada aquí
        // La inicialización debe ocurrir solo en main()
      }
      _isInitialized = true;
    }
  }

  // USUARIOS
  static Future<String> insertUsuario(Usuario usuario) async {
    try {
      // Verificar si ya existe
      final existingUser = await _firestore
          .collection('usuarios')
          .where('dni', isEqualTo: usuario.dni)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Ya existe un usuario con este DNI');
      }

      final docRef = await _firestore.collection('usuarios').add({
        ...usuario.toMap(),
        'created_at': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Error al insertar usuario: $e');
    }
  }

  static Future<List<Usuario>> getUsuarios({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Usuario.fromMap(data, docId: doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

// Añadir stream para actualizaciones en tiempo real
  static Stream<List<Usuario>> getUsuariosStream({int limit = 100}) {
    return _firestore
        .collection('usuarios')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Usuario.fromMap(data, docId: doc.id);
      }).toList();
    });
  }

  static Future<Usuario?> getUsuarioByDni(String dni) async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('dni', isEqualTo: dni)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return Usuario.fromMap(data, docId: snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al buscar usuario: $e');
    }
  }

  static Future<Usuario?> getUsuarioByDniAndPassword(
      String dni, String password) async {
    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .where('dni', isEqualTo: dni)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return Usuario.fromMap(data, docId: snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al autenticar usuario: $e');
    }
  }

  static Future<void> deleteUsuario(String id) async {
    try {
      await _firestore.collection('usuarios').doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  // PLANTAS
  static Future<String> insertPlanta(Planta planta) async {
    try {
      final docRef = await _firestore.collection('plantas').add({
        ...planta.toMap(),
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Error al insertar planta: $e');
    }
  }

  static Future<List<Planta>> getPlantas() async {
    try {
      final snapshot = await _firestore
          .collection('plantas')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Planta.fromMap(data, docId: doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener plantas: $e');
    }
  }

// Añadir stream para actualizaciones en tiempo real
  static Stream<List<Planta>> getPlantasStream() {
    return _firestore
        .collection('plantas')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Planta.fromMap(data, docId: doc.id);
      }).toList();
    });
  }

  static Future<void> deletePlanta(String id) async {
    try {
      await _firestore.collection('plantas').doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar planta: $e');
    }
  }

  // SUPERVISORES
  static Future<String> insertSupervisor(Supervisor supervisor) async {
    try {
      final docRef = await _firestore.collection('supervisores').add({
        ...supervisor.toMap(),
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Error al insertar supervisor: $e');
    }
  }

  static Future<List<Supervisor>> getSupervisores() async {
    try {
      final snapshot = await _firestore
          .collection('supervisores')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Supervisor.fromMap(data, docId: doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener supervisores: $e');
    }
  }

// Añadir stream para actualizaciones en tiempo real
  static Stream<List<Supervisor>> getSupervisoresStream() {
    return _firestore
        .collection('supervisores')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Supervisor.fromMap(data, docId: doc.id);
      }).toList();
    });
  }

  static Future<Supervisor?> getSupervisorByDniAndPassword(
      String dni, String password) async {
    try {
      final snapshot = await _firestore
          .collection('supervisores')
          .where('dni', isEqualTo: dni)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        return Supervisor.fromMap(data, docId: snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error al autenticar supervisor: $e');
    }
  }

  static Future<void> deleteSupervisor(String id) async {
    try {
      await _firestore.collection('supervisores').doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar supervisor: $e');
    }
  }

  // ASISTENCIAS
  static Future<String> insertAsistencia(Asistencia asistencia) async {
    try {
      final docRef = await _firestore.collection('asistencias').add({
        ...asistencia.toMap(),
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Error al insertar asistencia: $e');
    }
  }

  static Future<List<String>> insertAsistenciasBatch(
      List<Asistencia> asistencias) async {
    try {
      final batch = _firestore.batch();
      final List<String> ids = [];

      for (final asistencia in asistencias) {
        final docRef = _firestore.collection('asistencias').doc();
        batch.set(docRef, {
          ...asistencia.toMap(),
          'created_at': FieldValue.serverTimestamp(),
        });
        ids.add(docRef.id);
      }

      await batch.commit();
      return ids;
    } catch (e) {
      throw Exception('Error al insertar lote de asistencias: $e');
    }
  }

  static Future<void> updateBatchSalida(
    String batchId,
    String horaSalida,
    double? ubicacionSalidaLat,
    double? ubicacionSalidaLng,
    String? direccionSalida,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('asistencias')
          .where('batch_id', isEqualTo: batchId)
          .where('hora_salida', isNull: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'hora_salida': horaSalida,
          'ubicacion_salida_lat': ubicacionSalidaLat,
          'ubicacion_salida_lng': ubicacionSalidaLng,
          'direccion_salida': direccionSalida,
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error al actualizar salida del lote: $e');
    }
  }

  static Future<void> updateAsistenciaSalidaConUbicacion(
    String asistenciaId,
    String horaSalida,
    double? ubicacionSalidaLat,
    double? ubicacionSalidaLng,
    String? direccionSalida,
  ) async {
    try {
      await _firestore.collection('asistencias').doc(asistenciaId).update({
        'hora_salida': horaSalida,
        'ubicacion_salida_lat': ubicacionSalidaLat,
        'ubicacion_salida_lng': ubicacionSalidaLng,
        'direccion_salida': direccionSalida,
      });
    } catch (e) {
      throw Exception('Error al actualizar salida: $e');
    }
  }

  // CONSULTAS COMPLEJAS
  // Método auxiliar para obtener documentos en lotes
  static Future<Map<String, Map<String, dynamic>>> _getBatchDocuments(
      String collection, List<String> ids) async {
    final Map<String, Map<String, dynamic>> result = {};

    if (ids.isEmpty) return result;

    // Firestore permite máximo 10 elementos en whereIn
    const batchSize = 10;

    for (int i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize).toList();

      final snapshot = await _firestore
          .collection(collection)
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        result[doc.id] = doc.data() as Map<String, dynamic>;
      }
    }

    return result;
  }

  // REEMPLAZA tu método getBatchesAgrupados() actual con esta versión optimizada
  static Future<List<Map<String, dynamic>>> getBatchesAgrupados() async {
    try {
      print('🔍 Iniciando getBatchesAgrupados (sin índice)...');

      // 🔧 CONSULTA SIN ÍNDICE - Solo filtro, sin orderBy
      final asistenciasSnapshot = await _firestore
          .collection('asistencias')
          .where('batch_id', isNull: false)
          .get(); // ← ELIMINAR: .orderBy('created_at', descending: true) y .limit(100)

      print('📊 Documentos encontrados: ${asistenciasSnapshot.docs.length}');

      if (asistenciasSnapshot.docs.isEmpty) {
        print('⚠️ No se encontraron documentos con batch_id');
        return [];
      }

      // 2. Recolectar IDs únicos (NO hacer consultas individuales)
      final Map<String, Map<String, dynamic>> batchesMap = {};
      final Set<String> supervisorIds = {};
      final Set<String> plantaIds = {};

      for (final doc in asistenciasSnapshot.docs) {
        final data = doc.data();
        final batchId = data['batch_id'] as String;

        supervisorIds.add(data['supervisor_id']);
        plantaIds.add(data['planta_id']);

        if (!batchesMap.containsKey(batchId)) {
          batchesMap[batchId] = {
            'batch_id': batchId,
            'supervisor_id': data['supervisor_id'],
            'planta_id': data['planta_id'],
            'fecha': data['fecha'],
            'hora_ingreso': data['hora_ingreso'],
            'hora_salida': data['hora_salida'],
            'direccion_entrada': data['direccion_entrada'],
            'direccion_salida': data['direccion_salida'],
            'total_usuarios': 0,
            'usuarios_con_salida': 0,
          };
        }

        batchesMap[batchId]!['total_usuarios'] =
            (batchesMap[batchId]!['total_usuarios'] as int) + 1;
        if (data['hora_salida'] != null) {
          batchesMap[batchId]!['usuarios_con_salida'] =
              (batchesMap[batchId]!['usuarios_con_salida'] as int) + 1;
        }
      }

      // 3. Obtener datos relacionados en LOTES (NO uno por uno)
      final supervisoresData =
          await _getBatchDocuments('supervisores', supervisorIds.toList());
      final plantasData =
          await _getBatchDocuments('plantas', plantaIds.toList());

      // 4. Construir resultado final
      final List<Map<String, dynamic>> result = [];

      for (final batch in batchesMap.values) {
        final supervisorData = supervisoresData[batch['supervisor_id']] ?? {};
        final plantaData = plantasData[batch['planta_id']] ?? {};

        result.add({
          'batch_id': batch['batch_id'],
          'supervisor_dni': supervisorData['dni'] ?? '',
          'supervisor_nombre': supervisorData['nombre'] ?? '',
          'planta_nombre': plantaData['nombre'] ?? '',
          'fecha': batch['fecha'],
          'hora_ingreso': batch['hora_ingreso'],
          'hora_salida': batch['hora_salida'],
          'direccion_entrada': batch['direccion_entrada'],
          'direccion_salida': batch['direccion_salida'],
          'total_usuarios': batch['total_usuarios'],
          'usuarios_con_salida': batch['usuarios_con_salida'],
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error al obtener lotes agrupados: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getBatchDetails(
      String batchId) async {
    try {
      final snapshot = await _firestore
          .collection('asistencias')
          .where('batch_id', isEqualTo: batchId)
          .get();

      final List<Map<String, dynamic>> result = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Obtener usuario
        final usuarioDoc = await _firestore
            .collection('usuarios')
            .doc(data['usuario_id'] as String)
            .get();
        final usuarioData = usuarioDoc.data() ?? {};

        // Obtener planta
        final plantaDoc = await _firestore
            .collection('plantas')
            .doc(data['planta_id'] as String)
            .get();
        final plantaData = plantaDoc.data() ?? {};

        // Obtener supervisor
        final supervisorDoc = await _firestore
            .collection('supervisores')
            .doc(data['supervisor_id'] as String)
            .get();
        final supervisorData = supervisorDoc.data() ?? {};

        result.add({
          'id': doc.id,
          'usuario_dni': usuarioData['dni'] ?? '',
          'usuario_nombres': usuarioData['nombres'] ?? '',
          'planta_nombre': plantaData['nombre'] ?? '',
          'supervisor_dni': supervisorData['dni'] ?? '',
          'supervisor_nombre': supervisorData['nombre'] ?? '',
          'fecha': data['fecha'],
          'hora_ingreso': data['hora_ingreso'],
          'hora_salida': data['hora_salida'],
          'ubicacion_entrada_lat': data['ubicacion_entrada_lat'],
          'ubicacion_entrada_lng': data['ubicacion_entrada_lng'],
          'direccion_entrada': data['direccion_entrada'],
          'ubicacion_salida_lat': data['ubicacion_salida_lat'],
          'ubicacion_salida_lng': data['ubicacion_salida_lng'],
          'direccion_salida': data['direccion_salida'],
          'batch_id': data['batch_id'],
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error al obtener detalles del lote: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getBatchesActivosBySupervisor(
      String supervisorId) async {
    try {
      final snapshot = await _firestore
          .collection('asistencias')
          .where('supervisor_id', isEqualTo: supervisorId)
          .where('batch_id', isNull: false)
          .where('hora_salida', isNull: true)
          .get();

      // Agrupar por batch_id
      final Map<String, Map<String, dynamic>> batchesMap = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final batchId = data['batch_id'] as String;

        if (!batchesMap.containsKey(batchId)) {
          batchesMap[batchId] = {
            'batch_id': batchId,
            'planta_id': data['planta_id'],
            'fecha': data['fecha'],
            'hora_ingreso': data['hora_ingreso'],
            'direccion_entrada': data['direccion_entrada'],
            'total_usuarios': 0,
            'usuarios_ids': <String>[],
          };
        }

        batchesMap[batchId]!['total_usuarios'] =
            (batchesMap[batchId]!['total_usuarios'] as int) + 1;
        (batchesMap[batchId]!['usuarios_ids'] as List<String>)
            .add(data['usuario_id'] as String);
      }

      // Obtener información adicional
      final List<Map<String, dynamic>> result = [];

      for (final batch in batchesMap.values) {
        // Obtener planta
        final plantaDoc = await _firestore
            .collection('plantas')
            .doc(batch['planta_id'] as String)
            .get();
        final plantaData = plantaDoc.data() ?? {};

        // Obtener usuarios
        final List<String> usuariosNombres = [];
        for (final usuarioId in batch['usuarios_ids'] as List<String>) {
          final usuarioDoc =
              await _firestore.collection('usuarios').doc(usuarioId).get();
          final usuarioData = usuarioDoc.data() ?? {};
          usuariosNombres.add(usuarioData['nombres'] ?? '');
        }

        result.add({
          'batch_id': batch['batch_id'],
          'planta_nombre': plantaData['nombre'] ?? '',
          'fecha': batch['fecha'],
          'hora_ingreso': batch['hora_ingreso'],
          'direccion_entrada': batch['direccion_entrada'],
          'total_usuarios': batch['total_usuarios'],
          'usuarios_nombres': usuariosNombres.join(', '),
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error al obtener lotes activos: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAllBatchesActivos() async {
    try {
      final snapshot = await _firestore
          .collection('asistencias')
          .where('batch_id', isNull: false)
          .where('hora_salida', isNull: true)
          .get();

      // Agrupar por batch_id
      final Map<String, Map<String, dynamic>> batchesMap = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final batchId = data['batch_id'] as String;

        if (!batchesMap.containsKey(batchId)) {
          batchesMap[batchId] = {
            'batch_id': batchId,
            'supervisor_id': data['supervisor_id'],
            'planta_id': data['planta_id'],
            'fecha': data['fecha'],
            'hora_ingreso': data['hora_ingreso'],
            'direccion_entrada': data['direccion_entrada'],
            'total_usuarios': 0,
            'usuarios_ids': <String>[],
          };
        }

        batchesMap[batchId]!['total_usuarios'] =
            (batchesMap[batchId]!['total_usuarios'] as int) + 1;
        (batchesMap[batchId]!['usuarios_ids'] as List<String>)
            .add(data['usuario_id'] as String);
      }

      // Obtener información adicional
      final List<Map<String, dynamic>> result = [];

      for (final batch in batchesMap.values) {
        // Obtener supervisor
        final supervisorDoc = await _firestore
            .collection('supervisores')
            .doc(batch['supervisor_id'] as String)
            .get();
        final supervisorData = supervisorDoc.data() ?? {};

        // Obtener planta
        final plantaDoc = await _firestore
            .collection('plantas')
            .doc(batch['planta_id'] as String)
            .get();
        final plantaData = plantaDoc.data() ?? {};

        // Obtener usuarios
        final List<String> usuariosNombres = [];
        for (final usuarioId in batch['usuarios_ids'] as List<String>) {
          final usuarioDoc =
              await _firestore.collection('usuarios').doc(usuarioId).get();
          final usuarioData = usuarioDoc.data() ?? {};
          usuariosNombres.add(usuarioData['nombres'] ?? '');
        }

        result.add({
          'batch_id': batch['batch_id'],
          'supervisor_nombre': supervisorData['nombre'] ?? '',
          'planta_nombre': plantaData['nombre'] ?? '',
          'fecha': batch['fecha'],
          'hora_ingreso': batch['hora_ingreso'],
          'direccion_entrada': batch['direccion_entrada'],
          'total_usuarios': batch['total_usuarios'],
          'usuarios_nombres': usuariosNombres.join(', '),
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error al obtener todos los lotes activos: $e');
    }
  }

  // OPTIMIZADO: getAsistenciasDetalladas
  static Future<List<Map<String, dynamic>>> getAsistenciasDetalladas(
      {int limit = 100}) async {
    try {
      // 1. Obtener asistencias con límite para rendimiento
      final asistenciasSnapshot = await _firestore
          .collection('asistencias')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      // 2. Recolectar IDs únicos (NO hacer consultas individuales)
      final Set<String> usuarioIds = {};
      final Set<String> plantaIds = {};
      final Set<String> supervisorIds = {};

      for (final doc in asistenciasSnapshot.docs) {
        final data = doc.data();
        usuarioIds.add(data['usuario_id']);
        plantaIds.add(data['planta_id']);
        supervisorIds.add(data['supervisor_id']);
      }

      // 3. Obtener datos relacionados en LOTES (NO uno por uno)
      final usuariosData =
          await _getBatchDocuments('usuarios', usuarioIds.toList());
      final plantasData =
          await _getBatchDocuments('plantas', plantaIds.toList());
      final supervisoresData =
          await _getBatchDocuments('supervisores', supervisorIds.toList());

      // 4. Construir resultado final
      final List<Map<String, dynamic>> result = [];

      for (final doc in asistenciasSnapshot.docs) {
        final data = doc.data();
        final usuarioData = usuariosData[data['usuario_id']] ?? {};
        final plantaData = plantasData[data['planta_id']] ?? {};
        final supervisorData = supervisoresData[data['supervisor_id']] ?? {};

        result.add({
          'id': doc.id,
          'usuario_dni': usuarioData['dni'] ?? '',
          'usuario_nombres': usuarioData['nombres'] ?? '',
          'planta_nombre': plantaData['nombre'] ?? '',
          'supervisor_dni': supervisorData['dni'] ?? '',
          'supervisor_nombre': supervisorData['nombre'] ?? '',
          'fecha': data['fecha'],
          'hora_ingreso': data['hora_ingreso'],
          'hora_salida': data['hora_salida'],
          'ubicacion_entrada_lat': data['ubicacion_entrada_lat'],
          'ubicacion_entrada_lng': data['ubicacion_entrada_lng'],
          'direccion_entrada': data['direccion_entrada'],
          'ubicacion_salida_lat': data['ubicacion_salida_lat'],
          'ubicacion_salida_lng': data['ubicacion_salida_lng'],
          'direccion_salida': data['direccion_salida'],
          'batch_id': data['batch_id'],
          'usuario_id': data['usuario_id'],
          'planta_id': data['planta_id'],
          'supervisor_id': data['supervisor_id'],
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error al obtener asistencias detalladas: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAsistenciasBySupervisor(
      String supervisorId) async {
    try {
      final snapshot = await _firestore
          .collection('asistencias')
          .where('supervisor_id', isEqualTo: supervisorId)
          .orderBy('created_at', descending: true)
          .get();

      final List<Map<String, dynamic>> result = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Obtener usuario
        final usuarioDoc = await _firestore
            .collection('usuarios')
            .doc(data['usuario_id'] as String)
            .get();
        final usuarioData = usuarioDoc.data() ?? {};

        // Obtener planta
        final plantaDoc = await _firestore
            .collection('plantas')
            .doc(data['planta_id'] as String)
            .get();
        final plantaData = plantaDoc.data() ?? {};

        // Obtener supervisor
        final supervisorDoc = await _firestore
            .collection('supervisores')
            .doc(data['supervisor_id'] as String)
            .get();
        final supervisorData = supervisorDoc.data() ?? {};

        result.add({
          'id': doc.id,
          'usuario_dni': usuarioData['dni'] ?? '',
          'usuario_nombres': usuarioData['nombres'] ?? '',
          'planta_nombre': plantaData['nombre'] ?? '',
          'supervisor_dni': supervisorData['dni'] ?? '',
          'supervisor_nombre': supervisorData['nombre'] ?? '',
          'fecha': data['fecha'],
          'hora_ingreso': data['hora_ingreso'],
          'hora_salida': data['hora_salida'],
          'direccion_entrada': data['direccion_entrada'],
          'direccion_salida': data['direccion_salida'],
          'batch_id': data['batch_id'],
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error al obtener asistencias por supervisor: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getAsistenciasByUsuario(
      String usuarioId) async {
    try {
      final snapshot = await _firestore
          .collection('asistencias')
          .where('usuario_id', isEqualTo: usuarioId)
          .orderBy('created_at', descending: true)
          .get();

      final List<Map<String, dynamic>> result = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Obtener usuario
        final usuarioDoc = await _firestore
            .collection('usuarios')
            .doc(data['usuario_id'] as String)
            .get();
        final usuarioData = usuarioDoc.data() ?? {};

        // Obtener planta
        final plantaDoc = await _firestore
            .collection('plantas')
            .doc(data['planta_id'] as String)
            .get();
        final plantaData = plantaDoc.data() ?? {};

        // Obtener supervisor
        final supervisorDoc = await _firestore
            .collection('supervisores')
            .doc(data['supervisor_id'] as String)
            .get();
        final supervisorData = supervisorDoc.data() ?? {};

        result.add({
          'id': doc.id,
          'usuario_dni': usuarioData['dni'] ?? '',
          'usuario_nombres': usuarioData['nombres'] ?? '',
          'planta_nombre': plantaData['nombre'] ?? '',
          'supervisor_dni': supervisorData['dni'] ?? '',
          'supervisor_nombre': supervisorData['nombre'] ?? '',
          'fecha': data['fecha'],
          'hora_ingreso': data['hora_ingreso'],
          'hora_salida': data['hora_salida'],
          'ubicacion_entrada_lat': data['ubicacion_entrada_lat'],
          'ubicacion_entrada_lng': data['ubicacion_entrada_lng'],
          'direccion_entrada': data['direccion_entrada'],
          'ubicacion_salida_lat': data['ubicacion_salida_lat'],
          'ubicacion_salida_lng': data['ubicacion_salida_lng'],
          'direccion_salida': data['direccion_salida'],
          'batch_id': data['batch_id'],
        });
      }

      return result;
    } catch (e) {
      throw Exception('Error al obtener asistencias por usuario: $e');
    }
  }

  static Future<Map<String, dynamic>?> getAsistenciaActivaByUsuario(
      String usuarioId, String fecha) async {
    try {
      final snapshot = await _firestore
          .collection('asistencias')
          .where('usuario_id', isEqualTo: usuarioId)
          .where('fecha', isEqualTo: fecha)
          .where('hora_salida', isNull: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();

        // Obtener planta
        final plantaDoc = await _firestore
            .collection('plantas')
            .doc(data['planta_id'] as String)
            .get();
        final plantaData = plantaDoc.data() ?? {};

        // Obtener supervisor
        final supervisorDoc = await _firestore
            .collection('supervisores')
            .doc(data['supervisor_id'] as String)
            .get();
        final supervisorData = supervisorDoc.data() ?? {};

        return {
          'id': snapshot.docs.first.id,
          'hora_ingreso': data['hora_ingreso'],
          'hora_salida': data['hora_salida'],
          'batch_id': data['batch_id'],
          'planta_nombre': plantaData['nombre'] ?? '',
          'supervisor_nombre': supervisorData['nombre'] ?? '',
        };
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener asistencia activa: $e');
    }
  }

  // VERIFICAR CONEXIÓN
  static Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // INICIALIZAR DATOS DE PRUEBA
  static Future<void> initializeTestData() async {
    try {
      final usuarios = await getUsuarios();
      if (usuarios.isNotEmpty) return;

      await insertUsuario(Usuario(dni: '12345678', nombres: 'Juan Pérez'));
      await insertUsuario(Usuario(dni: '87654321', nombres: 'María García'));
      await insertUsuario(Usuario(
          dni: '11111111', nombres: 'Admin Usuario', password: 'admin123'));

      await insertPlanta(Planta(nombre: 'Planta Norte'));
      await insertPlanta(Planta(nombre: 'Planta Sur'));
      await insertPlanta(Planta(nombre: 'Planta Central'));

      await insertSupervisor(Supervisor(
          dni: '98765432', nombre: 'Carlos Rodríguez', password: '1234'));
      await insertSupervisor(
          Supervisor(dni: '56789012', nombre: 'Ana López', password: '1234'));
      await insertSupervisor(Supervisor(
          dni: '34567890', nombre: 'Pedro Martínez', password: '1234'));
    } catch (e) {
      print('Error al inicializar datos de prueba: $e');
    }
  }
}

// Widget para mostrar estado de conexión
class ConnectionIndicator extends StatefulWidget {
  const ConnectionIndicator({Key? key}) : super(key: key);

  @override
  _ConnectionIndicatorState createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();

    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkConnection() async {
    final isConnected = await FirebaseService.isConnected();
    setState(() {
      _isOnline = isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Servicio para exportar a Excel
class ExcelService {
  static Future<String> exportAttendanceToExcel(
      List<Map<String, dynamic>> asistencias, String fileName) async {
    // Crear un nuevo archivo Excel
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Asistencias'];

    // Agregar encabezados
    sheet.appendRow([
      excel_lib.TextCellValue('DNI'),
      excel_lib.TextCellValue('Nombre'),
      excel_lib.TextCellValue('Planta'),
      excel_lib.TextCellValue('Supervisor'),
      excel_lib.TextCellValue('Fecha'),
      excel_lib.TextCellValue('Hora Entrada'),
      excel_lib.TextCellValue('Hora Salida'),
      excel_lib.TextCellValue('Ubicación Entrada'),
      excel_lib.TextCellValue('Ubicación Salida'),
      excel_lib.TextCellValue('Tiempo Trabajado'),
      excel_lib.TextCellValue('Lote ID')
    ]);

    // Estilo para encabezados
    final headerStyle = excel_lib.CellStyle(
      backgroundColorHex: excel_lib.ExcelColor.blue,
      fontColorHex: excel_lib.ExcelColor.white,
      bold: true,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
    );

    // Aplicar estilo a encabezados
    for (int i = 0; i < 11; i++) {
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    // Agregar datos
    for (int i = 0; i < asistencias.length; i++) {
      final record = asistencias[i];

      // Calcular tiempo trabajado
      String tiempoTrabajado = 'N/A';
      if (record['hora_ingreso'] != null && record['hora_salida'] != null) {
        tiempoTrabajado =
            _calculateWorkTime(record['hora_ingreso'], record['hora_salida']);
      }

      sheet.appendRow([
        excel_lib.TextCellValue(record['usuario_dni'] ?? ''),
        excel_lib.TextCellValue(record['usuario_nombres'] ?? ''),
        excel_lib.TextCellValue(record['planta_nombre'] ?? ''),
        excel_lib.TextCellValue(record['supervisor_nombre'] ?? ''),
        excel_lib.TextCellValue(record['fecha'] ?? ''),
        excel_lib.TextCellValue(record['hora_ingreso'] ?? 'N/A'),
        excel_lib.TextCellValue(record['hora_salida'] ?? 'N/A'),
        excel_lib.TextCellValue(record['direccion_entrada'] ?? 'N/A'),
        excel_lib.TextCellValue(record['direccion_salida'] ?? 'N/A'),
        excel_lib.TextCellValue(tiempoTrabajado),
        excel_lib.TextCellValue(record['batch_id'] ?? 'N/A')
      ]);

      // Estilo alternado para filas
      final rowStyle = excel_lib.CellStyle(
        backgroundColorHex:
            i % 2 == 0 ? excel_lib.ExcelColor.grey : excel_lib.ExcelColor.white,
      );

      for (int j = 0; j < 11; j++) {
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: j, rowIndex: i + 1))
            .cellStyle = rowStyle;
      }
    }

    // Ajustar ancho de columnas
    for (int i = 0; i < 11; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Guardar archivo
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);

    return path;
  }

  // Exportar lotes a Excel
  static Future<String> exportBatchesToExcel(
      List<Map<String, dynamic>> batches, String fileName) async {
    // Crear un nuevo archivo Excel
    final excel = excel_lib.Excel.createExcel();
    final sheet = excel['Lotes'];

    // Agregar encabezados
    sheet.appendRow([
      excel_lib.TextCellValue('ID Lote'),
      excel_lib.TextCellValue('Planta'),
      excel_lib.TextCellValue('Supervisor'),
      excel_lib.TextCellValue('Fecha'),
      excel_lib.TextCellValue('Hora Entrada'),
      excel_lib.TextCellValue('Hora Salida'),
      excel_lib.TextCellValue('Total Usuarios'),
      excel_lib.TextCellValue('Usuarios con Salida'),
      excel_lib.TextCellValue('Ubicación Entrada'),
      excel_lib.TextCellValue('Ubicación Salida')
    ]);

    // Estilo para encabezados
    final headerStyle = excel_lib.CellStyle(
      backgroundColorHex: excel_lib.ExcelColor.blue,
      fontColorHex: excel_lib.ExcelColor.white,
      bold: true,
      horizontalAlign: excel_lib.HorizontalAlign.Center,
    );

    // Aplicar estilo a encabezados
    for (int i = 0; i < 10; i++) {
      sheet
          .cell(
              excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .cellStyle = headerStyle;
    }

    // Agregar datos
    for (int i = 0; i < batches.length; i++) {
      final batch = batches[i];

      sheet.appendRow([
        excel_lib.TextCellValue(batch['batch_id'] ?? ''),
        excel_lib.TextCellValue(batch['planta_nombre'] ?? ''),
        excel_lib.TextCellValue(batch['supervisor_nombre'] ?? ''),
        excel_lib.TextCellValue(batch['fecha'] ?? ''),
        excel_lib.TextCellValue(batch['hora_ingreso'] ?? 'N/A'),
        excel_lib.TextCellValue(batch['hora_salida'] ?? 'N/A'),
        excel_lib.TextCellValue(batch['total_usuarios']?.toString() ?? '0'),
        excel_lib.TextCellValue(
            batch['usuarios_con_salida']?.toString() ?? '0'),
        excel_lib.TextCellValue(batch['direccion_entrada'] ?? 'N/A'),
        excel_lib.TextCellValue(batch['direccion_salida'] ?? 'N/A')
      ]);

      // Estilo alternado para filas
      final rowStyle = excel_lib.CellStyle(
        backgroundColorHex:
            i % 2 == 0 ? excel_lib.ExcelColor.grey : excel_lib.ExcelColor.white,
      );

      for (int j = 0; j < 10; j++) {
        sheet
            .cell(excel_lib.CellIndex.indexByColumnRow(
                columnIndex: j, rowIndex: i + 1))
            .cellStyle = rowStyle;
      }
    }

    // Ajustar ancho de columnas
    for (int i = 0; i < 10; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Guardar archivo
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(excel.encode()!);

    return path;
  }

  // Calcular tiempo trabajado
  static String _calculateWorkTime(String entrada, String salida) {
    try {
      final entradaTime = TimeOfDay(
        hour: int.parse(entrada.split(':')[0]),
        minute: int.parse(entrada.split(':')[1]),
      );
      final salidaTime = TimeOfDay(
        hour: int.parse(salida.split(':')[0]),
        minute: int.parse(salida.split(':')[1]),
      );

      final entradaMinutes = entradaTime.hour * 60 + entradaTime.minute;
      final salidaMinutes = salidaTime.hour * 60 + salidaTime.minute;

      final diffMinutes = salidaMinutes - entradaMinutes;
      final hours = diffMinutes ~/ 60;
      final minutes = diffMinutes % 60;

      return '${hours}h ${minutes}m';
    } catch (e) {
      return 'N/A';
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase solo una vez
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase inicializado correctamente en main()');
    } else {
      print('Firebase ya estaba inicializado, usando instancia existente');
    }
  } catch (e) {
    print('Error inicializando Firebase: $e');
  }

  // Inicializar datos de prueba
  await FirebaseService.initializeTestData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DEMMPRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        cardTheme: ThemeData.light().cardTheme.copyWith(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.darkBlue],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: _animation,
                child: const Text(
                  'DEMMPRO',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _animation,
                child: const Text(
                  'Sistema de Gestión de Asistencia',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'v5.0.0 - Firebase Edition',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              const ConnectionIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

// LoginScreen actualizado para usar FirebaseService
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _dniController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedRole = 'Usuario';

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final dni = _dniController.text.trim();

    if (dni.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingrese su DNI';
        _isLoading = false;
      });
      return;
    }

    if (dni.length != 8) {
      setState(() {
        _errorMessage = 'El DNI debe tener 8 dígitos';
        _isLoading = false;
      });
      return;
    }

    try {
      if (_selectedRole == 'Usuario') {
        final usuario = await FirebaseService.getUsuarioByDni(dni);
        if (usuario != null && !usuario.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(usuario: usuario),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'DNI no encontrado como usuario regular';
            _isLoading = false;
          });
        }
      } else if (_selectedRole == 'Admin') {
        final password = _passwordController.text.trim();
        if (password.isEmpty) {
          setState(() {
            _errorMessage = 'Por favor ingrese su contraseña';
            _isLoading = false;
          });
          return;
        }

        final usuario =
            await FirebaseService.getUsuarioByDniAndPassword(dni, password);
        if (usuario != null && usuario.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(usuario: usuario),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'DNI o contraseña incorrectos para administrador';
            _isLoading = false;
          });
        }
      } else if (_selectedRole == 'Supervisor') {
        final password = _passwordController.text.trim();
        if (password.isEmpty) {
          setState(() {
            _errorMessage = 'Por favor ingrese su contraseña';
            _isLoading = false;
          });
          return;
        }

        final supervisor =
            await FirebaseService.getSupervisorByDniAndPassword(dni, password);
        if (supervisor != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SupervisorDashboard(supervisor: supervisor),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'DNI o contraseña incorrectos para supervisor';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100, Colors.grey.shade200],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(
                        Icons.business,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Base de datos compartida en tiempo real',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const ConnectionIndicator(),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      items: ['Usuario', 'Supervisor', 'Admin'].map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                          _passwordController.clear();
                          _errorMessage = '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: 'DNI',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.badge),
                        counterText: '',
                      ),
                    ),
                    if (_selectedRole == 'Supervisor' ||
                        _selectedRole == 'Admin') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                      ),
                    ],
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Ingresar',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// DashboardScreen actualizado para usar FirebaseService
// REEMPLAZA tu DashboardScreen - ELIMINA la carga de datos estáticos
class DashboardScreen extends StatefulWidget {
  final Usuario usuario;

  const DashboardScreen({
    Key? key,
    required this.usuario,
  }) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ← ELIMINA ESTAS VARIABLES ESTÁTICAS:
  // List<Planta> _plantas = [];
  // List<Supervisor> _supervisores = [];
  // List<Usuario> _usuarios = [];
  // List<Map<String, dynamic>> _asistencias = [];

  @override
  void initState() {
    super.initState();
    // ← ELIMINA _loadData() - ya no es necesario
  }

  // ← ELIMINA el método _loadData() completo

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.usuario.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DEMMPRO'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          const ConnectionIndicator(),
          const SizedBox(width: 8),
          // ← ELIMINA el botón de refresh - ya no es necesario
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content:
                        const Text('¿Está seguro que desea cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            isAdmin ? AppColors.primary : AppColors.secondary,
                        child: Icon(
                          isAdmin ? Icons.admin_panel_settings : Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenido, ${widget.usuario.nombres}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'DNI: ${widget.usuario.dni}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? AppColors.primary.withOpacity(0.2)
                                    : AppColors.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isAdmin ? 'Administrador' : 'Usuario',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isAdmin
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Seleccione una opción:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildOptionCard(
                        title: 'Marcar Asistencia',
                        subtitle: 'Registrar entrada/salida',
                        icon: Icons.fingerprint,
                        color: AppColors.secondary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserView(
                                usuario: widget.usuario,
                                // ← ELIMINA plantas y supervisores - UserView los obtendrá directamente
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOptionCard(
                        title: 'Vista Admin',
                        subtitle: 'Gestión completa del sistema',
                        icon: Icons.admin_panel_settings,
                        color: AppColors.primary,
                        onTap: isAdmin
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminView(), // ← SIN PARÁMETROS
                                  ),
                                );
                              }
                            : null,
                        disabled: !isAdmin,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ← ELIMINA las estadísticas estáticas - usa StreamBuilder si las necesitas
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: disabled ? Colors.grey[300] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 60,
                color: disabled ? Colors.grey : color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: disabled ? Colors.grey : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: disabled ? Colors.grey : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              if (disabled)
                const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    'Acceso restringido',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// UserView actualizado para usar FirebaseService
// REEMPLAZA tu UserView actual - ELIMINA los parámetros y carga los datos internamente
class UserView extends StatefulWidget {
  final Usuario usuario;

  const UserView({
    Key? key,
    required this.usuario,
    // ← ELIMINA: required this.plantas,
    // ← ELIMINA: required this.supervisores,
  }) : super(key: key);

  @override
  _UserViewState createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  final _documentController = TextEditingController();
  Planta? _selectedPlanta;
  List<Supervisor> _selectedSupervisores = [];
  List<Map<String, dynamic>> _userRecords = [];
  bool _isLoading = false;
  String _currentLocation = 'Detectando ubicación...';
  Map<String, dynamic>? _activeAttendance;

  // ← AGREGAR: Variables para cargar datos dinámicamente
  List<Planta> _plantas = [];
  List<Supervisor> _supervisores = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // ← NUEVO: Cargar datos al inicializar
    _getCurrentLocation();
    _checkActiveAttendance();
  }

  // ← NUEVO: Método para cargar plantas y supervisores
  Future<void> _loadInitialData() async {
    try {
      final plantas = await FirebaseService.getPlantas();
      final supervisores = await FirebaseService.getSupervisores();

      setState(() {
        _plantas = plantas;
        _supervisores = supervisores;
        _isLoadingData = false;
        if (_plantas.isNotEmpty) {
          _selectedPlanta = _plantas.first;
        }
      });

      _loadUserRecords();
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _currentLocation = address;
        });
      } else {
        setState(() {
          _currentLocation = 'Ubicación no disponible';
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Error al obtener ubicación';
      });
    }
  }

  Future<void> _loadUserRecords() async {
    try {
      final records =
          await FirebaseService.getAsistenciasByUsuario(widget.usuario.id!);
      setState(() {
        _userRecords = records;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar registros: $e')),
      );
    }
  }

  Future<void> _checkActiveAttendance() async {
    try {
      final now = DateTime.now();
      final fecha =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final activeAttendance =
          await FirebaseService.getAsistenciaActivaByUsuario(
              widget.usuario.id!, fecha);

      setState(() {
        _activeAttendance = activeAttendance;
      });
    } catch (e) {
      print('Error checking active attendance: $e');
    }
  }

  void _toggleSupervisorSelection(Supervisor supervisor) {
    setState(() {
      if (_selectedSupervisores.contains(supervisor)) {
        _selectedSupervisores.remove(supervisor);
      } else {
        _selectedSupervisores.add(supervisor);
      }
    });
  }

  Future<void> _registerAttendance(bool isEntry) async {
    if (!isEntry && _activeAttendance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay una entrada activa para registrar la salida'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (isEntry && _activeAttendance != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya tiene una entrada registrada sin salida'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (isEntry) {
      if (_documentController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingrese un documento')),
        );
        return;
      }

      if (_selectedPlanta == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor seleccione una planta')),
        );
        return;
      }

      if (_selectedSupervisores.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor seleccione al menos un supervisor')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      String direccion = 'Ubicación no disponible';

      if (position != null) {
        direccion = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
      }

      final now = DateTime.now();
      final fecha =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final hora =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      if (isEntry) {
        // REGISTRAR ENTRADA PARA CADA SUPERVISOR SELECCIONADO
        for (Supervisor supervisor in _selectedSupervisores) {
          final asistencia = Asistencia(
            usuarioId: widget.usuario.id!,
            plantaId: _selectedPlanta!.id!,
            supervisorId: supervisor.id!,
            fecha: fecha,
            horaIngreso: hora,
            ubicacionEntradaLat: position?.latitude,
            ubicacionEntradaLng: position?.longitude,
            direccionEntrada: direccion,
          );

          await FirebaseService.insertAsistencia(asistencia);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Entrada registrada con ${_selectedSupervisores.length} supervisor(es)'),
            backgroundColor: Colors.green,
          ),
        );

        _documentController.clear();
        _selectedSupervisores.clear();
      } else {
        // REGISTRAR SALIDA CON UBICACIÓN
        await FirebaseService.updateAsistenciaSalidaConUbicacion(
            _activeAttendance!['id'],
            hora,
            position?.latitude,
            position?.longitude,
            direccion);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salida registrada con éxito'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      await _loadUserRecords();
      await _checkActiveAttendance();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAttendanceForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Registrar Entrada',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _documentController,
                      decoration: InputDecoration(
                        labelText: 'Documento',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Planta>(
                      decoration: InputDecoration(
                        labelText: 'Planta',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.business),
                      ),
                      value: _selectedPlanta,
                      items: _plantas.map((planta) {
                        return DropdownMenuItem<Planta>(
                          value: planta,
                          child: Text(planta.nombre),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedPlanta = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // SELECCIÓN MÚLTIPLE DE SUPERVISORES
                    const Text(
                      'Supervisores (puede seleccionar múltiples):',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        itemCount: _supervisores.length,
                        itemBuilder: (context, index) {
                          final supervisor = _supervisores[index];
                          final isSelected =
                              _selectedSupervisores.contains(supervisor);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setModalState(() {
                                _toggleSupervisorSelection(supervisor);
                              });
                            },
                            title: Text(
                              supervisor.nombre,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              'DNI: ${supervisor.dni}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            activeColor: AppColors.primary,
                            dense: true,
                          );
                        },
                      ),
                    ),

                    if (_selectedSupervisores.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Seleccionados: ${_selectedSupervisores.map((s) => s.nombre).join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ubicación actual:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentLocation,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                                _registerAttendance(true);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Registrar Entrada',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ← AGREGAR: Mostrar loading mientras cargan los datos
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Asistencia'),
          backgroundColor: AppColors.secondary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia'),
        backgroundColor: AppColors.secondary,
        elevation: 0,
        actions: [
          const ConnectionIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadUserRecords();
              _checkActiveAttendance();
              _getCurrentLocation();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.secondary, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            // INFORMACIÓN DEL USUARIO Y UBICACIÓN
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.secondary,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.usuario.nombres,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'DNI: ${widget.usuario.dni}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentLocation,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ESTADO ACTUAL
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: _activeAttendance != null
                    ? Colors.green[50]
                    : Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _activeAttendance != null
                                ? Icons.check_circle
                                : Icons.warning,
                            color: _activeAttendance != null
                                ? Colors.green
                                : Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _activeAttendance != null
                                ? 'Entrada Registrada'
                                : 'Sin Entrada Activa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _activeAttendance != null
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_activeAttendance != null) ...[
                        Text(
                          'Planta: ${_activeAttendance!['planta_nombre']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Supervisor: ${_activeAttendance!['supervisor_nombre']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Hora de entrada: ${_activeAttendance!['hora_ingreso']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _registerAttendance(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Registrar Salida'),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'No tiene una entrada registrada para hoy.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _showAttendanceForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Registrar Entrada'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // HISTORIAL DE ASISTENCIAS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.history, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Historial de Asistencias',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_userRecords.length} registros',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _userRecords.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay registros de asistencia',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _userRecords.length,
                                itemBuilder: (context, index) {
                                  final record = _userRecords[index];
                                  final hasExit = record['hora_salida'] != null;

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: hasExit
                                          ? Colors.green
                                          : Colors.orange,
                                      child: Icon(
                                        hasExit
                                            ? Icons.check_circle
                                            : Icons.schedule,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      'Planta: ${record['planta_nombre']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fecha: ${record['fecha']}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          'Supervisor: ${record['supervisor_nombre']}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          'Entrada: ${record['hora_ingreso']}${hasExit ? ' - Salida: ${record['hora_salida']}' : ''}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: hasExit
                                        ? const Icon(Icons.check_circle,
                                            color: Colors.green, size: 16)
                                        : const Icon(Icons.schedule,
                                            color: Colors.orange, size: 16),
                                    onTap: () {
                                      // Mostrar detalles del registro
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Detalles'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    'Fecha: ${record['fecha']}'),
                                                Text(
                                                    'Planta: ${record['planta_nombre']}'),
                                                Text(
                                                    'Supervisor: ${record['supervisor_nombre']}'),
                                                Text(
                                                    'Entrada: ${record['hora_ingreso']}'),
                                                if (hasExit)
                                                  Text(
                                                      'Salida: ${record['hora_salida']}'),
                                                const SizedBox(height: 8),
                                                Text(
                                                    'Ubicación Entrada: ${record['direccion_entrada'] ?? 'No disponible'}'),
                                                if (hasExit)
                                                  Text(
                                                      'Ubicación Salida: ${record['direccion_salida'] ?? 'No disponible'}'),
                                                if (record['batch_id'] != null)
                                                  Text(
                                                      'ID de Lote: ${record['batch_id']}'),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cerrar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupervisorDashboard extends StatefulWidget {
  final Supervisor supervisor;

  const SupervisorDashboard({Key? key, required this.supervisor})
      : super(key: key);

  @override
  _SupervisorDashboardState createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  List<Planta> _plantas = [];
  List<Usuario> _usuarios = [];
  List<Map<String, dynamic>> _asistencias = [];
  List<Map<String, dynamic>> _batchesActivos = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final plantas = await FirebaseService.getPlantas();
      final usuarios = await FirebaseService.getUsuarios();
      final asistencias = await FirebaseService.getAsistenciasDetalladas();
      final batchesActivos =
          await FirebaseService.getBatchesActivosBySupervisor(
              widget.supervisor.id!);

      setState(() {
        _plantas = plantas;
        _usuarios = usuarios;
        _asistencias = asistencias;
        _batchesActivos = batchesActivos;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Supervisor'),
        backgroundColor: AppColors.secondary,
        elevation: 0,
        actions: [
          const ConnectionIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content:
                        const Text('¿Está seguro que desea cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.secondary, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.secondary,
                        child: Icon(
                          Icons.supervisor_account,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenido, ${widget.supervisor.nombre}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'DNI: ${widget.supervisor.dni}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Supervisor',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Opciones disponibles:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  // 🔧 AGREGADO: ScrollView para evitar overflow
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildOptionCard(
                              title: 'Registrar Lotes',
                              subtitle: 'Marcar asistencia múltiple',
                              icon: Icons.group_add,
                              color: AppColors.secondary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SupervisorView(
                                      supervisor: widget.supervisor,
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildOptionCard(
                              title: 'Ver Lotes',
                              subtitle: 'Historial agrupado',
                              icon: Icons.view_list,
                              color: AppColors.primary,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SupervisorBatchView(
                                      supervisor: widget.supervisor,
                                    ),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildOptionCard(
                              title: 'Exportar Datos',
                              subtitle: 'Generar Excel de asistencias',
                              icon: Icons.file_download,
                              color: AppColors.success,
                              onTap: () => _showExportOptions(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child:
                                Container(), // Espacio vacío para mantener simetría
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // LOTES ACTIVOS
                      if (_batchesActivos.isNotEmpty) ...[
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.schedule,
                                        color: AppColors.warning),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      // 🔧 AGREGADO: Flexible para el texto
                                      child: Text(
                                        'Lotes Activos (sin salida)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _batchesActivos.length,
                                    itemBuilder: (context, index) {
                                      final batch = _batchesActivos[index];
                                      return Container(
                                        width: 200,
                                        margin:
                                            const EdgeInsets.only(right: 12),
                                        child: Card(
                                          color: Colors.orange[50],
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  batch['planta_nombre'] ??
                                                      'Sin nombre',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${batch['total_usuarios'] ?? 0} usuarios',
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                                Text(
                                                  'Entrada: ${batch['hora_ingreso'] ?? 'N/A'}',
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                                const Spacer(),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: () =>
                                                        _registrarSalidaLote(
                                                            batch['batch_id']),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.blue,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 4),
                                                    ),
                                                    child: const Text(
                                                      'Salida Lote',
                                                      style: TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 🔧 SECCIÓN DE ESTADÍSTICAS CORREGIDA
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estadísticas del día',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // 🔧 CAMBIO: Wrap en lugar de Row
                              Wrap(
                                spacing: 16.0,
                                runSpacing: 16.0,
                                alignment: WrapAlignment.spaceAround,
                                children: [
                                  _buildStatCard(
                                    title: 'Usuarios',
                                    value: _usuarios.length.toString(),
                                    icon: Icons.people,
                                    color: AppColors.primary,
                                  ),
                                  _buildStatCard(
                                    title: 'Lotes Activos',
                                    value: _batchesActivos.length.toString(),
                                    icon: Icons.schedule,
                                    color: AppColors.warning,
                                  ),
                                  _buildStatCard(
                                    title: 'Registros Hoy',
                                    value: _asistencias
                                        .where((a) =>
                                            a['fecha'] ==
                                                DateTime.now()
                                                    .toString()
                                                    .split(' ')[0] &&
                                            a['supervisor_dni'] ==
                                                widget.supervisor.dni)
                                        .length
                                        .toString(),
                                    icon: Icons.today,
                                    color: AppColors.success,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mostrar opciones de exportación
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Exportar Datos a Excel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.list_alt, color: AppColors.primary),
                title: const Text('Exportar Asistencias Individuales'),
                subtitle:
                    const Text('Todas las asistencias registradas por ti'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAttendanceData();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.group, color: AppColors.secondary),
                title: const Text('Exportar Lotes de Asistencia'),
                subtitle: const Text('Asistencias agrupadas por lotes'),
                onTap: () {
                  Navigator.pop(context);
                  _exportBatchData();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Exportar asistencias individuales
  Future<void> _exportAttendanceData() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener datos
      final asistencias = await FirebaseService.getAsistenciasBySupervisor(
          widget.supervisor.id!);

      // Generar nombre de archivo con fecha y hora
      final now = DateTime.now();
      final fileName =
          'asistencias_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';

      // Exportar a Excel
      final filePath =
          await ExcelService.exportAttendanceToExcel(asistencias, fileName);

      // Cerrar diálogo de carga
      Navigator.pop(context);

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Asistencias exportadas por ${widget.supervisor.nombre}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Archivo Excel generado y compartido correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si hay error
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar datos: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // Exportar datos de lotes
  Future<void> _exportBatchData() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener datos de lotes
      final allBatches = await FirebaseService.getBatchesAgrupados();
      final supervisorBatches = allBatches
          .where((batch) => batch['supervisor_dni'] == widget.supervisor.dni)
          .toList();

      // Generar nombre de archivo con fecha y hora
      final now = DateTime.now();
      final fileName =
          'lotes_asistencia_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';

      // Exportar a Excel
      final filePath =
          await ExcelService.exportBatchesToExcel(supervisorBatches, fileName);

      // Cerrar diálogo de carga
      Navigator.pop(context);

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Lotes de asistencia exportados por ${widget.supervisor.nombre}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Archivo Excel de lotes generado y compartido correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si hay error
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar lotes: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // Registrar salida para todo un lote
  Future<void> _registrarSalidaLote(String batchId) async {
    try {
      final position = await LocationService.getCurrentPosition();
      String direccion = 'Ubicación no disponible';

      if (position != null) {
        direccion = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
      }

      final now = DateTime.now();
      final hora =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      await FirebaseService.updateBatchSalida(
        batchId,
        hora,
        position?.latitude,
        position?.longitude,
        direccion,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salida registrada para todo el lote'),
          backgroundColor: Colors.green,
        ),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar salida: $e')),
      );
    }
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 50,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, // 🔧 AGREGADO
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, // 🔧 AGREGADO
                maxLines: 2, // 🔧 AGREGADO
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔧 MÉTODO _buildStatCard CORREGIDO
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      // 🔧 CAMBIO: SizedBox con ancho fijo
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis, // 🔧 AGREGADO
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // 🔧 AGREGADO
            maxLines: 2, // 🔧 AGREGADO
          ),
        ],
      ),
    );
  }
}

// SupervisorBatchView actualizado para usar FirebaseService
class SupervisorBatchView extends StatefulWidget {
  final Supervisor supervisor;

  const SupervisorBatchView({
    Key? key,
    required this.supervisor,
  }) : super(key: key);

  @override
  _SupervisorBatchViewState createState() => _SupervisorBatchViewState();
}

class _SupervisorBatchViewState extends State<SupervisorBatchView> {
  List<Map<String, dynamic>> _batches = [];
  bool _isLoading = true;
  String _filterStatus = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allBatches = await FirebaseService.getBatchesAgrupados();
      final supervisorBatches = allBatches
          .where((batch) => batch['supervisor_dni'] == widget.supervisor.dni)
          .toList();

      setState(() {
        _batches = supervisorBatches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar lotes: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredBatches {
    if (_filterStatus == 'Todos') {
      return _batches;
    } else if (_filterStatus == 'Activos') {
      return _batches.where((batch) => batch['hora_salida'] == null).toList();
    } else {
      return _batches.where((batch) => batch['hora_salida'] != null).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lotes de Asistencia'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          const ConnectionIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBatches,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filtrar por estado:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildFilterChip('Todos'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Activos'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Completados'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredBatches.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay lotes disponibles',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredBatches.length,
                          itemBuilder: (context, index) {
                            final batch = _filteredBatches[index];
                            final isCompleted = batch['hora_salida'] != null;

                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: isCompleted
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isCompleted
                                              ? Icons.check_circle
                                              : Icons.schedule,
                                          color: isCompleted
                                              ? Colors.green
                                              : Colors.orange,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Planta: ${batch['planta_nombre']}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isCompleted
                                                ? Colors.green
                                                : Colors.orange,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isCompleted
                                                ? 'Completado'
                                                : 'Activo',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Fecha: ${batch['fecha']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      'Entrada: ${batch['hora_ingreso']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    if (isCompleted)
                                      Text(
                                        'Salida: ${batch['hora_salida']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Total usuarios: ${batch['total_usuarios']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isCompleted)
                                      Text(
                                        'Usuarios con salida: ${batch['usuarios_con_salida']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ubicación entrada: ${batch['direccion_entrada'] ?? 'No disponible'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (isCompleted)
                                      Text(
                                        'Ubicación salida: ${batch['direccion_salida'] ?? 'No disponible'}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    BatchDetailView(
                                                  batchId: batch['batch_id'],
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.visibility),
                                          label: const Text('Ver Detalles'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                        if (!isCompleted) ...[
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _registrarSalidaLote(
                                                    batch['batch_id']),
                                            icon: const Icon(Icons.exit_to_app),
                                            label:
                                                const Text('Registrar Salida'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Registrar salida para todo un lote
  Future<void> _registrarSalidaLote(String batchId) async {
    try {
      final position = await LocationService.getCurrentPosition();
      String direccion = 'Ubicación no disponible';

      if (position != null) {
        direccion = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
      }

      final now = DateTime.now();
      final hora =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      await FirebaseService.updateBatchSalida(
        batchId,
        hora,
        position?.latitude,
        position?.longitude,
        direccion,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salida registrada para todo el lote'),
          backgroundColor: Colors.green,
        ),
      );

      _loadBatches();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar salida: $e')),
      );
    }
  }
}

// BatchDetailView actualizado para usar FirebaseService
class BatchDetailView extends StatefulWidget {
  final String batchId;

  const BatchDetailView({
    Key? key,
    required this.batchId,
  }) : super(key: key);

  @override
  _BatchDetailViewState createState() => _BatchDetailViewState();
}

class _BatchDetailViewState extends State<BatchDetailView> {
  List<Map<String, dynamic>> _attendances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBatchDetails();
  }

  Future<void> _loadBatchDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final details = await FirebaseService.getBatchDetails(widget.batchId);
      setState(() {
        _attendances = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar detalles: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lote ${widget.batchId.substring(0, 8)}...'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          const ConnectionIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBatchDetails,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _attendances.isEmpty
                ? const Center(
                    child: Text(
                      'No hay registros en este lote',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info,
                                        color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Información del Lote',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'ID: ${widget.batchId}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Planta: ${_attendances[0]['planta_nombre']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Supervisor: ${_attendances[0]['supervisor_nombre']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Fecha: ${_attendances[0]['fecha']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  'Total usuarios: ${_attendances.length}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _attendances.length,
                          itemBuilder: (context, index) {
                            final attendance = _attendances[index];
                            final hasExit = attendance['hora_salida'] != null;

                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              color: hasExit
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: hasExit
                                              ? Colors.green
                                              : Colors.orange,
                                          radius: 20,
                                          child: Icon(
                                            hasExit
                                                ? Icons.check
                                                : Icons.schedule,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                attendance['usuario_nombres'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'DNI: ${attendance['usuario_dni']}',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: hasExit
                                                ? Colors.green
                                                : Colors.orange,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            hasExit ? 'Completo' : 'Pendiente',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Entrada: ${attendance['hora_ingreso']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    if (hasExit)
                                      Text(
                                        'Salida: ${attendance['hora_salida']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ubicación entrada: ${attendance['direccion_entrada'] ?? 'No disponible'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (hasExit)
                                      Text(
                                        'Ubicación salida: ${attendance['direccion_salida'] ?? 'No disponible'}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    if (!hasExit) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _registrarSalidaIndividual(
                                                  attendance['id']),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text('Registrar Salida'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  // Registrar salida individual
  Future<void> _registrarSalidaIndividual(String asistenciaId) async {
    try {
      final position = await LocationService.getCurrentPosition();
      String direccion = 'Ubicación no disponible';

      if (position != null) {
        direccion = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
      }

      final now = DateTime.now();
      final hora =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      await FirebaseService.updateAsistenciaSalidaConUbicacion(
        asistenciaId,
        hora,
        position?.latitude,
        position?.longitude,
        direccion,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salida registrada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      _loadBatchDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar salida: $e')),
      );
    }
  }
}

// REEMPLAZA tu SupervisorView actual - ELIMINA los parámetros y carga los datos internamente
class SupervisorView extends StatefulWidget {
  final Supervisor supervisor;

  const SupervisorView({
    Key? key,
    required this.supervisor,
    // ← ELIMINA: required this.plantas,
    // ← ELIMINA: required this.usuarios,
  }) : super(key: key);

  @override
  _SupervisorViewState createState() => _SupervisorViewState();
}

class _SupervisorViewState extends State<SupervisorView> {
  Planta? _selectedPlanta;
  List<Usuario> _selectedUsuarios = [];
  bool _isLoading = false;
  String _currentLocation = 'Detectando ubicación...';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // ← AGREGAR: Variables para cargar datos dinámicamente
  List<Planta> _plantas = [];
  List<Usuario> _usuarios = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // ← NUEVO: Cargar datos al inicializar
    _getCurrentLocation();
  }

  // ← NUEVO: Método para cargar plantas y usuarios
  Future<void> _loadInitialData() async {
    try {
      final plantas = await FirebaseService.getPlantas();
      final usuarios = await FirebaseService.getUsuarios();

      setState(() {
        _plantas = plantas;
        _usuarios = usuarios;
        _isLoadingData = false;
        if (_plantas.isNotEmpty) {
          _selectedPlanta = _plantas.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _currentLocation = address;
        });
      } else {
        setState(() {
          _currentLocation = 'Ubicación no disponible';
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Error al obtener ubicación';
      });
    }
  }

  void _toggleUsuarioSelection(Usuario usuario) {
    setState(() {
      if (_selectedUsuarios.contains(usuario)) {
        _selectedUsuarios.remove(usuario);
      } else {
        _selectedUsuarios.add(usuario);
      }
    });
  }

  List<Usuario> get _filteredUsuarios {
    if (_searchQuery.isEmpty) {
      return _usuarios;
    }
    return _usuarios.where((usuario) {
      return usuario.nombres
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          usuario.dni.contains(_searchQuery);
    }).toList();
  }

  Future<void> _registerBatchAttendance() async {
    if (_selectedPlanta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione una planta')),
      );
      return;
    }

    if (_selectedUsuarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor seleccione al menos un usuario')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      String direccion = 'Ubicación no disponible';

      if (position != null) {
        direccion = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
      }

      final now = DateTime.now();
      final fecha =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final hora =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final batchId = DateTime.now().millisecondsSinceEpoch.toString();

      // Crear lista de asistencias para el lote
      final List<Asistencia> asistencias = [];
      for (final usuario in _selectedUsuarios) {
        asistencias.add(
          Asistencia(
            usuarioId: usuario.id!,
            plantaId: _selectedPlanta!.id!,
            supervisorId: widget.supervisor.id!,
            fecha: fecha,
            horaIngreso: hora,
            ubicacionEntradaLat: position?.latitude,
            ubicacionEntradaLng: position?.longitude,
            direccionEntrada: direccion,
            batchId: batchId,
          ),
        );
      }

      // Insertar lote de asistencias
      await FirebaseService.insertAsistenciasBatch(asistencias);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Lote registrado con ${_selectedUsuarios.length} usuarios'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedUsuarios.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar lote: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ← AGREGAR: Mostrar loading mientras cargan los datos
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Registrar Lote'),
          backgroundColor: AppColors.secondary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Lote'),
        backgroundColor: AppColors.secondary,
        elevation: 0,
        actions: [
          const ConnectionIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.secondary, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            // INFORMACIÓN DEL SUPERVISOR Y UBICACIÓN
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.secondary,
                            child: Icon(
                              Icons.supervisor_account,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.supervisor.nombre,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'DNI: ${widget.supervisor.dni}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentLocation,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // FORMULARIO DE REGISTRO DE LOTE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registrar Lote de Asistencia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Planta>(
                        decoration: InputDecoration(
                          labelText: 'Planta',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.business),
                        ),
                        value: _selectedPlanta,
                        items: _plantas.map((planta) {
                          return DropdownMenuItem<Planta>(
                            value: planta,
                            child: Text(planta.nombre),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPlanta = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar usuarios',
                          hintText: 'Ingrese nombre o DNI',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Usuarios seleccionados: ${_selectedUsuarios.length}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedUsuarios.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedUsuarios.clear();
                                });
                              },
                              child: const Text('Limpiar selección'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _registerBatchAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Registrar Lote'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // LISTA DE USUARIOS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.people, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Lista de Usuarios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_filteredUsuarios.length} usuarios',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _filteredUsuarios.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay usuarios disponibles',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredUsuarios.length,
                                itemBuilder: (context, index) {
                                  final usuario = _filteredUsuarios[index];
                                  final isSelected =
                                      _selectedUsuarios.contains(usuario);

                                  return CheckboxListTile(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      _toggleUsuarioSelection(usuario);
                                    },
                                    title: Text(
                                      usuario.nombres,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'DNI: ${usuario.dni}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    secondary: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? AppColors.primary
                                          : Colors.grey[300],
                                      child: Icon(
                                        Icons.person,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                    ),
                                    activeColor: AppColors.primary,
                                    checkColor: Colors.white,
                                    dense: true,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// AdminView actualizado para usar FirebaseService
// REEMPLAZA tu AdminView actual - ELIMINA los parámetros y la carga de datos
class AdminView extends StatefulWidget {
  const AdminView({Key? key}) : super(key: key); // ← SIN PARÁMETROS

  @override
  _AdminViewState createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _batchesActivos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBatchesActivos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBatchesActivos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final batches = await FirebaseService.getAllBatchesActivos();
      setState(() {
        _batchesActivos = batches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar lotes activos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          const ConnectionIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBatchesActivos,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          // 🎯 CAMBIOS PARA MEJOR LEGIBILIDAD
          labelColor: Colors.black, // ← PESTAÑA SELECCIONADA EN NEGRO
          unselectedLabelColor:
              Colors.white, // ← PESTAÑAS NO SELECCIONADAS EN BLANCO
          indicatorColor: Colors.white, // ← INDICADOR BLANCO
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, // ← TEXTO EN NEGRITA PARA SELECCIONADA
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight:
                FontWeight.normal, // ← TEXTO NORMAL PARA NO SELECCIONADAS
            fontSize: 12,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.business), text: 'Plantas'),
            Tab(icon: Icon(Icons.supervisor_account), text: 'Supervisores'),
            Tab(icon: Icon(Icons.history), text: 'Asistencias'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color.fromARGB(172, 16, 89, 144), Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            // USUARIOS TAB - SIN PARÁMETROS
            const UsuariosTab(),

            // PLANTAS TAB - SIN PARÁMETROS
            const PlantasTab(),

            // SUPERVISORES TAB - SIN PARÁMETROS
            const SupervisoresTab(),

            // ASISTENCIAS TAB - SOLO CON DATOS DE LOTES ACTIVOS
            AsistenciasTab(
              batchesActivos: _batchesActivos,
              isLoading: _isLoading,
              onRefresh: _loadBatchesActivos,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          switch (_tabController.index) {
            case 0:
              _showAddUsuarioDialog();
              break;
            case 1:
              _showAddPlantaDialog();
              break;
            case 2:
              _showAddSupervisorDialog();
              break;
            case 3:
              _showExportOptions();
              break;
          }
        },
        backgroundColor: AppColors.primary,
        child: Icon(
          _tabController.index == 3 ? Icons.file_download : Icons.add,
        ),
      ),
    );
  }

  // Mostrar diálogo para agregar usuario
  void _showAddUsuarioDialog() {
    final nombreController = TextEditingController();
    final dniController = TextEditingController();
    final passwordController = TextEditingController();
    bool isAdmin = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar Usuario'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dniController,
                      decoration: const InputDecoration(
                        labelText: 'DNI',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Es administrador'),
                      value: isAdmin,
                      onChanged: (bool? value) {
                        setState(() {
                          isAdmin = value ?? false;
                        });
                      },
                    ),
                    if (isAdmin)
                      TextField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nombreController.text.isEmpty ||
                        dniController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Por favor complete todos los campos')),
                      );
                      return;
                    }

                    if (isAdmin && passwordController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Por favor ingrese una contraseña para el administrador')),
                      );
                      return;
                    }

                    try {
                      final usuario = Usuario(
                        dni: dniController.text,
                        nombres: nombreController.text,
                        password: isAdmin ? passwordController.text : null,
                      );

                      await FirebaseService.insertUsuario(usuario);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Usuario agregado correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Mostrar diálogo para agregar planta
  void _showAddPlantaDialog() {
    final nombreController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Planta'),
          content: TextField(
            controller: nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Planta',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor ingrese un nombre')),
                  );
                  return;
                }

                try {
                  final planta = Planta(
                    nombre: nombreController.text,
                  );

                  await FirebaseService.insertPlanta(planta);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Planta agregada correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Mostrar diálogo para agregar supervisor
  void _showAddSupervisorDialog() {
    final nombreController = TextEditingController();
    final dniController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Supervisor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dniController,
                  decoration: const InputDecoration(
                    labelText: 'DNI',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isEmpty ||
                    dniController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Por favor complete todos los campos')),
                  );
                  return;
                }

                try {
                  final supervisor = Supervisor(
                    dni: dniController.text,
                    nombre: nombreController.text,
                    password: passwordController.text,
                  );

                  await FirebaseService.insertSupervisor(supervisor);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Supervisor agregado correctamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Mostrar opciones de exportación
  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Exportar Datos a Excel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.list_alt, color: AppColors.primary),
                title: const Text('Exportar Todas las Asistencias'),
                subtitle: const Text('Registros individuales de asistencia'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAttendanceData();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.group, color: AppColors.secondary),
                title: const Text('Exportar Todos los Lotes'),
                subtitle: const Text('Asistencias agrupadas por lotes'),
                onTap: () {
                  Navigator.pop(context);
                  _exportBatchData();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Exportar asistencias individuales
  Future<void> _exportAttendanceData() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener datos
      final asistencias = await FirebaseService.getAsistenciasDetalladas();

      // Generar nombre de archivo con fecha y hora
      final now = DateTime.now();
      final fileName =
          'todas_asistencias_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';

      // Exportar a Excel
      final filePath =
          await ExcelService.exportAttendanceToExcel(asistencias, fileName);

      // Cerrar diálogo de carga
      Navigator.pop(context);

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Todas las asistencias exportadas',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Archivo Excel generado y compartido correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si hay error
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar datos: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // Exportar datos de lotes
  Future<void> _exportBatchData() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener datos de lotes
      final batches = await FirebaseService.getBatchesAgrupados();

      // Generar nombre de archivo con fecha y hora
      final now = DateTime.now();
      final fileName =
          'todos_lotes_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';

      // Exportar a Excel
      final filePath =
          await ExcelService.exportBatchesToExcel(batches, fileName);

      // Cerrar diálogo de carga
      Navigator.pop(context);

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Todos los lotes de asistencia exportados',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Archivo Excel de lotes generado y compartido correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si hay error
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar lotes: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}

// REEMPLAZA tu UsuariosTab actual con esta versión que usa StreamBuilder
class UsuariosTab extends StatefulWidget {
  const UsuariosTab({Key? key}) : super(key: key); // ← SIN PARÁMETROS

  @override
  _UsuariosTabState createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Usuario> _filterUsuarios(List<Usuario> usuarios) {
    if (_searchQuery.isEmpty) return usuarios;
    return usuarios.where((usuario) {
      return usuario.nombres
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          usuario.dni.contains(_searchQuery);
    }).toList();
  }

  Future<void> _deleteUsuario(Usuario usuario) async {
    try {
      await FirebaseService.deleteUsuario(usuario.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar usuario: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar usuarios',
              hintText: 'Ingrese nombre o DNI',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Usuario>>(
              // ← STREAMBUILDER EN LUGAR DE LISTA ESTÁTICA
              stream: FirebaseService.getUsuariosStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final usuarios = snapshot.data ?? [];
                final filteredUsuarios = _filterUsuarios(usuarios);

                if (filteredUsuarios.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay usuarios disponibles',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = filteredUsuarios[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: usuario.isAdmin
                              ? AppColors.primary
                              : AppColors.secondary,
                          child: Icon(
                            usuario.isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          usuario.nombres,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text('DNI: ${usuario.dni}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (usuario.isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title:
                                          const Text('Confirmar Eliminación'),
                                      content: Text(
                                          '¿Está seguro que desea eliminar a ${usuario.nombres}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteUsuario(usuario);
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// REEMPLAZA tu PlantasTab actual con esta versión que usa StreamBuilder
class PlantasTab extends StatefulWidget {
  const PlantasTab({Key? key}) : super(key: key); // ← SIN PARÁMETROS

  @override
  _PlantasTabState createState() => _PlantasTabState();
}

class _PlantasTabState extends State<PlantasTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Planta> _filterPlantas(List<Planta> plantas) {
    if (_searchQuery.isEmpty) return plantas;
    return plantas.where((planta) {
      return planta.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _deletePlanta(Planta planta) async {
    try {
      await FirebaseService.deletePlanta(planta.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Planta eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar planta: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar plantas',
              hintText: 'Ingrese nombre de la planta',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Planta>>(
              // ← STREAMBUILDER EN LUGAR DE LISTA ESTÁTICA
              stream: FirebaseService.getPlantasStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final plantas = snapshot.data ?? [];
                final filteredPlantas = _filterPlantas(plantas);

                if (filteredPlantas.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay plantas disponibles',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredPlantas.length,
                  itemBuilder: (context, index) {
                    final planta = filteredPlantas[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.secondary,
                          child: Icon(
                            Icons.business,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          planta.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Creada: ${planta.createdAt?.toString().split(' ')[0] ?? 'N/A'}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirmar Eliminación'),
                                  content: Text(
                                      '¿Está seguro que desea eliminar la planta ${planta.nombre}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deletePlanta(planta);
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// REEMPLAZA tu SupervisoresTab actual con esta versión que usa StreamBuilder
class SupervisoresTab extends StatefulWidget {
  const SupervisoresTab({Key? key}) : super(key: key); // ← SIN PARÁMETROS

  @override
  _SupervisoresTabState createState() => _SupervisoresTabState();
}

class _SupervisoresTabState extends State<SupervisoresTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<Supervisor> _filterSupervisores(List<Supervisor> supervisores) {
    if (_searchQuery.isEmpty) return supervisores;
    return supervisores.where((supervisor) {
      return supervisor.nombre
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          supervisor.dni.contains(_searchQuery);
    }).toList();
  }

  Future<void> _deleteSupervisor(Supervisor supervisor) async {
    try {
      await FirebaseService.deleteSupervisor(supervisor.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supervisor eliminado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar supervisor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Buscar supervisores',
              hintText: 'Ingrese nombre o DNI',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Supervisor>>(
              // ← STREAMBUILDER EN LUGAR DE LISTA ESTÁTICA
              stream: FirebaseService.getSupervisoresStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final supervisores = snapshot.data ?? [];
                final filteredSupervisores = _filterSupervisores(supervisores);

                if (filteredSupervisores.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay supervisores disponibles',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredSupervisores.length,
                  itemBuilder: (context, index) {
                    final supervisor = filteredSupervisores[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.dark,
                          child: Icon(
                            Icons.supervisor_account,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          supervisor.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text('DNI: ${supervisor.dni}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirmar Eliminación'),
                                  content: Text(
                                      '¿Está seguro que desea eliminar a ${supervisor.nombre}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteSupervisor(supervisor);
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// REEMPLAZA tu AsistenciasTab actual - ELIMINA el parámetro asistencias
class AsistenciasTab extends StatefulWidget {
  final List<Map<String, dynamic>> batchesActivos;
  final bool isLoading;
  final VoidCallback onRefresh;

  const AsistenciasTab({
    Key? key,
    required this.batchesActivos,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  _AsistenciasTabState createState() => _AsistenciasTabState();
}

class _AsistenciasTabState extends State<AsistenciasTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Variables para cargar asistencias dinámicamente
  List<Map<String, dynamic>> _asistencias = [];
  bool _isLoadingAsistencias = true;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _loadAsistencias();
  }

  @override
  void dispose() {
    // 🔧 SOLUCIÓN: Limpiar recursos antes de dispose
    _subTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 🔧 SOLUCIÓN: Verificar mounted antes de setState
  Future<void> _loadAsistencias() async {
    if (!mounted) return; // ← VERIFICACIÓN AGREGADA

    setState(() {
      _isLoadingAsistencias = true;
    });

    try {
      final asistencias = await FirebaseService.getAsistenciasDetalladas();

      // 🔧 VERIFICAR mounted ANTES de setState
      if (mounted) {
        setState(() {
          _asistencias = asistencias;
          _isLoadingAsistencias = false;
        });
      }
    } catch (e) {
      // 🔧 VERIFICAR mounted ANTES de setState
      if (mounted) {
        setState(() {
          _isLoadingAsistencias = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar asistencias: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredAsistencias {
    if (_searchQuery.isEmpty) {
      return _asistencias;
    }
    return _asistencias.where((asistencia) {
      return asistencia['usuario_nombres']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          asistencia['usuario_dni'].contains(_searchQuery) ||
          asistencia['planta_nombre']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          asistencia['supervisor_nombre']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _subTabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Asistencias'),
              Tab(text: 'Lotes Activos'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              // ASISTENCIAS INDIVIDUALES
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Buscar asistencias',
                              hintText:
                                  'Ingrese nombre, DNI, planta o supervisor',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        // 🔧 VERIFICAR mounted ANTES de setState
                                        if (mounted) {
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        }
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              // 🔧 VERIFICAR mounted ANTES de setState
                              if (mounted) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadAsistencias,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _isLoadingAsistencias
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredAsistencias.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No hay asistencias disponibles',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _filteredAsistencias.length,
                                  itemBuilder: (context, index) {
                                    final asistencia =
                                        _filteredAsistencias[index];
                                    final hasExit =
                                        asistencia['hora_salida'] != null;

                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      color: hasExit
                                          ? Colors.green[50]
                                          : Colors.orange[50],
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: hasExit
                                              ? Colors.green
                                              : Colors.orange,
                                          child: Icon(
                                            hasExit
                                                ? Icons.check_circle
                                                : Icons.schedule,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          asistencia['usuario_nombres'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'DNI: ${asistencia['usuario_dni']} - ${asistencia['fecha']}',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'Planta: ${asistencia['planta_nombre']}',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'Supervisor: ${asistencia['supervisor_nombre']}',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'Entrada: ${asistencia['hora_ingreso']}${hasExit ? ' - Salida: ${asistencia['hora_salida']}' : ''}',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        trailing: hasExit
                                            ? const Icon(Icons.check_circle,
                                                color: Colors.green, size: 16)
                                            : const Icon(Icons.schedule,
                                                color: Colors.orange, size: 16),
                                        onTap: () {
                                          _showAsistenciaDetails(asistencia);
                                        },
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),

              // LOTES ACTIVOS
              widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Lotes Activos (${widget.batchesActivos.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: widget.onRefresh,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: widget.batchesActivos.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No hay lotes activos',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: widget.batchesActivos.length,
                                    itemBuilder: (context, index) {
                                      final batch =
                                          widget.batchesActivos[index];

                                      return Card(
                                        elevation: 4,
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        color: Colors.orange[50],
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.schedule,
                                                      color: Colors.orange,
                                                      size: 24),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Planta: ${batch['planta_nombre']}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: const Text(
                                                      'Activo',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Supervisor: ${batch['supervisor_nombre']}',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                              Text(
                                                'Fecha: ${batch['fecha']}',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                              Text(
                                                'Entrada: ${batch['hora_ingreso']}',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Total usuarios: ${batch['total_usuarios']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Ubicación: ${batch['direccion_entrada'] ?? 'No disponible'}',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      // Navegar a detalles del lote
                                                      // Navigator.push(...);
                                                    },
                                                    icon: const Icon(
                                                        Icons.visibility),
                                                    label: const Text(
                                                        'Ver Detalles'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          AppColors.primary,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔧 MÉTODO HELPER PARA MOSTRAR DETALLES
  void _showAsistenciaDetails(Map<String, dynamic> asistencia) {
    final hasExit = asistencia['hora_salida'] != null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detalles'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Usuario: ${asistencia['usuario_nombres']}'),
                Text('DNI: ${asistencia['usuario_dni']}'),
                Text('Fecha: ${asistencia['fecha']}'),
                Text('Planta: ${asistencia['planta_nombre']}'),
                Text('Supervisor: ${asistencia['supervisor_nombre']}'),
                Text('Entrada: ${asistencia['hora_ingreso']}'),
                if (hasExit) Text('Salida: ${asistencia['hora_salida']}'),
                const SizedBox(height: 8),
                Text(
                    'Ubicación Entrada: ${asistencia['direccion_entrada'] ?? 'No disponible'}'),
                if (hasExit)
                  Text(
                      'Ubicación Salida: ${asistencia['direccion_salida'] ?? 'No disponible'}'),
                if (asistencia['batch_id'] != null)
                  Text('ID de Lote: ${asistencia['batch_id']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
