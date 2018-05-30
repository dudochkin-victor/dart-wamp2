library wamp.server;

import 'dart:io';
import 'dart:convert' show JSON;
import 'dart:math';
import 'dart:async';

import 'package:wamp/wamp.dart';
import 'package:uuid/uuid.dart';

part 'src/server/client.dart';

/// Server-side handler for wamp connections.
class WampHandler implements StreamConsumer<WebSocket> {
  Set<Client> clients = new Set();
  Map<String, Set<Client>> topicMap = new Map();
  CurieCodec curie = new CurieCodec();

  Future addStream(Stream<WebSocket> stream) {
//    stream.listen((socket) {
//      handle(socket);
      handle(stream);
//    }, onDone: () {
//      print('Client disconnected');
//    });
    return new Future.value(stream); // TODO: what to return here?
  }

  Future close() {
    return new Future.value(); // TODO: what to do here?
  }

  void handle(WebSocket socket) {
    var c = new Client(socket, generateSessionId())..welcome();

    clients.add(c);

    socket.listen((data) {
      var msg;

      try {
        msg = JSON.decode(data);

        print("MESSAGE " + data);

        switch(msg[0]) {
          case MessageType.PREFIX:
            c.prefixes[msg[1]] = msg[2];
            break;

          case MessageType.CALL:
            onCall(c, msg[1], msg[2], msg[3]);
            break;

          case MessageType.SUBSCRIBE:
            onSubscribe(c, msg[1]);
            break;

          case MessageType.UNSUBSCRIBE:
            onUnsubscribe(c, msg[1]);
            break;

          case MessageType.PUBLISH:
            onPublish(c, msg[1], msg[2]/*, msg[3], msg[4]*/);
            break;
        }
      } on FormatException {
        socket.close(WebSocketStatus.UNSUPPORTED_DATA, "Received data is not a valid JSON");
      }
    }, onDone: () {
      print('Client disconnected');
      c.topics.forEach((t) => _unsubscribe(c, t));
      clients.remove(c);
    });
  }

  /// To be overriden by subclasses.
  void onCall(Client c, String callId, String uri, arg) {
  }

  /// Handles subscription events.
  void onSubscribe(Client c, String topicUri) {
    var uri = curie.decode(topicUri);

    c.topics.add(uri);

    if (!topicMap.containsKey(uri)) {
      topicMap[uri] = new Set();
    }

    topicMap[uri].add(c);
  }

  void onUnsubscribe(Client c, String topicUri) {
    final uri = curie.decode(topicUri);
    c.topics.remove(uri);

    _unsubscribe(c, topicUri);
  }

  void onPublish(Client c, String topicUri, event, [exclude, eligible]) { // TODO: handle exclude, eligible.
    publish(topicUri, event);
  }

  void _unsubscribe(Client c, String topicUri) {
    var uri = curie.decode(topicUri);

    if (topicMap.containsKey(uri)) {
      topicMap[uri].remove(c);
      if (topicMap[uri].isEmpty) topicMap.remove(uri);
    }
  }

  /// Sends an event to all the subscribed clients.
  void publish(String topicUri, event) {
    final uri = curie.decode(topicUri);

    if (topicMap.containsKey(uri)) {
      final subscribers = topicMap[uri];

      subscribers.forEach((client) {
        if (clients.contains(client)) {
          client.event(topicUri, event);
        }
      });
    }
  }

  /// Generates an id for a client connection. By default uses UUID.v4, but
  /// can be overriden to return custom ids.
  String generateSessionId() {
    return new Uuid().v4();
  }
}