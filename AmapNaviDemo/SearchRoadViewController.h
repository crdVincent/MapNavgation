//
//  SearchRoadViewController.h
//  AmapNaviDemo
//
//  Created by 陈瑞 on 2017/6/28.
//  Copyright © 2017年 陈瑞. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchRoadViewController : UIViewController
    
@property (nonatomic,assign) float startLatitude;
@property (nonatomic,assign) float destinationLatitude;
@property (nonatomic,assign) float startLongitude;
@property (nonatomic,assign) float destinationLongitude;

@property (nonatomic,strong)NSString *cityName;

@end
