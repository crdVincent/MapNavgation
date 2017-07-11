//
//  RoutePathHeaderView.m
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/7/3.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import "RoutePathHeaderView.h"

@implementation RoutePathHeaderView

- (void)changeFrame {
    if (self.delegate && [self.delegate respondsToSelector:@selector(changeTableViewFrame)]) {
        [self.delegate changeTableViewFrame];
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(changeFrame)];
        [self addGestureRecognizer:tap];
        [self setUpViews];
    }
    return self;
}
- (void)setUpViews {

    _imageV = ({
        UIImageView *imageView = [[UIImageView alloc]init];
        imageView.image = [UIImage imageNamed:@"sanjiaodown"];
        [self addSubview:imageView];
        imageView;
    });
    _imageV.sd_layout.
    leftSpaceToView(self, ScreenWidth/2-ScalePx(20)).
    topEqualToView(self).
    widthIs(ScalePx(40)).
    heightIs(ScalePx(20));
    

    _timeInfoLabel = ({
        UILabel *label = [[UILabel alloc]init];
        label.textColor = LabelBaseColor;
        label.font = LabelFont;
        label.numberOfLines = 2;
        [self addSubview:label];
        label;
    });
    _timeInfoLabel.sd_layout.
    leftSpaceToView(self, ScalePx(20)).
    topSpaceToView(self, ScalePx(20)).
    rightSpaceToView(self, ScalePx(20)).
    heightIs(ScalePx(70));
    
    _taxiCostInfoLabel = ({
        UILabel *label = [[UILabel alloc]init];
        label.textColor = [UIColor grayColor];
        label.font = BaseFont;
        [self addSubview:label];
        label;
    });
    _taxiCostInfoLabel.sd_layout.
    leftEqualToView(self.timeInfoLabel).
    bottomSpaceToView(self, ScalePx(20)).
    rightEqualToView(self.timeInfoLabel).
    heightIs(ScalePx(30));
    
    _lineView = ({
        UIView *view = [[UIView alloc]init];
        view.backgroundColor = BackColor;
        [self addSubview:view];
        view;
    });
    _lineView.sd_layout.
    leftEqualToView(self).
    rightEqualToView(self).
    bottomEqualToView(self).
    heightIs(2);
}

@end
