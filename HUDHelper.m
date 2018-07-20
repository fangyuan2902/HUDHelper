//
//  HUDHelper.m
//  ProjectDemo
//
//  Created by 方远 on 2017/2/27.
//  Copyright © 2017年 方远. All rights reserved.
//

#import "HUDHelper.h"
#import "AppDelegate.h"
#import "NSString+Object.h"

@implementation HUDHelper {
    MBProgressHUD *_hud;
}

static HUDHelper *_instance = nil;


+ (HUDHelper *)sharedInstance {
    @synchronized(_instance) {
        if (_instance == nil) {
            _instance = [[HUDHelper alloc] init];
        }
        return _instance;
    }
}

+ (void)alert:(NSString *)msg {
    [HUDHelper alert:msg cancel:@"确定"];
}

+ (void)alert:(NSString *)msg action:(CommonVoidBlock)action {
    [HUDHelper alert:msg cancel:@"确定" action:action];
}

+ (void)alert:(NSString *)msg cancel:(NSString *)cancel {
    [HUDHelper alertTitle:@"提示" message:msg cancel:cancel];
}

+ (void)alert:(NSString *)msg cancel:(NSString *)cancel action:(CommonVoidBlock)action {
    [HUDHelper alertTitle:@"提示" message:msg cancel:cancel action:action];
}

+ (void)alertTitle:(NSString *)title message:(NSString *)msg cancel:(NSString *)cancel {
    [HUDHelper alertTitle:title message:msg cancel:cancel action:nil];
}

+ (void)alertTitle:(NSString *)title message:(NSString *)msg cancel:(NSString *)cancel action:(CommonVoidBlock)actions {
    title = (title && title.length > 0) ? title : @"";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    if (cancel && cancel.length > 0) {
        [alert addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            actions();
        }]];
    }
    UIViewController *topRootViewController = CurrentKeyWindow.rootViewController;
    while (topRootViewController.presentedViewController) {
        topRootViewController = topRootViewController.presentedViewController;
    }
    [topRootViewController presentViewController:alert animated:YES completion:nil];
}

- (MBProgressHUD *)loading {
    return [self loading:nil];
}

- (MBProgressHUD *)loading:(NSString *)msg {
    return [self loading:msg inView:nil];
}

- (MBProgressHUD *)loading:(NSString *)msg inView:(UIView *)view {
    UIView *inView = view ? view : APPDelegate.window;
    if (_hud == nil) {
        _hud = [[MBProgressHUD alloc] initWithView:inView];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![NSString isEmpty:msg]) {
            _hud.mode = MBProgressHUDModeIndeterminate;
            _hud.label.text = msg;
        }
        [inView addSubview:_hud];
        [_hud showAnimated:YES];
    });
    return _hud;
}

- (void)loading:(NSString *)msg delay:(CGFloat)seconds execute:(void (^)())exec completion:(void (^)())completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *inView = APPDelegate.window;
        if (_hud == nil) {
            _hud = [[MBProgressHUD alloc] initWithView:inView];
        }
        if (![NSString isEmpty:msg]) {
            _hud.mode = MBProgressHUDModeText;
            _hud.label.text = msg;
        }
        
        [inView addSubview:_hud];
        [_hud showAnimated:YES];
        if (exec) {
            exec();
        }
        // 超时自动消失
        [_hud hideAnimated:YES afterDelay:seconds];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_hud removeFromSuperview];
            _hud = nil;
            if (completion) {
                completion();
            }
        });
    });
}


- (void)stopLoading:(MBProgressHUD *)hud {
    [self stopLoading:hud message:nil];
}

- (void)stopLoading:(MBProgressHUD *)hud message:(NSString *)msg {
    [self stopLoading:hud message:msg delay:0 completion:nil];
}

- (void)stopLoading:(MBProgressHUD *)hud message:(NSString *)msg delay:(CGFloat)seconds completion:(void (^)())completion {
    if (hud && hud.superview) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![NSString isEmpty:msg]) {
                hud.label.text = msg;
                hud.mode = MBProgressHUDModeText;
            }
            [hud hideAnimated:YES afterDelay:seconds];
            _syncHUD = nil;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [_hud removeFromSuperview];
                _hud = nil;
                if (completion) {
                    completion();
                }
            });
        });
    }
    
}

- (void)tipMessage:(NSString *)msg {
    [self tipMessage:msg delay:2];
}

- (void)tipMessage:(NSString *)msg delay:(CGFloat)seconds {
    [self tipMessage:msg delay:seconds completion:nil];
    
}

- (void)tipMessage:(NSString *)msg delay:(CGFloat)seconds completion:(void (^)())completion {
    if ([NSString isEmpty:msg]) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_hud == nil) {
            _hud = [[MBProgressHUD alloc] initWithView:APPDelegate.window];
        }
        [APPDelegate.window addSubview:_hud];
        _hud.mode = MBProgressHUDModeText;
        _hud.label.text = msg;
        [_hud showAnimated:YES];
        [_hud hideAnimated:YES afterDelay:seconds];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_hud removeFromSuperview];
            _hud = nil;
            if (completion) {
                completion();
            }
        });
    });
}

#define kSyncHUDStartTag  100000

// 网络请求
- (void)syncLoading {
    [self syncLoading:nil];
}

- (void)syncLoading:(NSString *)msg {
    [self syncLoading:msg inView:nil];
}

- (void)syncLoading:(NSString *)msg inView:(UIView *)view {
    if (_syncHUD) {
        _syncHUD.tag++;
        
        if (![NSString isEmpty:msg]) {
            _syncHUD.label.text = msg;
            _syncHUD.mode = MBProgressHUDModeText;
        } else {
            _syncHUD.label.text = nil;
            _syncHUD.mode = MBProgressHUDModeIndeterminate;
        }
        return;
    }
    _syncHUD = [self loading:msg inView:view];
    _syncHUD.tag = kSyncHUDStartTag;
}

- (void)syncStopLoading {
    [self syncStopLoadingMessage:nil delay:0 completion:nil];
}

- (void)syncStopLoadingMessage:(NSString *)msg {
    [self syncStopLoadingMessage:msg delay:1 completion:nil];
}

- (void)syncStopLoadingMessage:(NSString *)msg delay:(CGFloat)seconds completion:(void (^)())completion {
    _syncHUD.tag--;
    if (_syncHUD.tag > kSyncHUDStartTag) {
        if (![NSString isEmpty:msg]) {
            _syncHUD.label.text = msg;
            _syncHUD.mode = MBProgressHUDModeText;
        } else {
            _syncHUD.label.text = nil;
            _syncHUD.mode = MBProgressHUDModeIndeterminate;
        }
    } else {
        [self stopLoading:_syncHUD message:msg delay:seconds completion:completion];
    }
}

@end
