//
//  ViewController.m
//  ApplePayTest
//
//  Created by 董强 on 16/2/25.
//  Copyright © 2016年 董强. All rights reserved.
//

#import "ViewController.h"
#import <PassKit/PassKit.h>  // 用户绑定的的银行卡信息
#import <PassKit/PKPaymentAuthorizationViewController.h>    // applePay展示控件
#import <AddressBook/AddressBook.h> // 用户联系信息相关



@interface ViewController () <PKPaymentAuthorizationViewControllerDelegate>
{
    NSMutableArray *summaryItems;
    NSMutableArray *shippingMethods;
}
    
    
    


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    
    
    
    
    
}
- (IBAction)payButtonAction:(id)sender {

    
    if (![PKPaymentAuthorizationViewController class]) {
        // 需要 iOS8以上支持
        NSLog(@"操作系统不支持ApplePay，请升级至9.0以上版本，且iPhone6以上设备才支持");
        return;
    }
    
    if (![PKPaymentAuthorizationViewController canMakePayments]) {
        // 支付需要 iOS9 以上支持
        NSLog(@"请升级至 iOS9.0 以上");
        
        return;
    }
    
    NSArray *supportedNetworks = @[PKPaymentNetworkVisa,PKPaymentNetworkChinaUnionPay];
    if (![PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:supportedNetworks]) {
        
        NSLog(@"没有绑定支付卡");
        
        return;
    }

    
    NSLog(@"可以支付，开始建立支付请求");
    
    
    /**
     *  创建支付请求 PKPaymentRequest
     *  设置币种、国家码及merchant标识符等基本信息
     */
    PKPaymentRequest *payRequest = [[PKPaymentRequest alloc] init];
    payRequest.countryCode = @"CN";     // 国家代码
    payRequest.currencyCode = @"CNY";   // 币种代码
    payRequest.merchantIdentifier = @"merchant.DQApplePayDemo"; //申请的 merchantID
    payRequest.supportedNetworks = supportedNetworks;  // 用户可支付的银行卡
    payRequest.merchantCapabilities = PKMerchantCapability3DS | PKMerchantCapabilityEMV;  // 设置支持的交易处理协议, 3DS 必须支持, 国内建议使用两者
    
    
    /**
     *  设置发票配送信息和货物配送地址信息,用户设置后可通过代理回调获取信息的更新
     */
    
    payRequest.requiredBillingAddressFields = PKAddressFieldEmail;
   
    // 如果需要邮寄账单可以选择进行设置，默认PKAddressFieldNone(不邮寄账单)
    payRequest.requiredShippingAddressFields = PKAddressFieldPostalAddress | PKAddressFieldPhone | PKAddressFieldName;
    // 送货地址信息，这里设置需要地址和联系方式和姓名，如果需要进行设置，默认PKAddressFieldNone(没有送货地址)
    
    
    /**
     *  设置货物配送方式   (按需)
     */
    PKShippingMethod *freeShipping = [PKShippingMethod summaryItemWithLabel:@"包邮" amount:[NSDecimalNumber zero]];
    freeShipping.identifier = @"freeShipping";
    freeShipping.detail = @"6 - 8天送达";
    
    PKShippingMethod *expressShipping = [PKShippingMethod summaryItemWithLabel:@"宅急送" amount:[NSDecimalNumber decimalNumberWithString:@"15.00"]];
    expressShipping.identifier = @"expressShipping";
    expressShipping.detail = @"2 - 3小时送达";
    
    //shippingMethods为配送方式列表，类型是 NSMutableArray，这里设置成成员变量，在后续的代理回调中可以进行配送方式的调整。
    payRequest.shippingMethods = @[freeShipping, expressShipping];
    
    
    
    /**
     *   添加账单列表
     */
    
    // 商品价格
    NSDecimalNumber *subtotalAmount = [NSDecimalNumber decimalNumberWithMantissa:10075 exponent:-2 isNegative:NO];
    PKPaymentSummaryItem *subtotal = [PKPaymentSummaryItem summaryItemWithLabel:@"商品价格" amount:subtotalAmount];
    
    
    // 折扣
    NSDecimalNumber *discountAmount = [NSDecimalNumber decimalNumberWithString:@"-12.1"];
    PKPaymentSummaryItem *discount = [PKPaymentSummaryItem summaryItemWithLabel:@"优惠折扣" amount:discountAmount];
    
    // 邮费价格
    NSDecimalNumber *methodsAmount = [NSDecimalNumber zero];
    PKPaymentSummaryItem *methods = [PKPaymentSummaryItem summaryItemWithLabel:@"包邮" amount:methodsAmount];
   
    
    // 账单
    NSDecimalNumber *totalAmount = [NSDecimalNumber zero];
    totalAmount = [totalAmount decimalNumberByAdding:subtotalAmount];
    totalAmount = [totalAmount decimalNumberByAdding:discountAmount];
    totalAmount = [totalAmount decimalNumberByAdding:methodsAmount];

    // 支付给谁
    PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:@"dongqiang" amount:totalAmount];
    
    
    summaryItems = [NSMutableArray arrayWithArray:@[subtotal, discount, methods, total] ];
    // summaryItems为账单列表，类型是 NSMutableArray，这里设置成成员变量，在后续的代理回调中可以进行支付金额的调整。
    payRequest.paymentSummaryItems = summaryItems;
    
    
    
    // 推出 ApplePay 界面
    PKPaymentAuthorizationViewController *view = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:payRequest];
    view.delegate = self;
    [self presentViewController:view animated:YES completion:nil];
    

}


