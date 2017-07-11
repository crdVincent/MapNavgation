//
//  SearchRoadFooterView.h
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/7/4.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SearchRoadFooterViewDelegate <NSObject>

- (void)exchangeToMapNavigation;

@end

@interface SearchRoadFooterView : UIView

@property (nonatomic,weak)id <SearchRoadFooterViewDelegate> delagate;

@end
