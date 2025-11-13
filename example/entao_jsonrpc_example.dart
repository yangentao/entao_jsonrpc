import 'dart:async';

import 'package:entao_jsonrpc/entao_jsonrpc.dart';

void main() async {
  RpcClient client = RpcClient();
  RpcServer server = RpcServer();
  server.addAction(RpcAction(method: "echoName", action: echoName));

  Future<void> clientReceiver(String text) async {
    client.onRecvText(text);
  }

  Future<void> serverReceiver(String text) async {
    String? resp = server.onRecvText(text);
    if (resp != null) {
      Future.delayed(Duration(seconds: 1), () {
        clientReceiver(resp);
      });
    }
  }

  FutureOr<bool> sender(String text) async {
    Future.delayed(Duration(seconds: 1), () {
      serverReceiver(text);
    });
    return true;
  }

  Object? result = await client.request(sender, "echoName", map: {"name": "entao", "age": 33}, timeoutSeconds: 5);
  logRpc.d("Result: ", result);
  Future.delayed(Duration(seconds: 3));
}

String echoName({required String name, required int age}) {
  return "Echo: $name, $age";
}
