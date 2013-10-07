#import "MWMApi.h"
#import "Framework.h"
#import "MapsAppDelegate.h"

#include "../../../search/result.hpp"

@implementation MWMApi
+(NSURL *)getBackUrl:(url_scheme::ApiPoint const &)apiPoint
{
  string const str = GetFramework().GenerateApiBackUrl(apiPoint);
  return [NSURL URLWithString:[NSString stringWithUTF8String:str.c_str()]];
}

+(void)openAppWithPoint:(url_scheme::ApiPoint const &)apiPoint
{
  NSString * z = [NSString stringWithUTF8String:apiPoint.m_id.c_str()];
  NSURL * url = [NSURL URLWithString:z];
  if ([APP canOpenURL:url])
    [APP openURL:url];
  else
    [APP openURL:[MWMApi getBackUrl:apiPoint]];
}

+(BOOL)canOpenApiUrl:(url_scheme::ApiPoint const &)apiPoint
{
  NSString * z = [NSString stringWithUTF8String:apiPoint.m_id.c_str()];
  if ([APP canOpenURL:[NSURL URLWithString:z]])
    return YES;
  if ([APP canOpenURL:[MWMApi getBackUrl:apiPoint]])
    return YES;
  return NO;
}
@end