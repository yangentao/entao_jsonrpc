part of 'rpc.dart';

class RpcRequest extends RpcPacket {
  final Object? id;
  final String method;
  final Object? params;

  RpcRequest({this.id, required this.method, AnyMap? map, AnyList? list}) : params = map ?? list {
    assert(id == null || id is int || id is String);
    assert(map == null || list == null);
    assert(method.isNotEmpty);
  }

  RpcRequest.notify({required this.method, AnyMap? map, AnyList? list}) : params = map ?? list, id = null {
    assert(method.isNotEmpty);
    assert(map == null || list == null);
  }

  RpcRequest.invoke({Object? id, required this.method, AnyMap? map, AnyList? list}) : params = map ?? list, id = id ?? Rpc.nextID {
    assert(id == null || id is int || id is String);
    assert(map == null || list == null);
    assert(method.isNotEmpty);
  }

  int get intID => id as int;

  bool get hasID => id is String || id is int;

  bool get isNotify => !hasID;

  int get paramCount => switch (params) {
    AnyMap m => m.length,
    AnyList l => l.length,
    _ => 0,
  };

  bool get hasParams => paramCount > 0;

  @override
  void onJson(AnyMap map) {
    super.onJson(map);
    if (id != null) {
      map[Rpc.ID] = id;
    }
    map[Rpc.METHOD] = method;
    switch (params) {
      case AnyMap m:
        map[Rpc.PARAMS] = m;
      case AnyList l:
        map[Rpc.PARAMS] = l;
      default:
        break;
    }
  }

  static RpcRequest? from(AnyMap map) {
    if (!_verifyVersion(map)) return null;
    String? method = map[Rpc.METHOD];
    if (method == null) return null;
    Object? id = map[Rpc.ID];
    Object? params = map[Rpc.PARAMS];
    switch (params) {
      case AnyMap m:
        return RpcRequest(id: id, method: method, map: m);
      case AnyList l:
        return RpcRequest(id: id, method: method, list: l);
      default:
        return RpcRequest(id: id, method: method);
    }
  }

  static List<RpcRequest> fromBatch(AnyList jlist) {
    List<RpcRequest> ls = [];
    for (var e in jlist) {
      if (e is AnyMap) {
        var r = from(e);
        if (r != null) ls.add(r);
      }
    }
    return ls;
  }
}
