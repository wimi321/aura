#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^AURLiteRTLoadCompletionHandler)(NSError * _Nullable error, NSString * _Nullable activeBackend);
typedef void (^AURLiteRTChunkHandler)(NSString *chunk);
typedef void (^AURLiteRTCompletionHandler)(NSError * _Nullable error);

@interface AURLiteRTNativeEngine : NSObject

- (void)configureWithPrimaryDelegate:(NSString *)primaryDelegate
                   fallbackDelegates:(NSArray<NSString *> *)fallbackDelegates
           maxContextTokensOverride:(NSNumber * _Nullable)maxContextTokensOverride;

- (NSDictionary<NSString *, id> *)runtimeStatus;

- (void)loadModelWithId:(NSString * _Nullable)modelId
                   path:(NSString *)path
             completion:(AURLiteRTLoadCompletionHandler)completion;

- (void)unloadModelWithCompletion:(AURLiteRTCompletionHandler)completion;

- (void)cancelActiveGeneration;

- (void)generateTextWithPrompt:(NSString *)prompt
               maxOutputTokens:(NSInteger)maxOutputTokens
                       onChunk:(AURLiteRTChunkHandler)onChunk
                    completion:(AURLiteRTCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
