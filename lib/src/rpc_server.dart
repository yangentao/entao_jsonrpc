part of 'rpc.dart';

// typedef RpcSender = bool Function(String);
typedef RpcInterceptor = FutureOr<void> Function(RpcContext context);

class RpcServer implements TextReceiver {
  final Map<String, RpcAction> _actions = {};
  final List<RpcInterceptor> _intersBefore = [];
  final List<RpcInterceptor> _intersAfter = [];

  /// void Function(RpcContext context, params)
  void addGroup(String group, String method, Function action, {bool context = false, bool expand = true}) {
    addAction(RpcAction("$group.$method", action, context: context, expand: expand));
  }

  /// void Function(RpcContext context, params)
  void add(String method, Function action, {bool context = false, bool expand = true}) {
    addAction(RpcAction(method, action, context: context, expand: expand));
  }

  void addAction(RpcAction action) {
    _actions[action.method] = action;
  }

  void before(RpcInterceptor interceptor) {
    _intersBefore.add(interceptor);
  }

  void after(RpcInterceptor interceptor) {
    _intersAfter.add(interceptor);
  }

  RpcAction? find(String method) => _actions[method];

  Future<RpcResponse?> onRequest(RpcRequest request) {
    return dispatch(RpcContext(request));
  }

  Future<RpcResponse?> dispatch(RpcContext context) async {
    RpcAction? ac = find(context.method);
    if (ac == null) {
      context.failedError(RpcError.methodNotFound);
      return context.response;
    }
    try {
      for (var bf in _intersBefore) {
        try {
          var r = bf.call(context);
          if (r is Future) await r;
        } on RpcError catch (e) {
          context.failedError(e);
        }
        if (context.commited) return context.response;
      }
      try {
        dynamic ret = ac.call(context);
        if (ret is Future) {
          var r = await ret;
          context.success(r);
        } else {
          context.success(ret);
        }
      } on RpcError catch (e) {
        print(e);
        context.failedError(e);
      }
      for (var af in _intersAfter) {
        try {
          var r = af.call(context);
          if (r is Future) await r;
        } catch (e) {
          loge(e);
        }
      }
    } on NoSuchMethodError {
      if (!context.commited) {
        context.failedError(RpcError.methodNotFound.withData("${context.request.id}, ${context.request.method}"));
      }
    } catch (e) {
      logRpc.e(e.toString());
      if (!context.commited) {
        context.failedError(RpcError.internal.withData("${context.request.id}, ${context.request.method}, ${e.toString()}"));
      }
    } finally {
      if (!context.commited) {
        context.failedError(RpcError.internal.withData("${context.request.id}, ${context.request.method}, NO response."));
      }
    }
    return context.response;
  }

  @override
  FutureOr<String?> onRecvText(String text) async {
    dynamic pk = Rpc.detectText(text);
    switch (pk) {
      case RpcRequest request:
        RpcResponse? resp = await onRequest(request);
        return resp?.jsonText;
      case List<dynamic> ls:
        List<RpcRequest> reqList = ls.map((e) => e as RpcRequest).nonNullList;
        List<RpcMap> arr = [];
        for (RpcRequest req in reqList) {
          RpcResponse? resp = await onRequest(req);
          if (resp != null) {
            arr.add(resp.toJson());
          }
        }
        if (arr.isNotEmpty) return json.encode(arr);
        return null;
    }
    return null;
  }
}

final class RpcAction {
  final String method;
  final Function action;
  final bool context;
  final bool expand;
  final Set<String>? names;

  RpcAction(this.method, this.action, {this.context = false, this.expand = true, this.names});

  dynamic call(RpcContext context) {
    dynamic params = context.request.params;

    if (!expand || params == null) {
      try {
        return Function.apply(action, [if (this.context) context]);
      } on NoSuchMethodError {
        return Function.apply(action, [if (this.context) context, params]);
      }
    }

    switch (params) {
      case RpcList ls:
        return Function.apply(action, [if (this.context) context, ...ls]);
      case RpcMap map:
        Map<Symbol, dynamic>? symMap;
        Set<String>? keySet = names;
        if (keySet != null && keySet.isNotEmpty) {
          symMap = Map<Symbol, dynamic>.fromEntries(map.entries.where((e) => keySet.contains(e.key)).map((e) => MapEntry(Symbol(e.key), e.value)));
        } else {
          symMap = map.map((k, v) => MapEntry(Symbol(k), v));
        }
        return Function.apply(action, [if (this.context) context], symMap);
      default:
        throw Exception("Invalid request params");
    }
  }
}
