//
//  IAPApi.h
//  IAPdemo
//
//  Created by Howe on 09/09/2017.
//  Copyright © 2017 Howe. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "InAppPurchase_oc.h"

@protocol EZIAPDelegate <NSObject>

- (void) payResult:(NSDictionary*)payInfo;

- (void) verifyResult:(NSString*)billNO andProductID:(NSString*)productID andResult:(NSDictionary*)verfyInfo;

- (void) productList:(NSArray*)list;

- (void) IAPFailed:(NSString*)billNO andProductID:(NSString*)productID widthError:(NSError*)error;
@end


@interface IAPApi : NSObject<IAPHandlerDelegate>
{
    @private
    InAppPurchase_oc * purchase_oc;
}
@property BOOL debugMode;

@property BOOL islock;
/**
 * set auto verify payment receipt ( default false )
 */
@property BOOL autoVerify;

@property(nonatomic, weak) id<EZIAPDelegate> delegate;

+(IAPApi*)Instance;

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
-(void)getProductList:(NSArray *)productIds;

/**
* 本地验证收据
* @param verifyInfo 必须包含 receipt-data字段！
* @param debug 是否用沙箱验证
**/
-(void)verifyReceipt:(NSString*) verifyInfo andDebug:(BOOL)debug withResultHandler: (void (^)(NSError* error,NSDictionary*response))resultHandler;

@end
