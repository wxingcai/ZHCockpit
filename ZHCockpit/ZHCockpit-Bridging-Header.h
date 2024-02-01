//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

@import Masonry;
#import "AFNetworkReachabilityManager.h"

#if 0 // 开发环境

#define App_MainUrl "https://ckpttest.bob-cardif.com:10880/"

#else // 生产环境

#define App_MainUrl "https://gljsc.bob-cardif.com/"

#endif

#define DownloadUrl "api/user/download"
