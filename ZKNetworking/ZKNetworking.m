//
//  ZKNetworking.m
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

#import "ZKNetworking.h"
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

@implementation NSURLRequest (Extension)

/** 判断是否是同一个请求（依据是请求URL和参数是否相同）*/
- (BOOL)isSameRequest:(NSURLRequest *)request
{
    if ([self.HTTPMethod isEqualToString:request.HTTPMethod]) {
        if ([self.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
            if ([self.HTTPMethod isEqualToString:@"GET"] || [self.HTTPBody isEqualToData:request.HTTPBody]) return YES;
        }
    }
    return NO;
}

@end

static BOOL _printLog = YES;
static NSMutableArray *_requestTasksPool;
static AFHTTPSessionManager *_sessionManager;
static ZKRequestsIgnoreMode _ignoreMode = ZKRequestsIgnoreModeNone;

@implementation ZKNetworking

#pragma mark -- 初始化
+ (void)initialize
{
    // 防止子类未实现 +initialize 方法时，调用父类 +initialize 方法，造成多次初始化
    if (self != [ZKNetworking class]) return;
    
    _sessionManager = [AFHTTPSessionManager manager];
    
    // 默认数据格式
    _sessionManager.requestSerializer  = [AFHTTPRequestSerializer serializer];
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    // 默认请求超时时间
    _sessionManager.requestSerializer.timeoutInterval = 30.f;
    
    // 配置响应序列化
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", @"application/octet-stream", @"application/zip"]];
    
    // 开启网络请求菊花显示
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
}

#pragma mark -- GET请求
+ (__kindof NSURLSessionTask *)GET:(NSString *)url parameters:(id)params success:(ZKSuccess)success failure:(ZKFailure)failure
{
    if (_printLog) NSLog(@"URL = %@\nparams = %@", url, params);
    
    // 特殊字符转码
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURLSessionTask *sessionTask = [_sessionManager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_printLog) NSLog(@"response = %@", responseObject);
        if (success) success(responseObject);
        [[self allTasks] removeObject:task];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_printLog) NSLog(@"error = %@", error);
        if (failure) failure(error);
        [[self allTasks] removeObject:task];
    }];
    
    // 将请求添加到请求池
    [self addTask:sessionTask];
    
    return sessionTask;
}

#pragma mark -- POST请求
+ (__kindof NSURLSessionTask *)POST:(NSString *)url parameters:(id)params success:(ZKSuccess)success failure:(ZKFailure)failure
{
    if (_printLog) NSLog(@"URL = %@\nparams = %@", url, params);
    
    // 特殊字符转码
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_printLog) NSLog(@"response = %@", responseObject);
        if (success) success(responseObject);
        [[self allTasks] removeObject:task];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_printLog) NSLog(@"error = %@", error);
        if (failure) failure(error);
        [[self allTasks] removeObject:task];
    }];
    
    // 将请求添加到请求池
    [self addTask:sessionTask];
    
    return sessionTask;
}

#pragma mark -- 上传文件
+ (__kindof NSURLSessionTask *)uploadFileWithUrl:(NSString *)url parameters:(id)params folderName:(NSString *)name filePath:(NSString *)filePath progress:(ZKProgress)progress success:(ZKSuccess)success failure:(ZKFailure)failure
{
    if (_printLog) NSLog(@"URL = %@\nparams = %@", url, params);
    
    // 特殊字符转码
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSError *error = nil;
        [formData appendPartWithFileURL:[NSURL URLWithString:filePath] name:name error:&error];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (progress) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
            });
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_printLog) NSLog(@"response = %@", responseObject);
        if (success) success(responseObject);
        [[self allTasks] removeObject:task];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_printLog) NSLog(@"error = %@", error);
        if (failure) failure(error);
        [[self allTasks] removeObject:task];
    }];
    
    if (sessionTask) [[self allTasks] addObject:sessionTask];
    
    return sessionTask;
}

