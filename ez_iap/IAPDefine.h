//
//  IAPDefine.h
//  IAPdemo
//
//  Created by Howe on 09/09/2017.
//  Copyright © 2017 Howe. All rights reserved.
//

#ifndef IAPDefine_h
#define IAPDefine_h

enum IAP_CODE
{
    ErrorUnknown = 100,
    ErrorClientInvalid = 101,                          // client is not allowed to issue the request, etc.
    ErrorPaymentError = 99,
    ErrorPaymentCancelled = 102,                       // user cancelled the request, etc.
    ErrorPaymentInvalid=103,                           // purchase identifier was invalid, etc.
    ErrorPaymentNotAllowed=104,                        // this device is not allowed to make the payment
    ErrorStoreProductNotAvailable=105,                  // Product is not available in the current storefront
    ErrorCloudServicePermissionDenied =106,           // user has not allowed access to cloud service information
    ErrorCloudServiceNetworkConnectionFailed =107,    // the device could not connect to the nework
    ErrorCloudServiceRevoked =108,                   // user has revoked permission to use this cloud service
    ErrorVerifyReceipt = 110,  // IAP验证错误
    ErrorRestoreTransactionsFailed = 111,
    
    LIST_AVALIABLE = 0,        // 获得购买列表
    IAPPAY_SUCCESS  = 1,
    VERIFY_RECEIPT_RESULT = 2,
    
};

#define IAP_SANDBOX "https://sandbox.itunes.apple.com/verifyReceipt"
#define IAP_RELEASE "https://buy.itunes.apple.com/verifyReceipt"

#endif /* IAPDefine_h */
