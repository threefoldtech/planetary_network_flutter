#import "YggdrasilPlugin.h"
#if __has_include(<yggdrasil_plugin/yggdrasil_plugin-Swift.h>)
#import <yggdrasil_plugin/yggdrasil_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "yggdrasil_plugin-Swift.h"
#endif

@implementation YggdrasilPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftYggdrasilPlugin registerWithRegistrar:registrar];
}
@end