+ (__kindof NSURLSessionTask *)uploadImahesWithUrl:(NSString *)url parameters:(id)params folderName:(NSString *)name imageScale:(CGFloat)scale images:(NSArray<UIImage *> *)images imageTypes:(NSArray<NSString *> *)types mimeTypes:(NSArray<NSString *> *)mimeTypes progress:(ZKProgress)progress success:(ZKSuccess)success failure:(ZKFailure)failure
{
    if (_printLog) NSLog(@"URL = %@\nparams = %@", url, params);
    
    // 特殊字符转码
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURLSessionTask *sessionTask = [_sessionManager POST:url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (NSInteger i = 0; i < images.count; i++) {
            @autoreleasepool {
                // 图片经过等比压缩后得到的二进制文件
                NSData *imageData = UIImageJPEGRepresentation(images[i], scale);
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.dateFormat = @"yyyyMMddHHmmss";
                NSString *dateString = [formatter stringFromDate:[NSDate date]];
                NSString *imageName = [NSString stringWithFormat:@"%@_%zd.%@", dateString, i, types[i]];
                
                [formData appendPartWithFileData:imageData name:name fileName:imageName mimeType:mimeTypes[i]];
            }
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (progress) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                progress(uploadProgress.completedUnitCount, uploadProgress.totalUnitCount);
            });
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (_printLog) NSLog(@"response = %@", responseObject);
        if (success) success(responseObject);
        [[self allTasks] removeObject:task];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (_printLog) NSLog(@"error = %@", error);
        if (failure) failure(error);
        [[self allTasks] removeObject:task];
    }];
    
    if (sessionTask) [[self allTasks] addObject:sessionTask];
    
    return sessionTask;
}

#pragma mark -- 下载文件
+ (__kindof NSURLSessionTask *)downloadFile:(NSString *)url savaPath:(NSString *)path progress:(ZKProgress)progress complete:(ZKSuccess)complete failure:(ZKFailure)failure
{
    if (_printLog) NSLog(@"URL = %@", url);
    
    // 特殊字符转码
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    __block NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        if (progress) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                progress(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
            });
        }
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        if (error) {
            if (_printLog) NSLog(@"error = %@", error);
            if (failure) failure(error);
        } else {
            if (_printLog && response) NSLog(@"response = %@", response);
            if (complete) complete([NSData dataWithContentsOfURL:filePath]);
        }
    }];
    
    [downloadTask resume];
    
    if (downloadTask) [[self allTasks] addObject:downloadTask];
    
    return downloadTask;
}

#pragma mark -- 网络监听
+ (void)startNetworkStatusStateMonitoring
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

+ (void)networkStatusWithBlock:(ZKNetworkStatusChanged)block
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    if (block) block(ZKNetworkStatusUnknown);
                    if (_printLog) NSLog(@"未知网络");
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    if (block) block(ZKNetworkStatusNotReachable);
                    if (_printLog) NSLog(@"无网络");
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    if (block) block(ZKNetworkStatusReachableViaWWAN);
                    if (_printLog) NSLog(@"蜂窝数据网络");
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    if (block) block(ZKNetworkStatusReachableViaWiFi);
                    if (_printLog) NSLog(@"WiFi网络");
                    break;
                default:
                    if (block) block(ZKNetworkStatusUnknown);
                    if (_printLog) NSLog(@"未知网络");
                    break;
            }
        }];
    });
}

#pragma mark -- 开启日志打印
+ (void)openLogs:(BOOL)log
{
    _printLog = log;
}

#pragma mark -- 忽略 value 为 null 的键值对
+ (void)removesKeysWithNullValues:(BOOL)remove
{
    ((AFJSONResponseSerializer *)_sessionManager.responseSerializer).removesKeysWithNullValues = remove;
}

#pragma mark -- 取消所有请求
+ (void)cancleAllRequests
{
    @synchronized (self) {
        [[self allTasks] enumerateObjectsUsingBlock:^(NSURLSessionTask  *_Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
            [task cancel];
        }];
        [[self allTasks] removeAllObjects];
    }
}