// 送货地址回调
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingContact:(PKContact *)contact completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {

    //contact送货地址信息，PKContact类型
    NSPersonNameComponents *name = contact.name;                //联系人姓名
    CNPostalAddress *postalAddress = contact.postalAddress;     //联系人地址
    NSString *emailAddress = contact.emailAddress;              //联系人邮箱
    CNPhoneNumber *phoneNumber = contact.phoneNumber;           //联系人手机
    NSString *supplementarySubLocality = contact.supplementarySubLocality;  //补充信息,iOS9.2及以上才有

    //送货信息选择回调，如果需要根据送货地址调整送货方式，比如普通地区包邮+极速配送，偏远地区只有付费普通配送，进行支付金额重新计算，可以实现该代理，返回给系统：shippingMethods配送方式，summaryItems账单列表，如果不支持该送货信息返回想要的PKPaymentAuthorizationStatus
    completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, summaryItems);
}


// 送货方式回调
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion{
    //配送方式回调，如果需要根据不同的送货方式进行支付金额的调整，比如包邮和付费加速配送，可以实现该代理
    PKShippingMethod *oldShippingMethod = [summaryItems objectAtIndex:2];
    PKPaymentSummaryItem *total = [summaryItems lastObject];
    total.amount = [total.amount decimalNumberBySubtracting:oldShippingMethod.amount];
    total.amount = [total.amount decimalNumberByAdding:shippingMethod.amount];
    
    [summaryItems replaceObjectAtIndex:2 withObject:shippingMethod];
    [summaryItems replaceObjectAtIndex:3 withObject:total];
    
    completion(PKPaymentAuthorizationStatusSuccess, summaryItems);
}


// 支付卡选择回调
-(void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectPaymentMethod:(PKPaymentMethod *)paymentMethod completion:(void (^)(NSArray<PKPaymentSummaryItem *> * _Nonnull))completion{
    
    //支付银行卡回调，如果需要根据不同的银行调整付费金额，可以实现该代理
    completion(summaryItems);
}



// 支付完成苹果服务器返回信息回调，做服务器验证
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion {
    
    PKPaymentToken *payToken = payment.token;
    //支付凭据，发给服务端进行验证支付是否真实有效
    PKContact *billingContact = payment.billingContact;     //账单信息
    PKContact *shippingContact = payment.shippingContact;   //送货信息
    PKContact *shippingMethod = payment.shippingMethod;     //送货方式
    //等待服务器返回结果后再进行系统block调用
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //模拟服务器通信
        completion(PKPaymentAuthorizationStatusSuccess);
    });
    
    
}
- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller{
    [controller dismissViewControllerAnimated:YES completion:nil];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
