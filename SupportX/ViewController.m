//
//  ViewController.m
//  SupportX
//
//  Created by ZhangLiGuang on 17/9/27.
//  Copyright © 2017年 Beijing Lvye Shijie Information Technology Co.,Ltd. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>

#define HUIRGBColor(r, g, b, a)         [UIColor colorWithRed:(r)/255.00 green:(g)/255.00 blue:(b)/255.00 alpha:(a)]

#define KBtnForDoneBeginTag             (108322)
#define KBtnForDoneSynchronizeTag       (108323)
#define KBtnForDoneFinishTag            (108324)

#pragma mark -Image TOOL
UIImage* createImageWithColor(UIColor *color)
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

@interface ViewController ()<UITextFieldDelegate>


/*!
* @breif 时间间隔
* @See null
*/
@property (nonatomic , weak)     UITextField        *synchronizeTimeIntegerField;

/*!
 * @breif 时间间隔
 * @See null
 */
@property (nonatomic , weak)     UILabel        *synchronizeLabel;

/*!
 * @breif log显示框
 * @See null
 */
@property (nonatomic , weak)      UITextView *logContentTextField;

/*!
 * @breif 倒计时处理
 * @See null
 */
@property (nonatomic,strong)           NSTimer               *timer;

/*!
 * @breif 倒计时读秒
 * @See null
 */
@property (nonatomic,assign)           NSInteger             currentSec;

/*!
 * @breif 倒计时读秒
 * @See null
 */
@property (nonatomic,assign)           int                  productTourId;


/*!
 * @breif 同步操作按键
 * @See null
 */
@property (nonatomic ,  weak)      UIButton                 *doneSynchronizeButton;

/*!
 * @breif 是否支持保存内容
 * @See null
 */
@property (nonatomic ,  assign)      bool       isAuthorization;

/*!
 * @breif HealthClient
 * @See null
 */
@property (nonatomic , strong)      HKHealthStore * healthStore;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.healthStore = [[HKHealthStore alloc]init];
    [self setupUserOperationView];
}


- (void)setupUserOperationView{

    UILabel * cerCodeLabel = [[UILabel alloc]init];
    [cerCodeLabel setFrame:CGRectMake(20.0f, 100.0f, 80.0f, 40.0f)];
    [cerCodeLabel setBackgroundColor:[UIColor clearColor]];
    [cerCodeLabel setText:@"可写数据"];
    [cerCodeLabel setFont:[UIFont systemFontOfSize:16.0]];
    [cerCodeLabel setTextAlignment:NSTextAlignmentLeft];
    [self.view addSubview:cerCodeLabel];
    
    
    UITextField *timeTextField = [[UITextField alloc]init];
    [timeTextField setTextAlignment:NSTextAlignmentLeft];
    [timeTextField setDelegate:self];
    [timeTextField setBackgroundColor:HUIRGBColor(245.0f, 245.0f, 245.0f, 1.0f)];
    [timeTextField setKeyboardType:UIKeyboardTypePhonePad];
    [timeTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [timeTextField setFont:[UIFont systemFontOfSize:22.0f]];
    [timeTextField setTextColor:HUIRGBColor(45.0f, 45.0f, 45.0f, 1.0f)];
    [timeTextField setFrame:CGRectMake(100.0f, 100.0f, 180.0f, 40.0f)];
    self.synchronizeTimeIntegerField = timeTextField;
    [self.view addSubview:self.synchronizeTimeIntegerField];
    
    
    
    
    UILabel * tourIDLabel = [[UILabel alloc]init];
    [tourIDLabel setFrame:CGRectMake(20.0f,160, 80.0f, 40.0f)];
    [tourIDLabel setBackgroundColor:[UIColor clearColor]];
    [tourIDLabel setText:@"所读数据"];
    [tourIDLabel setFont:[UIFont systemFontOfSize:16.0]];
    [tourIDLabel setTextAlignment:NSTextAlignmentLeft];
    [self.view addSubview:tourIDLabel];
    
    UILabel *tourIDTextField = [[UILabel alloc]init];
    [tourIDTextField setTextAlignment:NSTextAlignmentLeft];
    [tourIDTextField setBackgroundColor:HUIRGBColor(245.0f, 245.0f, 245.0f, 1.0f)];
    [tourIDTextField setFrame:CGRectMake(100.0f, 160.0f, 180.0f, 40.0f)];
    [timeTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [timeTextField setText:@"11"];
    [tourIDTextField setTextColor:HUIRGBColor(45.0f, 45.0f, 45.0f, 1.0f)];
    [tourIDTextField setFont:[UIFont systemFontOfSize:22.0f]];
    self.synchronizeLabel = tourIDTextField;
    [self.view addSubview:self.synchronizeLabel];


    [self getStepsFromHealthKit];
    
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [doneButton setFrame:CGRectMake(295.0f, 100.0f, 60.0f, 100.0f)];
    [doneButton setBackgroundImage:createImageWithColor(HUIRGBColor(245.0f, 245.0f, 245.0f, 1.0f))
                          forState:UIControlStateNormal];
    [doneButton setBackgroundImage:createImageWithColor(HUIRGBColor(205.0f, 205.0f, 205.0f, 1.0f))
                          forState:UIControlStateHighlighted];
    [doneButton setTag:KBtnForDoneBeginTag];
    [doneButton setTitleColor:HUIRGBColor(45.0f, 45.0f, 45.0f, 1.0f) forState:UIControlStateNormal];
    [doneButton.titleLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [doneButton setTitle:@"开始同步" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(doneAnsy:) forControlEvents:UIControlEventTouchUpInside];
    self.doneSynchronizeButton = doneButton;
    [self.view addSubview:self.doneSynchronizeButton];
}

#pragma mark - 获取步数 刷新界面
- (void)getStepsFromHealthKit{
    
    
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
   
    __weak __typeof(&*self)weakSelf = self;
    [self fetchSumOfSamplesTodayForType:stepType unit:[HKUnit countUnit] completion:^(double stepCount, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"你的步数为：%.f",stepCount);
            [weakSelf.synchronizeLabel setText:[NSString stringWithFormat:@"%.f",stepCount]];
        });
    }];
}

