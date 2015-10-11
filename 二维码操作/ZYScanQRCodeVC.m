//
//  ZYScanQRCodeVC.m
//  二维码操作
//
//  Created by zhuyi on 15/10/9.
//  Copyright © 2015年 zhuyi. All rights reserved.
//

#import "ZYScanQRCodeVC.h"
#import "ZYCreateQRCodeVC.h"

#import <AVFoundation/AVFoundation.h>

@interface ZYScanQRCodeVC ()<UITabBarDelegate,AVCaptureMetadataOutputObjectsDelegate>

//扫描容器高度约束
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintHeightConstant;
//冲击波顶部的约束
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scanLineCons;

//底部的工具条
@property (weak, nonatomic) IBOutlet UITabBar *customTabBar;
//边框的imageView
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
//冲击波视图
@property (weak, nonatomic) IBOutlet UIImageView *scanLineView;

/**session会话**/
@property(nonatomic,strong)AVCaptureSession *session;
/**输入设备**/
@property(nonatomic,strong)AVCaptureDeviceInput *input;
/**输出对象**/
@property(nonatomic,strong)AVCaptureMetadataOutput *output;
//创建预览图层
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
/**提示边框**/
@property(nonatomic,strong)CALayer *drawLayer;

//扫描器灰色蒙板。
@property (nonatomic,strong)CALayer * maskLayer;

@end


@implementation ZYScanQRCodeVC

#pragma mark 懒加载

//提示图层
- (CALayer *)drawLayer
{
    if (!_drawLayer) {
        _drawLayer = [CALayer layer];
        _drawLayer.frame = [UIScreen mainScreen].bounds;
    }
    return _drawLayer;
}
//创建捕捉会话
-(AVCaptureSession *)session
{
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

//输出对象
- (AVCaptureMetadataOutput *)output
{
    if (!_output) {
        _output = [[AVCaptureMetadataOutput alloc] init];
        
        //设置整个视图的尺寸填充控制器的view
        CGSize size =[UIScreen mainScreen].bounds.size;
        
        //屏幕的宽高
        CGFloat ScreenHight = [UIScreen mainScreen].bounds.size.height;
        CGFloat ScreenWidth = [UIScreen mainScreen].bounds.size.width;
        
        //扫描区域的宽高
        CGFloat width = 300;
        CGFloat height = 300;
        
        //计算扫描区域的xy值
        CGFloat x =(ScreenWidth -width)/2;
        CGFloat y = (ScreenHight - height)/2 ;
        
        //计算感兴趣的区域
        CGRect cropRect = CGRectMake(x , y, width, height);
        
        //计算当前屏幕的宽高比
        CGFloat currentScreenScale = size.height/size.width;
        
        //设定一个标准的比例（这里仅仅是做个参照 因为现在普遍的屏幕都是这个尺寸）
        CGFloat standardScreenScale = 1920./1080.;
        
        //如果当前的屏幕宽高比小于我们标准的宽高比 重新计算高度比例
        if (currentScreenScale < standardScreenScale) {
            //计算高度比例
            CGFloat fixHeight = ScreenWidth * 1920. / 1080.;
            CGFloat fixPadding = (fixHeight - size.height)/2;
            _output.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                cropRect.origin.x/size.width,
                                                cropRect.size.height/fixHeight,
                                                cropRect.size.width/size.width);
        } else {//重新计算宽度比例
            
            //计算宽度比例
            CGFloat fixWidth =ScreenHight * 1080. / 1920.;
            CGFloat fixPadding = (fixWidth - size.width)/2;
            _output.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                (cropRect.origin.x + fixPadding)/fixWidth,
                                                cropRect.size.height/size.height,
                                                cropRect.size.width/fixWidth);
        }
        
    }
    return _output;
}
//输入设备(数据从摄像头输入)
- (AVCaptureDeviceInput *)input
{
    if (!_input) {
        
        //设置类型
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        //创建输入设备
        NSError *error;
        _input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
        
        //创建输入设备失败
        if (error) return nil;
        
    }
    return _input;
    
}
//预览图层
- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (!_previewLayer) {
        //创建预览图层
        _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        //设置frame
        _previewLayer.frame = self.view.bounds;
        //设置填充模式
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewLayer;
}

