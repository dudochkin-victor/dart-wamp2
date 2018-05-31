part of wamp2;

const int PROTOCOL_VERSION = 2;

/**
 * WAMP defines the message types which are used in the communication between
 * two WebSocket endpoints, the client and the server, and describes associated
 * semantics.
 */
abstract class MessageType {
  // Auxiliary messages.
  static const int HELLO = 1;
  static const int WELCOME = 2;
  static const int ABORT = 3;
  static const int CHALLENGE = 4;
  static const int AUTHENTICATE = 5;
  static const int GOODBYE = 6;
  static const int ERROR = 8;

  static const int PUBLISH = 16;
  static const int PUBLISHED = 17;

  static const int SUBSCRIBE = 32;
  static const int SUBSCRIBED = 33;
  static const int UNSUBSCRIBE = 34;
  static const int UNSUBSCRIBED = 35;

  static const int EVENT = 36;

  static const int CALL = 48;
  static const int RESULT = 50;
  static const int REGISTER = 64;
  static const int REGISTERED = 65;

  static const int UNREGISTER = 66;
  static const int UNREGISTERED = 67;
  static const int INVOCATION = 68;
  static const int YIELD = 70;
}