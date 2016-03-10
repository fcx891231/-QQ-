//
//  FXMusicTool.h
//  QQMusic
//
//  Created by xiaomage on 15/8/15.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FXMusic;

@interface FXMusicTool : NSObject

+ (NSArray *)musics;

+ (FXMusic *)playingMusic;

+ (void)setPlayingMusic:(FXMusic *)playingMusic;

+ (FXMusic *)nextMusic;

+ (FXMusic *)previousMusic;

@end
