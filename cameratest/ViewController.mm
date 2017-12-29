//
//  ViewController.m
//  cameratest
//
//  Created by 马涛 on 21/08/2017.
//  Copyright © 2017 koma. All rights reserved.
//

#import "ViewController.h"
#import "GRPanoramaView.h"

@interface ViewController ()
{
    cv::Mat backImage;
    
    LIGHTID lightid0;
    LIGHTID lightid1;
    LIGHTID lightid2;
    
    int isDetected;
    
    BOOL _isPause;
}

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name: UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name: UIApplicationWillEnterForegroundNotification object:nil];
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //load cascade classifier from the XML file
    
    _isPause = NO;
    [self initPanoramaView];
    [self initCapture];

}
-(void)initPanoramaView{
    CGRect panoRect = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    GRPanoramaView *panoView = [[GRPanoramaView alloc] initWithFrame:panoRect imageName:@"WechatIMG39.jpeg"];
    [self.view addSubview:panoView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) initCapture{
    //ViewController *aa = [[ViewController alloc] init];
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == AVCaptureDevicePositionBack)
        {
            _backFacingCamera = device;
            NSLog(@"back camera found.");
        }
    }
    
    _session = [[AVCaptureSession alloc] init];
    
    NSError *e = nil;
    if([_backFacingCamera lockForConfiguration: &e]) {
        
        _session.sessionPreset = AVCaptureSessionPreset3840x2160;
        //_session.sessionPreset = AVCaptureSessionPreset1920x1080;AVCaptureSessionPresetHigh；AVCaptureSessionPreset3840x2160
        //NSLog(@"Frame resolution: %@", _session.sessionPreset);
        AVCaptureDeviceFormat *activeFormat = _backFacingCamera.activeFormat;
        //float isoValue = 0.9;
        //float clampedISO = isoValue*(maxISO-minISO)+minISO;
        float minISO = activeFormat.minISO;
        float maxISO = activeFormat.maxISO;
        //float clampedISO = 665; // for iphone 6s plus
        float clampedISO = 305; // for iphone 7 plus
        
        CMTime minDuration = activeFormat.minExposureDuration;
        CMTime maxDuration = activeFormat.maxExposureDuration;
        int durVal = 25;
        CMTime clampedDuration = CMTimeMake(durVal, minDuration.timescale);
        
        //        backFacingCamera.exposureMode=AVCaptureExposureModeCustom;
        
        [_backFacingCamera setExposureModeCustomWithDuration:clampedDuration ISO:clampedISO completionHandler:nil];
        
        NSString *isoInfo = [NSString stringWithFormat:@"%f in [%f, %f]", clampedISO, minISO, maxISO];
        
        
        NSLog(@"ISO: %@", isoInfo);
        NSLog(@"Exposure duration: ");
        CMTimeShow(clampedDuration);
        NSLog(@"Min exposure duration:");
        CMTimeShow(minDuration);
        NSLog(@"Max exposure duration:");
        CMTimeShow(maxDuration);
        
        
        if ([_backFacingCamera isFocusModeSupported:AVCaptureFocusModeLocked]) {
            _backFacingCamera.focusMode = AVCaptureFocusModeLocked;
            [_backFacingCamera setFocusModeLockedWithLensPosition:0.84
                                                completionHandler:nil];
        }
        
        [_backFacingCamera setActiveVideoMaxFrameDuration:CMTimeMake(1, 30)];
        [_backFacingCamera setActiveVideoMinFrameDuration:CMTimeMake(1, 30)];
        //NSLog(@"fps:");
        CMTimeShow(_backFacingCamera.activeVideoMinFrameDuration);
        
        [_backFacingCamera unlockForConfiguration];
    } else {
        NSLog((@" coundn't config the back camera"));
    }
    
    NSError *error = nil;
    _videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_backFacingCamera error:&error];
    
    
    // Use RGB frames instead of YUV
    //[_videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    // CoreImage wants BGRA pixel format
    NSDictionary *outputSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
    // create and configure video data output
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoOutput.videoSettings = outputSettings;
    
    // Add the video output
    dispatch_queue_t queue;
    queue = dispatch_queue_create("myQueue", NULL);
    [_videoOutput setSampleBufferDelegate:self queue: queue];
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    
    [_captureSession beginConfiguration];
    
    if ([_session canAddInput:_videoInput])
    {
        [_session addInput:_videoInput];
        NSLog(@" video input added succesfully.");
    }else{
        NSLog(@"Could not add input port to capture session %@", _session);
    }
    
    if ([_session canAddOutput: _videoOutput])
    {
        [_session addOutput: _videoOutput];
        NSLog(@" video output added succesfully.");
    } else {
        NSLog(@"Couldn't add video output.");
    }
    
    [_captureSession commitConfiguration];
    
    [_session startRunning];
    
    
    _concurrentQueue = dispatch_queue_create("com.lightID.concurrency", DISPATCH_QUEUE_CONCURRENT);
    
    isDetected = 0;
    
    [self setSession:_session];
    //setSession: session;
    
    NSLog(@"session start");
    self.imageView.hidden = YES;
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    // Create a UIImage from the sample buffer data
    
    //    < Add your code here that uses the image >
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    /*Get information about the image*/
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);

    /*Create a CGImageRef from the CVImageBufferRef*/
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
//    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
//
//    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
//
//    /*We release some components*/
//    CGContextRelease(newContext);
//    CGColorSpaceRelease(colorSpace);
//
//    /*We display the result on the custom layer*/
//    /*self.customLayer.contents = (id) newImage;*/
//
//    /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly)*/
//    UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
//
//    //[_imageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
//    //UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    
    VideoFrame frame = {width, height, bytesPerRow, baseAddress};
    
    [self frameReady:frame];
    
    /*We relase the CGImageRef*/
