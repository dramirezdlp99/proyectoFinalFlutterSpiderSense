import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TranslationService extends Translations {
  static Map<String, Map<String, String>> translations = {};

  static Future<void> init() async {
    translations['en_US'] = await _loadJson('en-US');
    translations['es_ES'] = await _loadJson('es-ES');
  }

  static Future<Map<String, String>> _loadJson(String code) async {
    try {
      final String response =
          await rootBundle.loadString('assets/langs/$code.json');
      final Map<String, dynamic> data = json.decode(response);
      return data.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      debugPrint("Error loading translation $code: $e");
      return {};
    }
  }

  @override
  Map<String, Map<String, String>> get keys => translations;
}