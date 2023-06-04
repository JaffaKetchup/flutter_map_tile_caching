// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:http2/http2.dart';
import 'package:http_parser/http_parser.dart';

//////////////////////////////////////////////////////////////////////////////////
//            Originally maintained at github.com/daadu/http_plus               //
// Now maintained internally due to incompatbility with the latest dependencies //
//////////////////////////////////////////////////////////////////////////////////

/// HttpClient that supports HTTP2.
class HttpPlusClient extends BaseClient {
  /// Flag to enable HTTP2.
  ///
  /// Defaults to `true`.
  final bool enableHttp2;

  /// HTTP1 client that should be used.
  ///
  /// If null then new object of [IOClient] with appropriate configuration is
  /// used.
  final BaseClient http1Client;

  /// [SecurityContext] used when calling [SecureSocket.connect].
  final SecurityContext? context;

  /// [BadCertificateCallback] used when calling [SecureSocket.connect].
  final BadCertificateCallback? badCertificateCallback;

  /// Timeout [Duration] used when calling [SecureSocket.connect].
  final Duration? connectionTimeout;

  /// Automatically decompress response payload.
  ///
  /// If set to `true` and value of [HttpHeaders.contentEncodingHeader] in
  /// response headers is either `gzip` or `deflate` then [GZipCodec.decoder] and
  /// [ZLibCodec.decoder] is used respectively to transform the response body.
  ///
  /// Defaults to `true`.
  final bool autoUncompress;

  /// Keep connections to the server open.
  ///
  /// If set to `false`, then the connection is closed immediately after the
  /// response is collected.
  ///
  /// Defaults to `true`.
  final bool maintainOpenConnections;

  /// Maximum number of connection that can be open at a time.
  ///
  /// Set to `-1` to have no limit on number of connections.
  ///
  /// If it is set to positive number and the connection limit is reached, then
  /// the oldest connection is closed and removed.
  ///
  /// Defaults to `-1`.
  final int maxOpenConnections;

  /// Enable logging.
  ///
  /// Defaults to `false`.
  final bool enableLogging;

  /// Default client instance used by top-level functions.
  ///
  /// This client is shared across all top-level HTTP-method functions provided
  /// by the library.
  ///
  /// [maxOpenConnections] is set to `8`, to limit resources.
  static final HttpPlusClient defaultClient =
      HttpPlusClient(maxOpenConnections: 8);

  final Map<String, ClientTransportConnection> _h2Connections = {};

  /// Create [HttpPlusClient] object.
  HttpPlusClient({
    this.enableHttp2 = true,
    BaseClient? http1Client,
    this.context,
    this.badCertificateCallback,
    this.connectionTimeout,
    this.autoUncompress = true,
    this.maintainOpenConnections = true,
    this.maxOpenConnections = -1,
    this.enableLogging = false,
  })  : assert(
          maxOpenConnections == -1 || maxOpenConnections > 0,
          'maxOpenConnections must be -1, or > 0.',
        ),
        http1Client = http1Client ??
            IOClient(
              HttpClient(context: context)
                ..badCertificateCallback = badCertificateCallback
                ..connectionTimeout = connectionTimeout
                ..autoUncompress = autoUncompress,
            );

  @override
  Future<StreamedResponse> send(BaseRequest request) async =>
      _send(request, []);

  Future<StreamedResponse> _send(
    BaseRequest request,
    List<RedirectInfo> redirects,
  ) async {
    // if not-enabled or non-HTTPS -> HTTP 1.x
    if (!enableHttp2 || request.url.scheme != 'https') {
      return _sendHttp1(request);
    }

    // get-or-create HTTP2 connection
    final h2Connection =
        await _getOrCreateHttp2Connection(request.url.host, request.url.port);

    // if no h2Connection - then fallback to HTTP 1.x
    if (h2Connection == null) return _sendHttp1(request);

    // make HTTP2 request
    return _sendHttp2(request, h2Connection, redirects);
  }

  Future<ClientTransportConnection?> _getOrCreateHttp2Connection(
    String host,
    int port,
  ) async {
    // get an existing (if any) HTTP2 connection
    var connection = _h2Connections[host];

    // return if connection exists and is open
    if (connection?.isOpen ?? false) return connection;

    // if connection exists - then reset and remove it from _connections
    if (connection != null) {
      connection = null;
      _h2Connections.remove(host);
    }

    // create new socket
    const http2Protocol = 'h2';
    final socket = await SecureSocket.connect(
      host,
      port,
      supportedProtocols: [http2Protocol],
      onBadCertificate: badCertificateCallback != null
          ? (cert) => badCertificateCallback!.call(cert, host, port)
          : null,
      context: context,
      timeout: connectionTimeout,
    );

    // if HTTP2 not selected - then close and return null
    if (socket.selectedProtocol != http2Protocol) {
      await socket.close();
      return null;
    }

    // if maxOpenConnections limit reached -> close some connections
    if (maxOpenConnections > -1) {
      while (_h2Connections.length >= maxOpenConnections) {
        final oldConnection = _h2Connections.remove(_h2Connections.keys.first)!;
        await oldConnection.finish();
      }
    }

    // create connection from socket, save it for future use, and return it
    connection = ClientTransportConnection.viaSocket(socket);
    if (maintainOpenConnections) _h2Connections[host] = connection;
    return connection;
  }

