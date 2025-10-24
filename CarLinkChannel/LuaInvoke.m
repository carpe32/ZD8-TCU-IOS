//
//  LuaInvoke.m
//  CarLinkChannel
//
//  Created by job on 2023/3/24.
//

#import "LuaInvoke.h"
#import "lualib.h"
#import "lua.h"
#import "lauxlib.h"
#import "LuaBridge.h"


@interface LuaInvoke()
{
    lua_State * state;
}
@end

@implementation LuaInvoke

-(NSString *)parseEcuWithHexString:(NSString *)hexString {
    
    state = [[LuaBridge instance] L];
    
    
    NSString * fn = [[NSBundle mainBundle] pathForResource:@"dkjson" ofType:@"lua"];
    NSData * luaData = [NSData dataWithContentsOfFile:fn];
    NSString * luastring = [[NSString alloc] initWithData:luaData encoding:NSUTF8StringEncoding];
    if(luaL_dofile(state,fn.UTF8String)){
     //   NSLog(@"------->  lua error: %s",lua_tostring(state, -1));
    }
    
    fn = [[NSBundle mainBundle] pathForResource:@"utils" ofType:@"lua"];
    if(luaL_dofile(state, fn.UTF8String)){
     //   NSLog(@"------->  lua error: %s",lua_tostring(state, -1));
    }
    
    fn = [[NSBundle mainBundle] pathForResource:@"FormatUtility" ofType:@"lua"];
    luaData = [NSData dataWithContentsOfFile:fn];
    luastring = [[NSString alloc] initWithData:luaData encoding:NSUTF8StringEncoding];
    if(luaL_dofile(state,fn.UTF8String)){
      //  NSLog(@"------->  lua error: %s",lua_tostring(state, -1));
    }
    
    fn = [[NSBundle mainBundle] pathForResource:@"BMWJobParse" ofType:@"lua"];
    luaData = [NSData dataWithContentsOfFile:fn];
    luastring = [[NSString alloc] initWithData:luaData encoding:NSUTF8StringEncoding];
    if(luaL_dofile(state,fn.UTF8String)){
     //   NSLog(@"------->  lua error: %s",lua_tostring(state, -1));
    }
    lua_getglobal(state, "parseECU");
    
 //   NSString * hexString = @"010100051801248A04D2010000100000000100001CA90113010600001CA30131020800001CAA1D960108000020341D96030500000B0A006401";
    const char * hexChar = hexString.UTF8String;
    const char * add = @"12".UTF8String;
    lua_pushstring(state, hexChar);
    lua_pushstring(state, add);
    
    NSString * dstString = @"";
    if(lua_pcall(state, 2, 1, 0)){
     //   NSLog(@"--------> result  = %s",lua_tostring(state, -1));
        dstString = [NSString stringWithFormat:@"%s",lua_tostring(state, -1)];
     //   NSLog(@"-------> dstString: %@",dstString);
    }else{
      //  NSLog(@"--------> result %s \n = %s",lua_tostring(state, -1),lua_tostring(state, 1));
        dstString = [NSString stringWithFormat:@"%s",lua_tostring(state, -1)];
//        NSData * stringData = [dstString dataUsingEncoding:NSUTF8StringEncoding];
//        NSDictionary * jsonDict = [NSJSONSerialization JSONObjectWithData:stringData options:NSJSONReadingFragmentsAllowed error:nil];
     //   NSLog(@"-------> dstString: %@",jsonDict);
    }
    return dstString;
}

@end
