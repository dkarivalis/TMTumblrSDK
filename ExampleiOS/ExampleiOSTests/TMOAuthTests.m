//
//  TMOAuthTests.m
//  ExampleiOSTests
//
//  Created by dave on 11/28/17.
//  Copyright © 2017 tumblr. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <TMTumblrSDK/TMOAuth.h>

@interface TMOAuthTests : XCTestCase

@end

@implementation TMOAuthTests

- (void)testSignUrlWithQueryComponentCalculatesProperSignature {
    NSURL *signedURL = [TMOAuth signUrlWithQueryComponent:[NSURL URLWithString:@"https://tumblr.com/"]
                                                   method:@"GET"
                                           postParameters:[NSDictionary dictionary]
                                                    nonce:@"1234"
                                              consumerKey:@"consumerKey"
                                           consumerSecret:@"consumerSecret"
                                                    token:@"token"
                                              tokenSecret:@"tokenSecret"
                                                timestamp:@"1511967770"];
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:signedURL resolvingAgainstBaseURL:false];
    NSArray *queryItems = urlComponents.queryItems;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", @"oauth_signature"];
    NSURLQueryItem *queryItem = [[queryItems filteredArrayUsingPredicate:predicate] firstObject];
    
    XCTAssert([queryItem.value isEqualToString:@"w%2FLP1MdJwiCfakR3GbW9IoeOz1E%3D"], @"Calculated OAuth signature is incorrect!");
}

@end
