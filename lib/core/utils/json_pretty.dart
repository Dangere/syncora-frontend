import 'dart:convert';

class JsonPretty {
  static String prettify(Map<String, dynamic> json) {
    var encoder = const JsonEncoder.withIndent('  ');

    return encoder.convert(json);
  }
}
