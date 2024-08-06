import 'package:light_waves/config/request.dart';

class Wave {
  // 获取抽卡记录
  static gachaRecord(data) async {
    return await HttpRequest.post(
      '/gacha/record/query',
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