  Future<StreamedResponse> _sendHttp1(BaseRequest request) =>
      http1Client.send(request);

  Future<StreamedResponse> _sendHttp2(
    BaseRequest request,
    ClientTransportConnection connection,
    List<RedirectInfo> redirects,
  ) async {
    // finalize request
    final requestStream = request.finalize();

    // make headers
    final headers = [
      Header.ascii(':method', request.method),
      Header.ascii(':path', _fullUrlPath(request.url)),
      Header.ascii(':scheme', request.url.scheme),
      Header.ascii(':authority', request.url.host),
      // if method-with-data and no content-length and transfer-encoding != chunked
      // -> then add `contentLengthHeader`
      if ({'PUT', 'POST', 'PATCH'}.contains(request.method) &&
          !request.headers.containsKey(HttpHeaders.contentLengthHeader) &&
          request.headers[HttpHeaders.transferEncodingHeader] != 'chunked')
        Header.ascii(
          HttpHeaders.contentLengthHeader,
          request.contentLength.toString(),
        ),
      ...request.headers.keys.map(
        (key) => Header.ascii(
          key.toLowerCase(),
          request.headers[key] ?? '',
        ),
      ),
    ];

    // create outgoing stream
    final stream = connection.makeRequest(headers);

    // stream request data to stream - and then close outgoing sink
    await requestStream.forEach(stream.sendData);
    await stream.outgoingMessages.close();

    // make StreamedResponse
    final response = await _makeResponse(request, stream, redirects);

    // if not maintainOpenConnections - then close connection
    if (!maintainOpenConnections) await connection.finish();

    // return response
    return response;
  }

  Future<StreamedResponse> _makeResponse(
    BaseRequest request,
    ClientTransportStream stream,
    List<RedirectInfo> redirects,
  ) {
    // initialize - header, body
    final headers = CaseInsensitiveMap<String>();
    final body = StreamController<List<int>>();
    final responseCompleter = Completer<StreamedResponse>();

    void complete() {
      // ignore if already completed
      if (responseCompleter.isCompleted) return;

      // check if status is present
      final statusCode = int.tryParse(headers.remove(':status').toString());
      if (statusCode == null) {
        return responseCompleter.completeError(
          StateError(
            'Server ${request.url} did not send a response status code.',
          ),
        );
      }

      // follow redirects - if has locationHeader
      if (request.followRedirects &&
          headers.containsKey(HttpHeaders.locationHeader)) {
        // check if not exceeding maxRedirects
        if (redirects.length >= request.maxRedirects) {
          return responseCompleter.completeError(
            RedirectException(
              'max redirect count of ${request.maxRedirects} exceeded',
              redirects,
            ),
          );
        }

        // get location and create new - redirects and request
        final location =
            request.url.resolve(headers[HttpHeaders.locationHeader]!);
        final newRedirects = List<RedirectInfo>.from(redirects)
          ..add(_RedirectInfo(request.method, statusCode, location));
        final newRequest = Request(
          statusCode == HttpStatus.temporaryRedirect ? request.method : 'GET',
          location,
        )
          ..followRedirects = request.followRedirects
          ..headers.addAll(request.headers)
          ..maxRedirects = request.maxRedirects;
        if (request is Request) {
          newRequest.encoding = request.encoding;
          if (statusCode == 307) {
            newRequest.bodyBytes = request.bodyBytes;
          }
        }
        if (request.contentLength != null) {
          newRequest.headers[HttpHeaders.contentLengthHeader] =
              request.contentLength.toString();
        }
        // call _send with new request and redirect and complete with it
        return responseCompleter.complete(_send(newRequest, newRedirects));
      }

      // transform stream if compressed
      var responseStream = body.stream;
      if (autoUncompress) {
        if (headers[HttpHeaders.contentEncodingHeader] == 'gzip') {
          responseStream = responseStream.transform(gzip.decoder);
        } else if (headers[HttpHeaders.contentEncodingHeader] == 'deflate') {
          responseStream = responseStream.transform(zlib.decoder);
        }
      }
      responseCompleter.complete(
        StreamedResponse(
          responseStream,
          statusCode,
          contentLength:
              int.tryParse(headers[HttpHeaders.contentLengthHeader].toString()),
          headers: headers,
          request: request,
          reasonPhrase: _findReasonPhrase(statusCode),
          isRedirect: headers.containsKey(HttpHeaders.locationHeader),
        ),
      );
    }

    stream.incomingMessages.listen(
      (message) {
        if (message is HeadersStreamMessage) {
          for (final header in message.headers) {
            headers[utf8.decode(header.name)] = utf8.decode(header.value);
          }
        } else if (message is DataStreamMessage) {
          body.add(message.bytes);
        } else if (!responseCompleter.isCompleted) {
          responseCompleter.completeError(
            ArgumentError.value(
              message,
              'message',
              'must be HeadersStreamMessage or DataStreamMessage',
            ),
          );
        }
      },
      cancelOnError: true,
      onDone: () {
        complete();
        body.close();
      },
      onError: (e, s) {
        if (!responseCompleter.isCompleted) {
          responseCompleter.completeError(e, s);
        }
      },
    );

    return responseCompleter.future;
  }

