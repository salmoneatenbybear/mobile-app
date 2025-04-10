import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mobile_app/constants.dart';
import 'package:mobile_app/locator.dart';
import 'package:mobile_app/models/failure_model.dart';
import 'package:mobile_app/services/local_storage_service.dart';
import 'package:mobile_app/utils/app_exceptions.dart';

class ApiUtils {
  static http.Client client = http.Client();

  /// Returns JSON GET response
  static Future<dynamic> get(
    String uri, {
    Map<String, String>? headers,
    bool utfDecoder = false,
    bool rawResponse = false,
  }) async {
    try {
      final response = await client.get(Uri.parse(uri), headers: headers);

      if (rawResponse) {
        return response.body;
      }

      return ApiUtils.jsonResponse(response, utfDecoder: utfDecoder);
    } on SocketException {
      throw Failure(Constants.NO_INTERNET_CONNECTION);
    } on HttpException {
      throw Failure(Constants.HTTP_EXCEPTION);
    }
  }

  /// Returns JSON POST response
  static Future<dynamic> post(
    String uri, {
    required Map<String, String> headers,
    dynamic body,
  }) async {
    try {
      final response = await client.post(
        Uri.parse(uri),
        headers: headers,
        body: jsonEncode(body),
      );
      return ApiUtils.jsonResponse(response);
    } on SocketException {
      throw Failure(Constants.NO_INTERNET_CONNECTION);
    } on HttpException {
      throw Failure(Constants.HTTP_EXCEPTION);
    }
  }

  /// Returns JSON PUT response
  static Future<dynamic> put(
    String uri, {
    required Map<String, String> headers,
    dynamic body,
  }) async {
    try {
      final response = await client.put(
        Uri.parse(uri),
        headers: headers,
        body: jsonEncode(body),
      );
      return ApiUtils.jsonResponse(response);
    } on SocketException {
      throw Failure(Constants.NO_INTERNET_CONNECTION);
    } on HttpException {
      throw Failure(Constants.HTTP_EXCEPTION);
    }
  }

  /// Returns JSON PATCH response
  static Future<dynamic> patch(
    String uri, {
    required Map<String, String> headers,
    dynamic body,
  }) async {
    try {
      final response = await client.patch(
        Uri.parse(uri),
        headers: headers,
        body: jsonEncode(body),
      );
      return ApiUtils.jsonResponse(response);
    } on SocketException {
      throw Failure(Constants.NO_INTERNET_CONNECTION);
    } on HttpException {
      throw Failure(Constants.HTTP_EXCEPTION);
    }
  }

  static Future patchMutipart(
    String uri, {
    required Map<String, String> headers,
    required List<http.MultipartFile> files,
    dynamic body,
  }) async {
    try {
      final request = http.MultipartRequest('PATCH', Uri.parse(uri));
      request.headers.addAll(headers);

      body ??= {};
      for (final key in body.keys) {
        if (body[key] == null) continue;

        request.fields[key] = body[key].toString();
      }

      for (final file in files) {
        request.files.add(file);
      }

      final response = await http.Response.fromStream(
        await client.send(request),
      );
      return ApiUtils.jsonResponse(response);
    } on SocketException {
      throw Failure(Constants.NO_INTERNET_CONNECTION);
    } on HttpException {
      throw Failure(Constants.HTTP_EXCEPTION);
    }
  }

  /// Returns JSON DELETE response
  static Future<dynamic> delete(
    String uri, {
    required Map<String, String> headers,
  }) async {
    try {
      final response = await client.delete(Uri.parse(uri), headers: headers);
      return ApiUtils.jsonResponse(response);
    } on SocketException {
      throw Failure(Constants.NO_INTERNET_CONNECTION);
    } on HttpException {
      throw Failure(Constants.HTTP_EXCEPTION);
    }
  }

  static dynamic jsonResponse(
    http.Response response, {
    bool utfDecoder = false,
  }) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 202:
      case 204:
        return response.body == ''
            ? {}
            : json.decode(
              utfDecoder ? utf8.decode(response.bodyBytes) : response.body,
            );
      case 400:
        throw BadRequestException(response.body);
      case 401:
        throw UnauthorizedException(response.body);
      case 403:
        throw ForbiddenException(response.body);
      case 404:
        throw NotFoundException(response.body);
      case 409:
        throw ConflictException(response.body);
      case 422:
        throw UnprocessableIdentityException(response.body);
      case 500:
        throw InternalServerErrorException(response.body);
      case 503:
        throw ServiceUnavailableException(response.body);
      default:
        throw FetchDataException(
          'Error Occurred while Communication with Server with StatusCode : ${response.statusCode}',
        );
    }
  }

  static void addTokenToHeaders(Map<String, String> headers) {
    var token = locator<LocalStorageService>().token;
    headers.addAll({'Authorization': 'Token $token'});
  }
}
