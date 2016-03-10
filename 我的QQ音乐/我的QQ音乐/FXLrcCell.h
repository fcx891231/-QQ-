//
//  FXLrcCell.h
//  我的QQ音乐
//
//  Created by fanxi on 16/3/10.
//  Copyright © 2016年 fanxi. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FXLrcLabel;

@interface FXLrcCell : UITableViewCell

@property (nonatomic, weak, readonly) FXLrcLabel *lrcLabel;

+ (instancetype)lrcCellWithTableView:(UITableView *)tableView;

@end
