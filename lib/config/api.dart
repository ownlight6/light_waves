import 'package:light_waves/config/request.dart';

class Wave {
  /// 用于判断是否为国服
  /// 参考 Rust 代码：国服使用 .com，国际服使用 .net
  static bool _isOverseas(String svrArea) {
    return svrArea.isNotEmpty && svrArea != 'cn';
  }

  // 获取抽卡记录
  // [svrArea] 服务器区域，用于判断 API 端点（cn=国服，其他=国际服）
  static gachaRecord(data, {String svrArea = 'cn'}) async {
    final baseUrl = _isOverseas(svrArea)
        ? 'https://gmserver-api.aki-game2.net'
        : 'https://gmserver-api.aki-game2.com';
    // 使用绝对 URL，Dio 会覆盖默认 baseUrl
    return await HttpRequest.post(
      '$baseUrl/gacha/record/query',
      data: data,
    );
  }

  // 获取wiki信息
  static wikiInfo(data) async {
    return await WikiRequest.post(
      '/wiki/core/catalogue/item/getPage',
      params: data,
      headers: {
        'wiki_type': 9,
      },
    );
  }
}
