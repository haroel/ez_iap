//
//  InAppPurchaseManager.m
//  RoN
//
//  Created by CoA Studio on 13-3-18.
//
//
#import "InAppPurchase_oc.h"
#import <Foundation/Foundation.h>
#include "IAPDefine.h"

@implementation InAppPurchase_oc
-(void)initIAP
{
    //监听购买状态
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    NSArray<SKPaymentTransaction *> *arr = [[SKPaymentQueue defaultQueue] transactions];
    for (SKPaymentTransaction *transaction in arr){
        NSLog(@"-----[EZIAP InAppPurchase_oc] initIAP finishTransaction productID = %@, transactionIdentifier = %@",transaction.payment.productIdentifier, transaction.transactionIdentifier);
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
    _billNo = nil;
    _productId = nil;
}

-(void)buy:(NSString *)product andBillNO:(NSString*)bNo{
    if ([SKPaymentQueue canMakePayments]){
        _billNo = [bNo copy];
        _productId = [product copy];
        NSLog(@"-----[EZIAP InAppPurchase_oc] start buy productyID = %@ ,billNO = %@",_productId,_billNo);
        NSArray *productArray = [[NSArray alloc] initWithObjects:_productId, nil];
        NSSet *nsset = [NSSet setWithArray:productArray];
        SKProductsRequest *request=[[SKProductsRequest alloc] initWithProductIdentifiers: nsset];
        request.delegate=self;
        [request start];
    }else
    {
        NSLog(@"-----[EZIAP InAppPurchase_oc] This device is not able or allowed to make payments.");
        [self.delegate errorHandler:[self errorWithCode:ErrorPaymentNotAllowed andDesc:@"This device is not able or allowed to make payments."] withProductID:product andBillNO:bNo];
    }
}

-(void)getProductList:(NSArray *)productIds
{
    _productId = nil;
    _billNo = nil;
    NSSet *nsset = [NSSet setWithArray:productIds];
    SKProductsRequest *request=[[SKProductsRequest alloc] initWithProductIdentifiers: nsset];
    request.delegate=self;
    [request start];
}

///<SKProductsRequestDelegate> 请求协议
#pragma mark -
#pragma mark SKProductsRequestDelegate
//收到的产品信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"-----[EZIAP InAppPurchase_oc] Begin *************** ");
    NSArray *myProduct = response.products;
    if ([response.invalidProductIdentifiers count] > 0){
        NSLog(@"invalidProductIdentifiers :%@",response.invalidProductIdentifiers);
    }
    NSLog(@"productlist count: %lu", (unsigned long)[myProduct count]);
    SKProduct *cproduct = nil;
    for(SKProduct *product in myProduct){
//        NSLog(@"SKProduct 描述信息%@", [product description]);
        NSLog(@"");
        NSLog(@"title %@" , [product localizedTitle]);
        NSLog(@"localizedDescription: %@" , [product localizedDescription]);
        NSLog(@"price: %@" , [product price]);
        NSLog(@"productIdentifier: %@" , [product productIdentifier]);
        NSString *pId = [product productIdentifier];
        if (  _productId != nil && [_productId isEqualToString:pId] ){
            cproduct = product;
        }
        NSLog(@"");
    }
    if (cproduct!=nil)
    {
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:cproduct];
        if (_billNo != nil){
            payment.applicationUsername = _billNo;
        }
        NSLog(@" start pay productId = %@ billNO = %@ ------------", _productId ,_billNo);
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }else if ( _productId == nil )
    {
        NSMutableArray *plistArray = [[NSMutableArray alloc] init];
        for(SKProduct *product in myProduct){
            NSString *title= product.localizedTitle;
            NSString *description= product.localizedDescription;
            NSString *price= [NSString stringWithFormat:@"%f",product.price.doubleValue];
            NSString *productid= product.productIdentifier;
            NSDictionary *pdata = [NSDictionary dictionaryWithObjectsAndKeys:title,@"title", description,@"description", price ,@"price", productid ,@"productid",nil];
            [plistArray addObject:pdata];
        }
        [self.delegate productList:plistArray];
//        if ( [NSJSONSerialization isValidJSONObject:plistArray] ){
//            NSError *error;
//            NSData * data = [NSJSONSerialization dataWithJSONObject:plistArray options:0 error:&error];
//            NSString * jsonString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//            NSLog(@"[InAppPurchase_oc] skproducts info: %@",jsonString);
//        }
    }else{
        NSLog(@"The selected item cannot be purchased.check your appstoreconnect ! productId = %@------------", _productId );
        [self.delegate errorHandler:[self errorWithCode:ErrorStoreProductNotAvailable andDesc:@"The selected item cannot be purchased."] withProductID:_productId andBillNO:self.billNo];
    }
    NSLog(@"-----[EZIAP InAppPurchase_oc] End ***************");
}

