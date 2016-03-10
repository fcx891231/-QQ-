//
//  FXLrcView.h
//  我的QQ音乐
//
//  Created by fanxi on 16/3/10.
//  Copyright © 2016年 fanxi. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FXLrcLabel;

@interface FXLrcView : UIScrollView

@property (nonatomic, copy) NSString *lrcName;

/** 当前播放的时间 */
@property (nonatomic, assign) NSTimeInterval currentTime;

/** 外面歌词的Label */
@property (nonatomic, weak) FXLrcLabel *lrcLabel;

/** 当前歌曲的总时长 */
@property (nonatomic, assign) NSTimeInterval duration;

@end
