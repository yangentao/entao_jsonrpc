## JSON RPC 2.0 for dart language
 
 
## Server Side
* Register method use server.addAction().
* When server transport receive a text packet, call server.onRecvText. 
* errorRpc() will raise an exception with 'RpcError', this will response to client.
* RpcAction.context, indicate whether a method need RpcContext parameter.
* RpcAction.expand, indicate whether expand all parameters when invoke a method.


## Client Side
* RpcClient.request() invoke server method which has a response
* RpcClient.notify() invoke server method which has NO response
* RpcClient.remote() with a transport callback, invoke server method which has a response immediately.  
  it can be used on http request or blocked tcp connection.
* When client transport receive a text packet, call client.onRecvText.

## Usage
 
```dart
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
  //    if method is named. an argument named 'context' is placed.
  server.addAction(RpcAction(method: "echoName", action: echoName, context: false, expand: true));
  server.addAction(RpcAction(method: "echoIndex", action: echoIndex, context: false, expand: true));

  // ‘expand’ is ignored when no result (null) received
  server.addAction(RpcAction(method: "echoVoid", action: echoVoid, context: false));
  server.addAction(RpcAction(method: "echoContext", action: echoContext, context: true, expand: false));
  server.addAction(RpcAction(method: "echoContextParams", action: echoContextParams, context: true, expand: false));

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

  Future.delayed(Duration(seconds: 1));
}

// server side method
String echoName({required String name, required int age}) {
  return "echoName: $name, $age";
}
// server side method
String echoIndex(String name, int age) {
  return "echoIndex: $name, $age";
}
// server side method
String echoVoid() {
  return "echoVoid: void";
}
// server side method
String echoContext(RpcContext context) {
  return "echoContext: ${context.request.params}";
}
// server side method
String echoContextParams(RpcContext context, dynamic params) {
  return "echoContextParams: $params";
}

```
 