#pragma mark - 读取HealthKit数据
- (void)fetchSumOfSamplesTodayForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit completion:(void (^)(double, NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSamplesToday];
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        HKQuantity *sum = [result sumQuantity];
        if (completionHandler) {
            double value = [sum doubleValueForUnit:unit];
            completionHandler(value, error);
        }
    }];
    [self.healthStore executeQuery:query];
}


#pragma mark - NSPredicate数据模型
- (NSPredicate *)predicateForSamplesToday {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)doneAnsy:(UIButton *)button{
    
    
    if(button.tag == KBtnForDoneBeginTag){
        
        button.tag = KBtnForDoneSynchronizeTag;
        
        
        double stepInt = [self.synchronizeTimeIntegerField.text doubleValue];
        [self addstepWithStepNum:stepInt];
        
     }else if (KBtnForDoneSynchronizeTag == button.tag ){
         UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"" message:@"已更改" delegate: nil
                                                  cancelButtonTitle:@"取消" otherButtonTitles: nil];
         [alertView show];
    }
    
}





#pragma mark - 添加步数
- (void)addstepWithStepNum:(double)stepNum {
    HKQuantitySample *stepCorrelationItem = [self stepCorrelationWithStepNum:stepNum];
    
    [self.healthStore saveObject:stepCorrelationItem withCompletion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self.view endEditing:YES];
                UIAlertView *doneAlertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"添加成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                [doneAlertView show];
                //刷新数据  重新获取步数
                [self getStepsFromHealthKit];
            }else {
                NSLog(@"The error was: %@.", error);
                UIAlertView *doneAlertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"添加失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                [doneAlertView show];
                return ;
            }
        });
    }];
}

#pragma Mark - 获取HKQuantitySample数据模型
- (HKQuantitySample *)stepCorrelationWithStepNum:(double)stepNum {
    NSDate *endDate = [NSDate date];
    NSDate *startDate = [NSDate dateWithTimeInterval:-3000 sinceDate:endDate];
    
    HKQuantity *stepQuantityConsumed = [HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:-stepNum];
    HKQuantityType *stepConsumedType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    NSString *strName = [[UIDevice currentDevice] name];
    NSString *strModel = [[UIDevice currentDevice] model];
    NSString *strSysVersion = [[UIDevice currentDevice] systemVersion];
    NSString *localeIdentifier = [[NSLocale currentLocale] localeIdentifier];
    
    HKDevice *device = [[HKDevice alloc] initWithName:strName manufacturer:@"Apple" model:strModel hardwareVersion:strModel firmwareVersion:strModel softwareVersion:strSysVersion localIdentifier:localeIdentifier UDIDeviceIdentifier:localeIdentifier];
    
//    HKQuantitySample *stepConsumedSample = [HKQuantitySample quantitySampleWithType:stepConsumedType quantity:stepQuantityConsumed startDate:startDate endDate:endDate device:device metadata:nil];
//    
    
    HKQuantitySample *stepConsumedSample = [HKQuantitySample quantitySampleWithType:stepConsumedType quantity:stepQuantityConsumed startDate:startDate endDate:endDate];
    
    return stepConsumedSample;
}


@end
