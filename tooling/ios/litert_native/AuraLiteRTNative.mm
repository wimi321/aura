#import "AuraLiteRTNative.h"

#import <Foundation/Foundation.h>

#include <atomic>
#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "absl/status/status.h"
#include "absl/strings/match.h"
#include "absl/time/time.h"
#include "runtime/conversation/conversation.h"
#include "runtime/conversation/io_types.h"
#include "runtime/engine/engine.h"
#include "runtime/engine/engine_factory.h"
#include "runtime/engine/litert_lm_lib.h"

namespace {

extern "C" void AuraLiteRTNativeForceLinkEngineImpl(void);

constexpr char kRuntimeName[] = "litert-lm";
constexpr char kCancelledError[] = "AURA_GENERATION_CANCELLED";
constexpr char kLoadFailedError[] = "AURA_ENGINE_LOAD_FAILED";
constexpr char kUnloadFailedError[] = "AURA_ENGINE_UNLOAD_FAILED";
constexpr char kInferenceFailedError[] = "AURA_TEXT_INFERENCE_FAILED";
constexpr char kNotLoadedError[] = "AURA_MODEL_NOT_LOADED";

NSString *ToNSString(const std::string &value) {
  return [[NSString alloc] initWithBytes:value.data()
                                  length:value.size()
                                encoding:NSUTF8StringEncoding] ?: @"";
}

std::string ToStdString(NSString *value) {
  if (value == nil) {
    return std::string();
  }
  const char *utf8 = value.UTF8String;
  return utf8 == nullptr ? std::string() : std::string(utf8);
}

NSError *AuraError(NSString *code, NSString *message) {
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey: message ?: @"Unknown error.",
    @"AuraLiteRTCode": code ?: @"AURA_NATIVE_ERROR",
  };
  return [NSError errorWithDomain:@"app.aura.story.litert" code:1 userInfo:userInfo];
}

