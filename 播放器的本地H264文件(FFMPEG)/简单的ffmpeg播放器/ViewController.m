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

@property(nonatomic,weak)UIButton * startButton;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
   
    UIButton * startButton = [[UIButton alloc] init];
    [startButton setTitle:@"打开流" forState:UIControlStateNormal];
    startButton.frame = CGRectMake(100,400, 100, 100);
    startButton.backgroundColor = [UIColor greenColor];
    [startButton addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startButton];
    self.startButton = startButton;

    //用于显示解码出来的UIImage
    UIImageView * imageVIew = [[UIImageView alloc] initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width * (9.0 /16.0))];
    imageVIew.backgroundColor = [UIColor blackColor];
    [self.view addSubview:imageVIew];
    self.imageVIew = imageVIew;
    
    //创建解码器
    NSString * videoPath =[[NSBundle mainBundle] pathForResource:@"SPSTest.h264" ofType:nil];
//    NSString * videoPath = @"/Users/zhongspace/Desktop/FFMPEG播放器制作/SPSTest.h264";
    SPSDecoder * decoder = [[SPSDecoder alloc] initWithPath:videoPath];
    decoder.delegate = self;
    self.decoder = decoder;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decodeFailure:) name:decodeFailureNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(decodeDidFinish:) name:decodeDidFinishNotification object:nil];
}

-(void)btnClick:(UIButton *)btn
{
    if (btn.selected == YES) return;
    btn.selected = !btn.selected;
    [self.decoder startDecoder];
    
}

-(void)decodeFailure:(NSNotification *)info
{
    self.startButton.selected = NO;
}

-(void)decodeDidFinish:(NSNotification *)info
{
    self.startButton.selected = NO;
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
