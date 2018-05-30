library wamp.client;

import 'dart:html';
import 'dart:convert' show JSON;
import 'dart:math';
import 'dart:async';

import 'package:wamp/wamp.dart';

// TODO: add reconnect functionality.

class WampClient {
  WebSocket _socket;

  String sessionId;
  Map<String, String> prefixes = new Map();
  Map<String, Completer> callCompleters = new Map();
  Map<String, Function> subscriptions = new Map();

  WampClient(this._socket) {
    _socket.onMessage.listen((e) => onMessage(JSON.decode(e.data)));
  }

  void onMessage(List msg) {
    // print("ON MESSAGE" + JSON.encode(msg));
    switch (msg[0]) {
      case MessageType.WELCOME:
        sessionId = msg[1];
        onWelcome();
        break;

      case MessageType.RESULT:
        var completer = callCompleters.remove(msg[1]);

        if (completer != null) {
          switch(msg.length) {
            case 3: // [RESULT, CALL.Request|id, Details|dict]
              completer.complete();
              break;
            // case 4: // [RESULT, CALL.Request|id, Details|dict, YIELD.Arguments|list]
            //   completer.complete(msg[3]);
            //   break;
            // case 5: // [RESULT, CALL.Request|id, Details|dict, YIELD.Arguments|list, YIELD.ArgumentsKw|dict]
            //   completer.complete(/*msg[3], */msg[4]); // ACHTUNG
            //   break;
            default:
              completer.complete(msg.sublist(3));
              break;
          }
        } else {
          // TODO: handle unknown callId error.
        }
        break;

      case MessageType.ERROR:
        // TODO: implement me!
        break;
      case MessageType.SUBSCRIBED:
        var completer = callCompleters.remove(msg[1]);
        var subId = msg[2];

        if (completer != null) {
          completer.complete(subId);
        } else {
          // TODO: handle unknown callId error.
        }
        break;
      case MessageType.EVENT:
        var subId = msg[1];
        var pubId = msg[2];
        var details = msg[3];
        var args = msg[4];
        var kwArgs = msg[5];

        var subHandler = subscriptions[subId];
        if (subHandler != null) {
          subHandler(pubId, details, args, kwArgs);
        } else {
          onEvent(subId, pubId, details, args, kwArgs);
        }
        break;
    }
  }

  void send(msg) {
    _socket.send(JSON.encode(msg));
  }

  void onWelcome() {
    // Override me!
  }

  void onEvent(String subId, pubId, details, args, kwArgs) {
    // Override me!
    print("GOT EVENT TO $subId, $pubId, $details, $args, $kwArgs");
  }

  // Sets a CURIE prefix.
  void prefix(String prefix, String uri) {
    prefixes[prefix] = uri;
    send([MessageType.PREFIX, prefix, uri]);
  }

  // Calls remote procedure.
  Future call(uri, arg) {
    final callId = generateSessionId();
    final completer = new Completer();

    callCompleters[callId] = completer;

    send([MessageType.CALL, callId, {}, uri, arg]);

    return completer.future;
  }

  // Subscribes to the given topic.
  Future subscribe(topicUri, callback) {
    final callId = generateSessionId();
    final completer = new Completer();
    final notification = new Completer();

    callCompleters[callId] = completer;

    send([MessageType.SUBSCRIBE, callId, {}, topicUri]);
    completer.future.then((val) { 
        subscriptions[val] = callback;
        notification.complete(val);
      });
    return notification.future;
  }

  // Unsubscribes from the given topic.
  void unsubscribe(topicUri) {
    send([MessageType.UNSUBSCRIBE, topicUri]);
  }

  // Sends an event to the given topic.
  void publish(String topicUri, event, [exclude, eligible]) { // TODO: convert to named parameters.
    send([MessageType.PUBLISH, topicUri, event]); //, exclude, eligible]);
  }

  int generateSessionId() {
    return new Random().nextInt(99999999); // TODO: use some kind of hash.
  }
}