  @override
  void close() {
    super.close();
    http1Client.close();
    for (final socket in _h2Connections.values) {
      socket.finish();
    }
  }
}

class _RedirectInfo implements RedirectInfo {
  @override
  final String method;
  @override
  final int statusCode;
  @override
  final Uri location;

  _RedirectInfo(this.method, this.statusCode, this.location);
}

String _fullUrlPath(Uri uri, {bool withFragment = false}) => Uri(
      fragment: uri.hasFragment && withFragment ? uri.fragment : null,
      query: uri.hasQuery ? uri.query : null,
      path: uri.path,
    ).toString();

/// Taken from `dart:_http`. Finds the HTTP reason phrase for a given [statusCode].
String _findReasonPhrase(int statusCode) {
  switch (statusCode) {
    case HttpStatus.continue_:
      return 'Continue';
    case HttpStatus.switchingProtocols:
      return 'Switching Protocols';
    case HttpStatus.ok:
      return 'OK';
    case HttpStatus.created:
      return 'Created';
    case HttpStatus.accepted:
      return 'Accepted';
    case HttpStatus.nonAuthoritativeInformation:
      return 'Non-Authoritative Information';
    case HttpStatus.noContent:
      return 'No Content';
    case HttpStatus.resetContent:
      return 'Reset Content';
    case HttpStatus.partialContent:
      return 'Partial Content';
    case HttpStatus.multipleChoices:
      return 'Multiple Choices';
    case HttpStatus.movedPermanently:
      return 'Moved Permanently';
    case HttpStatus.found:
      return 'Found';
    case HttpStatus.seeOther:
      return 'See Other';
    case HttpStatus.notModified:
      return 'Not Modified';
    case HttpStatus.useProxy:
      return 'Use Proxy';
    case HttpStatus.temporaryRedirect:
      return 'Temporary Redirect';
    case HttpStatus.badRequest:
      return 'Bad Request';
    case HttpStatus.unauthorized:
      return 'Unauthorized';
    case HttpStatus.paymentRequired:
      return 'Payment Required';
    case HttpStatus.forbidden:
      return 'Forbidden';
    case HttpStatus.notFound:
      return 'Not Found';
    case HttpStatus.methodNotAllowed:
      return 'Method Not Allowed';
    case HttpStatus.notAcceptable:
      return 'Not Acceptable';
    case HttpStatus.proxyAuthenticationRequired:
      return 'Proxy Authentication Required';
    case HttpStatus.requestTimeout:
      return 'Request Time-out';
    case HttpStatus.conflict:
      return 'Conflict';
    case HttpStatus.gone:
      return 'Gone';
    case HttpStatus.lengthRequired:
      return 'Length Required';
    case HttpStatus.preconditionFailed:
      return 'Precondition Failed';
    case HttpStatus.requestEntityTooLarge:
      return 'Request Entity Too Large';
    case HttpStatus.requestUriTooLong:
      return 'Request-URI Too Long';
    case HttpStatus.unsupportedMediaType:
      return 'Unsupported Media Type';
    case HttpStatus.requestedRangeNotSatisfiable:
      return 'Requested range not satisfiable';
    case HttpStatus.expectationFailed:
      return 'Expectation Failed';
    case HttpStatus.internalServerError:
      return 'Internal Server Error';
    case HttpStatus.notImplemented:
      return 'Not Implemented';
    case HttpStatus.badGateway:
      return 'Bad Gateway';
    case HttpStatus.serviceUnavailable:
      return 'Service Unavailable';
    case HttpStatus.gatewayTimeout:
      return 'Gateway Time-out';
    case HttpStatus.httpVersionNotSupported:
      return 'Http Version not supported';
    default:
      return 'Status $statusCode';
  }
}
