// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:flutter_app/main.dart';
import 'package:flutter_app/services/storage_service.dart';

class TestPathProvider extends PathProviderPlatform {
  Directory? _root;

  Future<String> _createSubDirectory(String name) async {
    _root ??= await Directory.systemTemp.createTemp('time_tracker_test');
    final dir = Directory('${_root!.path}/$name');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  @override
  Future<String?> getTemporaryPath() async => _createSubDirectory('tmp');

  @override
  Future<String?> getApplicationDocumentsPath() async => _createSubDirectory('docs');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = TestPathProvider();
    await StorageService.init();
  });

  tearDownAll(() async {
    await StorageService.clearAllData();
  });

  testWidgets('Home screen renders key sections', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Time Tracker'), findsOneWidget);
    expect(find.text('Registro de Actividades'), findsWidgets);
    expect(find.byIcon(Icons.settings), findsWidgets);
    expect(find.byIcon(Icons.add), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}