#pragma mark - ------


- (IBAction)backToPreviousVC {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - 初始化----1

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置控制器view的背景
    //    self.view.backgroundColor = [UIColor redColor];
    
    //设置item的字体颜色
    [self.customTabBar setTintColor:[UIColor orangeColor]];
    //设置底部视图默认选中第0个
    self.customTabBar.selectedItem = self.customTabBar.items[0];
    //设置代理
    self.customTabBar.delegate = self;
}

#pragma mark - 2
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //开始动画
    [self startAnimation];
    
    //开始扫描
    [self startScan];
}

#pragma  mark - 3 --- 再次调用动画---8
//开始动画(待优化---不执行动画)
- (void)startAnimation
{
    //让约束从顶部开始
    //    self.scanLineCons.constant = -self.constraintHeightConstant.constant;
    //    [self.scanLineView layoutIfNeeded];
    
    //执行冲击波动画
    [UIView animateWithDuration:1.0 animations:^{
        //1.修改约束
        self.scanLineCons.constant = 0;//self.constraintHeightConstant.constant;
        //设置动画指定次数
        [UIView setAnimationRepeatCount:MAXFLOAT];
        //强制更新画面
        [self.scanLineView layoutIfNeeded];
    }];
    
}


#pragma mark - 功能实现- 4
- (void)startScan
{
    //1.判断是否能够将输入添加到会话中
    if (![self.session canAddInput:self.input]) {
        return;
    }
    // 2.判断是否能够将输出添加到会话中
    if (![self.session canAddOutput:self.output]) {
        return;
    }
    
    //3.添加输入输入对象
    [self.session addInput:self.input];
    [self.session addOutput:self.output];
    
    // 4.设置输出能够解析的数据类型
    // 注意: 设置能够解析的数据类型, 一定要在输出对象添加到会员之后设置, 否则会报错
    self.output.metadataObjectTypes = self.output.availableMetadataObjectTypes;
    
    // 5.设置输出对象的代理, 只要解析成功就会通知代理
    [ self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    // 如果想实现只扫描一张图片, 那么系统自带的二维码扫描是不支持的
    // 只能设置让二维码只有出现在某一块区域才去扫描
//     [self.output rectOfInterest] = CGRectMake(0.0, 0.0, 1, 1)
    
    //添加预览图层
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    //添加提示框图层-添加绘制图层到预览图层上
    [self.previewLayer addSublayer:self.drawLayer];
    
    
    
    
    //创建蒙版图层
    self.maskLayer = [CALayer layer];
    self.maskLayer.frame = self.view.frame;
    //设置layer的代理
    self.maskLayer.delegate = self;
    //添加到我们预览图层的上面
    [self.view.layer insertSublayer:self.maskLayer above:self.previewLayer];
    //绘制layer
    [self.maskLayer setNeedsDisplay];
    
    //开始扫描
    [self.session startRunning];
    
}

#pragma mark  蒙版layer的代理方法---5---9
//layer需要绘图时，会调用代理的drawLayer:inContext:方法进行绘图
//注意这个方法 不会自动调用 需要通过setNeedDisplay方法调用
-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{
    
    if (layer == self.maskLayer) {
        //开启一个图形上下文
        UIGraphicsBeginImageContextWithOptions(self.maskLayer.frame.size, NO, 1.0);
        //设置填充颜色
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0 alpha:0.6].CGColor);
        //设置填充区域
        CGContextFillRect(ctx, self.maskLayer.frame);
        //设置需要清除的区域
        CGRect scanFrame = [self.view convertRect:self.scanLineView.bounds fromView:self.scanLineView.superview];
        //清除区域
        CGContextClearRect(ctx, scanFrame);
    }
}


#pragma mark UITabBarDelegate --6
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
     // 1.修改容器的高度约束
    if (item.tag == 0) {//如果是二维码  这里事先已经绑定了tag值
        self.constraintHeightConstant.constant = 300;
    }else{
        self.constraintHeightConstant.constant = 150;
    }
    //2.停止动画
    [self.scanLineView.layer removeAllAnimations];
    
    //3.重新开始动画
    [self reStartAnimation];
}

