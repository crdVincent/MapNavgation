//
//  MapViewController.h
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/6/29.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AMapPath;
@class AMapRoute;
@class AMapTransit;

@interface MapViewController : UIViewController

@property (nonatomic,assign) float startLatitude;
@property (nonatomic,assign) float destinationLatitude;
@property (nonatomic,assign) float startLongitude;
@property (nonatomic,assign) float destinationLongitude;

@property (nonatomic,assign)NSInteger styleIndex;//出行方式
@property (nonatomic,assign)NSInteger index;//相应出行方式的路线索引值
@property (nonatomic,strong)NSString *cityName;

@property (strong, nonatomic) AMapRoute *route1;
@property (strong, nonatomic) AMapPath *path;
@property (strong, nonatomic) AMapTransit *transit;  //公交换乘方案的详细信息


@end
