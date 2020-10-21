//
//  IAPApi.m
//  IAPdemo
//
//  Created by Howe on 09/09/2017.
//  Copyright © 2017 Howe. All rights reserved.
//
#import <Foundation/Foundation.h>

#import "IAPApi.h"
#import "InAppPurchase_oc.h"
#import "IAPDefine.h"

static IAPApi *_shareIap = nil;

@implementation IAPApi

+(IAPApi*)Instance
{
    if (_shareIap == nil){
        _shareIap = [[IAPApi alloc] init];
        [_shareIap initIAP];
    }
    return _shareIap;
}

-(void) initIAP
{
    purchase_oc = [InAppPurchase_oc alloc];
    purchase_oc.delegate = self;
    [purchase_oc initIAP];
    messageHandler = nil;
}
-(void)setMessageHandler:(IAPMessageHandler)callback{
    messageHandler = callback;
}

-(void)buy:(NSString*)product billNo:(NSString*)bNo{
    NSString *iapLKey = [NSString stringWithFormat:@"eziap_%@",product];
    [[NSUserDefaults standardUserDefaults] setObject:bNo forKey:iapLKey];
    [purchase_oc buy:product andBillNO:bNo];
}

-(void)getCanBuyProductList:(NSArray *)productIds{
    [purchase_oc getCanBuyProductList:productIds];
}

-(void)errorCall:(int)code andErrorMsg:(NSString*)error{
    messageHandler(code,error);
}

-(void)productListCall:(int)code andParams:(NSString*)params{
    messageHandler(code,params);
}

// 获取产品列表的回调
-(void)finishPay:(SKPaymentTransaction*)transaction
{
    NSData *receipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    NSString * productIdentifier = transaction.payment.productIdentifier;
    NSString * billNO  = transaction.payment.applicationUsername;
    
    NSLog(@"[EZ_IAP]-----finishPay begin --------");
    NSLog(@"[EZ_IAP]-----transactionIdentifier:%@",transaction.transactionIdentifier);
    NSLog(@"[EZ_IAP]-----productIdentifier:%@",productIdentifier);
    NSLog(@"[EZ_IAP]-----billNO.:%@",billNO);
    NSLog(@"[EZ_IAP]-----finishPay end --------");
    
    NSString *receiptStr = [receipt base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
    NSMutableDictionary *retDict = [NSMutableDictionary dictionary];
    [retDict setObject:productIdentifier forKey:@"productIdentifier"];
    [retDict setObject:transaction.transactionIdentifier forKey:@"transactionIdentifier"];
    NSString *iapLKey = [NSString stringWithFormat:@"eziap_%@",productIdentifier];
    if (billNO == nil){
        billNO =[[NSUserDefaults standardUserDefaults] objectForKey:iapLKey];
    }else{
        [[NSUserDefaults standardUserDefaults] setObject:billNO forKey:iapLKey];
    }
    if(billNO != nil){
        [retDict setObject:billNO forKey:@"billNO"];
    }
    [retDict setObject:receiptStr forKey:@"receipt"];


//    NSDictionary *retDict = [NSDictionary dictionaryWithObjectsAndKeys:productIdentifier,@"productIdentifier",
//                             transaction.transactionIdentifier,@"transactionIdentifier",
//                                             billNO,@"billNO",
//                                             receiptStr,@"receipt",nil];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:retDict options:0 error:nil];
    if (jsonData){
        // json字符串
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        messageHandler(IAPPAY_SUCCESS,jsonString);
    }
}

//
/**
 21000 App Store无法读取你提供的JSON数据
 21002 收据数据不符合格式
 21003 收据无法被验证
 21004 你提供的共享密钥和账户的共享密钥不一致
 21005 收据服务器当前不可用
 21006 收据是有效的，但订阅服务已经过期。当收到这个信息时，解码后的收据信息也包含在返回内容中
 21007 收据信息是测试用（sandbox），但却被发送到产品环境中验证
 21008 收据信息是产品环境中使用，但却被发送到测试环境中验证
 **/
-(void) verifyReceipt:(NSString*)receiptStr andDebug:(BOOL)debug
{
    NSLog(@"[EZ_IAP]------ warn!, 你正在进行客户端验证收据, 建议服务器来做验证");
    // Create the JSON object that describes the request
    NSError *error;
    NSMutableDictionary *requestContents = [NSMutableDictionary dictionary];
    [requestContents setObject:receiptStr forKey:@"receipt-data"];
//    NSDictionary *requestContents = @{
//                                      @"receipt-data": receiptStr
//                                      };
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents
                                                          options:0
                                                            error:&error];
    if (!requestData) { /* ... Handle error ... */ }
    
    // Create a POST request with the receipt data.
    NSString *url = nil;
    if (debug){
        url = [NSString stringWithUTF8String:IAP_SANDBOX];
    }else{
        url = [NSString stringWithUTF8String:IAP_RELEASE];
    }
    NSURL *storeURL = [NSURL URLWithString:url];
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    // Make a connection to the iTunes Store on a background queue.
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:storeRequest
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      // ...
                                      if (error) {
                                          /* ... Handle error ... */
                                          NSLog(@"[IAPApi] 验证connectionError :%@",error);
                                      } else {
                                          NSString * str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                          NSError *error;
                                          NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                          if (!jsonResponse) {
                                              /* ... Handle error ...*/
                                              NSLog(@"[IAPApi] 验证错误:%@",error);
                                              messageHandler(ErrorVerifyReceipt,str);
                                              return;
                                          }
                                          /* ... Send a response back to the device ... */
                                          NSLog(@"[IAPApi] 验证结果 :%@",str);
                                          NSNumber *status = jsonResponse[@"status"];
                                          switch ([status intValue]) {
                                              case 21007:
                                                  NSLog(@"[IAPApi] verify result code: 21007,resend to sandbox env");
                                                  [self verifyReceipt:receiptStr andDebug:YES];
                                                  break;
                                              case 21008:
                                                  NSLog(@"[IAPApi] verify result code: 21008,resend to production env ");
                                                  [self verifyReceipt:receiptStr andDebug:NO];
                                                  break;
                                              default:
                                                  messageHandler(VERIFY_RECEIPT_RESULT,str);
                                                  break;
                                          }
                                      }
                                      
                                  }];
    
    [task resume];
}

-(void)dealloc{
    purchase_oc = nil;
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}
@end