NSString *NormalizeBackendLabel(NSString *value) {
  const NSString *trimmed = [[value lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([trimmed isEqualToString:@"gpu"]) {
    return @"gpu";
  }
  if ([trimmed isEqualToString:@"cpu"]) {
    return @"cpu";
  }
  return @"cpu";
}

std::vector<std::string> BuildBackendAttempts(NSString *primary, NSArray<NSString *> *fallbacks) {
  NSMutableOrderedSet<NSString *> *ordered = [NSMutableOrderedSet orderedSet];
  if (primary.length > 0) {
    [ordered addObject:NormalizeBackendLabel(primary)];
  }
  for (NSString *candidate in fallbacks) {
    NSString *normalized = NormalizeBackendLabel(candidate);
    if (normalized.length > 0) {
      [ordered addObject:normalized];
    }
  }
  [ordered addObject:@"cpu"];

  std::vector<std::string> attempts;
  attempts.reserve(ordered.count);
  for (NSString *candidate in ordered) {
    attempts.push_back(ToStdString(candidate));
  }
  return attempts;
}

NSString *ExtractMessageText(const litert::lm::Message &message) {
  if (!message.contains("content")) {
    return @"";
  }

  const auto &content = message["content"];
  std::string collected;

  if (content.is_array()) {
    for (const auto &item : content) {
      if (item.is_object()) {
        if (item.contains("text") && item["text"].is_string()) {
          collected += item["text"].get<std::string>();
        } else if (item.contains("content") && item["content"].is_string()) {
          collected += item["content"].get<std::string>();
        }
      } else if (item.is_string()) {
        collected += item.get<std::string>();
      }
    }
  } else if (content.is_object()) {
    if (content.contains("text") && content["text"].is_string()) {
      collected = content["text"].get<std::string>();
    } else if (content.contains("content") && content["content"].is_string()) {
      collected = content["content"].get<std::string>();
    }
  } else if (content.is_string()) {
    collected = content.get<std::string>();
  }

  return ToNSString(collected);
}

NSString *CacheDirectoryPath(void) {
  NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
  NSString *base = paths.firstObject ?: NSTemporaryDirectory();
  return [base stringByAppendingPathComponent:@"AuraLiteRTCache"];
}

litert::lm::LiteRtLmSettings BuildSettings(const std::string &modelPath,
                                           const std::string &backend,
                                           std::optional<int> maxContextTokens,
                                           const std::string &cacheDir) {
  litert::lm::LiteRtLmSettings settings;
  settings.model_path = modelPath;
  settings.backend = backend;
  settings.cache_dir = cacheDir;
  settings.async = true;
  settings.input_prompt = "Aura iOS bootstrap";
  settings.max_output_tokens = -1;
  if (maxContextTokens.has_value() && *maxContextTokens > 0) {
    settings.max_num_tokens = *maxContextTokens;
  }
  if (backend == "cpu") {
    settings.num_cpu_threads = 4;
  }
  return settings;
}

NSError *WrapStatus(const absl::Status &status, NSString *fallbackCode) {
  NSString *message = ToNSString(std::string(status.message()));
  if (absl::IsCancelled(status)) {
    NSString *cancelCode = [NSString stringWithUTF8String:kCancelledError] ?: @"AURA_GENERATION_CANCELLED";
    return AuraError(cancelCode, message.length > 0 ? message : cancelCode);
  }
  return AuraError(fallbackCode, message.length > 0 ? message : @"LiteRT-LM operation failed.");
}

NSError *MissingRegisteredEngineError(void) {
  return AuraError(
      [NSString stringWithUTF8String:kLoadFailedError] ?: @"AURA_ENGINE_LOAD_FAILED",
      @"No LiteRT-LM engine is registered in the iOS native runtime. Check force_load linkage for AuraLiteRTNative.");
}

}  // namespace

@interface AURLiteRTNativeEngine ()
@end

@implementation AURLiteRTNativeEngine {
  dispatch_queue_t _stateQueue;
  dispatch_queue_t _workerQueue;
  std::vector<std::string> _backendAttempts;
  std::optional<int> _maxContextTokensOverride;
  std::unique_ptr<litert::lm::Engine> _engine;
  std::shared_ptr<litert::lm::Conversation> _activeConversation;
  NSString *_loadedModelId;
  NSString *_loadedModelPath;
  NSString *_activeBackendLabel;
  std::atomic<unsigned long long> _generation;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    AuraLiteRTNativeForceLinkEngineImpl();
    _stateQueue = dispatch_queue_create("app.aura.story.litert.state", DISPATCH_QUEUE_SERIAL);
    _workerQueue = dispatch_queue_create("app.aura.story.litert.worker", DISPATCH_QUEUE_CONCURRENT);
    _backendAttempts = BuildBackendAttempts(@"gpu", @[ @"cpu" ]);
    _activeBackendLabel = @"cpu";
    _generation.store(0);
  }
  return self;
}

- (void)configureWithPrimaryDelegate:(NSString *)primaryDelegate
                   fallbackDelegates:(NSArray<NSString *> *)fallbackDelegates
           maxContextTokensOverride:(NSNumber * _Nullable)maxContextTokensOverride {
  dispatch_sync(_stateQueue, ^{
    self->_backendAttempts = BuildBackendAttempts(primaryDelegate, fallbackDelegates ?: @[]);
    if (maxContextTokensOverride != nil && maxContextTokensOverride.intValue > 0) {
      self->_maxContextTokensOverride = maxContextTokensOverride.intValue;
    } else {
      self->_maxContextTokensOverride = std::nullopt;
    }
    self->_activeBackendLabel = primaryDelegate.length > 0 ? NormalizeBackendLabel(primaryDelegate) : @"cpu";
  });
}

- (NSDictionary<NSString *, id> *)runtimeStatus {
  __block NSDictionary<NSString *, id> *status = nil;
  dispatch_sync(_stateQueue, ^{
    status = @{
      @"runtime": [NSString stringWithUTF8String:kRuntimeName] ?: @"litert-lm",
      @"primaryBackend": self->_activeBackendLabel ?: @"cpu",
      @"audioInputSupported": @NO,
      @"loadedModelId": self->_loadedModelId ?: [NSNull null],
      @"loadedModelPath": self->_loadedModelPath ?: [NSNull null],
    };
  });
  return status;
}

