//
//  RoadViewCell.m
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/6/29.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import "RoadViewCell.h"
#import <AMapSearchKit/AMapSearchKit.h>


@implementation RoadViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = LineColor;
        [self setUpViews];
    }
    return self;
}
- (void)setUpViews {

    _trafficTransferInfoLabel = ({
        UILabel *label = [[UILabel alloc]init];
        label.textColor = LabelBaseColor;
        label.font = LabelFont;
        label.numberOfLines = 2;
        [self addSubview:label];
        label;
    });
    _otherInfoLabel = ({
        UILabel *label = [[UILabel alloc]init];
        label.textColor = SmallLabelColor;
        label.font = BaseFont;
        [self addSubview:label];
        label;
    });
    _lineView = ({
        UIView *view = [[UIView alloc]init];
        view.backgroundColor = BackColor;
        [self addSubview:view];
        view;
    });
    
    [self setLayout];
}
- (void)setLayout {
    _trafficTransferInfoLabel.sd_layout.
    leftSpaceToView(self, ScalePx(20)).
    topSpaceToView(self, ScalePx(20)).
    rightSpaceToView(self, ScalePx(40)).
    heightIs(ScalePx(70));
    
    _otherInfoLabel.sd_layout.
    leftEqualToView(_trafficTransferInfoLabel).
    topSpaceToView(_trafficTransferInfoLabel, ScalePx(10)).
    rightEqualToView(_trafficTransferInfoLabel).
    heightIs(ScalePx(30));
    
    _lineView.sd_layout.
    leftSpaceToView(self, ScalePx(20)).
    rightEqualToView(self).
    bottomEqualToView(self).
    heightIs(ScalePx(2));
}
//MARK:公交路线数据
- (void)configureWithTransit:(AMapTransit *)transit {
    
    NSMutableArray *buslineArray = @[].mutableCopy;
    for (AMapSegment *segment in transit.segments) {
        AMapRailway *railway = segment.railway; //火车,一个城市内的不会出现火车。
        AMapBusLine *busline = [segment.buslines firstObject];  // 地铁或者公交线路
        if (busline.name) {
            [buslineArray addObject:busline.name];
        } else if (railway.uid) {
            [buslineArray addObject:railway.name];
        }
    }
    self.trafficTransferInfoLabel.text = [buslineArray componentsJoinedByString:@" > "];
    
    NSInteger hours = transit.duration / 3600;
    NSInteger minutes = (NSInteger)(transit.duration / 60) % 60;
    self.otherInfoLabel.text = [NSString stringWithFormat:@"%u小时%u分钟 | %u公里 | %.0f元 | 步行%.1f公里",(unsigned)hours,(unsigned)minutes,(unsigned)transit.distance / 1000, transit.cost,transit.walkingDistance / 1000.0];
}
//MARK:驾驶路线数据
- (void)configureWithPath:(AMapPath *)path {

    NSMutableArray *carLineArray = @[].mutableCopy;
    for (AMapStep *step in path.steps) {
        if (step.road) {
            [carLineArray addObject:step.road];
        }
    }
    self.trafficTransferInfoLabel.text = [carLineArray componentsJoinedByString:@" > "];
    
    NSInteger hours = path.duration / 3600;
    NSInteger minutes = (NSInteger)(path.duration / 60) % 60;
    self.otherInfoLabel.text = [NSString stringWithFormat:@"%u小时%u分钟 | %u公里 | %.0f元 | %ld个红绿灯",(unsigned)hours,(unsigned)minutes,(unsigned)path.distance / 1000, path.tolls,path.totalTrafficLights];
}
//步行路线数据源
- (void)configureWithWarkPath:(AMapPath *)path {

    NSMutableArray *carLineArray = @[].mutableCopy;
    for (AMapStep *step in path.steps) {
        if (step.road) {
            [carLineArray addObject:step.road];
        }
    }
    self.trafficTransferInfoLabel.text = [carLineArray componentsJoinedByString:@" > "];
    
    NSInteger hours = path.duration / 3600;
    NSInteger minutes = (NSInteger)(path.duration / 60) % 60;
    self.otherInfoLabel.text = [NSString stringWithFormat:@"%u小时%u分钟 | %u公里 ",(unsigned)hours,(unsigned)minutes,(unsigned)path.distance / 1000];
}
//骑行路线数据源
- (void)configureWithRidePath:(AMapPath *)path {

    NSMutableArray *carLineArray = @[].mutableCopy;
    for (AMapStep *step in path.steps) {
        if (step.road) {
            [carLineArray addObject:step.road];
        }
    }
    self.trafficTransferInfoLabel.text = [carLineArray componentsJoinedByString:@" > "];
    
    NSInteger hours = path.duration / 3600;
    NSInteger minutes = (NSInteger)(path.duration / 60) % 60;
    self.otherInfoLabel.text = [NSString stringWithFormat:@"%u小时%u分钟 | %u公里 ",(unsigned)hours,(unsigned)minutes,(unsigned)path.distance / 1000];
}

@end
