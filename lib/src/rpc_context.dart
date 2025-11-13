part of 'rpc.dart';

class RpcContext {
  final RpcRequest request;
  RpcResponse? response;
  final Map<String, dynamic> attrs = {};
  bool _commited = false;

  RpcContext(this.request);

  bool get commited => _commited;

  RpcResponse? success(Object? result) {
    if (commited) _error("Already commited");
    _commited = true;
    if (isNotify) return null;
    this.response = RpcResponse.success(id: request.id!, result: result);
    return this.response;
  }

  RpcResponse? failedError(RpcError e) {
    if (commited) _error("Already commited");
    _commited = true;
    if (isNotify) return null;
    this.response = RpcResponse.failed(id: request.id!, error: e);
    return this.response;
  }

  RpcResponse? failed(int code, String message, [Object? data]) {
    return failedError(RpcError(code, message, data));
  }

  String get method => request.method;

  bool get isNotify => !request.hasID;

  int get intID => request.intID;

  String get stringID => request.id as String;

  int get paramCount => request.paramCount;

  bool get hasParams => paramCount > 0;

  AnyMap? get paramMap => request.params?.castTo();

  AnyList? get paramList => request.params?.castTo();

  bool hasParam(String name) => true == paramMap?.containsKey(name);

  bool? getBool(String name) => paramMap?[name];

  int? getInt(String name) => paramMap?[name];

  double? getDouble(String name) => paramMap?[name];

  String? getString(String name) => paramMap?[name];

  bool? getBoolAt(int index) => paramList?.getOr(index);

  int? getIntAt(int index) => paramList?.getOr(index);

  double? getDoubleAt(int index) => paramList?.getOr(index);

  String? getStringAt(int index) => paramList?.getOr(index);

  T? getModel<T extends Object>(String name, T Function(AnyMap) mapper) {
    AnyMap? m = paramMap?[name] as AnyMap?;
    if (m == null) return null;
    return mapper(m);
  }
  T? getModelAt<T extends Object>(int index, T Function(AnyMap) mapper) {
    AnyMap? m = paramList?[index] as AnyMap?;
    if (m == null) return null;
    return mapper(m);
  }
}
