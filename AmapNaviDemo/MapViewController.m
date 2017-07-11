//
//  MapViewController.m
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/6/29.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import "MapViewController.h"

#import <AMapFoundationKit/AMapFoundationKit.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

#import "CommonUtility.h"
#import "MANaviRoute.h"

#import "RoutePathDetailTableViewCell.h"
#import "RoutePathHeaderView.h"

static const NSInteger RoutePlanningPaddingEdge = 20;
static const NSString *RoutePlanningViewControllerStartTitle = @"起点";
static const NSString *RoutePlanningViewControllerDestinationTitle = @"终点";
static const NSString *RoutePathDetailStepInfoImageName = @"RoutePathDetailStepInfoImageName";
static const NSString *RoutePathDetailStepInfoText = @"RoutePathDetailStepInfoText";

@interface MapViewController ()<MAMapViewDelegate,AMapSearchDelegate,UITableViewDelegate,UITableViewDataSource,RoutePathHeaderViewDelegate>

@property (strong, nonatomic) MAMapView *mapView;  //地图
@property (strong, nonatomic) AMapSearchAPI *search;  // 地图内的搜索API类
@property (strong, nonatomic) AMapRoute *route;  //路径规划信息
@property (strong, nonatomic) MANaviRoute * naviRoute;  //用于显示当前路线方案.
@property (assign, nonatomic) NSUInteger currentRouteIndex; //当前显示线路的索引值，从0开始

@property (strong, nonatomic) MAPointAnnotation *startAnnotation;
@property (strong, nonatomic) MAPointAnnotation *destinationAnnotation;

@property (assign, nonatomic) CLLocationCoordinate2D startCoordinate; //起始点经纬度
@property (assign, nonatomic) CLLocationCoordinate2D destinationCoordinate; //终点经纬度
@property (copy, nonatomic) NSArray *routeArray;  //规划的路径数组

@property (nonatomic,strong)UITableView *tableView;
@property (nonatomic,strong)RoutePathHeaderView *headerView;
//data
@property (strong, nonatomic) NSMutableArray *routeDetailDataArray;  //路径步骤数组
@property (copy, nonatomic) NSDictionary *drivingImageDic;  //根据AMapStep.action获得对应的图片名字

@end

static BOOL isFrameTop;

@implementation MapViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.mapView.showsUserLocation = YES;
    [self.mapView setUserTrackingMode:MAUserTrackingModeFollow animated:YES];

}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"路线详情";
    UIBarButtonItem *rightButtom = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"daohangmap"] style:UIBarButtonItemStyleDone target:self action:@selector(backToCenterPoint)];
    self.navigationItem.rightBarButtonItem = rightButtom;

    [self initMapViewAndSearch];
    
    [self setUpData];
    
    [self resetSearchResultAndXibViewsToDefault];
    
    [self addDefaultAnnotations];
    
    switch (self.styleIndex) {
        case 1:
        {
            [self searchRoutePlanningBus];  //公交路线开始规划
        }
            break;
        case 2:
        {
            [self searchRoutePlanningDrive];  //驾驶路线开始规划
        }
            break;
        case 3:
        {
            [self searchRoutePlanningWalk];  //步行路线开始规划
        }
            break;
        case 4:
        {
            [self searchRoutePlanningRide];   //骑行路线开始规划
        }
            break;
            
        default:
            break;
    }
    [self presentCurrentRouteCourse];//在地图上显示路径
    isFrameTop = NO;
    _headerView = [[RoutePathHeaderView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScalePx(160))];
    _headerView.delegate = self;
    self.tableView.tableHeaderView = self.headerView;
    
    NSMutableArray *lineArray = @[].mutableCopy;
    if (self.styleIndex == 1) {
    
        for (AMapSegment *segment in self.transit.segments) {
            AMapRailway *railway = segment.railway; //火车,一个城市内的不会出现火车。
            AMapBusLine *busline = [segment.buslines firstObject];  // 地铁或者公交线路
            if (busline.name) {
                [lineArray addObject:busline.name];
            } else if (railway.uid) {
                [lineArray addObject:railway.name];
            }
        }
        self.headerView.timeInfoLabel.text = [lineArray componentsJoinedByString:@" > "];
        
        NSInteger hours = self.transit.duration / 3600;
        NSInteger minutes = (NSInteger)(self.transit.duration / 60) % 60;
        self.headerView.taxiCostInfoLabel.text = [NSString stringWithFormat:@"%u小时%u分钟 | %u公里 | %.0f元 | 步行%.1f公里",(unsigned)hours,(unsigned)minutes,(unsigned)self.transit.distance / 1000, self.transit.cost,self.transit.walkingDistance / 1000.0];
    }
    else {
    
        for (AMapStep *step in self.path.steps) {
            if (step.road) {
                [lineArray addObject:step.road];
            }
        }
        self.headerView.timeInfoLabel.text = [lineArray componentsJoinedByString:@" > "];
        
        NSInteger hours = self.path.duration / 3600;
        NSInteger minutes = (NSInteger)(self.path.duration / 60) % 60;
        self.headerView.taxiCostInfoLabel.text = [NSString stringWithFormat:@"%u小时%u分钟 | %u公里 ",(unsigned)hours,(unsigned)minutes,(unsigned)self.path.distance / 1000];
    }

    [self.view addSubview:self.tableView];
}


