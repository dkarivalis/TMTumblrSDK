//
//  TMOAuth.m
//  TumblrAuthentication
//
//  Created by Bryan Irace on 11/19/12.
//  Copyright (c) 2012 Tumblr. All rights reserved.
//

#import "TMOAuth.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <sys/sysctl.h>
#import "TMSDKFunctions.h"

@interface TMOAuth()

NSString *generateBaseString(NSString *baseURL, NSString *method, NSDictionary *headers, NSDictionary *queryParameters,
                             NSDictionary *postParameters);

NSString *sign(NSString *baseString, NSString *consumerSecret, NSString *tokenSecret);

NSString *UNIXTimestamp(NSDate *date);

NSData *HMACSHA1(NSString *dataString, NSString *keyString);

@end


@implementation TMOAuth

+ (NSString *)headerForURL:(NSURL *)URL method:(NSString *)method postParameters:(NSDictionary *)postParameters
                     nonce:(NSString *)nonce consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret
                     token:(NSString *)token tokenSecret:(NSString *)tokenSecret {
    TMOAuth *auth = [[TMOAuth alloc] initWithURL:URL method:method postParameters:postParameters nonce:nonce
                                     consumerKey:consumerKey consumerSecret:consumerSecret token:token tokenSecret:tokenSecret];
    return auth.headerString;
}

+ (NSURL *)signUrlWithQueryComponent:(NSURL *)URL method:(NSString *)method postParameters:(NSDictionary *)postParameters
                               nonce:(NSString *)nonce consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret
                               token:(NSString *)token tokenSecret:(NSString *)tokenSecret timestamp:(NSString *)timestamp {
    NSMutableDictionary *oauthParameters = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                              @"oauth_timestamp" : timestamp,
                                                                                              @"oauth_nonce" : nonce,
                                                                                              @"oauth_version" : @"1.0",
                                                                                              @"oauth_signature_method" : @"HMAC-SHA1",
                                                                                              @"oauth_consumer_key" : consumerKey,
                                                                                              }];
    if (token && token.length > 0)
        oauthParameters[@"oauth_token"] = token;

    NSDictionary *queryParameters = TMQueryStringToDictionary(URL.query);
    NSString *baseURLString = [[URL absoluteString] componentsSeparatedByString:@"?"][0];
    NSString *baseString = generateBaseString(baseURLString, method, oauthParameters, queryParameters, postParameters);
    oauthParameters[@"oauth_signature"] = sign(baseString, consumerSecret, tokenSecret);

    NSMutableArray *queryItems = [NSMutableArray array];
    for (NSString *key in oauthParameters)
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:TMURLEncode(oauthParameters[key])]];

    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:URL resolvingAgainstBaseURL:true];
    urlComponents.queryItems = queryItems;

    return [urlComponents URL];
}

- (id)initWithURL:(NSURL *)URL method:(NSString *)method postParameters:(NSDictionary *)postParameters
            nonce:(NSString *)nonce consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret
            token:(NSString *)token tokenSecret:(NSString *)tokenSecret {
    if (self = [super init]) {
        NSMutableDictionary *headerParameters = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                 @"oauth_timestamp" : UNIXTimestamp([NSDate date]),
                                                 @"oauth_nonce" : nonce,
                                                 @"oauth_version" : @"1.0",
                                                 @"oauth_signature_method" : @"HMAC-SHA1",
                                                 @"oauth_consumer_key" : consumerKey,
                                                 }];
        
        if (token && token.length > 0)
            headerParameters[@"oauth_token"] = token;
        
        NSDictionary *queryParameters = TMQueryStringToDictionary(URL.query);
        
        NSString *baseURLString = [[URL absoluteString] componentsSeparatedByString:@"?"][0];
        
        NSString *baseString = generateBaseString(baseURLString, method, headerParameters, queryParameters, postParameters);
        
        _baseString = baseString;
        
        headerParameters[@"oauth_signature"] = sign(baseString, consumerSecret, tokenSecret);
        
        NSMutableArray *components = [NSMutableArray array];
        
        for (NSString *key in headerParameters)
            [components addObject:[NSString stringWithFormat:@"%@=\"%@\"", key, TMURLEncode(headerParameters[key])]];
        
        _headerString = [NSString stringWithFormat:@"OAuth %@", [components componentsJoinedByString:@","]];
    }
    
    return self;
}

#pragma mark - Private

NSString *generateBaseString(NSString *baseURL, NSString *method, NSDictionary *headers, NSDictionary *queryParameters,
                             NSDictionary *postParameters) {
    NSMutableDictionary *signatureParameters = [NSMutableDictionary dictionaryWithDictionary:headers];
    [signatureParameters addEntriesFromDictionary:queryParameters];
    [signatureParameters addEntriesFromDictionary:postParameters];
    
    NSString *parameterString = TMDictionaryToQueryString(signatureParameters);
    
    return [NSString stringWithFormat:@"%@&%@&%@", method, TMURLEncode(baseURL), TMURLEncode(parameterString)];
}

NSString *sign(NSString *baseString, NSString *consumerSecret, NSString *tokenSecret) {
    NSString *keyString = [NSString stringWithFormat:@"%@&%@", consumerSecret, tokenSecret ? tokenSecret : @""];
    
    NSData *hashedData = HMACSHA1(baseString, keyString);

    return [hashedData base64EncodedStringWithOptions:0];
}

NSString *UNIXTimestamp(NSDate *date) {
    return [NSString stringWithFormat:@"%f", round([date timeIntervalSince1970])];
}

NSData *HMACSHA1(NSString *dataString, NSString *keyString) {
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *key = [keyString dataUsingEncoding:NSUTF8StringEncoding];
    
    void *buffer = malloc(CC_SHA1_DIGEST_LENGTH);
    CCHmac(kCCHmacAlgSHA1, [key bytes], [key length], [data bytes], [data length], buffer);
    
    return [NSData dataWithBytesNoCopy:buffer length:CC_SHA1_DIGEST_LENGTH freeWhenDone:YES];
}

@end
