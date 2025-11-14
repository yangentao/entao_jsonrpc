import 'dart:async';

import 'package:entao_jsonrpc/entao_jsonrpc.dart';

RpcClient client = RpcClient();
RpcServer server = RpcServer();

/// simulate transport, tcp/udp/websocket/http etc

// when server transport receive json data, call server.onRecvText().
// and send back to client, if response is NOT null.
Future<void> serverReceiver(String text) async {
  String? response = server.onRecvText(text);
  if (response != null) {
    Future.delayed(Duration(milliseconds: 100), () {
      clientReceiver(response);
    });
  }
}

// client send request json data to server.
// if return true, client will wait server response.
FutureOr<bool> clientSender(String text) async {
  Future.delayed(Duration(milliseconds: 100), () {
    serverReceiver(text);
  });
  return true;
}

// when client transport receive json data, call client.onRecvText().
Future<void> clientReceiver(String text) async {
  client.onRecvText(text);
}

void main() async {
  // register actions on server side.
  // if context parameter is true,
  //    if method is positioned, the first argument is 'RpcContext context'
  //    if method is named. an argument named 'RpcContext context' is placed.
  server.addAction(RpcAction(method: "echoName", action: echoName, context: false, expand: true));
  server.addAction(RpcAction(method: "echoIndex", action: echoIndex, context: false, expand: true));

  // expand is ignored when no result (null) received
  server.addAction(RpcAction(method: "echoVoid", action: echoVoid, context: false));
  server.addAction(RpcAction(method: "echoContext", action: echoContext, context: true, expand: false));
  server.addAction(RpcAction(method: "echoContextParams", action: echoContextParams, context: true, expand: false));
  server.addAction(RpcAction(method: "echoNameWithContext", action: echoNameWithContext, context: true, expand: true, names: {"name", "age"}));

  // named arguments
  Object? result = await client.request(clientSender, "echoName", map: {"name": "entao", "age": 33}, timeoutSeconds: 1);
  logRpc.d("Result echoName: ", result);
  // 2025-11-14 06:07:57.645 D RPC: Result echoName:  echoName: entao, 33

  // positioned arguments
  Object? resultIndex = await client.request(clientSender, "echoIndex", list: ["tom", 99], timeoutSeconds: 1);
  logRpc.d("Result echoIndex: ", resultIndex);
  // 2025-11-14 06:07:57.852 D RPC: Result echoIndex:  echoIndex: tom, 99

  // no arguments
  Object? resultEchoVoid = await client.request(clientSender, "echoVoid", timeoutSeconds: 1);
  logRpc.d("Result echoVoid: ", resultEchoVoid);
  // 2025-11-14 06:07:58.056 D RPC: Result echoVoid:  echoVoid: void

  // with RpcContext argument
  Object? resultEchoContext = await client.request(clientSender, "echoContext", list: [1, 2, 3], timeoutSeconds: 1);
  logRpc.d("Result echoContext: ", resultEchoContext);
  // 2025-11-14 06:07:58.261 D RPC: Result echoContext:  echoContext: [1, 2, 3]

  // with RpcContext argument and raw parameters result
  Object? resultEchoContextParams = await client.request(clientSender, "echoContextParams", map: {"a": 1, "b": 2}, timeoutSeconds: 1);
  logRpc.d("Result echoContextParams: ", resultEchoContextParams);
  // 2025-11-14 06:07:58.466 D RPC: Result echoContextParams:  echoContextParams: {a: 1, b: 2}

  // with RpcContext argument and raw parameters result
  Object? resultEchoNameWithContext = await client.request(clientSender, "echoNameWithContext", map: {"name": "Jerry", "age": 3, "addr": "USA"}, timeoutSeconds: 1);
  logRpc.d("Result echoNameWithContext: ", resultEchoNameWithContext);
  // 2025-11-14 08:16:43.150 D RPC: Result echoNameWithContext:  echoNameWithContext: Jerry, 3

  Future.delayed(Duration(seconds: 1));
}

String echoIndex(String name, int age) {
  return "echoIndex: $name, $age";
}

String echoName({required String name, required int age}) {
  return "echoName: $name, $age";
}

String echoVoid() {
  return "echoVoid: void";
}

String echoContext(RpcContext context) {
  return "echoContext: ${context.request.params}";
}

String echoContextParams(RpcContext context, dynamic params) {
  return "echoContextParams: $params";
}

String echoNameWithContext(RpcContext context, {required String name, required int age}) {
  return "echoNameWithContext: $name, $age";
}
