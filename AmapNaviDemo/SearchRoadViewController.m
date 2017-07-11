//
//  SearchRoadViewController.m
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/6/28.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import "SearchRoadViewController.h"
#import "SearchLocationView.h"
#import "RoadViewCell.h"
#import "MapViewController.h"
#import "SearchRoadFooterView.h"

#import <AMapFoundationKit/AMapFoundationKit.h>
#import <MAMapKit/MAMapKit.h>
#import <MapKit/MapKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

#import "CommonUtility.h"
#import "MANaviRoute.h"

static const NSString *RoutePlanningViewControllerStartTitle = @"起点";
static const NSString *RoutePlanningViewControllerDestinationTitle = @"终点";
static NSString *roadCell = @"roadCell";

@interface SearchRoadViewController ()<AMapSearchDelegate,LoadionViewDelagete,SearchRoadFooterViewDelegate,UITableViewDelegate,UITableViewDataSource>

//@property (strong, nonatomic) MAMapView *mapView;  //地图
@property (strong, nonatomic) AMapSearchAPI *search;  // 地图内的搜索API类
@property (strong, nonatomic) AMapRoute *route;  //路径规划信息
@property (strong, nonatomic) MANaviRoute * naviRoute;  //用于显示当前路线方案.

@property (strong, nonatomic) MAPointAnnotation *startAnnotation;
@property (strong, nonatomic) MAPointAnnotation *destinationAnnotation;

@property (assign, nonatomic) CLLocationCoordinate2D startCoordinate; //起始点经纬度
@property (assign, nonatomic) CLLocationCoordinate2D destinationCoordinate; //终点经纬度

@property (assign, nonatomic) NSUInteger currentRouteIndex; //当前显示线路的索引值，从0开始
@property (copy, nonatomic) NSArray *routeArray;  //规划的路径数组，collectionView的数据源

@property (nonatomic,strong)SearchLocationView *locationView;//顶部视图
@property (nonatomic,strong)UITableView *loadTableView;
@property (nonatomic,assign)NSInteger buttonTag;//1代表公交路线；2代表驾驶路线；3代表步行路线
@property (nonatomic,strong)SearchRoadFooterView *footerView;

@end

@implementation SearchRoadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"查看路线";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.locationView];
    [self initMapViewAndSearch];
    
    [self setUpData];
    
    [self resetSearchResultAndXibViewsToDefault];
    _buttonTag = 1;
    [self searchRoutePlanningBus];  //公交路线开始规划
    [self.view addSubview:self.loadTableView];
    self.loadTableView.tableFooterView = self.footerView;
}
//初始化地图,和搜索API
- (void)initMapViewAndSearch {
    
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

    self.routeArray = nil; //线路信息清空
    [self.loadTableView reloadData];
    [self.naviRoute removeFromMapView]; //移除已经绘制的线路
}

//MARK:公交路线开始规划
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
//MARK:驾车路线开始规划
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
//MARK:步行路线开始规划
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
//MARK:骑行路线开始规划
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
    switch (_buttonTag) {
        case 1:
        {
            self.routeArray = self.route.transits;  //给公交换乘方案作为数据源

        }
            break;
        case 2:
        {
            self.routeArray = self.route.paths;   //给驾驶方案作为数据源
        }
            break;
        case 3:
        {
            self.routeArray = self.route.paths;   //给步行方案作为数据源
        }
            break;
        case 4:
        {
            self.routeArray = self.route.paths;   //给骑行方案作为数据源
        }
            break;

        default:
            break;
    }