#pragma mark -- 当前正在进行的请求
+ (NSArray<__kindof NSURLSessionTask *> *)currentRunningTasks
{
    return [[self allTasks] copy];
}

#pragma mark -- 相关配置
+ (void)setRequestsIgnoreMode:(ZKRequestsIgnoreMode)mode
{
    _ignoreMode = mode;
}

+ (void)setHttpHeader:(NSString *)value forKey:(NSString *)key
{
    [_sessionManager.requestSerializer setValue:value forHTTPHeaderField:key];
}

+ (void)setTimeoutInterval:(NSTimeInterval)timeout
{
    _sessionManager.requestSerializer.timeoutInterval = timeout;
}

+ (void)setSecurityPolicyWithCerPath:(NSString *)path SSLPinningMode:(ZKSSLPinningMode)mode allowInvalidCertificates:(BOOL)allow validatesDomainName:(BOOL)validates
{
    AFSSLPinningMode pinningMode;
    NSData *cerData = [NSData dataWithContentsOfFile:path];
    
    switch (mode) {
        case ZKSSLPinningModeNone:
            pinningMode = AFSSLPinningModeNone;
            break;
        case ZKSSLPinningModePublicKey:
            pinningMode = AFSSLPinningModePublicKey;
            break;
        case ZKSSLPinningModeCertificate:
            pinningMode = AFSSLPinningModeCertificate;
            break;
    }
    
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:pinningMode];
    securityPolicy.allowInvalidCertificates = allow;
    securityPolicy.validatesDomainName = validates;
    securityPolicy.pinnedCertificates = [NSSet setWithObject:cerData];
    
    [_sessionManager setSecurityPolicy:securityPolicy];
}

+ (void)setRequestSerializer:(ZKRequestSerializer)requestSerializer
{
    switch (requestSerializer) {
        case ZKRequestSerializerHTTP:
            _sessionManager.requestSerializer = [AFHTTPRequestSerializer serializer];
            break;
        case ZKRequestSerializerJSON:
            _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
            break;
    }
}

+ (void)setResponseSerializer:(ZKResponseSerializer)responseSerializer
{
    switch (responseSerializer) {
        case ZKResponseSerializerHTTP:
            _sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        case ZKResponseSerializerJSON:
            _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
            break;
        case ZKResponseSerializerXMLParser:
            _sessionManager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        case ZKResponseSerializerPropertyList:
            _sessionManager.responseSerializer = [AFPropertyListResponseSerializer serializer];
            break;
        case ZKResponseSerializerImage:
            _sessionManager.responseSerializer = [AFImageResponseSerializer serializer];
            break;
    }
}

+ (void)setAFHTTPSessionManagerProperty:(void(^)(AFHTTPSessionManager *sessionManager))sessionManager
{
    if (sessionManager) sessionManager(_sessionManager);
}

#pragma mark -- Pravite Methods
+ (NSMutableArray *)allTasks
{
    if (_requestTasksPool == nil) {
        
        _requestTasksPool = [NSMutableArray array];
    }
    return _requestTasksPool;
}

+ (__kindof NSURLSessionTask *)findSameRequestInTasksPool:(NSURLSessionTask *)task
{
    __block NSURLSessionTask *sameTask = nil;
    [[self currentRunningTasks] enumerateObjectsUsingBlock:^(NSURLSessionTask *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([task.originalRequest isSameRequest:obj.originalRequest]) {
            sameTask = obj;
            *stop = YES;
        }
    }];
    return sameTask;
}

+ (void)addTask:(NSURLSessionTask *)task
{
    if (task == nil) return;
    
    if (_ignoreMode != ZKRequestsIgnoreModeNone) { // 忽略重复请求
        NSURLSessionTask *sameTask = [self findSameRequestInTasksPool:task];
        if (sameTask) {
            if (_ignoreMode == ZKRequestsIgnoreModeForward) {
                [sameTask cancel];
                [[self allTasks] removeObject:sameTask];
            } else {
                [task cancel];
                return;
            }
        }
    }
    [[self allTasks] addObject:task];
}

@end
