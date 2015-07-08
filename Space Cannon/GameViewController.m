//
//  GameViewController.m
//  Space Cannon
//
//  Created by Abner Castro Aguilar on 02/01/15.
//  Copyright (c) 2015 Abner Castro Aguilar. All rights reserved.
//

#import "GameViewController.h"
#import "GameScene.h"


@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    //skView.showsFPS = YES;
    //skView.showsNodeCount = YES;
    /* Sprite Kit applies additional optimizations to improve rendering performance */
    //skView.ignoresSiblingOrder = YES;
    
    // Create and configure the scene.
    GameScene *scene = [[GameScene alloc] initWithSize:self.view.frame.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
}

@end
