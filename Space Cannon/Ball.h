//
//  Ball.h
//  Space Cannon
//
//  Created by Abner Castro Aguilar on 15/01/15.
//  Copyright (c) 2015 Abner Castro Aguilar. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Ball : SKSpriteNode

@property (nonatomic) SKEmitterNode *trail;
@property (nonatomic)int bounces;

- (void)updateTrail;

@end