- (void)loadModelWithId:(NSString * _Nullable)modelId
                   path:(NSString *)path
             completion:(AURLiteRTLoadCompletionHandler)completion {
  AURLiteRTLoadCompletionHandler completionCopy = [completion copy];
  dispatch_async(_stateQueue, ^{
    [self cancelLockedAndWait];
    self->_engine.reset();

    if (path.length == 0) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completionCopy(AuraError([NSString stringWithUTF8String:kLoadFailedError] ?: @"AURA_ENGINE_LOAD_FAILED", @"Model path is required."), nil);
      });
      return;
    }

    NSString *cachePath = CacheDirectoryPath();
    [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    NSMutableArray<NSString *> *errors = [NSMutableArray array];
    auto registeredEngineTypesOr = litert::lm::EngineFactory::Instance().ListEngineTypes();
    if (!registeredEngineTypesOr.ok()) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completionCopy(WrapStatus(
            registeredEngineTypesOr.status(),
            [NSString stringWithUTF8String:kLoadFailedError] ?: @"AURA_ENGINE_LOAD_FAILED"), nil);
      });
      return;
    }
    if (registeredEngineTypesOr->empty()) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completionCopy(MissingRegisteredEngineError(), nil);
      });
      return;
    }

    for (const std::string &attempt : self->_backendAttempts) {
      litert::lm::LiteRtLmSettings settings = BuildSettings(
          ToStdString(path),
          attempt,
          self->_maxContextTokensOverride,
          ToStdString(cachePath));
      auto engineSettingsOr = litert::lm::CreateEngineSettings(settings);
      if (!engineSettingsOr.ok()) {
        [errors addObject:[NSString stringWithFormat:@"%s: %@", attempt.c_str(), ToNSString(std::string(engineSettingsOr.status().message()))]];
        continue;
      }
      auto engineOr = litert::lm::CreateEngine(settings, *engineSettingsOr);
      if (!engineOr.ok()) {
        [errors addObject:[NSString stringWithFormat:@"%s: %@", attempt.c_str(), ToNSString(std::string(engineOr.status().message()))]];
        continue;
      }

      self->_engine = std::move(*engineOr);
      self->_loadedModelId = [modelId copy];
      self->_loadedModelPath = [path copy];
      self->_activeBackendLabel = ToNSString(attempt);

      dispatch_async(dispatch_get_main_queue(), ^{
        completionCopy(nil, self->_activeBackendLabel);
      });
      return;
    }

    NSString *joined = errors.count > 0 ? [errors componentsJoinedByString:@" | "] : @"No backend attempt succeeded.";
    dispatch_async(dispatch_get_main_queue(), ^{
      completionCopy(AuraError([NSString stringWithUTF8String:kLoadFailedError] ?: @"AURA_ENGINE_LOAD_FAILED", joined), nil);
    });
  });
}

- (void)unloadModelWithCompletion:(AURLiteRTCompletionHandler)completion {
  AURLiteRTCompletionHandler completionCopy = [completion copy];
  dispatch_async(_stateQueue, ^{
    [self cancelLockedAndWait];
    self->_engine.reset();
    self->_loadedModelId = nil;
    self->_loadedModelPath = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
      completionCopy(nil);
    });
  });
}

- (void)cancelActiveGeneration {
  dispatch_async(_stateQueue, ^{
    [self cancelLockedAndWait];
  });
}

