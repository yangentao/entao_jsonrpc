import 'dart:async';
import 'dart:convert';

import 'package:entao_log/entao_log.dart';

part 'rpc_client.dart';
part 'rpc_context.dart';
part 'rpc_error.dart';
part 'rpc_request.dart';
part 'rpc_response.dart';
part 'rpc_server.dart';
part 'rpc_service.dart';
part 'rpc_utils.dart';

TagLog logRpc = TagLog("RPC");



typedef AnyMap = Map<String, dynamic>;
typedef AnyList = List<dynamic>;


class Rpc {
  static String JSONRPC = "jsonrpc";
  static String VERSION = "2.0";
  static String ID = "id";
  static String METHOD = "method";
  static String PARAMS = "params";
  static String RESULT = "result";
  static String ERROR = "error";
  static String CODE = "code";
  static String MESSAGE = "message";
  static String DATA = "data";

  static int _autoID = 1;

  static int get nextID => _autoID++;

  /// RpcPacket,   Or, List&ltRpcPacket&gt
  static dynamic detectText(String text) {
    var jv = json.decode(text);
    switch (jv) {
      case AnyMap map:
        return detectPacket(map);
      case List<dynamic> list:
        List<RpcPacket> ls = list
            .map((e) {
              if (e is AnyMap) {
                return detectPacket(e);
              } else {
                return null;
              }
            })
            .nonNulls
            .toList();
        if (ls.isNotEmpty) return ls;
    }
    return null;
  }

  static RpcPacket? detectPacket(AnyMap map) {
    if (!_verifyVersion(map)) return null;
    if (map.containsKey(Rpc.RESULT) || map.containsKey(Rpc.ERROR)) {
      return RpcResponse.from(map);
    }
    if (map.containsKey(Rpc.METHOD)) return RpcRequest.from(map);
    return null;
  }
}

bool _verifyVersion(AnyMap map) {
  return map[Rpc.JSONRPC] == Rpc.VERSION;
}

sealed class RpcPacket {
  RpcPacket();

  AnyMap toJson() {
    AnyMap map = AnyMap();
    map[Rpc.JSONRPC] = Rpc.VERSION;
    onJson(map);
    return map;
  }

  void onJson(AnyMap map) {}

  @override
  String toString() {
    return json.encode(toJson());
  }
}

typedef StringFuncString = String? Function(String text);

abstract mixin class TextSender {
  /// 返回值表示是否发送成功
  Future<bool> sendText(String text);
}

abstract mixin class TextReceiver {
  /// 返回值表示，是否已经处理了text, 如果处理了， 后续的TextReceiver不会再处理该text
  String? onRecvText(String text);
}

class TextResult {
  final bool ok;
  final String? _text;

  TextResult._(this.ok, this._text);

  TextResult.success(this._text) : ok = true;

  TextResult.failed(this._text) : ok = false;

  String? get data {
    if (ok) return _text;
    _error("NO data");
  }

  String? get message {
    if (!ok) return _text;
    _error("No message");
  }
}

class FuncTextReceiver implements TextReceiver {
  StringFuncString func;

  FuncTextReceiver(this.func);

  @override
  String? onRecvText(String text) {
    return func(text);
  }
}
