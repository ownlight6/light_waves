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
          'accept': 'application/json, text/plain, */*',
          'accept-encoding': 'gzip, deflate, br, zstd',
          'accept-language': 'zh-CN,zh;q=0.9',
          'content-type': 'application/x-www-form-urlencoded;charset=UTF-8',
          'origin': 'http://wiki.kurobbs.com',
          'priority': 'u=1, i',
          'referer': 'http://wiki.kurobbs.com/',
          'sec-ch-ua':
              '"Not)A;Brand";v="99", "Google Chrome";v="127", "Chromium";v="127"',
          'sec-ch-ua-mobile': '?0',
          'sec-ch-ua-platform': '"macOS"',
          'sec-fetch-dest': 'empty',
          'sec-fetch-mode': 'cors',
          'sec-fetch-site': 'cross-site',
          'source': 'h5',
          'user-agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36',
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