#pragma mark - 7(点击了Bottombar)
////重新开始动画的方法  注意每一次约束高度改变之后 都要调用一次这个方法
- (void)reStartAnimation
{
    //重新开始动画
    [self startAnimation];
    
    //重新绘制
    [self.maskLayer setNeedsDisplay];
}


- (void)dealloc
{
    //停止扫描
    [self.session stopRunning];
    [self.previewLayer removeFromSuperlayer];
}

#pragma mark AVCaptureMetadataOutputObjectsDelegate 扫描001 ---005
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // 0.清空图层
    [self clearLayer];
    
    NSString *url = nil;
    
    if ([[metadataObjects lastObject] respondsToSelector:@selector(stringValue)]) {
        // 1.获取扫描到的数据(注意: 要使用stringValue)
        url = [[metadataObjects lastObject] stringValue];
        
/*self.resultLabel.text=[[metadataObjects lastObject]stringValue];
        [self.resultLabel sizeToFit];*/
    }
    
    if (metadataObjects.count > 0) {
        
        // 2.获取扫描到的二维码的位置
        // 2.1转换坐标
        for (id obj in metadataObjects) {
            // 2.1.1判断当前获取到的数据, 是否是机器可识别的类型
            if ([obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
                 // 2.1.2将坐标转换界面可识别的坐标
                id codeObj = [self.previewLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject*)(AVMetadataObject*)obj];
                
                // 2.1.3绘制图形
                [self drawCorners:codeObj];
            }
        }
    }else{
        NSLog(@"没有数据");
    }
    
    if ([url hasPrefix:@"http://"]) {
        NSString *message = [NSString stringWithFormat:@"可能存在风险,是否打开此链接?　　　%@",url];
        
        //只显示一个AlertView
        //        if (self.alert) return;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
        
        
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"打开链接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
            //            [self dismissViewControllerAnimated:YES completion:nil];
            [alert dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }else{
        NSLog(@"扫描到的信息为：%@",url);
    }
    
}

#pragma mark - 扫描002--006
//清空边线
- (void)clearLayer
{
    // 1.判断drawLayer上是否有其它图层
    if((self.drawLayer.sublayers.count == 0) || (self.drawLayer.sublayers == nil)){
        return;
    }
    // 2.移除所有子图层
    //    [self.drawLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    for (CALayer *subLayer in self.drawLayer.sublayers) {
        [subLayer removeFromSuperlayer];
    }
    
}

#pragma mark - 扫描003---007
//画边框
- (void)drawCorners:(AVMetadataMachineReadableCodeObject*)codeObject
{
    if (codeObject.corners.count == 0)  return;
    
     // 1.创建一个图层
    CAShapeLayer *shap = [CAShapeLayer layer];
    shap.lineWidth = 4;
    shap.strokeColor = [UIColor redColor].CGColor;
    shap.fillColor = [UIColor clearColor].CGColor;
    
    //2.绘制路径
    shap.path = [self drawPath:codeObject.corners];
    
   // 3.将绘制好的图层添加到drawLayer上
    [self.drawLayer addSublayer:shap];
    
}

#pragma mark - 扫描004---008
//绘制路径
- (CGPathRef)drawPath:(NSArray*)pathPoint
{
    //1.创建贝塞尔路径
    UIBezierPath *path = [UIBezierPath bezierPath];
    //初始化开始的位置
    CGPoint point = CGPointZero;
    //定义索引
    int  index = 0;
    
    // 2.1移动到第一个点
    // 从corners数组中取出第0个元素, 将这个字典中的x/y赋值给point
    CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)pathPoint[index++], &point);
    //移动到第1个点
    [path moveToPoint:point];
    
     // 2.2移动到其它的点
    while (index < pathPoint.count) {
        //将字典中的获取一个坐标
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)pathPoint[index++], &point);
        //每获取到一个坐标就画一次
        [path addLineToPoint:point];
    }
    
    //2.3关闭路径
    [path closePath];
    
    //2.4返回路径
    return  path.CGPath;
}



#pragma mark - 生成我的二维码
//我的二维码按钮被点击
- (IBAction)myQRcodeClick {
    
    //创建我的二维码控制器
    ZYCreateQRCodeVC *myCode = [[ZYCreateQRCodeVC alloc] init];
    //modal出来
    [self presentViewController:myCode animated:YES completion:nil];
    
}


@end
