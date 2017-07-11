//
//  RoutePathHeaderView.h
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/7/3.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RoutePathHeaderViewDelegate <NSObject>

- (void)changeTableViewFrame;

@end

@interface RoutePathHeaderView : UIView

@property (nonatomic,strong)UIImageView *imageV;
@property (nonatomic,strong)UILabel *timeInfoLabel;
@property (nonatomic,strong)UILabel *taxiCostInfoLabel;
@property (nonatomic,strong)UIView *lineView;

@property (nonatomic,weak)id <RoutePathHeaderViewDelegate> delegate;

@end
