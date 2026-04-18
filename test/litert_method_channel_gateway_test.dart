import 'package:aura_app/backend/services/litert_method_channel_gateway.dart';
import 'package:aura_core/aura_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel methodChannel = MethodChannel('aura/litert');
  const EventChannel textChannel = EventChannel('aura/litert/text_stream');

  late LiteRtMethodChannelGateway gateway;
  late List<String> requestIds;
  late MockStreamHandlerEventSink textSink;
  late int listenCount;
  late int cancelCount;

  const PromptEnvelope prompt = PromptEnvelope(
    systemInstruction: 'Stay in character.',
    messages: <ChatMessage>[
      ChatMessage(
        id: 'user-1',
        role: ChatRole.user,
        content: 'Hello',
      ),
    ],
    generationConfig: GenerationConfig.roleplayDefaults(),
    assistantLabel: 'The Keeper',
    userLabel: 'You',
  );

  setUp(() {
    requestIds = <String>[];
    listenCount = 0;
    cancelCount = 0;
    gateway = LiteRtMethodChannelGateway(
      methodChannel: methodChannel,
      textStreamChannel: textChannel,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      methodChannel,
      (MethodCall call) async {
        if (call.method == 'beginTextInference') {
          final Map<Object?, Object?> arguments =
              call.arguments as Map<Object?, Object?>;
          requestIds.add(arguments['requestId']!.toString());
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
      textChannel,
      MockStreamHandler.inline(
        onListen: (_, MockStreamHandlerEventSink events) {
          listenCount += 1;
          textSink = events;
        },
        onCancel: (_) {
          cancelCount += 1;
        },
      ),
    );
  });

  test('reuses one EventChannel listener across consecutive text requests',
      () async {
    final Future<List<String>> firstResponse =
        gateway.streamText(prompt: prompt).toList();
    await Future<void>.delayed(Duration.zero);

    expect(requestIds, hasLength(1));

    textSink.success(<String, Object?>{
      'requestId': requestIds[0],
      'chunk': 'first reply',
      'done': false,
    });
    textSink.success(<String, Object?>{
      'requestId': requestIds[0],
      'done': true,
    });

    expect(await firstResponse, <String>['first reply']);

    final Future<List<String>> secondResponse =
        gateway.streamText(prompt: prompt).toList();
    await Future<void>.delayed(Duration.zero);

    expect(requestIds, hasLength(2));

    textSink.success(<String, Object?>{
      'requestId': requestIds[1],
      'chunk': 'second reply',
      'done': false,
    });
    textSink.success(<String, Object?>{
      'requestId': requestIds[1],
      'done': true,
    });

    expect(await secondResponse, <String>['second reply']);
    expect(listenCount, 1);
    expect(cancelCount, 0);
  });
}