//初始化地图,和搜索API
- (void)initMapViewAndSearch {
    
    self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height-ScalePx(160))];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    
    _mapView.desiredAccuracy = kCLLocationAccuracyBest;
    _mapView.distanceFilter = 2.0f;
    _mapView.showsUserLocation = YES;
    
    self.mapView.compassOrigin = CGPointMake(_mapView.compassOrigin.x, 64);
    [self.view addSubview:self.mapView];
    
    self.search = [[AMapSearchAPI alloc] init];
    self.search.delegate = self;
}

//初始化坐标数据
- (void)setUpData {
    self.startCoordinate = CLLocationCoordinate2DMake(self.startLatitude, self.startLongitude);
    self.destinationCoordinate = CLLocationCoordinate2DMake(self.destinationLatitude, self.destinationLongitude);
}

//初始化或者规划失败后，设置view和数据为默认值
- (void)resetSearchResultAndXibViewsToDefault {
    self.currentRouteIndex = self.index;
    self.routeArray = nil; //线路信息清空
    [self.naviRoute removeFromMapView]; //移除已经绘制的线路
}

//在地图上添加起始和终点的标注点
- (void)addDefaultAnnotations {
    MAPointAnnotation *startAnnotation = [[MAPointAnnotation alloc] init];
    startAnnotation.coordinate = self.startCoordinate;
    startAnnotation.title = (NSString *)RoutePlanningViewControllerStartTitle;
    startAnnotation.subtitle = [NSString stringWithFormat:@"{%f, %f}", self.startCoordinate.latitude, self.startCoordinate.longitude];
    self.startAnnotation = startAnnotation;
    
    MAPointAnnotation *destinationAnnotation = [[MAPointAnnotation alloc] init];
    destinationAnnotation.coordinate = self.destinationCoordinate;
    destinationAnnotation.title = (NSString *)RoutePlanningViewControllerDestinationTitle;
    destinationAnnotation.subtitle = [NSString stringWithFormat:@"{%f, %f}", self.destinationCoordinate.latitude, self.destinationCoordinate.longitude];
    self.destinationAnnotation = destinationAnnotation;
    
    [self.mapView addAnnotation:startAnnotation];
    [self.mapView addAnnotation:destinationAnnotation];
}

