# ez_iap

A lib for iOS IAP

## GET STARTED

1. git clone sourcecode or cocoapods（ `pod 'ez_iap', :git => 'https://github.com/haroel/ez_iap.git'` ）, 支持ios8.0及以上


2. 初始化

```
#import <ez_iap/IAPApi.h>



    // 是否自动开启验证
    [IAPApi Instance].autoVerify = YES;
    
    // 开启将看到更多日志
	[IAPApi Instance].debugMode = YES;

    [IAPApi Instance].delegate = self;

```

3. 设置delegate回调

```

当前Objective-C 类需实现 <EZIAPDelegate>

#pragma mark -
#pragma mark EZIAPDelegate
- (void) payResult:(NSDictionary*)payInfo{
    // 支付成功，下一步需做订单校验，如果autoVerify = true，则自动完成
    [self nativeEventHandler:@"pay_success" andParams:[JSONUtil stringify:payInfo]];
}

- (void) verifyResult:(NSString*)billNO andProductID:(NSString*)productID andResult:(NSDictionary*)verfyInfo{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:verfyInfo];
    [dict setObject:billNO forKey:@"billNO"];
    [dict setObject:productID forKey:@"productID"];
    [self nativeEventHandler:@"verify_result" andParams:[JSONUtil stringify:dict]];
}

- (void) productList:(NSArray*)list{
    [self nativeEventHandler:@"list_success" andParams:[JSONUtil stringify:list]];
}

- (void) IAPFailed:(NSString*)billNO andProductID:(NSString*)productID widthError:(NSError*)error{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    if (error){
        NSLog(@"[PluginIAP] %@ %@ error = %@",productID,billNO,error);
        NSString *desc = [error localizedDescription];
        switch (error.code) {
            case SKErrorPaymentCancelled:
            {
                desc = @"The payment has been cancelled.";
                break;
            }
            case SKErrorPaymentInvalid:
            {
                desc = @"Purchase identifier was invalid.";
                break;
            }
            case SKErrorStoreProductNotAvailable:
            {
                desc = @"Product is not available in the current storefront.";
                break;
            }
            default:
                break;
        }
        [PluginCore alert:@"Message" andMsg:desc];
        [ret setObject:desc forKey:@"msg"];
    }
    [ret setObject:billNO forKey:@"billNO"];
    [ret setObject:productID forKey:@"productID"];
    [self nativeEventHandler:@"pay_error" andParams:[JSONUtil stringify:ret]];
}

```


5. 发起购买请求

```
/**
 * 购买，购买结果在setMessageHandler里处理
 * @param product 购买产品id
 * @param billNo 订单号
 **/
[[IAPApi Instance] buy:{productId} billNo:{billNo}];

```

6. 获取itunestore后台产品列表

```

/**
 * 获取App Store的产品列表，结果在setMessageHandler里处理
 * @param productArray 产品id数组
 **/
[[IAPApi Instance] getProductList:{productArray}];

```



7. 校验订单


```


IAPApi *api = [IAPApi Instance];
        [api verifyReceipt:receiptStr andDebug:NO withResultHandler:^(NSError *error, NSDictionary *response) {
            if (error){
                [self nativeCallbackErrorHandler:callback andParams:[error localizedDescription] ];
            }else{
                [self nativeCallbackHandler:callback andParams:[JSONUtil stringify:response]];
            }
        }];
        

```

说明： 对于json字符串处理，推荐用iOS Foundation框架库提供的原生`NSJSONSerialization`类处理，功能全面，无需再次引入第三方的json解析库！

> 以下提供一个json字符串解析的方法

```
+(id)parseJSON:(NSString *)jsonString
{
    NSData *jsonData= [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData == nil){
        NSLog(@"Error: NSString->NSData错误：%@",jsonString);
        return nil;
    }
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (jsonObject != nil && error == nil) {
        return jsonObject;
    } else {
        NSLog(@"Error: json解析错误：%@",error);
        return nil;
    }
}
```
enjoy！

ihowe@outlook.com  2020/10/23
