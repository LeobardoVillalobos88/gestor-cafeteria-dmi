import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:gestor_cafeteria/core/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient con respuestas del servidor', () {
    // 1. Éxito
    test('GET exitoso devuelve el JSON decodificado', () async {
      final mock = MockClient((request) async {
        return http.Response('[{"id": 1}]', 200);
      });
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      final resultado = await api.get('/orders');

      expect(resultado, isA<List>());
      expect(resultado, [
        {'id': 1},
      ]);
    });

    // 2. No encontrado
    test('404 lanza NotFoundFailure con el mensaje de detail', () async {
      final mock = MockClient((request) async {
        return http.Response('{"detail": "Order 9 not found"}', 404);
      });
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      expect(
        api.get('/orders/9'),
        throwsA(
          isA<NotFoundFailure>().having(
            (f) => f.message,
            'message',
            'Order 9 not found',
          ),
        ),
      );
    });

    // 3. Conflicto
    test('409 lanza ConflictFailure con el mensaje de detail', () async {
      final mock = MockClient((request) async {
        return http.Response(
          '{"detail": "Cannot change status from pending to delivered"}',
          409,
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      expect(
        api.patch('/orders/9', {'status': 'delivered'}),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            'Cannot change status from pending to delivered',
          ),
        ),
      );
    });

    // 4. Validación
    test('422 lanza ValidationFailure con los campos de detail', () async {
      final mock = MockClient((request) async {
        return http.Response(
          '{"detail": [{"loc": ["body", "customer"], '
          '"msg": "Must be 1-50 characters"}]}',
          422,
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      expect(
        api.post('/orders', {'customer': '', 'drink': 'latte', 'size': 'M'}),
        throwsA(
          isA<ValidationFailure>().having((f) => f.fields, 'fields', {
            'customer': 'Must be 1-50 characters',
          }),
        ),
      );
    });

    // 5. Servidor
    test('503 lanza ServerFailure con el statusCode', () async {
      final mock = MockClient((request) async {
        return http.Response('{"detail": "Simulated failure"}', 503);
      });
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      expect(
        api.get('/orders'),
        throwsA(
          isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503),
        ),
      );
    });
  });

  group('ApiClient sin respuesta del servidor', () {
    // 6. Sin conexión
    test('sin conexión lanza NetworkFailure', () async {
      final mock = MockClient((request) async {
        throw http.ClientException('sin red');
      });
      final api = ApiClient(client: mock, baseUrl: 'http://prueba');

      expect(api.get('/orders'), throwsA(isA<NetworkFailure>()));
    });

    // 6. Tiempo agotado
    test('respuesta más lenta que el timeout lanza NetworkFailure', () async {
      final mock = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response('[]', 200);
      });
      final api = ApiClient(
        client: mock,
        baseUrl: 'http://prueba',
        timeout: const Duration(milliseconds: 50),
      );

      expect(api.get('/orders'), throwsA(isA<NetworkFailure>()));
    });
  });

}
