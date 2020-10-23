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
    self.debugMode = false;
    self.autoVerify = false;
    self.islock = NO;
    self.delegate = nil;
    purchase_oc = [InAppPurchase_oc alloc];
    purchase_oc.delegate = self;
    [purchase_oc initIAP];
    NSLog(@"-----[EZIAP IAPApi] inited!");

}

-(void)buy:(NSString*)product billNo:(NSString*)bNo{
    if (self.islock){
        NSLog(@"-----[EZIAP IAPApi] The system is processing your request, please wait.");
        NSDictionary * userInfo = [NSDictionary dictionaryWithObject:@"The system is processing your request, please wait." forKey:NSLocalizedDescriptionKey];
        NSError * aError = [NSError errorWithDomain:NSCocoaErrorDomain code:999 userInfo:userInfo];
        if (self.delegate!= nil){
            [self.delegate IAPFailed:bNo andProductID:product widthError:aError];
        }
        return;
    }
    self.islock = YES;
    NSString *iapLKey = [NSString stringWithFormat:@"eziap_%@",product];
    [[NSUserDefaults standardUserDefaults] setObject:bNo forKey:iapLKey];
    [purchase_oc buy:product andBillNO:bNo];
}

-(void)getProductList:(NSArray *)productIds{
    [purchase_oc getProductList:productIds];
}

#pragma mark -
#pragma mark IAPHandlerDelegate

- (void) productRequestFinishWithProductID:(NSString*)productID andBillNO:(NSString*)billNO {
    self.islock = false;
}

- (void) productList:(NSArray*)list{
    NSLog(@"-----[EZIAP IAPApi] productList = %@",list);
    [self.delegate productList:list];
}

- (void) receiveTransaction:(SKPaymentTransaction *_Nullable)transaction andBillNO:(NSString*)sbillNO{
    if (transaction!= nil){
        NSString * productID = transaction.payment.productIdentifier;
        NSString * billNO = transaction.payment.applicationUsername;
        if (billNO == nil || billNO.length == 0){
            billNO = sbillNO;
        }
        NSString *iapLKey = [NSString stringWithFormat:@"eziap_%@",productID];
        if (billNO == nil){
            billNO =[[NSUserDefaults standardUserDefaults] objectForKey:iapLKey];
        }
        [[NSUserDefaults standardUserDefaults] setObject:billNO forKey:iapLKey];

        NSData *receipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
        NSString *receiptStr = [receipt base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        // 订单结果回调
        NSMutableDictionary *retDict = [NSMutableDictionary dictionary];
        [retDict setObject:productID forKey:@"productID"];
        [retDict setObject:productID forKey:@"productIdentifier"];

        [retDict setObject:transaction.transactionIdentifier forKey:@"transactionIdentifier"];
        if(billNO != nil){
            [retDict setObject:billNO forKey:@"billNO"];
        }
        if (self.debugMode){
            NSLog(@"-----[EZIAP IAPApi] payResult = %@",retDict);
        }
        [retDict setObject:receiptStr forKey:@"receipt"];
        if (self.debugMode){
            NSLog(@"-----[EZIAP IAPApi] pay receipt length  = %ld",receiptStr.length);
        }
        if (self.delegate!= nil){
            [self.delegate payResult:retDict];
        }
        if (self.autoVerify){
            void (^resultHandler)(NSError*,NSDictionary*) = ^(NSError* error,NSDictionary*response){
                if (self.delegate!= nil){
                    if (error != nil){
                        [self.delegate IAPFailed:billNO andProductID:productID widthError:transaction.error];
                    }else{
                        if (self.debugMode){
                            NSLog(@"-----[EZIAP IAPApi] verifyReceipt response = %@",response);
                        }
                        [self.delegate verifyResult:billNO andProductID:productID andResult:response];
                    }
                }
            };
            [self verifyReceipt:receiptStr andDebug:NO withResultHandler:resultHandler];
        }
    }
}

- (void) receiveErrorTransaction:(SKPaymentTransaction *_Nullable)transaction andBillNO:(NSString*)sbillNO{
    self.islock = false;
    if (transaction!= nil){
        NSString * productID = transaction.payment.productIdentifier;
        NSString * billNO = transaction.payment.applicationUsername;
        if (billNO == nil){
            billNO = sbillNO;
        }
        if (self.delegate){
            [self.delegate IAPFailed:billNO andProductID:productID widthError:transaction.error];
        }
    }
}

- (void) errorHandler:(NSError *)error withProductID:(NSString*)productID andBillNO:(NSString*)billNO{
    self.islock = false;
    NSLog(@"-----[EZIAP IAPApi] productId = %@ billNO = %@ error = %@",productID,billNO,error);
    if (self.delegate){
        [self.delegate IAPFailed:billNO andProductID:productID widthError:error];
    }
}
/**
 * https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html
 * statuecode https://developer.apple.com/documentation/appstorereceipts/status
     21000 App Store无法读取你提供的JSON数据
     21002 收据数据不符合格式
     21003 收据无法被验证
     21004 你提供的共享密钥和账户的共享密钥不一致
     21005 收据服务器当前不可用
     21006 收据是有效的，但订阅服务已经过期。当收到这个信息时，解码后的收据信息也包含在返回内容中
     21007 收据信息是测试用（sandbox），但却被发送到产品环境中验证
     21008 收据信息是产品环境中使用，但却被发送到测试环境中验证
 **/
-(void)verifyReceipt:(NSString*) receiptStr andDebug:(BOOL)debug withResultHandler: (void (^)(NSError* error,NSDictionary*response))resultHandler
{
    if (receiptStr == nil){
        return;
    }
    NSLog(@"-----[EZIAP IAPApi] WARNNING: Client side verification is not secure. It is recommended that you use the server to verify the order！ ");
    // Create the JSON object that describes the request
    NSError *error;
    NSMutableDictionary *requestContents = [NSMutableDictionary dictionary];
    [requestContents setObject:receiptStr forKey:@"receipt-data"];
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
                                          NSLog(@"-----[EZIAP IAPApi] %@",error);
                                          resultHandler(error,nil);
                                      } else {
                                          NSString * str  =[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                          NSError *error;
                                          NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
                                          if (!jsonResponse) {
                                              /* ... Handle error ...*/
                                              NSLog(@"-----[EZIAP IAPApi] result parse error = %@",error);
                                              resultHandler(error,nil);
                                              return;
                                          }
                                          /* ... Send a response back to the device ... */
                                          if (self.debugMode){
                                              NSLog(@"-----[EZIAP IAPApi] result  = %@",str);
                                          }
                                          NSNumber *status = jsonResponse[@"status"];
                                          switch ([status intValue]) {
                                              case 21007:{
                                                  NSLog(@"-----[EZIAP IAPApi] verify result code: 21007,resend to sandbox env");
                                                  [self verifyReceipt:receiptStr andDebug:YES withResultHandler:resultHandler];
                                                  break;
                                              }
                                              case 21008:{
                                                  NSLog(@"-----[EZIAP IAPApi] verify result code: 21008,resend to production env ");
                                                  [self verifyReceipt:receiptStr andDebug:NO withResultHandler:resultHandler];
                                                  break;
                                              }
                                              default:
                                                  resultHandler(nil,jsonResponse);
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

