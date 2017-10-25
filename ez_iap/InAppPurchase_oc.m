//
//  InAppPurchaseManager.m
//  RoN
//
//  Created by CoA Studio on 13-3-18.
//
//
#import "InAppPurchase_oc.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include "IAPDefine.h"

@implementation InAppPurchase_oc
-(void)initIAP
{
    //监听购买状态
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    _billNo = nil;
    _productId = nil;
}

-(void)buy:(NSString *)product andBillNO:(NSString*)bNo{
    if ([SKPaymentQueue canMakePayments]){
        _billNo = [bNo copy];
        _productId = [product copy];

        NSLog(@"[InAppPurchase_oc]向App Store申请购买的Product ID:%@ ,订单号：%@",_productId,_billNo);
        [self RequestProductData:product];
    }else
    {
        NSLog(@"[InAppPurchase_oc] 当前不允许程序内付费购买");
        [self.delegate errorCall:ErrorPaymentNotAllowed andErrorMsg:@"ErrorPaymentNotAllowed"];
    }
}

-(void)getCanBuyProductList:(NSArray *)productIds
{
    _productId = nil;
    _billNo = nil;
    NSSet *nsset = [NSSet setWithArray:productIds];
    SKProductsRequest *request=[[SKProductsRequest alloc] initWithProductIdentifiers: nsset];
    request.delegate=self;
    [request start];
}

-(void)RequestProductData:(NSString*)pid
{
    NSLog(@"---------请求对应的产品信息------------");
    NSArray *productArray = [[NSArray alloc] initWithObjects:pid, nil];
    NSSet *nsset = [NSSet setWithArray:productArray];
    SKProductsRequest *request=[[SKProductsRequest alloc] initWithProductIdentifiers: nsset];
    request.delegate=self;
    [request start];
}
///<SKProductsRequestDelegate> 请求协议
//收到的产品信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *myProduct = response.products;
    if ([response.invalidProductIdentifiers count] > 0){
        NSLog(@"无效产品Product ID:%@",response.invalidProductIdentifiers);
    }
    NSLog(@"可用的产品付费数量: %lu", (unsigned long)[myProduct count]);
    SKProduct *cproduct = nil;
    for(SKProduct *product in myProduct){
//        NSLog(@"SKProduct 描述信息%@", [product description]);
        NSLog(@"产品标题 %@" , [product localizedTitle]);
        NSLog(@"产品描述信息: %@" , [product localizedDescription]);
        NSLog(@"价格: %@" , [product price]);
        NSLog(@"Product id: %@" , [product productIdentifier]);
        NSString *pId = [product productIdentifier];
        if (  _productId != nil && [_productId isEqualToString:pId] ){
            cproduct = product;
        }
    }
    if (cproduct!=nil)
    {
//        SKPayment *payment = [SKPayment paymentWithProduct:cproduct];
        NSLog(@"[InAppPurchase_oc]Product ID:%@ ",_productId);
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:cproduct];
        if (_billNo != nil){
            NSLog(@"[InAppPurchase_oc]订单号：%@",_billNo);
            NSString *tempBillNo = [NSString stringWithString:_billNo];
            payment.requestData = [tempBillNo dataUsingEncoding:NSUTF8StringEncoding];
        }
        NSLog(@"---------发送购买请求 %@------------",_productId);
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
        if ( [NSJSONSerialization isValidJSONObject:plistArray] ){
            NSError *error;
            NSData * data = [NSJSONSerialization dataWithJSONObject:plistArray options:0 error:&error];
            NSString * jsonString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"skproducts info: %@",jsonString);
            [self.delegate productListCall:LIST_AVALIABLE andParams:jsonString];
        }
    }else{
        NSLog(@"--------- 所选商品 %@ 无法购买，请检查itunesconnect后台------------", _productId );
        [self.delegate errorCall:ErrorStoreProductNotAvailable andErrorMsg:@"所选商品无法购买！"];
    }
}

//弹出错误信息
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"-------弹出错误信息----------");
    [self.delegate errorCall:ErrorPaymentError andErrorMsg:[error localizedDescription]];
}

-(void) requestDidFinish:(SKRequest *)request
{
    NSLog(@"----------反馈信息结束--------------");
}

-(void) PurchasedTransaction: (SKPaymentTransaction *)transaction
{
    NSLog(@"-----PurchasedTransaction----");
    NSArray *transactions =[[NSArray alloc] initWithObjects:transaction, nil];
    [self paymentQueue:[SKPaymentQueue defaultQueue] updatedTransactions:transactions];
}

/**** 监听交易状态  ***/
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions//交易结果
{
    NSLog(@"-----paymentQueue--------");
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased://交易完成
            {
                NSLog(@"-----交易完成 --------");
                [self completeTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateFailed://交易失败
            {
                NSLog(@"-----交易失败 --------");
                [self failedTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateRestored://已经购买过该商品
            {
                NSLog(@"-----已经购买过该商品 --------");
                [self restoreTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStatePurchasing:      //商品添加进列表
            {
                NSLog(@"-----商品添加进列表 --------");
                break;
            }
            default:
                NSLog(@"----- 交易状态 transactionState %ld--------",(long)transaction.transactionState);
                break;
        }
    }
}
- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
    NSLog(@"-----completeTransaction--------");
    [self.delegate finishPay:transaction];
    // Remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    _productId = nil;
    _billNo = nil;
}

- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{
    [self.delegate finishPay:transaction];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    NSLog(@" 交易恢复处理");
}

- (void) failedTransaction: (SKPaymentTransaction *)transaction{
    NSError *error = transaction.error;
    long code =transaction.error.code;
    NSLog(@"failedTransaction errorCode:%ld; msg:%@",code,[error localizedDescription]);
    switch (transaction.error.code) {
        case SKErrorPaymentCancelled:
        {
            NSLog(@"-----取消支付--------");
            [self.delegate errorCall:ErrorPaymentCancelled andErrorMsg:[error localizedDescription]];
            break;
        }
        case SKErrorPaymentInvalid:
        {
            NSLog(@"-----无效支付--------");
            [self.delegate errorCall:ErrorPaymentInvalid andErrorMsg:[error localizedDescription]];
            break;
        }
        case SKErrorPaymentNotAllowed:
        {
            NSLog(@"-----不允许支付--------");
            [self.delegate errorCall:ErrorPaymentNotAllowed andErrorMsg:[error localizedDescription]];
            break;
        }
        default:{
            [self.delegate errorCall:ErrorPaymentError andErrorMsg:[error localizedDescription]];
            break;
        }
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    _productId = nil;
    _billNo = nil;
}
#pragma mark connection delegate
-(void) paymentQueueRestoreCompletedTransactionsFinished: (SKPaymentTransaction *)transaction{
    NSLog(@"-------paymentQueue RestoreCompleted ----");
}

-(void) paymentQueue:(SKPaymentQueue *) paymentQueue restoreCompletedTransactionsFailedWithError:(NSError *)error{
    NSLog(@"-------paymentQueue----");
    if (error != nil){
        [self.delegate errorCall:ErrorRestoreTransactionsFailed andErrorMsg:[error localizedDescription]];
        NSLog(@"ERROR:%@",error);
    }
}

-(void)dealloc
{
    _delegate = nil;
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];//解除监听
    
#if ! __has_feature(objc_arc)
    [super dealloc];
#endif
}
@end
