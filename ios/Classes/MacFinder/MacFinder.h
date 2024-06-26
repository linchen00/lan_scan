//
//  MacFinder.h
//  MacFinder
//
//  Created by Michael Mavris on 08/06/16.
//  Copyright © 2016 Miksoft. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_IPHONE_SIMULATOR
#include <net/route.h>
#else
#include "mac_finder_route.h"
#endif

#include "if_ether.h"
#include <arpa/inet.h>

@interface MacFinder : NSObject;
+(NSString*)ip2mac: (NSString*)strIP;
@end
