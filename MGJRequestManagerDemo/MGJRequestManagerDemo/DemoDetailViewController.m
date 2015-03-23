//
//  DemoDetailViewController.m
//  MGJRequestManagerDemo
//
//  Created by limboy on 3/20/15.
//  Copyright (c) 2015 juangua. All rights reserved.
//

#import "DemoDetailViewController.h"
#import "DemoListViewController.h"
#import "MGJRequestManager.h"
#import <CommonCrypto/CommonDigest.h>

@interface DemoDetailViewController ()
@property (nonatomic) UITextView *resultTextView;
@property (nonatomic) SEL selectedSelector;
@end

@implementation DemoDetailViewController

+ (void)load
{
    DemoDetailViewController *detailViewController = [[DemoDetailViewController alloc] init];
    [DemoListViewController registerWithTitle:@"发送一个 GET 请求" handler:^UIViewController *{
        detailViewController.selectedSelector = @selector(makeGETRequest);
        return detailViewController;
    }];
    
    [DemoListViewController registerWithTitle:@"发送一个可以缓存 GET 的请求" handler:^UIViewController *{
        detailViewController.selectedSelector = @selector(makeCacheGETRequest);
        return detailViewController;
    }];
    
    [DemoListViewController registerWithTitle:@"设置每次请求都会带上的参数" handler:^UIViewController *{
        detailViewController.selectedSelector = @selector(makeBuiltinParametersRequest);
        return detailViewController;
    }];
    
    [DemoListViewController registerWithTitle:@"每次请求都根据参数计算 Token" handler:^UIViewController *{
        detailViewController.selectedSelector = @selector(calculateTokenEveryRequest);
        return detailViewController;
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:239.f/255 green:239.f/255 blue:244.f/255 alpha:1];
    [self.view addSubview:self.resultTextView];
    // Do any additional setup after loading the view.
}

- (void)appendLog:(NSString *)log
{
    NSString *currentLog = self.resultTextView.text;
    currentLog = [currentLog stringByAppendingString:[NSString stringWithFormat:@"\n----------\n%@", log]];
    self.resultTextView.text = currentLog;
    [self.resultTextView sizeThatFits:CGSizeMake(self.view.frame.size.width, CGFLOAT_MAX)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [MGJRequestManager sharedInstance].configuration = nil;
    [self appendLog:@"准备中..."];
    [self.resultTextView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self performSelector:self.selectedSelector withObject:nil afterDelay:0];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.resultTextView.text = @"";
    [self.resultTextView removeObserver:self forKeyPath:@"contentSize"];
}

- (UITextView *)resultTextView
{
    if (!_resultTextView) {
        NSInteger padding = 20;
        NSInteger viewWith = self.view.frame.size.width;
        NSInteger viewHeight = self.view.frame.size.height - 64;
        _resultTextView = [[UITextView alloc] initWithFrame:CGRectMake(padding, padding + 64, viewWith - padding * 2, viewHeight - padding * 2)];
        _resultTextView.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1].CGColor;
        _resultTextView.layer.borderWidth = 1;
        _resultTextView.editable = NO;
        _resultTextView.contentInset = UIEdgeInsetsMake(-64, 0, 0, 0);
        _resultTextView.font = [UIFont systemFontOfSize:14];
        _resultTextView.textColor = [UIColor colorWithWhite:0.2 alpha:1];
        _resultTextView.contentOffset = CGPointZero;
    }
    return _resultTextView;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentSize"]) {
        NSInteger contentHeight = self.resultTextView.contentSize.height;
        NSInteger textViewHeight = self.resultTextView.frame.size.height;
        [self.resultTextView setContentOffset:CGPointMake(0, MAX(contentHeight - textViewHeight, 0)) animated:YES];
    }
}

