//
//  IAPApi.h
//  IAPdemo
//
//  Created by Howe on 09/09/2017.
//  Copyright © 2017 Howe. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "InAppPurchase_oc.h"

typedef void(^IAPMessageHandler)(int code,NSString *params);

@interface IAPApi : NSObject<IAPProtocol>
{
    @private
    InAppPurchase_oc * purchase_oc;
    @private
    IAPMessageHandler messageHandler;
}
+(IAPApi*)Instance;

/**
 * 设置iap 回调block
 * @param callback 回调block
 **/
-(void)setMessageHandler:(IAPMessageHandler)callback;
/**
 * 购买
 * @param product 购买产品id
 * @param billNo 订单号，可以为nil
 **/
-(void)buy:(NSString*)product billNo:(NSString*)billNo;

/**
 * 获取App Store的产品列表
 * @param productIds 产品id数组
 **/
-(void)getCanBuyProductList:(NSArray *)productIds;

/**
* 本地验证收据
* @param receiptStr IAP收据
* @param debug 是否用沙箱验证
**/
-(void)verifyReceipt:(NSString*)receiptStr andDebug:(BOOL)debug;

@end
