//
//  YXNetworking.m
//  Networking
//
//  Created by YouXianMing on 2017/8/18.
//  Copyright © 2017年 TechCode. All rights reserved.
//

#import "YXNetworking.h"

@interface YXNetworking ()

@property (nonatomic, strong) AFHTTPSessionManager *session;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@end

@implementation YXNetworking

- (instancetype)init {
    
    if (self = [super init]) {
     
        // AFNetworking 3.x 相关初始化
        self.session = [AFHTTPSessionManager manager];
        
        // requestSerializer
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
        
        // responseSerializer
        self.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        // 请求参数预处理策略
        self.requestParameterSerializer = [RequestParameterSerializer new];
        
        // 回复数据预处理策略
        self.responseDataSerializer = [ResponseDataSerializer new];
        
        // timeoutInterval
        self.timeoutInterval = @(5.f);
        
        // 默认GET请求
        self.method = kYXNetworkingGET;
    }
    
    return self;
}

- (void)startRequest {

    NSParameterAssert(self.urlString);
    NSParameterAssert(self.requestSerializer);
    NSParameterAssert(self.responseSerializer);
    NSParameterAssert(self.requestParameterSerializer);
    NSParameterAssert(self.responseDataSerializer);
    
    // 设置请求序列化
    self.session.requestSerializer = self.requestSerializer;
    
    // 设置超时时间
    if (self.timeoutInterval && self.timeoutInterval.floatValue > 0) {
        
        [self.session.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        self.session.requestSerializer.timeoutInterval = self.timeoutInterval.floatValue;
        [self.session.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    }
    
    // 设置请求头部信息
    if (self.HTTPHeaderFieldsWithValues) {
        
        NSArray *allKeys = self.HTTPHeaderFieldsWithValues.allKeys;
        
        for (NSString *headerField in allKeys) {
            
            NSString *value = [self.HTTPHeaderFieldsWithValues valueForKey:headerField];
            [self.session.requestSerializer setValue:value forHTTPHeaderField:headerField];
        }
    }
    
    // 设置回复序列化以及回复数据的ContentType支持的类型
    self.session.responseSerializer                        = self.responseSerializer;
    self.session.responseSerializer.acceptableContentTypes = [self.session.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    self.session.responseSerializer.acceptableContentTypes = [self.session.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
    
    // 如果设置了信息对象,则显示信息
    if (self.networkingInfo) {
        
        self.networkingInfo.networking = self;
        [self.networkingInfo showMessage];
    }
    
    if /* GET */ (self.method == kYXNetworkingGET) {
        
        self.isRunning                = YES;
        __weak YXNetworking *weakSelf = self;
        
        self.dataTask = [self.session GET:self.urlString
                               parameters:[self.requestParameterSerializer serializeRequestParameter:self.requestParameter]
                                 progress:nil
                                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                      
                                      weakSelf.isRunning              = NO;
                                      weakSelf.originalResponseData   = responseObject;
                                      weakSelf.serializerResponseData = [weakSelf.responseDataSerializer serializeResponseData:responseObject];
                                      
                                      if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(YXNetworkingRequestSucess:tag:data:)]) {
                                          
                                          [weakSelf.delegate YXNetworkingRequestSucess:self tag:self.tag data:weakSelf.serializerResponseData];
                                      }
                                      
                                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                      
                                      weakSelf.isRunning = NO;
                                      
                                      if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(YXNetworkingRequestFailed:tag:error:)]) {
                                          
                                          [weakSelf.delegate YXNetworkingRequestFailed:self tag:self.tag error:error];
                                      }
                                  }];
        
    } /* POST */ else if (self.method == kYXNetworkingPOST) {
        
        self.isRunning                = YES;
        __weak YXNetworking *weakSelf = self;
        
        self.dataTask = [self.session POST:self.urlString
                                parameters:[self.requestParameterSerializer serializeRequestParameter:self.requestParameter]
                                  progress:nil
                                   success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                       
                                       weakSelf.isRunning              = NO;
                                       weakSelf.originalResponseData   = responseObject;
                                       weakSelf.serializerResponseData = [weakSelf.responseDataSerializer serializeResponseData:responseObject];
                                       
                                       if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(YXNetworkingRequestSucess:tag:data:)]) {
                                           
                                           [weakSelf.delegate YXNetworkingRequestSucess:self tag:self.tag data:weakSelf.serializerResponseData];
                                       }
                                       
                                   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                       
                                       weakSelf.isRunning = NO;
                                       
                                       if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(YXNetworkingRequestFailed:tag:error:)]) {
                                           
                                           [weakSelf.delegate YXNetworkingRequestFailed:self tag:self.tag error:error];
                                       }
                                   }];
    }
}

- (void)cancelRequest {
 
    [self.dataTask cancel];
}

+ (instancetype)networkingWithUrlString:(NSString *)urlString
                       requestParameter:(id)requestParameter
                                 method:(EYXNetworkingMethod)method
             requestParameterSerializer:(RequestParameterSerializer *)requestParameterSerializer
                 responseDataSerializer:(ResponseDataSerializer *)responseDataSerializer
                                    tag:(NSInteger)tag
                               delegate:(id <YXNetworkingDelegate>)delegate
                      requestSerializer:(AFHTTPRequestSerializer <AFURLRequestSerialization> *)requestSerializer
                     ResponseSerializer:(AFHTTPResponseSerializer <AFURLResponseSerialization> *)responseSerializer {
    
    YXNetworking *networking    = [[self class] new];
    networking.urlString        = urlString;
    networking.method           = method;
    networking.tag              = tag;
    networking.requestParameter = requestParameter;
    networking.delegate         = delegate;

    requestSerializer  ? networking.requestSerializer  = requestSerializer : 0;
    responseSerializer ? networking.responseSerializer = responseSerializer : 0;
    requestParameterSerializer ? networking.requestParameterSerializer = requestParameterSerializer : 0;
    responseDataSerializer     ? networking.responseDataSerializer     = responseDataSerializer     : 0;
    
    return networking;
}

- (void)dealloc {
    
    NSLog(@"%@ dealloc", self.serviceInfo);
    [self.dataTask cancel];
    self.dataTask = nil;
    self.session  = nil;
}

@end