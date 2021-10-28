#import "FlutterWalletPlugin.h"
#if __has_include(<flutter_wallet/flutter_wallet-Swift.h>)
#import <flutter_wallet/flutter_wallet-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_wallet-Swift.h"
#endif

@implementation FlutterWalletPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterWalletPlugin registerWithRegistrar:registrar];
}
@end