//公交路线开始规划
- (void)searchRoutePlanningBus {
    
    AMapTransitRouteSearchRequest *navi = [[AMapTransitRouteSearchRequest alloc] init];  //公交路径规划请求
    navi.requireExtension = YES;
    navi.city = self.cityName;  //指定城市，必填
    
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude
                                           longitude:self.startCoordinate.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude
                                                longitude:self.destinationCoordinate.longitude];
    
    [self.search AMapTransitRouteSearch:navi];
}
//驾车路线开始规划
- (void)searchRoutePlanningDrive {
    
    AMapDrivingRouteSearchRequest *navi = [[AMapDrivingRouteSearchRequest alloc] init];
    navi.requireExtension = YES;
    navi.strategy = 5; //驾车导航策略,5-多策略（同时使用速度优先、费用优先、距离优先三个策略）
    
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude
                                           longitude:self.startCoordinate.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude
                                                longitude:self.destinationCoordinate.longitude];
    
    [self.search AMapDrivingRouteSearch:navi];
}
//步行路线开始规划
- (void)searchRoutePlanningWalk {
    
    AMapWalkingRouteSearchRequest *navi = [[AMapWalkingRouteSearchRequest alloc] init];
    
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude
                                           longitude:self.startCoordinate.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude
                                                longitude:self.destinationCoordinate.longitude];
    
    [self.search AMapWalkingRouteSearch:navi];
}
//骑行路线开始规划
- (void)searchRoutePlanningRide {
    
    AMapRidingRouteSearchRequest *navi = [[AMapRidingRouteSearchRequest alloc] init];
    
    /* 出发点. */
    navi.origin = [AMapGeoPoint locationWithLatitude:self.startCoordinate.latitude
                                           longitude:self.startCoordinate.longitude];
    /* 目的地. */
    navi.destination = [AMapGeoPoint locationWithLatitude:self.destinationCoordinate.latitude
                                                longitude:self.destinationCoordinate.longitude];
    
    [self.search AMapRidingRouteSearch:navi];
}


#pragma mark - AMapSearchDelegate

//当路径规划搜索请求发生错误时，会调用代理的此方法
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error);
    [self resetSearchResultAndXibViewsToDefault];
}

//路径规划搜索完成回调.
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response {

    if (response.route == nil){
        [self resetSearchResultAndXibViewsToDefault];
        return;
    }
    self.route = response.route;
    self.currentRouteIndex = self.index;
    
    switch (self.styleIndex) {
        case 1:
        {
            self.routeArray = self.route.transits;  //给公交换乘方案数据源
        }
            break;
        case 2:
        {
            self.routeArray = self.route.paths;  //驾驶方案的数据源
        }
            break;
        case 3:
        {
            self.routeArray = self.route.paths;  //步行方案的数据源
        }
            break;
        case 4:
        {
            self.routeArray = self.route.paths;  //骑行方案的数据源
        }
            break;

        default:
            break;
    }
    
    [self presentCurrentRouteCourse];
}

//在地图上显示当前选择的路径
- (void)presentCurrentRouteCourse {
    
    if (self.routeArray.count <= 0) {
        return;
    }
    
    [self.naviRoute removeFromMapView];  //清空地图上已有的路线
    
    AMapGeoPoint *startPoint = [AMapGeoPoint locationWithLatitude:self.startAnnotation.coordinate.latitude longitude:self.startAnnotation.coordinate.longitude]; //起点
    
    AMapGeoPoint *endPoint = [AMapGeoPoint locationWithLatitude:self.destinationAnnotation.coordinate.latitude longitude:self.destinationAnnotation.coordinate.longitude];  //终点
    
    //根据已经规划的换乘方案，起点，终点，生成显示方案
    switch (self.styleIndex) {
        case 1:
        {
            self.naviRoute = [MANaviRoute naviRouteForTransit:self.route.transits[self.currentRouteIndex] startPoint:startPoint endPoint:endPoint];

        }
            break;
        case 2:
        {
            self.naviRoute = [MANaviRoute naviRouteForPath:self.route.paths[self.currentRouteIndex] withNaviType:MANaviAnnotationTypeDrive showTraffic:YES startPoint:startPoint endPoint:endPoint];

        }
            break;
        case 3:
        {
            //根据已经规划的路径，起点，终点，规划类型，是否显示实时路况，生成显示方案
            self.naviRoute = [MANaviRoute naviRouteForPath:self.route.paths[self.currentRouteIndex] withNaviType:MANaviAnnotationTypeWalking showTraffic:NO startPoint:startPoint endPoint:endPoint];
        }
            break;
        case 4:
        {
            //根据已经规划的路径，起点，终点，规划类型，是否显示实时路况，生成显示方案
            self.naviRoute = [MANaviRoute naviRouteForPath:self.route.paths[self.currentRouteIndex] withNaviType:MANaviAnnotationTypeRiding showTraffic:NO startPoint:startPoint endPoint:endPoint];
        }
            break;
            
        default:
            break;
    }
    
    [self.naviRoute addToMapView:self.mapView];  //显示到地图上
    
    UIEdgeInsets edgePaddingRect = UIEdgeInsetsMake(RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge, RoutePlanningPaddingEdge);
    
    //缩放地图使其适应polylines的展示
    [self.mapView setVisibleMapRect:[CommonUtility mapRectForOverlays:self.naviRoute.routePolylines] edgePadding:edgePaddingRect animated:NO];
}

