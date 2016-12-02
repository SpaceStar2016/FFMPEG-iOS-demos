//
//  SPSDecoder.m
//  简单的ffmpeg播放器
//
//  Created by ZhongSpace on 2016/11/23.
//  Copyright © 2016年 ZhongSpace. All rights reserved.
//

#import "SPSDecoder.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"


@interface SPSDecoder()
{
    AVFormatContext * pFormatCtx;
    int i , videoIndex;
    AVCodecContext * pCodeCtx;
    AVCodec * pCode;
    AVFrame * pFrame,*pFrameYUV;
    uint8_t * out_Buffer;
    AVPacket * packet;
    int y_size;
    int ret, got_picture;
    struct SwsContext * img_convert_ctx;
    int frame_cnt;
    AVPicture picture;
}
@property(nonatomic,copy)NSString * videoPath;
@end

@implementation SPSDecoder

-(instancetype)initWithPath:(NSString *)videoPath
{
    if (self = [super init]) {
        
        self.videoPath = videoPath;
    }
    return self;
}
-(void)startDecoder
{
    [self setupFFMPEGwithPath:self.videoPath];
}

-(void)setupFFMPEGwithPath:(NSString *)path
{
    //启动FFMPEG模块,调用avcodec_register_all()注册编解码器,注册一堆东西，看不懂-.-!
    av_register_all();
    //注册网络协议
    avformat_network_init();
    //
    pFormatCtx = avformat_alloc_context();
    
    //avformat_open_input 返回0表示成功
    if (avformat_open_input(&pFormatCtx, path.UTF8String, NULL, NULL)!=0) {
        
        [self showAlerViewTitle:@"不能打开流"];
        return;
    }
    //读取流信息
    if (avformat_find_stream_info(pFormatCtx, NULL) < 0) {
        [self showAlerViewTitle:@"不能读取到流信息"];
        return;
    }
    videoIndex = -1;
    //nb_streams 与 streams 有什么区别
    for (i  = 0; i < pFormatCtx->nb_streams; i ++) {
        //如果是视频流
        if (pFormatCtx ->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            videoIndex = i;


            break;
        }
        if (videoIndex == -1) {
            [self showAlerViewTitle:@"没有视频流"];
            return;
        }
        NSLog(@"videoIndex==%d",videoIndex);
    }
    pCodeCtx = pFormatCtx->streams[videoIndex]->codec;


    pCode = avcodec_find_decoder(pCodeCtx->codec_id);
    if (pCode == NULL) {
        [self showAlerViewTitle:@"找不到解码器"];
        return;
    }
    if (avcodec_open2(pCodeCtx, pCode, NULL) < 0) {
        [self showAlerViewTitle:@"不能打开解码器"];
        return;
    }
    //初始化AVFrame
    pFrame = av_frame_alloc();
    //AVPacket里面的是H.264码流数据
    //AVFrame里面装的是YUV数据。YUV是经过decoder解码AVPacket的数据
    packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    NSLog(@"AVPacket-size ==%lu",sizeof(AVPacket));
    av_dump_format(pFormatCtx, 0, path.UTF8String,0);
    img_convert_ctx = sws_getContext(pCodeCtx->width, pCodeCtx->height, pCodeCtx->pix_fmt, pCodeCtx->width, pCodeCtx->height, PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
    frame_cnt = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (av_read_frame(pFormatCtx, packet) >= 0) {
            NSLog(@"packet->data==%d",packet->size);
            if (packet ->stream_index == videoIndex) {
                //根据获取到的packet生成pFrame(AVFrame)
                ret = avcodec_decode_video2(pCodeCtx, pFrame, &got_picture, packet);
                if (ret < 0) {
                    [self showAlerViewTitle:@"解码错误"];
                    return;
                }
                if (got_picture) {
                    //给picture分配空间
                    AVPicture pictureL = [self AllocAVPicture];
                    int pictRet = sws_scale (img_convert_ctx,(const uint8_t * const *)pFrame->data, pFrame->linesize,
                                             0, pCodeCtx->height,
                                             pictureL.data, pictureL.linesize);
                    if (pictRet > 0) {
                        UIImage * image = [self imageFromAVPicture:pictureL width:pCodeCtx->width height:pCodeCtx->height];
                        [NSThread sleepForTimeInterval:1.0/80.0];
                        if ([self.delegate respondsToSelector:@selector(SPSDecoderImage:image:)]) {
                            [self.delegate SPSDecoderImage:self image:image];
                        }
                        
                    }
                    //释放AVPicture
                    avpicture_free(&pictureL);
                }
            }
            av_free_packet(packet);
        }
        sws_freeContext(img_convert_ctx);
        av_frame_free(&pFrameYUV);
        av_frame_free(&pFrame);
        avcodec_close(pCodeCtx);
        avformat_close_input(&pFormatCtx);
        [[NSNotificationCenter defaultCenter] postNotificationName:decodeDidFinishNotification object:nil];
    });
  
}

-(AVPicture)AllocAVPicture
{
    //创建AVPicture
    AVPicture pictureL;
    sws_freeContext(img_convert_ctx);
    avpicture_alloc(&pictureL, PIX_FMT_RGB24,pCodeCtx->width,pCodeCtx->height);
    static int sws_flags =  SWS_FAST_BILINEAR;
    img_convert_ctx = sws_getContext(pCodeCtx->width,
                                     pCodeCtx->height,
                                     pCodeCtx->pix_fmt,
                                     pCodeCtx->width,
                                     pCodeCtx->height,
                                     PIX_FMT_RGB24,
                                     sws_flags, NULL, NULL, NULL);
    

    return pictureL;
}

/**AVPicture转UIImage*/
-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height {
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0]*height,kCFAllocatorNull);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       8,
                                       24,
                                       pict.linesize[0],
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       NO,
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
}

-(void)showAlerViewTitle:(NSString*)title
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"取消");
    switch (buttonIndex) {
        case 0:{
            [[NSNotificationCenter defaultCenter] postNotificationName:decodeFailureNotification object:nil];
        }
            break;
            
        default:
            break;
    }
}
@end
