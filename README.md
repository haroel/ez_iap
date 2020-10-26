# ez_iap

A simple lib for iOS IAP.


# GET STARTED

### 1. Add the following to your Podfile:

`pod 'ez_iap'`



### 2. Import the required header files

```

#import <ez_iap/IAPApi.h>


// Declare that the IAP delegate implements the EZIAPDelegate protocol.
@interface PluginIAP : PluginBase<EZIAPDelegate>

```


### 3. Add IAPApi to you code

```

    // if YES, IAPApi will autoverfify the receipt,  default NO;
    // Recommended use server authentication!
	[IAPApi Instance].autoVerify = YES;
	
    // set to debugMode or not, default NO;
	[IAPApi Instance].debugMode = YES;
	
	[IAPApi Instance].delegate = self;

```


### 4. Implement the EZIAPDelegate protocol to handle the iap process by defining the following methods:


```
#pragma mark -
#pragma mark EZIAPDelegate 
- (void) payResult:(NSDictionary*)payInfo{

	/**
		payInfo = {
			productID:"xxxx",
			productIdentifier:"xxxx",     //same as ‘productID’
			billNO:"zzzz",                // A billNO you send to IAP
 			transactionIdentifier:"yyyy", // appstore transactionIdentifier
			receipt:"KKKKK",              // appstore payment receipt 
		}
	
	*/
    // If the payment is successful, the next step is to verify the order. 
    // If autoverify = true, it will be completed automatically
    [self nativeEventHandler:@"pay_success" andParams:[JSONUtil stringify:payInfo]];
}

- (void) verifyResult:(NSString*)billNO andProductID:(NSString*)productID andResult:(NSDictionary*)verfyInfo{
	// receipt verify Result 
	// Verfyinfo is the result of Apple's order， you can check the order status and paymentInfo;
    
}

- (void) productList:(NSArray*)list{
    // appleconnect payment list
    
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


### 5. Start pay

```
/**
 * request pay
 * @param product productIdentifier
 * @param billNO  you billNO （a string which can identify the user）
 **/
[[IAPApi Instance] buy:{productId} billNo:{billNO}];

```


### 6. Get product list of app store

```

/**
 * Get product list of app store
 * @param productArray 产品id数组
 **/
[[IAPApi Instance] getProductList:{productArray}];

```


### 7. Verify Receipt


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

enjoy！

ihowe@outlook.com  2020/10/26