#pragma mark - MAMapViewDelegate
//地图定位
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {

}


//地图上覆盖物的渲染，可以设置路径线路的宽度，颜色等
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay {
    //虚线，如需要步行的
    if ([overlay isKindOfClass:[LineDashPolyline class]]) {
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:((LineDashPolyline *)overlay).polyline];
        polylineRenderer.lineWidth = 6;
        polylineRenderer.lineDash = YES;
        polylineRenderer.strokeColor = [UIColor redColor];
        
        return polylineRenderer;
    }
    
    //路径为单一颜色，比如公交线路目前为blueColor
    if ([overlay isKindOfClass:[MANaviPolyline class]]) {
        MANaviPolyline *naviPolyline = (MANaviPolyline *)overlay;
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:naviPolyline.polyline];
        
        polylineRenderer.lineWidth = 6;
        
        if (naviPolyline.type == MANaviAnnotationTypeWalking){
            polylineRenderer.strokeColor = self.naviRoute.walkingColor;
        }else if (naviPolyline.type == MANaviAnnotationTypeRailway){
            polylineRenderer.strokeColor = self.naviRoute.railwayColor;
        }else{
            polylineRenderer.strokeColor = self.naviRoute.routeColor;
        }
        return polylineRenderer;
    }
    //showTraffic为YES时，需要带实时路况，路径为多颜色渐变，多用于驾车路线规划，公交路线规划为单一颜色
    if ([overlay isKindOfClass:[MAMultiPolyline class]]) {
        MAMultiColoredPolylineRenderer * polylineRenderer = [[MAMultiColoredPolylineRenderer alloc] initWithMultiPolyline:overlay];
        
        polylineRenderer.lineWidth = 6;
        polylineRenderer.strokeColors = [self.naviRoute.multiPolylineColors copy];
        
        return polylineRenderer;
    }
    
    return nil;
}

