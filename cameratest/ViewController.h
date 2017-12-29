//
//  ViewController.h
//  cameratest
//
//  Created by 马涛 on 21/08/2017.
//  Copyright © 2017 koma. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <opencv2/opencv.hpp>

#import "light_label_detection.hpp"

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong)AVCaptureSession *session;
@property (nonatomic, strong)AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong)AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong)AVCaptureDevice *backFacingCamera;
@property (nonatomic, strong)AVCaptureSession *captureSession;
@property (nonatomic, strong)AVCaptureConnection *videoConnection;


@property (nonatomic, strong) IBOutlet UIImageView* imageView;
@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *tapGesture;
@property (nonatomic, strong) IBOutlet UIView *focusView;

@property (nonatomic, strong) dispatch_queue_t concurrentQueue;


//#pragma mark -
#pragma mark - Generate cv::Mat from UIImage
- (cv::Mat)cvMatFromUIImage:(UIImage*)image;


#pragma mark-
#pragma mark Generate UIImage from cv::Mat
- (UIImage*)UIImageFromCVMat:(cv::Mat)cvMat;

@end

