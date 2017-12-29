//
//  light_label_detection.hpp
//  algorithm
//
//  Created by 马涛 on 2017/12/11.
//  Copyright © 2017年 koma. All rights reserved.
//

#ifndef light_label_detection_hpp
#define light_label_detection_hpp

#include <stdio.h>


#include <stdlib.h>
#include <stdio.h>
#include <vector>
#include <algorithm>
#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif
#include <math.h>
#include <time.h>
#include <ctime>
#include <sys/time.h>
#ifdef OPENCL
#include <ocl/ocl.hpp>
#endif

#include <vector>
#include <numeric>
#include <functional>

#include <opencv2/highgui/highgui.hpp>
#include <opencv2/features2d/features2d.hpp>
#include <opencv2/objdetect/objdetect.hpp>

#include <sys/types.h>
#include <dirent.h>
#include <string.h>
#include <sys/stat.h>

#include <mach-o/dyld.h>
#include <fstream>

using namespace std;
using namespace cv;

#ifndef PI
#define PI 3.14159265
#endif

#define GET_SYS_TIME(times) do{\
struct timeval cur_time;\
gettimeofday(&cur_time, NULL);\
times = cur_time.tv_sec * 1000000llu + cur_time.tv_usec;\
}while(0)
/* resize by shift bit */
#define WIDTH_SCALE 1
#define HEIGHT_SCALE 1

#ifndef SUB_ABS
#define SUB_ABS(x, y) ((x) - (y) > 0 ? ((x) - (y)) : ((y) - (x)))
#endif

#ifndef ABS
#define ABS(x) ((x) > 0 ) ? (x) : (0 - (x))
#endif

#ifndef MAX
#define MAX(x, y) ((x) > (y) ? (x) : (y))
#endif

#ifndef MIN
#define MIN(x, y) ((x) < (y) ? (x) : (y))
#endif


//一些结构体的定义
    typedef struct{
        int x;
        int y;
        int width;
        int height;
        int code;
        int appear;
        //bool appear;
        int distance;
        int angleHor;
        int angleVer;
        //bool position;
    }LIGHTID;

    struct VideoFrame
    {
        size_t width;
        size_t height;
        size_t stride;
        unsigned char * data;
    };



//处理展示效果
    void preProcess(VideoFrame frame, cv::Mat &background);

//算法接口
    void scanFrame(VideoFrame frame, int &isTracked, LIGHTID &result0, LIGHTID &result1, LIGHTID &result2);



    std::vector<std::vector<int> > lightid_detect(cv::Mat src_img);
    
    
    int transxCoordinate(int x_in);
    
    int transyCoordinate(int y_in);
    
    //void detection(LIGHTID &li0, LIGHTID &li1, LIGHTID &li2);
    
    //****************检测 detect********************
    typedef struct _LIGHT_LABEL_INFO_S
    {
        int x;
        int y;
        int width;
        int height;
        
        bool light_label_flag;
        vector<unsigned char> light_label_encode_info;
    }LightLabelInfo;
    
    void ImageSegmentation(Mat &src_img, Mat &dst_img);
    
    float AverageGrayImage(Mat &src_img);
    
    void GammaCorrection(Mat& src, Mat& dst, float fGamma);
    
    int BackgroundEnhancement(Mat &src_img, Mat &dst_img);
    
    int ImageColorSegmentation(Mat &src_img, Mat &dst_img);
    
    int ImageColorSegmentationBeat(Mat &src_img, Mat &dst_img);
    
    int LightLabelCandidateSearch(Mat &src_img, vector<cv::Rect> &light_label_candidate);
    
    bool LightLabelRoiImageProcess(Mat &src_img);
    
    int LightLabelDetection(Mat &src_img, Mat &resized_src_img,
                            vector<LightLabelInfo> &light_label_info, cv::Rect roi_info);
    
    void SvmSamplesTest(const char *data_path);
    
    
    //*****************encode********************
    typedef enum _LIGHT_STRIPE_STATUS_EN
    {
        EN_STRIPE_0 = 0,    //bus lane yellow color
        EN_STRIPE_1,      //singapore bus lane pink
        EN_STRIPE_2,      //chinese license plate color
        EN_STRIPE_3,
    }enLightStripeStatus;
    
    typedef void(*svm_call_back)(const Mat &src_image,
    vector<float> &feature_vector);
    
    int LightLabelEncode(Mat &src_img, int bit_num, vector<unsigned char> &result);
    
    int LightStripeStatusDetection(Mat &src_img,
                                   unsigned char &light_stripe_status, vector<float> &feature,
                                   double &gray_diff_ratio);
    
    void SvmTrain(const char *data_path, int kernel_type,
                  int para_optimization);
    
    //vector<string> GetFileLists(const string &folder,const bool all /* = true */);
    
    void FeatureExtraction(const char *sample_path, int label,
                           Mat &training_image_features, vector<int> &training_image_labels,
                           svm_call_back GetFeatures);
    
    void GetFeatures(const Mat &src_image, vector<float> &feature_vector);
    
    void GetTestSamples(const char *test_samples_path, int labels,
                        vector<Mat>& testing_images, vector<int>& testing_labels);
    
    void SvmSamplesTest(const char *data_path);
    




#endif /* light_label_detection_hpp */