//    CGImageRelease(newImage);
    
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error != nil) {
        NSLog(@"Couldn't save image");
    } else {
        NSLog(@"Saved image");
    }
}


#pragma mark -
#pragma mark VideoSource Delegate
- (void)frameReady:(VideoFrame)frame{
    
    __weak typeof(self) _weakSelf = self;
    
//    dispatch_sync( dispatch_get_main_queue(), ^{
//        NSLog(@"第一个线程");
//        preProcess(frame, backImage);
//        _imageView.image = [self UIImageFromCVMat:backImage];
//
//    });
    
    NSLog(@"第一个线程 over");
    NSLog(@"Statu == %@",_isPause?@"YES":@"NO");
        dispatch_async(_concurrentQueue, ^ {
            NSLog(@"第二个线程");
            if (_isPause) {
                return ;
            }
            
            scanFrame(frame, isDetected, lightid0, lightid1, lightid2);
            NSLog(@"lightid0:%d, lightid1:%d, lightid2:%d", \
                  lightid0.code, lightid1.code, lightid2.code);
            
        });
    
}



- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data, cols, rows, 8, cvMat.step[0], colorSpace, kCGImageAlphaNoneSkipLast |kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


- (UIImage*)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData* data = [NSData dataWithBytes: cvMat.data length: cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    }else{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols, cvMat.rows, 8, 8 * cvMat.elemSize(), cvMat.step[0], colorSpace, kCGImageAlphaNone | kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault);
    
    UIImage* finalImage = [UIImage imageWithCGImage: imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

#pragma mark AppStatus
-(void)applicationEnterBackground{
    _isPause = YES;
    //暂停线程 (暂停队列只是让队列暂时停止执行下一个任务，而不是中断当前正在执行的任务)
    //dispatch_suspend(self.concurrentQueue);
}
-(void)applicationWillEnterForeground{
    _isPause = NO;
    //dispatch_resume(self.concurrentQueue);
}

@end
