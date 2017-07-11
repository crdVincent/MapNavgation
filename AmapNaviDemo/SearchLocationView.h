//
//  SearchLocationView.h
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/6/29.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoadionViewDelagete <NSObject>

- (void)exchangeLoadStyleWithTag:(NSInteger)tag;

@end

@interface SearchLocationView : UIView
    
@property (nonatomic,strong)UILabel *startLabel;
@property (nonatomic,strong)UILabel *endLabel;
@property (nonatomic,strong)UIImageView *locationImageV;
@property (nonatomic,strong)UIButton *exchangeBtn;
@property (nonatomic,strong)UIView *lineView1;
@property (nonatomic,strong)UIView *lineView2;
    
@property (nonatomic,weak)id <LoadionViewDelagete> delegate;
    
@end
