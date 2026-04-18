import 'package:file_selector/file_selector.dart';

const List<XTypeGroup> characterCardImportTypeGroups = <XTypeGroup>[
  XTypeGroup(
    label: 'Character Card PNG',
    extensions: <String>['png'],
    uniformTypeIdentifiers: <String>['public.png'],
  ),
  XTypeGroup(
    label: 'Character Card JSON',
    extensions: <String>['json'],
    uniformTypeIdentifiers: <String>['public.json'],
  ),
];

const List<XTypeGroup> lorebookImportTypeGroups = <XTypeGroup>[
  XTypeGroup(
    label: 'Worldbook JSON',
    extensions: <String>['json'],
    uniformTypeIdentifiers: <String>['public.json'],
  ),
];
