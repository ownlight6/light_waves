import 'package:dio/dio.dart';

class HttpRequest {
  static final BaseOptions options = BaseOptions(
    baseUrl: 'https://gmserver-api.aki-game2.com',
    connectTimeout: const Duration(
      milliseconds: 5000,
    ),
  );
  static Dio dio = Dio(options);

  static Future get(
    String url, {
    Map<String, dynamic>? params,
    Options? getOptions,
  }) async {
    try {
      Response response = await dio.get(
        url,
        queryParameters: params,
        options: getOptions,
      );
      final data = response.data;
      if (data['code'] == 0) {
        return data['data'];
      } else {
        return data;
      }
    } on DioException catch (e) {
      return Future.error(e);
    }
  }

  static Future post(
    String url, {
    required Map<String, dynamic> data,
  }) async {
    try {
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
        },
      );
      Response response = await dio.post(
        url,
        data: data,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      return Future.error(e);
    }
  }
}

class WikiRequest {
  static final BaseOptions options = BaseOptions(
    baseUrl: 'https://api.kurobbs.com',
    connectTimeout: const Duration(
      milliseconds: 5000,
    ),
  );
  static Dio dio = Dio(options);

  static Future post(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? params,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
      );
      Response response = await dio.post(
        url,
        data: data,
        options: options,
        queryParameters: params,
      );
      return response.data;
    } on DioException catch (e) {
      return Future.error(e);
    }
  }
}