#pragma mark -
#pragma mark SKRequestDelegate
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"-----[EZIAP InAppPurchase_oc]  SKRequest didFailWithError ----------");
    [self.delegate errorHandler:error withProductID:_productId andBillNO:self.billNo];
}

-(void) requestDidFinish:(SKRequest *)request
{
    NSLog(@"-----[EZIAP InAppPurchase_oc] SKRequest requestDidFinish----");
    [self.delegate productRequestFinishWithProductID:_productId andBillNO:self.billNo];
}

#pragma mark —— return a NSError
- (NSError *)errorWithCode:(int)code andDesc:(NSString*)localizedDescription{
    NSDictionary * userInfo = [NSDictionary dictionaryWithObject:localizedDescription forKey:NSLocalizedDescriptionKey];
    NSError * aError = [NSError errorWithDomain:NSCocoaErrorDomain code:code userInfo:userInfo];
    return aError;
}


-(void) PurchasedTransaction: (SKPaymentTransaction *)transaction
{
    NSLog(@"-----[EZIAP InAppPurchase_oc] PurchasedTransaction----");
    NSArray *transactions =[[NSArray alloc] initWithObjects:transaction, nil];
    [self paymentQueue:[SKPaymentQueue defaultQueue] updatedTransactions:transactions];
}

/**** 监听交易状态  ***/
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions//交易结果
{
    NSLog(@"-----[EZIAP InAppPurchase_oc] paymentQueue updatedTransactions --------");
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased://交易完成
            {
                NSLog(@"-----[EZIAP InAppPurchase_oc] SKPaymentTransactionStatePurchased --------");
                [self completeTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateFailed://交易失败
            {
                NSError *error = transaction.error;
                NSLog(@"-----[EZIAP InAppPurchase_oc] SKPaymentTransactionStateFailed errorCode = %ld; msg = %@ ",error.code,[error localizedDescription]);
                [self failedTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateRestored://已经购买过该商品
            {
                NSLog(@"-----[EZIAP InAppPurchase_oc] SKPaymentTransactionStateRestored --------");
                [self restoreTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStatePurchasing:      //商品添加进列表
            {
                NSLog(@"-----[EZIAP InAppPurchase_oc] SKPaymentTransactionStatePurchasing --------");
                break;
            }
            default:
                NSLog(@"-----[EZIAP InAppPurchase_oc] transactionState %ld--------",(long)transaction.transactionState);
                break;
        }
    }
}

-(void) paymentQueueRestoreCompletedTransactionsFinished: (SKPaymentTransaction *)transaction{
    NSLog(@"-----[EZIAP InAppPurchase_oc] paymentQueueRestoreCompletedTransactionsFinished  ----");
    [self.delegate receiveTransaction:transaction andBillNO:self.billNo];
}

-(void) paymentQueue:(SKPaymentQueue *) paymentQueue restoreCompletedTransactionsFailedWithError:(NSError *)error{
    NSLog(@"-----[EZIAP InAppPurchase_oc] restoreCompletedTransactionsFailedWithError----");
    if (error != nil){
        [self.delegate errorHandler:error withProductID:self.productId andBillNO:self.billNo];
    }
}

- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
    [self.delegate receiveTransaction:transaction andBillNO:self.billNo];
    // Remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    _productId = nil;
    _billNo = nil;
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{
    [self.delegate receiveTransaction:transaction andBillNO:self.billNo];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction{
    [self.delegate receiveErrorTransaction:transaction andBillNO:self.billNo ];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    _productId = nil;
    _billNo = nil;
}


-(void)dealloc
{
    _delegate = nil;
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}
@end
