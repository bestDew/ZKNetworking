//
//  ZKNetworking.h
//  ZKNetworking
//
//  Created by bestdew on 2018/10/9.
//  Copyright © 2018年 bestdew. All rights reserved.
//
//                      d*##$.
// zP"""""$e.           $"    $o
//4$       '$          $"      $
//'$        '$        J$       $F
// 'b        $k       $>       $
//  $k        $r     J$       d$
//  '$         $     $"       $~
//   '$        "$   '$E       $
//    $         $L   $"      $F ...
//     $.       4B   $      $$$*"""*b
//     '$        $.  $$     $$      $F
//      "$       R$  $F     $"      $
//       $k      ?$ u*     dF      .$
//       ^$.      $$"     z$      u$$$$e
//        #$b             $E.dW@e$"    ?$
//         #$           .o$$# d$$$$c    ?F
//          $      .d$$#" . zo$>   #$r .uF
//          $L .u$*"      $&$$$k   .$$d$$F
//           $$"            ""^"$$$P"$P9$
//          JP              .o$$$$u:$P $$
//          $          ..ue$"      ""  $"
//         d$          $F              $
//         $$     ....udE             4B
//          #$    """"` $r            @$
//           ^$L        '$            $F
//             RN        4N           $
//              *$b                  d$
//               $$k                 $F
//               $$b                $F
//                 $""               $F
//                 '$                $
//                  $L               $
//                  '$               $
//                   $               $

#import <Foundation/Foundation.h>

@import UIKit;
@class AFHTTPSessionManager;

/** 网络状态 */
typedef NS_ENUM(NSInteger, ZKNetworkStatus) {
    ZKNetworkStatusUnknown ,           // 未知网络
    ZKNetworkStatusNotReachable,       // 无网络
    ZKNetworkStatusReachableViaWWAN,   // 蜂窝数据网络
    ZKNetworkStatusReachableViaWiFi    // WiFi网络
};

/** 请求数据序列化格式 */
typedef NS_ENUM(NSUInteger, ZKRequestSerializer) {
    ZKRequestSerializerHTTP,           // 二进制格式
    ZKRequestSerializerJSON            // JSON格式
};

/** 响应数据序列化格式 */
typedef NS_ENUM(NSUInteger, ZKResponseSerializer) {
    ZKResponseSerializerHTTP,          // 二进制格式
    ZKResponseSerializerJSON,          // JSON格式
    ZKResponseSerializerXMLParser,     // XML格式
    ZKResponseSerializerPropertyList,  // plist格式
    ZKResponseSerializerImage          // 图片格式
};

/** Https证书验证模式 */
typedef NS_ENUM(NSUInteger, ZKSSLPinningMode) {
    ZKSSLPinningModeNone,              // 不校验
    ZKSSLPinningModePublicKey,         // 只校验publicKey
    ZKSSLPinningModeCertificate,       // 全部校验
};

/** 重复请求忽略模式 */
typedef NS_ENUM(NSUInteger, ZKRequestsIgnoreMode) {
    ZKRequestsIgnoreModeNone,          // 不忽略
    ZKRequestsIgnoreModeForward,       // 忽略旧请求
    ZKRequestsIgnoreModeBackward,      // 忽略新请求
};

/** 成功回调 */
typedef void (^ZKSuccess)(id response);
/** 失败回调 */
typedef void (^ZKFailure)(NSError *error);
/** 进度回调 */
typedef void (^ZKProgress)(int64_t bytesRead, int64_t totalBytes);
/** 网络实时状态回调 */
typedef void(^ZKNetworkStatusChanged)(ZKNetworkStatus status);

@interface ZKNetworking : NSObject

#pragma mark -- 请求方法
/** GET请求 */
+ (__kindof NSURLSessionTask *)GET:(NSString *)url
                        parameters:(id)params
                           success:(ZKSuccess)success
                           failure:(ZKFailure)failure;

/** POST请求 */
+ (__kindof NSURLSessionTask *)POST:(NSString *)url
                         parameters:(id)params
                            success:(ZKSuccess)success
                            failure:(ZKFailure)failure;

