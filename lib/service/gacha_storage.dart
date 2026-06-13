import 'package:light_waves/config/hive.dart';

/// 本地抽卡数据存储服务
/// API 返回的是每个池子的全量数据，直接覆盖存储即可
class GachaStorage {
  /// 读取某个池子的本地缓存数据
  static List<Map<String, dynamic>> loadPool(int poolType) {
    final key = SettingKey.gachaPoolKey(poolType);
    final raw = HiveData.gachaRecords.get(key);
    if (raw is List) {
      return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return [];
  }

  /// 保存某个池子的数据到本地（覆盖写入）
  static Future<void> savePool(int poolType, List items) async {
    final key = SettingKey.gachaPoolKey(poolType);
    await HiveData.gachaRecords.put(key, items);
  }

  /// 清除所有本地抽卡缓存
  static Future<void> clearAll() async {
    // 清除当前及旧版可能的 pool key
    final keys = <String>{
      for (final id in [1, 2, 3, 4, 5, 6, 8, 9, 10, 11])
        SettingKey.gachaPoolKey(id),
      for (final id in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        'pool_$id',
    };
    for (final key in keys) {
      await HiveData.gachaRecords.delete(key);
    }
  }
}
