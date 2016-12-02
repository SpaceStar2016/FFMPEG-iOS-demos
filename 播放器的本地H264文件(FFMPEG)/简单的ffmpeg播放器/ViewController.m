//
//  ViewController.m
//  简单的ffmpeg播放器
//
//  Created by ZhongSpace on 2016/11/12.
//  Copyright © 2016年 ZhongSpace. All rights reserved.
//

#import "ViewController.h"
#import "SPSDecoder.h"

@interface ViewController ()<UIAlertViewDelegate,SPSDecoderDelegate>

@property(nonatomic,weak)UIImageView * imageVIew;


@property(nonatomic,strong)SPSDecoder * decoder;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
   
    UIButton * btn = [[UIButton alloc] init];
    [btn setTitle:@"打开流" forState:UIControlStateNormal];
    btn.frame = CGRectMake(100,400, 100, 100);
    btn.backgroundColor = [UIColor greenColor];
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    

    //用于显示解码出来的UIImage
    UIImageView * imageVIew = [[UIImageView alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width * (9.0 /16.0))];
    imageVIew.backgroundColor = [UIColor blackColor];
    [self.view addSubview:imageVIew];
    self.imageVIew = imageVIew;
    
    //创建解码器
    NSString * videoPath =[[NSBundle mainBundle] pathForResource:@"SPSTest.h264" ofType:nil];;
    SPSDecoder * decoder = [[SPSDecoder alloc] initWithPath:videoPath];
    decoder.delegate = self;
    self.decoder = decoder;
    
}

-(void)btnClick:(UIButton *)btn
{
    
    [self.decoder startDecoder];
    
}

#pragma mark SPSDecoderDelegate

-(void)SPSDecoderImage:(SPSDecoder *)decoder image:(UIImage *)image
{
    NSLog(@"currentThread==%@",[NSThread currentThread]);
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.imageVIew.image = image;
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
