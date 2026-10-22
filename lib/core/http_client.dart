import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final http.Client? _client;
  final Uri? baseUrl;
  final Duration timeout;
  //Clase Client
  ApiClient({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       baseUrl = Uri.parse(
         baseUrl ??
             (const String.fromEnvironment('API_URL').isNotEmpty
                 ? const String.fromEnvironment('API_URL')
                 : (kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000')),
       );
  //POST,GET,PATCH,DELETE
  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Object body) => _send('POST', path, body);
  Future<dynamic> patch(String path, Object body) => _send('PATCH', path, body);
  Future<dynamic> update(String path, Object body) =>
      _send('UPDATE', path, body);
  Future<void> delete(String path) => _send('DELETE', path);

  //Funcion SEND -> Mandar la peticion al Servicio, esperar una respuesta y adecuarlo para flutter

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    //Request: Va arma la peticion con la inyeccion de los HEADERS
    final request = http.Request(method, baseUrl!.resolve(path))
      ..headers['Accept'] = 'application/json';
    //Si es una peticion que tiene que mandar un body
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    //Guardar la respuesta del servicio
    final http.Response response;
    //El response se va a tratar segun el caso con el servicio respondio
    try {
      response = await _client!
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on http.ClientException {
      throw const NetworkFailure();
    } on TimeoutException {
      throw const NetworkFailure();
    }
    final json = _tryDecode(response);
    final code = response.statusCode;
    if (code >= 200 && code <= 300) return json;
    //Si el servidor respondio con error, se lanza el Failure que le corresponde
    throw _mapearError(code, json);
  }

  dynamic _tryDecode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  //Traduce el codigo de estado al Failure correcto (json puede ser null)
  Failure _mapearError(int code, dynamic json) {
    return switch (code) {
      404 => NotFoundFailure(_detalle(json) ?? 'Recurso no encontrado'),
      409 => ConflictFailure(_detalle(json) ?? 'Acción no permitida'),
      422 => ValidationFailure(_campos(json)),
      >= 500 && <= 599 => ServerFailure(code),
      _ => UnexpectedFailure(
        code,
        _detalle(json) ?? 'Error inesperado ($code)',
      ),
    };
  }

  //En 404, 409 y errores simulados 'detail' es un texto
  String? _detalle(dynamic json) {
    if (json is Map && json['detail'] is String) {
      return json['detail'] as String;
    }
    return null;
  }

  //En 422 'detail' es una lista: la clave es loc[1] y el valor es msg
  Map<String, String> _campos(dynamic json) {
    final campos = <String, String>{};
    if (json is! Map || json['detail'] is! List) return campos;
    for (final error in json['detail'] as List) {
      if (error is Map && error['loc'] is List && error['msg'] is String) {
        final loc = error['loc'] as List;
        if (loc.length > 1) campos['${loc[1]}'] = error['msg'] as String;
      }
    }
    return campos;
  }
}
