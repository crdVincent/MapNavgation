//
//  SearchLocationView.m
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/6/29.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import "SearchLocationView.h"

@interface SearchLocationView ()

{
    UIButton *_selectBtn;
}

@end

@implementation SearchLocationView

- (instancetype)initWithFrame:(CGRect)frame
    {
        self = [super initWithFrame:frame];
        if (self) {
            self.backgroundColor = [UIColor whiteColor];
            [self creatViews];
        }
        return self;
    }
- (void)creatViews {

    _startLabel = ({
        UILabel *label = [[UILabel alloc]init];
        label.text = @"我的位置";
        label.textColor = LabelBaseColor;
        label.font = LabelFont;
        [self addSubview:label];
        label;
    });
    _lineView1 = ({
        UIView *view = [[UIView alloc]init];
        view.backgroundColor = SmallLabelColor;
        [self addSubview:view];
        view;
    });
    _endLabel = ({
        UILabel *label = [[UILabel alloc]init];
        label.text = @"终点位置";
        label.textColor = LabelBaseColor;
        label.font = LabelFont;
        [self addSubview:label];
        label;
    });
    _lineView2 = ({
        UIView *view = [[UIView alloc]init];
        view.backgroundColor = SmallLabelColor;
        [self addSubview:view];
        view;
    });
    _locationImageV = ({
        UIImageView *imageV = [[UIImageView alloc]init];
        imageV.image = [UIImage imageNamed:@"addressIcon"];
        [self addSubview:imageV];
        imageV;
    });
    _exchangeBtn = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setBackgroundColor:[UIColor redColor]];
        button.hidden = YES;
        [button setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(exchangeLoadClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        button;
    });
    [self setLayout];
    NSArray *selectArr = @[@"honggongjiaoche",@"hongqiche",@"hongwalkman",@"hongzixingche"];
    NSArray *normalArr = @[@"huigongjiaoche",@"huiqiche",@"huiwalkman",@"huizixingche"];
    CGFloat migint = (ScreenWidth-ScalePx(150))/5;
    for (int i = 0; i < normalArr.count; i ++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = 111+i;
        [button setImage:[[UIImage imageNamed:normalArr[i]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        [button setImage:[[UIImage imageNamed:selectArr[i]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateSelected];
        button.frame = CGRectMake(migint+i*(migint+ScalePx(50)), ScalePx(170), ScalePx(50), ScalePx(50));
        [button addTarget:self action:@selector(exchangeLoadStyle:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:button];
        
        if (!i) {//默认选中第一个
            _selectBtn = button;
            _selectBtn.selected = YES;
        }
    }
}
- (void)setLayout {

    _locationImageV.sd_layout.
    leftSpaceToView(self, ScalePx(20)).
    topSpaceToView(self, ScalePx(20)).
    widthIs(ScalePx(20)).
    heightIs(ScalePx(100));
    
    _startLabel.sd_layout.
    leftSpaceToView(_locationImageV, ScalePx(20)).
    topEqualToView(_locationImageV).
    rightSpaceToView(self, ScalePx(100)).
    heightIs(ScalePx(30));
    
    _lineView1.sd_layout.
    leftEqualToView(_startLabel).
    topSpaceToView(_startLabel, ScalePx(20)).
    rightSpaceToView(self, ScalePx(80)).
    heightIs(ScalePx(1));
    
    _endLabel.sd_layout.
    leftEqualToView(_startLabel).
    topSpaceToView(_lineView1, ScalePx(20)).
    rightSpaceToView(self, ScalePx(100)).
    heightIs(ScalePx(30));
    
    _lineView2.sd_layout.
    leftEqualToView(self).
    topSpaceToView(_endLabel, ScalePx(20)).
    rightEqualToView(self).
    heightIs(ScalePx(2));
    
    _exchangeBtn.sd_layout.
    leftSpaceToView(_lineView1, ScalePx(20)).
    topSpaceToView(self, ScalePx(30)).
    widthIs(ScalePx(40)).
    heightIs(ScalePx(90));
}
- (void)exchangeLoadClicked {
    NSLog(@"切换起始坐标和终点坐标");
}
- (void)exchangeLoadStyle:(UIButton *)btn {

    _selectBtn.selected = NO;
    _selectBtn = btn;
    _selectBtn.selected = YES;

    if (self.delegate && [self.delegate respondsToSelector:@selector(exchangeLoadStyleWithTag:)]) {
        [self.delegate exchangeLoadStyleWithTag:btn.tag-110];
    }
}
@end
