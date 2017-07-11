//
//  ViewController.m
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/6/27.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import "LocationAnnotationView.h"
#import "SearchRoadViewController.h"

@interface ViewController ()<MAMapViewDelegate>

{
    CGFloat _startLatitude;//用户经度坐标
    CGFloat _startLonggitude;//用户纬度坐标
    NSString *_cityName;//用户所在城市
    NSMutableArray *_annotations;
}
    
@property (nonatomic,strong)MAMapView *mapView;//地图
@property (nonatomic,strong)LocationAnnotationView *locationAnnotationView;

@end

@implementation ViewController
    
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];

    _mapView.showsUserLocation = YES;
    [_mapView setUserTrackingMode:MAUserTrackingModeFollow animated:YES];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"高德地图";
    
    UIBarButtonItem *rightButtom = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"daohangmap"] style:UIBarButtonItemStyleDone target:self action:@selector(backToCenterPoint)];
    self.navigationItem.rightBarButtonItem = rightButtom;
    
    [self initView];
    [self initBottomView];
}
//MARK:= = = == = = = = = 地图定位 = = = = = = = =
- (void)initView {

    self.mapView = [[MAMapView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height-40)];
    _mapView.backgroundColor = [UIColor whiteColor];
    _mapView.delegate = self;
    _mapView.desiredAccuracy = kCLLocationAccuracyBest;
    _mapView.distanceFilter = 2.0f;
    _mapView.zoomEnabled = YES;
    _mapView.mapType = MAMapTypeStandard;
    _mapView.showsCompass = YES;
    _mapView.compassOrigin = CGPointMake(_mapView.compassOrigin.x, 86);
    _mapView.showsScale = YES;
    _mapView.scaleOrigin = CGPointMake(_mapView.scaleOrigin.x, 86);
    [_mapView setZoomLevel:16 animated:YES];
    [self.view addSubview:self.mapView];
    
}
- (void)mapInitComplete:(MAMapView *)mapView {
     MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
    annotation.coordinate = CLLocationCoordinate2DMake(30.29034, 120.070313);
    [mapView addAnnotation:annotation];

}
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay {
    /* 自定义定位精度对应的MACircleView. */
    if (overlay == mapView.userLocationAccuracyCircle)
    {
        MACircleRenderer *accuracyCircleRenderer = [[MACircleRenderer alloc] initWithCircle:overlay];
        
        accuracyCircleRenderer.lineWidth    = 2.f;
        accuracyCircleRenderer.strokeColor  = [UIColor lightGrayColor];
        accuracyCircleRenderer.fillColor    = [UIColor colorWithRed:1 green:0 blue:0 alpha:.3];
        return accuracyCircleRenderer;
    }
    return nil;
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation{

    _startLatitude = userLocation.location.coordinate.latitude;
    _startLonggitude = userLocation.location.coordinate.longitude;
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:userLocation.location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (placemarks.count > 0) {
            
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            _cityName = placemark.locality;
        }
    }];
    
    if (!updatingLocation && _locationAnnotationView != nil)
    {
        _locationAnnotationView.rotateDegree = userLocation.heading.trueHeading - _mapView.rotationDegree;
    }
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {

//    定位起始坐标
    if([annotation isKindOfClass:[MAUserLocation class]]){
        static NSString *userLocationStyleReuseIndetifier = @"userLocationStyleReuseIndetifier";
        MAAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:userLocationStyleReuseIndetifier];
        if (annotationView == nil)
        {
            annotationView = [[LocationAnnotationView alloc] initWithAnnotation:annotation
                                                                reuseIdentifier:userLocationStyleReuseIndetifier];
            annotationView.canShowCallout = YES;
            annotationView.annotation.title = @"我的位置";
        }
        _locationAnnotationView = (LocationAnnotationView *)annotationView;
        [_locationAnnotationView updateImage:[UIImage imageNamed:@"userPosition"]];

        return annotationView;
    }
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *pointReuseIndetifier = @"pointReuseIndetifier";
        
        MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        
        if (annotationView == nil) {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndetifier];
            annotationView.image = [UIImage imageNamed:@"endPoint"];;
        }
        return annotationView;
    }
    return nil;
}

- (void)initBottomView {

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"查看详情路线" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor redColor]];
    [button addTarget:self action:@selector(clickToDetail) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, self.view.frame.size.height-40, self.view.frame.size.width, 40);
    [self.view addSubview:button];
}
//MARK:查看路线详情
- (void)clickToDetail {

    SearchRoadViewController *searchVC = [[SearchRoadViewController alloc]init];
    searchVC.startLatitude = _startLatitude;
    searchVC.startLongitude = _startLonggitude;
    searchVC.destinationLatitude = 30.29034;
    searchVC.destinationLongitude = 120.070313;
    searchVC.cityName = _cityName;
    [self.navigationController pushViewController:searchVC animated:YES];
}
//MARK:回到中心点
- (void)backToCenterPoint {

    MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
    annotation.coordinate = CLLocationCoordinate2DMake(_startLatitude, _startLonggitude);

    [_mapView showAnnotations:@[annotation] edgePadding:UIEdgeInsetsMake(0, 0, 0, 0) animated:YES];
}
@end
