//
//  GameScene.h
//  Space Cannon
//

//  Copyright (c) 2015 Abner Castro Aguilar. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameScene : SKScene <SKPhysicsContactDelegate> //In colaboration with contactBitMask property in SKPhysicsBody and SKPhysicsWorld

@property (nonatomic)int ammo;

@property (nonatomic)int score;

@property (nonatomic)int pointValue;

@property (nonatomic)BOOL multiMode;

@property (nonatomic)BOOL gamePaused;

@end
