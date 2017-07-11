//
//  RoadViewCell.h
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/6/29.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AMapTransit;
@class AMapPath;

@interface RoadViewCell : UITableViewCell

@property (nonatomic,strong)UILabel *trafficTransferInfoLabel;
@property (nonatomic,strong)UILabel *otherInfoLabel;
@property (nonatomic,strong)UIView *lineView;

//公交路线数据源
- (void)configureWithTransit:(AMapTransit *)transit;
//驾驶路线数据源
- (void)configureWithPath:(AMapPath *)path;
//步行路线数据源
- (void)configureWithWarkPath:(AMapPath *)path;
//骑行路线数据源
- (void)configureWithRidePath:(AMapPath *)path;
@end
