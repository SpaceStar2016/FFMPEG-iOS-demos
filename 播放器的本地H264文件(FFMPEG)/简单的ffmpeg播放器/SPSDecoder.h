//
//  SPSDecoder.h
//  简单的ffmpeg播放器
//
//  Created by ZhongSpace on 2016/11/23.
//  Copyright © 2016年 ZhongSpace. All rights reserved.
//

#import <UIKit/UIKit.h>

#define decodeDidFinishNotification @"decodeDidFinishNotification"

#define decodeFailureNotification @"decodeFailureNotification"

@class SPSDecoder;
@protocol SPSDecoderDelegate <NSObject>

-(void)SPSDecoderImage:(SPSDecoder *)decoder image:(UIImage *)image;

@end

@interface SPSDecoder : NSObject

@property(nonatomic,weak)id<SPSDecoderDelegate>delegate;

-(instancetype)initWithPath:(NSString *)videoPath;

-(void)startDecoder;


@end
