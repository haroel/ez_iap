# ez_iap

iap封装库

##使用方式

1. cocoapods  `pod 'ez_iap'`

2. 引入头文件
```
#import <ez_iap/IAPDefine.h>
#import <ez_iap/IAPApi.h>
```

3. 初始化设置IAP回调监听
```
   // 设置IAP事件回调
    [[IAPApi Instance] setMessageHandler:^(int code, NSString *params) {
        NSLog(@"IAPEvent %d  %@",code);
        switch (code) {
            case IAPPAY_SUCCESS:
            {
               /**
               * 支付成功，返回一个json字符串
               {
                  productIdentifier:"xxx",
                  billNO:"xxxx",
                  receipt:"xxxxxxx"
               }
               */
               // 建议服务器做收据校验，如果你想用客户端来验证收据（单机），请调用以下方法, 第二个参数表示是否用沙箱验证，此处填NO
               [[IAPApi Instance] verifyReceipt:{receipt} andDebug:NO];
               break;
            }
            case LIST_AVALIABLE:{
               /**
               * itunestore产品列表，返回一个json字符串数组
               [
                 {
                    title:"xxx",
                    description:"xxxx",
                    price:"xxxxxxx",
                    productid:"xxxxxxx"
                 }
               ]
               */
               break;
            }
            case VERIFY_RECEIPT_RESULT:
            {
                /***iap收据验证结果,  请参考Apple开发文档                  https://developer.apple.com/library/content/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html
                **/
                if (status == 0){
                    // 验证成功, 发货
                    return;
                }
                if (status == 21007){
                    [[IAPApi Instance] verifyReceipt:{receipt} andDebug:YES];
                }
                break;
            }
            case ErrorPaymentError:
            case ErrorPaymentNotAllowed:
            case ErrorPaymentInvalid:
            case ErrorStoreProductNotAvailable:
            {
                break;
            }
            case ErrorPaymentCancelled:{
                NSLog(@"user cancel！");
                break;
            }
            default:
            break;
        }
    }];
```

4. 发起购买请求
```
/**
 * 购买，购买结果在setMessageHandler里处理
 * @param product 购买产品id
 * @param billNo 订单号
 **/
[[IAPApi Instance] buy:{productId} billNo:{billNo}];

```

5. 获取itunestore后台产品列表
```
/**
 * 获取App Store的产品列表，结果在setMessageHandler里处理
 * @param productArray 产品id数组
 **/
[[IAPApi Instance] getCanBuyProductList:{productArray}];

```