//地图上的起始点，终点，拐点的标注，可以自定义图标展示等
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {

    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        //标注的view的初始化和复用
        static NSString *routePlanningCellIdentifier = @"RoutePlanningCellIdentifier";
        
        MAAnnotationView *poiAnnotationView = (MAAnnotationView*)[self.mapView dequeueReusableAnnotationViewWithIdentifier:routePlanningCellIdentifier];
        
        if (poiAnnotationView == nil) {
            poiAnnotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:routePlanningCellIdentifier];
        }
        
        poiAnnotationView.canShowCallout = YES;
        poiAnnotationView.image = nil;
        
        //拐点的图标标注
        if ([annotation isKindOfClass:[MANaviAnnotation class]]) {
            switch (((MANaviAnnotation*)annotation).type) {
                case MANaviAnnotationTypeRailway:
                    poiAnnotationView.image = [UIImage imageNamed:@"railway_station"];
                    break;
                    
                case MANaviAnnotationTypeBus:
                    poiAnnotationView.image = [UIImage imageNamed:@"bus"];
                    break;
                    
                case MANaviAnnotationTypeDrive:
                    poiAnnotationView.image = [UIImage imageNamed:@"car"];
                    break;
                    
                case MANaviAnnotationTypeWalking:
                    poiAnnotationView.image = [UIImage imageNamed:@"man"];
                    break;
                    
                default:
                    break;
            }
        }else{
            //起点，终点的图标标注
            if ([[annotation title] isEqualToString:(NSString*)RoutePlanningViewControllerStartTitle]) {
                poiAnnotationView.image = [UIImage imageNamed:@"startPoint"];  //起点
            } else if ([[annotation title] isEqualToString:(NSString*)RoutePlanningViewControllerDestinationTitle]) {
                poiAnnotationView.image = [UIImage imageNamed:@"endPoint"];  //终点
            }
        }
        return poiAnnotationView;
    }
    return nil;
}
//MARK:= = = = = = = = = = 回到地图中心点 = = = = = = = =
- (void)backToCenterPoint {

    MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
    annotation.coordinate = CLLocationCoordinate2DMake(_startLatitude, _startLongitude);
    [_mapView showAnnotations:@[annotation] edgePadding:UIEdgeInsetsMake(0, 0, 0, 0) animated:YES];
    
    __weak typeof(self) weakSelf = self;
    isFrameTop = YES;
    [UIView animateWithDuration:0.5 animations:^{
        //            weakSelf.mapView.frame = CGRectMake(0, 0, ScreenWidth, ScreeenHeight-ScalePx(400));
        weakSelf.headerView.imageV.image = [UIImage imageNamed:@"sanjiaotop"];
        weakSelf.tableView.frame = CGRectMake(0, ScreeenHeight-ScalePx(160), ScreeenHeight, ScalePx(160));
        [weakSelf.tableView reloadData];
    }];

    
}

//MARK: = = = = = = = = tableViewDelegate == = = = = = =  =
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

   return self.routeDetailDataArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    RoutePathDetailTableViewCell *cell = (RoutePathDetailTableViewCell *)[tableView dequeueReusableCellWithIdentifier:RoutePathDetailTableViewCellIdentifier forIndexPath:indexPath];
    if (self.styleIndex == 1) {
        NSDictionary *stepInfo = [self.routeDetailDataArray objectAtIndex:indexPath.row];
        cell.infoLabel.text = stepInfo[RoutePathDetailStepInfoText];
        cell.actionImageView.image = [UIImage imageNamed:stepInfo[RoutePathDetailStepInfoImageName]];
    }
    else {
        AMapStep *step = [self.routeDetailDataArray objectAtIndex:indexPath.row];
        cell.infoLabel.text = step.instruction;
        cell.actionImageView.image = [UIImage imageNamed:[self.drivingImageDic objectForKey:step.action]];
    }
    cell.topVerticalLine.hidden = indexPath.row == 0;
    cell.bottomVerticalLine.hidden = indexPath.row == self.routeDetailDataArray.count - 1;
    
    return cell;

}
//MARK:= = = = = tableView头视图的代理方法（改变frame）= = = = = =
-(void)changeTableViewFrame {
    if (isFrameTop) {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.5 animations:^{
//            weakSelf.mapView.frame = CGRectMake(0, 0, ScreenWidth, ScreeenHeight-ScalePx(160));
            weakSelf.headerView.imageV.image = [UIImage imageNamed:@"sanjiaotop"];
            weakSelf.tableView.frame = CGRectMake(0, ScreeenHeight-ScalePx(160), ScreeenHeight, ScalePx(160));
        }];
        isFrameTop = NO;
    }
    else {
        __weak typeof(self) weakSelf = self;
        [UIView animateWithDuration:0.5 animations:^{
//            weakSelf.mapView.frame = CGRectMake(0, 0, ScreenWidth, ScreeenHeight-ScalePx(400));
            weakSelf.headerView.imageV.image = [UIImage imageNamed:@"sanjiaodown"];
            weakSelf.tableView.frame = CGRectMake(0, ScreeenHeight-ScalePx(400), ScreeenHeight, ScalePx(400));
        }];
        isFrameTop = YES;
    }
}

