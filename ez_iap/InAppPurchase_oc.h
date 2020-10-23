//
//  InAppPurchaseManager.h
//  RoN
//
//  Created by CoA Studio on 13-3-18.
//
//
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

//接口声明
@protocol IAPHandlerDelegate <NSObject>

- (void) productList:(NSArray*)list;

- (void) productRequestFinishWithProductID:(NSString*)productID andBillNO:(NSString*)billNO;

- (void) receiveTransaction:(SKPaymentTransaction *_Nullable)transaction andBillNO:(NSString*)billNO;

- (void) receiveErrorTransaction:(SKPaymentTransaction *_Nullable)transaction andBillNO:(NSString*)billNO;

- (void) errorHandler:(NSError *)error withProductID:(NSString*)productID andBillNO:(NSString*)billNO;

@end

@interface InAppPurchase_oc : NSObject<SKProductsRequestDelegate,SKPaymentTransactionObserver>

@property(nonatomic, copy, readonly,nonnull) NSString *productId;

@property(nonatomic, copy, readonly,nonnull) NSString *billNo;

@property(nonatomic, weak) id<IAPHandlerDelegate> delegate;

-(void) initIAP;

/**
 * 购买
 * @param product 购买产品id
 * @param billNo 订单号，可以为nil
 **/
-(void)buy:(NSString*_Nonnull) product andBillNO:(NSString*_Nonnull)billNo; //传Product Id

/**
 * 获取App Store的产品列表
 * @param productIds 产品id数组
 **/
-(void)getProductList:(NSArray *_Nonnull)productIds;

#pragma mark -
#pragma mark SKPaymentTransactionObserver
-(void)paymentQueue:(SKPaymentQueue *_Nullable ) queue updatedTransactions:(NSArray*_Nullable) transactions;
-(void)paymentQueue:(SKPaymentQueue *_Nullable) paymentQueue restoreCompletedTransactionsFailedWithError:(NSError *_Nullable)error;
-(void)paymentQueueRestoreCompletedTransactionsFinished: (SKPaymentTransaction *_Nullable)transaction;

@end