- (NSString *)md5String:(NSString *)string
{
    const char *cStr = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (uint)strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (void)makeGETRequest
{
    [[MGJRequestManager sharedInstance] GET:@"http://httpbin.org/get" parameters:@{@"foo": @"bar"} startImmediately:YES
 configurationHandler:nil completionHandler:^(NSError *error, id<NSObject> result, BOOL isFromCache, AFHTTPRequestOperation *operation) {
     [self appendLog:result.description];
 }];
}

- (void)makeCacheGETRequest
{
    AFHTTPRequestOperation *operation1 = [[MGJRequestManager sharedInstance]
                                          GET:@"http://httpbin.org/get"
                                          parameters:@{@"foo": @"bar"}
                                          startImmediately:NO
                                          configurationHandler:^(MGJRequestManagerConfiguration *configuration) {
                                              configuration.resultCacheDuration = 30;
                                          }
                                          completionHandler:^(NSError *error, id<NSObject> result, BOOL isFromCache, AFHTTPRequestOperation *operation) {
                                              [self appendLog:[NSString stringWithFormat:@"来自缓存:%@", isFromCache ? @"是" : @"否"]];
                                              [self appendLog:result.description];
                                          }];
    
    AFHTTPRequestOperation *operation2 = [[MGJRequestManager sharedInstance]
                                          GET:@"http://httpbin.org/get"
                                          parameters:@{@"foo": @"bar"}
                                          startImmediately:NO
                                          configurationHandler:^(MGJRequestManagerConfiguration *configuration) {
                                              configuration.resultCacheDuration = 30;
                                          }
                                          completionHandler:^(NSError *error, id<NSObject> result, BOOL isFromCache, AFHTTPRequestOperation *operation) {
                                              [self appendLog:[NSString stringWithFormat:@"来自缓存:%@", isFromCache ? @"是" : @"否"]];
                                              [self appendLog:result.description];
                                          }];
    
    
    [[MGJRequestManager sharedInstance] batchOfRequestOperations:@[operation1, operation2] progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        [self appendLog:[NSString stringWithFormat:@"发送完成的请求：%ld/%ld", numberOfFinishedOperations, totalNumberOfOperations]];
    } completionBlock:^() {
        [self appendLog:@"请求发送完成"];
    }];
}

- (void)makeBuiltinParametersRequest
{
    MGJRequestManagerConfiguration *configuration = [[MGJRequestManagerConfiguration alloc] init];
    configuration.builtinParameters = @{@"t": @([[NSDate date] timeIntervalSince1970]), @"network": @"1", @"device": @"iphone3,2"};
    [MGJRequestManager sharedInstance].configuration = configuration;
    
    [[MGJRequestManager sharedInstance] GET:@"http://httpbin.org/get"
                                 parameters:nil startImmediately:YES
                       configurationHandler:nil
                          completionHandler:^(NSError *error, id<NSObject> result, BOOL isFromCache, AFHTTPRequestOperation *operation) {
                              if (error) {
                                  [self appendLog:error.description];
                              } else {
                                  [self appendLog:[NSString stringWithFormat:@"请求结果: %@", result.description]];
                              }
                          }];
}

- (void)calculateTokenEveryRequest
{
    MGJRequestManagerConfiguration *configuration = [[MGJRequestManagerConfiguration alloc] init];
    configuration.builtinParameters = @{@"t": @([[NSDate date] timeIntervalSince1970]), @"network": @"1", @"device": @"iphone3,2"};
    [MGJRequestManager sharedInstance].configuration = configuration;
    
    [MGJRequestManager sharedInstance].parametersHandler = ^(NSMutableDictionary *builtinParameters, NSMutableDictionary *requestParameters) {
        NSString *builtinValues = [builtinParameters.allValues componentsJoinedByString:@""];
        NSString *requestValues = [requestParameters.allValues componentsJoinedByString:@""];
        NSString *md5Values = [self md5String:[NSString stringWithFormat:@"%@%@", builtinValues, requestValues]];
        requestParameters[@"token"] = md5Values;
    };
    
    NSDictionary *requestParameters = @{@"user_id": @1024};
    [[MGJRequestManager sharedInstance] GET:@"http://httpbin.org/get"
                                 parameters:requestParameters
                           startImmediately:YES
                       configurationHandler:nil
                          completionHandler:^(NSError *error, id<NSObject> result, BOOL isFromCache, AFHTTPRequestOperation *operation) {
                              [self appendLog:result.description];
                          }];
}

@end
