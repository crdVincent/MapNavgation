//
//  SearchRoadFooterView.m
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/7/4.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import "SearchRoadFooterView.h"

@interface SearchRoadFooterView ()

@property (nonatomic,strong)UIButton *mapBtn;

@end

@implementation SearchRoadFooterView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self creatViews];
    }
    return self;
}
- (void)creatViews {

    _mapBtn = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor whiteColor];
        [button setTitle:@"使用本机地图导航" forState:UIControlStateNormal];
        button.titleLabel.font = LabelFont;
        [button setTitleColor:LabelBaseColor forState:UIControlStateNormal];
        [button addTarget:self action:@selector(exchangeToNativeMap) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        button;
    });

    _mapBtn.sd_layout.
    leftSpaceToView(self, ScreenWidth/4).
    topSpaceToView(self, ScalePx(20)).
    rightSpaceToView(self, ScreenWidth/4).
    heightIs(ScalePx(80));
}
- (void)exchangeToNativeMap {
    if (self.delagate && [self.delagate respondsToSelector:@selector(exchangeToMapNavigation)]) {
        [self.delagate exchangeToMapNavigation];
    }
}

@end