- (void)generateTextWithPrompt:(NSString *)prompt
               maxOutputTokens:(NSInteger)maxOutputTokens
                       onChunk:(AURLiteRTChunkHandler)onChunk
                    completion:(AURLiteRTCompletionHandler)completion {
  AURLiteRTChunkHandler chunkCopy = [onChunk copy];
  AURLiteRTCompletionHandler completionCopy = [completion copy];

  dispatch_async(_stateQueue, ^{
    if (!self->_engine) {
      dispatch_async(dispatch_get_main_queue(), ^{
        completionCopy(AuraError([NSString stringWithUTF8String:kNotLoadedError] ?: @"AURA_MODEL_NOT_LOADED", @"Model is not loaded."));
      });
      return;
    }

    [self cancelLockedAndWait];

    litert::lm::SessionConfig sessionConfig = litert::lm::SessionConfig::CreateDefault();
    if (maxOutputTokens > 0) {
      sessionConfig.SetMaxOutputTokens(static_cast<int>(maxOutputTokens));
    }

    auto configOr = litert::lm::ConversationConfig::Builder().SetSessionConfig(sessionConfig).Build(*self->_engine);
    if (!configOr.ok()) {
      NSError *error = WrapStatus(configOr.status(), [NSString stringWithUTF8String:kInferenceFailedError] ?: @"AURA_TEXT_INFERENCE_FAILED");
      dispatch_async(dispatch_get_main_queue(), ^{
        completionCopy(error);
      });
      return;
    }

    auto conversationOr = litert::lm::Conversation::Create(*self->_engine, *configOr);
    if (!conversationOr.ok()) {
      NSError *error = WrapStatus(conversationOr.status(), [NSString stringWithUTF8String:kInferenceFailedError] ?: @"AURA_TEXT_INFERENCE_FAILED");
      dispatch_async(dispatch_get_main_queue(), ^{
        completionCopy(error);
      });
      return;
    }

    std::shared_ptr<litert::lm::Conversation> conversation(std::move(conversationOr).value().release());
    const unsigned long long generation = self->_generation.fetch_add(1) + 1;
    self->_activeConversation = conversation;

    NSString *promptCopy = [prompt copy];
    dispatch_async(self->_workerQueue, ^{
      auto finished = std::make_shared<std::atomic<bool>>(false);
      litert::lm::Message message = {
        {"role", "user"},
        {"content", ToStdString(promptCopy)},
      };

      absl::Status sendStatus = conversation->SendMessageAsync(
          message,
          [finished, chunkCopy, completionCopy](absl::StatusOr<litert::lm::Message> response) mutable {
            if (finished->load()) {
              return;
            }
            if (!response.ok()) {
              if (finished->exchange(true)) {
                return;
              }
              NSError *error = WrapStatus(response.status(), [NSString stringWithUTF8String:kInferenceFailedError] ?: @"AURA_TEXT_INFERENCE_FAILED");
              dispatch_async(dispatch_get_main_queue(), ^{
                completionCopy(error);
              });
              return;
            }
            if (response->is_null()) {
              if (finished->exchange(true)) {
                return;
              }
              dispatch_async(dispatch_get_main_queue(), ^{
                completionCopy(nil);
              });
              return;
            }
            NSString *chunk = ExtractMessageText(*response);
            if (chunk.length == 0) {
              return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
              chunkCopy(chunk);
            });
          });

      if (!sendStatus.ok()) {
        if (!finished->exchange(true)) {
          dispatch_async(dispatch_get_main_queue(), ^{
            completionCopy(WrapStatus(sendStatus, [NSString stringWithUTF8String:kInferenceFailedError] ?: @"AURA_TEXT_INFERENCE_FAILED"));
          });
        }
      } else {
        absl::Status waitStatus = self->_engine->WaitUntilDone(absl::Minutes(10));
        if (!waitStatus.ok() && !finished->exchange(true)) {
          dispatch_async(dispatch_get_main_queue(), ^{
            completionCopy(WrapStatus(waitStatus, [NSString stringWithUTF8String:kInferenceFailedError] ?: @"AURA_TEXT_INFERENCE_FAILED"));
          });
        }
      }

      dispatch_async(self->_stateQueue, ^{
        if (self->_generation.load() == generation) {
          self->_activeConversation.reset();
        }
      });
    });
  });
}

- (void)cancelLockedAndWait {
  self->_generation.fetch_add(1);
  if (self->_activeConversation) {
    self->_activeConversation->CancelProcess();
    if (self->_engine) {
      self->_engine->WaitUntilDone(absl::Seconds(5));
    }
    self->_activeConversation.reset();
  }
}

@end
