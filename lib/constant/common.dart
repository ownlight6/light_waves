// 解析用户设置
final Map gachaSetting = {
  'svr_id': '', // 服务器ID
  'player_id': '', // UID
  'lang': '', // 语言
  'svr_area': '', // 服务器地区
  'record_id': '', // 记录ID
  'resources_id': '', // 卡池ID
};

// 用户设置数组
final List<Map<String, String>> gachaSettingList = [
  {'name': '服务器ID', 'id': 'svr_id'},
  {'name': 'UID', 'id': 'player_id'},
  {'name': '语言', 'id': 'lang'},
  {'name': '服务器地区', 'id': 'svr_area'},
  {'name': '记录ID', 'id': 'record_id'},
  {'name': '卡池ID', 'id': 'resources_id'},
];

// 卡池类型
List cardPoolType = [
  {'name': '角色活动唤取', 'id': 1},
  {'name': '武器活动唤取', 'id': 2},
  {'name': '角色常驻唤取', 'id': 3},
  {'name': '武器常驻唤取', 'id': 4},
  {'name': '新手角色唤取', 'id': 5},
  {'name': '新手自选唤取', 'id': 6},
  {'name': '角色新旅唤取', 'id': 8},
  {'name': '武器新旅唤取', 'id': 9},
  {'name': '角色联动唤取', 'id': 10},
  {'name': '武器联动唤取', 'id': 11},
];

// 卡池类型映射
Map<int, String> cardPoolTypeMap = {
  1: '限定',
  2: '专武',
  3: '角色',
  4: '武器',
  5: '新手',
  6: '自选',
  8: '旅角',
  9: '旅武',
  10: '联角',
  11: '联武',
};

// 默认请求参数
final Map defaultRequest = {
  "playerId": "",
  "cardPoolId": "",
  "cardPoolType": 1,
  "serverId": "",
  "languageCode": "zh-Hans",
  "recordId": ""
};

// 常驻五星角色ID
final List defaultFiveStar = [1405, 1301, 1203, 1503, 1104];