//    //处理view
    [self.loadTableView reloadData];
}
#pragma = = =  = = = tabelViewDelegate = = = =
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

   return  self.routeArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    RoadViewCell *cell = [tableView dequeueReusableCellWithIdentifier:roadCell forIndexPath:indexPath];
    switch (_buttonTag) {
        case 1:
        {
            AMapTransit *transit = [self.routeArray objectAtIndex:indexPath.row];
            [cell configureWithTransit:transit];

        }
            break;
        case 2:
        {
            AMapPath *path = [self.routeArray objectAtIndex:indexPath.row];
            [cell configureWithPath:path];
            
        }
            break;
        case 3:
        {
            AMapPath *path = [self.routeArray objectAtIndex:indexPath.row];
            [cell configureWithWarkPath:path];
        }
            break;
        case 4:
        {
            AMapPath *path = [self.routeArray objectAtIndex:indexPath.row];
            [cell configureWithRidePath:path];
        }
            break;

        default:
            break;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return ScalePx(150);
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    MapViewController *mapViewC = [[MapViewController alloc]init];
    mapViewC.startLatitude = self.startLatitude;
    mapViewC.startLongitude = self.startLongitude;
    mapViewC.destinationLatitude = self.destinationLatitude;
    mapViewC.destinationLongitude = self.destinationLongitude;
    mapViewC.index = indexPath.row;
    mapViewC.cityName = self.cityName;
    mapViewC.styleIndex = _buttonTag;
    
    mapViewC.route1 = self.route;
    mapViewC.path = self.route.paths[indexPath.row];
    mapViewC.transit = self.route.transits[indexPath.row];
    
    [self.navigationController pushViewController:mapViewC animated:YES];
}
//MARK:切换导航方式
-(void)exchangeLoadStyleWithTag:(NSInteger)tag {

    switch (tag) {
        case 1://公交路线
        {
            _buttonTag = 1;
            _routeArray = nil;
            [_loadTableView reloadData];
            [self initMapViewAndSearch];
            [self searchRoutePlanningBus];
        }
        break;
        case 2://驾驶路线
        {
            _buttonTag = 2;
            _routeArray = nil;
            [_loadTableView reloadData];
            [self initMapViewAndSearch];
            [self searchRoutePlanningDrive];

        }
        break;
        case 3://步行路线
        {
            _buttonTag = 3;
            _routeArray = nil;
            [_loadTableView reloadData];
            [self initMapViewAndSearch];
            [self searchRoutePlanningWalk];
        }
        break;
        case 4://骑行路线
        {
            _buttonTag = 4;
            _routeArray = nil;
            [_loadTableView reloadData];
            [self initMapViewAndSearch];
            [self searchRoutePlanningRide];

        }
            break;

        default:
        break;
    }
}
//MARK: = = == 切换到本级地图导航 = = = = =
-(void)exchangeToMapNavigation {

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"地图导航" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"自带地图" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        //使用自带地图导航
        MKMapItem *currentLocation =[MKMapItem mapItemForCurrentLocation];
        
        MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:self.destinationCoordinate addressDictionary:nil]];
        
        [MKMapItem openMapsWithItems:@[currentLocation,toLocation] launchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving,
                                                                                   MKLaunchOptionsShowsTrafficKey:[NSNumber numberWithBool:YES]}];
    }]];
    //判断是否安装了高德地图，如果安装了高德地图，则使用高德地图导航
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"高德地图" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"alertController -- 高德地图");
            NSString *urlsting =[[NSString stringWithFormat:@"iosamap://navi?sourceApplication= &backScheme= &lat=%f&lon=%f&dev=0&style=2",self.destinationCoordinate.latitude,self.destinationCoordinate.longitude]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [[UIApplication  sharedApplication]openURL:[NSURL URLWithString:urlsting]];

        }]];
    }
    //判断是否安装了百度地图，如果安装了百度地图，则使用百度地图导航
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"百度地图" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSLog(@"alertController -- 百度地图");
            NSString *urlsting =[[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=目的地&mode=driving&coord_type=gcj02",self.destinationCoordinate.latitude,self.destinationCoordinate.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlsting]];
            
        }]];
    }
    
    //添加取消选项
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        [alertController dismissViewControllerAnimated:YES completion:nil];
        
    }]];
    
    //显示alertController
    [self presentViewController:alertController animated:YES completion:nil];
    

}
//MARK:懒加载视图
- (SearchLocationView *)locationView {
    if (!_locationView) {
        _locationView = [[SearchLocationView alloc]initWithFrame:CGRectMake(0, 64, ScreenWidth, ScalePx(250))];
        _locationView.delegate = self;
    }
    return _locationView;
}
- (UITableView *)loadTableView {
    if (!_loadTableView) {
        _loadTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 64+ScalePx(250), ScreenWidth, ScreeenHeight-64-ScalePx(210)) style:UITableViewStylePlain];
        _loadTableView.backgroundColor = LineColor;
        _loadTableView.delegate = self;
        _loadTableView.dataSource = self;
        _loadTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_loadTableView registerClass:[RoadViewCell class] forCellReuseIdentifier:roadCell];
    }
    return _loadTableView;
}
- (NSArray *)routeArray {
    if (!_routeArray) {
        _routeArray = [NSArray array];
    }
    return _routeArray;
}
- (SearchRoadFooterView *)footerView {
    if (!_footerView) {
        _footerView = [[SearchRoadFooterView alloc]initWithFrame:CGRectMake(0, 0, ScreenWidth, ScalePx(120))];
        _footerView.delagate = self;
    }
    return _footerView;
}
@end
