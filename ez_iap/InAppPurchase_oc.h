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
@protocol IAPProtocol <NSObject>
@required
-(void)errorCall:(int)code andErrorMsg:(NSString*_Nullable)error;
-(void)productListCall:(int)code andParams:(NSString*_Nonnull)params; // 获取产品列表的回调
-(void)finishPay:(SKPaymentTransaction*_Nonnull)transaction;
@end

@interface InAppPurchase_oc : NSObject<SKProductsRequestDelegate,SKPaymentTransactionObserver>

@property(nonatomic, copy, readonly,nonnull) NSString *productId;

@property(nonatomic, copy, readonly,nonnull) NSString *billNo;

@property(nonatomic, assign,nonnull) id<IAPProtocol> delegate;

-(void) initIAP;

-(void)RequestProductData:(NSString*_Nullable)pid;
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
-(void)getCanBuyProductList:(NSArray *_Nonnull)productIds;

-(void)paymentQueue:(SKPaymentQueue *_Nullable ) queue updatedTransactions:(NSArray*_Nullable) transactions;
-(void)PurchasedTransaction: (SKPaymentTransaction*_Nullable) transaction;
-(void)completeTransaction: (SKPaymentTransaction*_Nullable) transaction;
-(void)failedTransaction: (SKPaymentTransaction *_Nullable)transaction;
-(void)paymentQueueRestoreCompletedTransactionsFinished: (SKPaymentTransaction *_Nullable)transaction;
-(void)paymentQueue:(SKPaymentQueue *_Nullable) paymentQueue restoreCompletedTransactionsFailedWithError:(NSError *_Nullable)error;
-(void)restoreTransaction: (SKPaymentTransaction *_Nullable)transaction;
@end
