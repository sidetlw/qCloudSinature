//
//  ViewController.m
//  qCloudSinature
//
//  Created by Longwei on 16/10/17.
//  Copyright © 2016年 Longwei. All rights reserved.
//

#import "ViewController.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>

#define POST_METHOD @"POST"
#define HOST_NAME @"live.api.qcloud.com/v2/index.php?"
#define SECRET_ID  @"AKIDiLn25RJ2aw7drb"                 //修改为你在腾讯云申请的
#define SECRET_KEY @"lT2OYXO3WnsRM5c"       //修改为你在腾讯云申请的

#define POST_URL @"https://live.api.qcloud.com/v2/index.php"

@interface ViewController ()
@property (strong,nonatomic) NSMutableDictionary* param;
@property (strong,nonatomic) NSArray *sortedKeys;
@property (strong,nonatomic) NSString *signatureStr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.param = [[NSMutableDictionary alloc] init];
    self.sortedKeys = [[NSArray alloc] init];
    self.signatureStr = [[NSString alloc] init];
    
    [self configCreateLVBChannelParam];
    
    [self sendPostWithParam:self.param url:POST_URL];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
   
}

-(void) configCreateLVBChannelParam
{
    self.param[@"Action"] = @"CreateLVBChannel";
    self.param[@"SecretId"] = SECRET_ID;
    
    NSString* timestamp = [[NSNumber numberWithUnsignedInteger:(NSUInteger)[[NSDate date] timeIntervalSince1970]] stringValue];
    self.param[@"Timestamp"] = timestamp;
    
    int nonce = (arc4random() % 88888) + 100;
    NSString *Nonce = [[NSString alloc] initWithFormat:@"%d", nonce];
    self.param[@"Nonce"] = Nonce;
    
    self.param[@"Region"] = @"gz";
    
    NSString *channelName = [[NSString alloc] initWithFormat:@"liveTest%@",Nonce];
    self.param[@"channelName"] = channelName;
    self.param[@"outputSourceType"] = @"2";
    self.param[@"sourceList.1.name"] = @"videoName";
    self.param[@"sourceList.1.type"] = @"1";
    self.param[@"outputRate.1"] = @"10";  //输出类型 0原画 10标清 20高清
    
    [self sortDic];
    
    self.param[@"Signature"] = self.signatureStr;
}

-(void)sortDic
{
    NSArray *myKeys = [self.param allKeys];
    self.sortedKeys = [myKeys sortedArrayUsingSelector:@selector(compare:)];
    
    NSString *result = [[NSMutableString alloc] init];
    int i = 0;
    for (id key in self.sortedKeys) {
        i++;
        NSString *str = [[NSString alloc] initWithFormat:@"%@=%@",key,self.param[key]];
        result = [result stringByAppendingString:str];
        if (i < self.sortedKeys.count) {
            result = [result stringByAppendingString:@"&"];
        }
    }
    
    //接下来拼接原文字符串
    NSString *originalStr = [[NSString alloc] initWithFormat:@"%@%@%@",POST_METHOD,HOST_NAME,result];
    
    //HmacSha1加密
    self.signatureStr = [self base_HmacSha1WithSecretKey:SECRET_KEY data:originalStr];
}

-(NSString *)base_HmacSha1WithSecretKey:(NSString *)key data:(NSString *)data{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    //sha1
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    //将加密结果进行一次BASE64编码。
    NSString *hash = [HMAC base64EncodedStringWithOptions:0];
    return hash;
}

-(void)sendPostWithParam:(NSDictionary *)param url:(NSString *)url
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    
    [manager POST:url parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *json = (NSDictionary *)responseObject;
            NSLog(@"\n\njson = %@",json);
            NSString *code = json[@"code"];
            NSLog(@"return code : %@",code);
            
            if ([json objectForKey:@"codeDesc"] != nil) {
                NSLog(@"codeDesc: %@",[json objectForKey:@"codeDesc"]);
            }
           
            if ([code integerValue] != 0) {
                NSLog(@"获取推流地址时出现错误，现在函数返回");
                
                return;
            }
            else {
                NSString *channel_id = json[@"channel_id"];
                NSDictionary *channelInfo = json[@"channelInfo"];
                NSString *upstream_address = channelInfo[@"upstream_address"];
                
                NSLog(@"\n\n频道ID是：%@\n推流地址是：%@\n\n",channel_id,upstream_address);
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"post method error = %@",[error localizedDescription]);
        
        return;
    }];
}


@end
