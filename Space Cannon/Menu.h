//
//  Menu.h
//  Space Cannon
//
//  Created by Abner Castro Aguilar on 13/01/15.
//  Copyright (c) 2015 Abner Castro Aguilar. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Menu : SKNode

@property (nonatomic)int score;
@property (nonatomic)int topScore;
@property (nonatomic)BOOL touchable;
@property (nonatomic)BOOL musicOn;

- (void)hide;
- (void)show;


@end