- (NSMutableArray *)routeDetailDataArray {
    if (!_routeDetailDataArray) {
            if (_styleIndex == 1) {
        
            _routeDetailDataArray = @[].mutableCopy;
            [_routeDetailDataArray addObject:@{RoutePathDetailStepInfoImageName : @"start",RoutePathDetailStepInfoText : @"开始出发"}]; // 图片的名字，具体步骤的文字信息
            for (AMapSegment *segment in self.transit.segments) {
                AMapRailway *railway = segment.railway; //火车
                AMapBusLine *busline = [segment.buslines firstObject];  // 地铁或者公交线路
                AMapWalking *walking = segment.walking;  //搭乘地铁或者公交前的步行信息
                
                if (walking.distance) {
                    NSString *walkInfo = [NSString stringWithFormat:@"步行%u米",(unsigned)walking.distance];
                    [self.routeDetailDataArray addObject:@{RoutePathDetailStepInfoImageName : @"walkRoute",RoutePathDetailStepInfoText : walkInfo}];
                }
                
                if (busline.name) {
                    NSString *busImageName = @"busRoute";
                    if ([busline.type isEqualToString:@"地铁线路"]) { //区分公交和地铁
                        busImageName = @"underGround";
                    }
                    //viaBusStops途径的公交车站的数组，如需具体站名，可解析。
                    NSString *busInfoText = [NSString stringWithFormat:@"乘坐%@，在 %@ 上车，途经 %u 站，在 %@ 下车",busline.name,busline.departureStop.name,(unsigned)(busline.viaBusStops.count + 1),busline.arrivalStop.name];
                    [_routeDetailDataArray addObject:@{RoutePathDetailStepInfoImageName : busImageName,RoutePathDetailStepInfoText : busInfoText}];
                    
                } else if (railway.uid) {
                    [_routeDetailDataArray addObject:@{RoutePathDetailStepInfoImageName : @"railwayRoute",RoutePathDetailStepInfoText : railway.name}];
                }
            }
            [_routeDetailDataArray addObject:@{RoutePathDetailStepInfoImageName : @"end",RoutePathDetailStepInfoText : @"抵达终点"}];
        }
        else {
        
            self.drivingImageDic = @{
                                     @"开始":@"start",
                                     @"结束":@"end",
                                     @"右转":@"right",
                                     @"左转":@"left",
                                     @"直行":@"straight",
                                     @"向右前方行驶":@"rightFront",
                                     @"向左前方行驶":@"leftFront",
                                     @"向左后方行驶":@"leftRear",
                                     @"向右后方行驶":@"rightRear",
                                     @"左转调头":@"leftRear",
                                     @"靠左":@"leftFront",
                                     @"靠右":@"rightFront",
                                     @"进入环岛":@"straight",
                                     @"离开环岛":@"straight",
                                     @"减速行驶":@"dottedStraight",
                                     @"插入直行":@"straight",
                                     @"":@"straight",
                                     };

            AMapStep *startStep = [AMapStep new];
            startStep.action = @"开始"; //导航主要动作，用来标示图标
            startStep.instruction = @"开始";  //行走指示
            
            AMapStep *endStep = [AMapStep new];
            endStep.action = @"结束";
            endStep.instruction = @"抵达";
            
            _routeDetailDataArray = @[].mutableCopy;
            [_routeDetailDataArray addObject:startStep];
            [_routeDetailDataArray addObjectsFromArray:self.path.steps];
            [_routeDetailDataArray addObject:endStep];
        
        }
    }
    return _routeDetailDataArray;
}
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, ScreeenHeight - ScalePx(400), ScreenWidth, ScalePx(400)) style:UITableViewStylePlain];
        _tableView.rowHeight = 54;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerNib:[UINib nibWithNibName:@"RoutePathDetailTableViewCell" bundle:nil] forCellReuseIdentifier:RoutePathDetailTableViewCellIdentifier];
    }
    return _tableView;
}


@end