/**
 上传文件
 
 @param name 文件对应服务器上的字段
 @param filePath 文件本地路径
 */
+ (__kindof NSURLSessionTask *)uploadFileWithUrl:(NSString *)url
                                      parameters:(id)params
                                      folderName:(NSString *)name
                                        filePath:(NSString *)filePath
                                        progress:(ZKProgress)progress
                                         success:(ZKSuccess)success
                                         failure:(ZKFailure)failure;

/**
 上传图片

 @param name 文件对应服务器上的字段
 @param scale 图片压缩比（0.f~1.f）
 @param types 图片格式数组
 @param mimeTypes 媒体类型数组
 */
+ (__kindof NSURLSessionTask *)uploadImahesWithUrl:(NSString *)url
                                        parameters:(id)params
                                        folderName:(NSString *)name
                                        imageScale:(CGFloat)scale
                                            images:(NSArray<UIImage *> *)images
                                        imageTypes:(NSArray<NSString *> *)types
                                         mimeTypes:(NSArray<NSString *> *)mimeTypes
                                          progress:(ZKProgress)progress
                                           success:(ZKSuccess)success
                                           failure:(ZKFailure)failure;

/** 文件下载 */
+ (__kindof NSURLSessionTask *)downloadFile:(NSString *)url
                                   savaPath:(NSString *)path
                                   progress:(ZKProgress)progress
                                   complete:(ZKSuccess)complete
                                    failure:(ZKFailure)failure;

#pragma mark -- 其他方法
/** 开启网络监测，建议在 AppDelegate 中调用 */
+ (void)startNetworkStatusStateMonitoring;

/** 当前正在进行的请求 */
+ (NSArray<__kindof NSURLSessionTask *> *)currentRunningTasks;

/** 取消所有请求 */
+ (void)cancleAllRequests;

/**
 获取实时网络状态，通过Block回调实时获取
 ⚠️需先调用 +startNetworkStatusStateMonitoring，开启网络监测功能
 */
+ (void)networkStatusWithBlock:(ZKNetworkStatusChanged)block;

#pragma mark -- 相关配置
/** 是否开启日志打印（默认为YES，仅Debug时有效）*/
+ (void)openLogs:(BOOL)log;

/** 是否移除响应数据的Null值（默认为NO）*/
+ (void)removesKeysWithNullValues:(BOOL)remove;

/** 设置请求忽略模式 */
+ (void)setRequestsIgnoreMode:(ZKRequestsIgnoreMode)mode;

/** 设置请求头 */
+ (void)setHttpHeader:(NSString *)value forKey:(nonnull NSString *)key;

/** 设置请求超时时间，默认30s */
+ (void)setTimeoutInterval:(NSTimeInterval)timeout;

/** 设置请求数据序列化格式（默认为二进制格式）*/
+ (void)setRequestSerializer:(ZKRequestSerializer)requestSerializer;
/** 设置响应数据序列化格式（默认为JSON格式）*/
+ (void)setResponseSerializer:(ZKResponseSerializer)responseSerializer;

/**
 配置Https请求证书

 @param path 证书本地路径
 @param mode 证书校验模式
 @param allow 如果需要验证自建证书(无效证书)，需要设置为YES
 @param validates 是否需要验证域名，默认为YES。假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；如置为NO，建议自己添加对应域名的校验逻辑。
 */
+ (void)setSecurityPolicyWithCerPath:(NSString *)path
                      SSLPinningMode:(ZKSSLPinningMode)mode
            allowInvalidCertificates:(BOOL)allow
                 validatesDomainName:(BOOL)validates;

/**
 在开发中，如果以下的设置方式不满足项目的需求，就调用此方法获取AFHTTPSessionManager实例进行自定义设置
 (⚠️注意: 在调用此方法的地方需要引入AFNetworking.h头文件)
 */
+ (void)setAFHTTPSessionManagerProperty:(void(^)(AFHTTPSessionManager *sessionManager))sessionManager;

@end
