//
//  Ball.m
//  Space Cannon
//
//  Created by Abner Castro Aguilar on 15/01/15.
//  Copyright (c) 2015 Abner Castro Aguilar. All rights reserved.
//

#import "Ball.h"

@implementation Ball

- (void)updateTrail
{
    if(self.trail) {
        self.trail.position = self.position;
        
    }
}

- (void)removeFromParent
{
    if(self.trail) {
    self.trail.particleBirthRate = 0.0;
    SKAction *removeTrail = [SKAction sequence:@[[SKAction waitForDuration:self.trail.particleLifetime
                                                  + self.trail.particleLifetimeRange],
                                                 [SKAction removeFromParent]]];
    [self.trail runAction:removeTrail];
    }
[super removeFromParent];
}

@end







































































































































