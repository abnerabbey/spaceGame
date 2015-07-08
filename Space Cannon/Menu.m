//
//  Menu.m
//  Space Cannon
//
//  Created by Abner Castro Aguilar on 13/01/15.
//  Copyright (c) 2015 Abner Castro Aguilar. All rights reserved.
//

#import "Menu.h"

@implementation Menu
{
    SKLabelNode *scoreLabel;
    SKLabelNode *topScoreLabel;
    SKSpriteNode *title;
    SKSpriteNode *scoreBoard;
    SKSpriteNode *PlayButton;
    SKSpriteNode *musicButton;
    
}

- (id)init
{
    self = [super init];
    if(self)
    {
        /*title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        title.name = @"title";
        title.position = CGPointMake(0.0, 140.0);
        [self addChild:title];*/
        
        scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        scoreBoard.name = @"scoreboard";
        scoreBoard.position = CGPointMake(0.0, 70.0);
        [self addChild:scoreBoard];
        
        PlayButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        PlayButton.name = @"play";
        PlayButton.position = CGPointMake(0.0, 0.0);
        [self addChild:PlayButton];
        
        scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        scoreLabel.name = @"scoreLabel";
        scoreLabel.fontSize = 38;
        scoreLabel.position = CGPointMake(-52, -20);
        [scoreBoard addChild:scoreLabel];
        
        topScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        topScoreLabel.name = @"topScoreLabel";
        topScoreLabel.fontSize = 38;
        topScoreLabel.position = CGPointMake(48, -20);
        [scoreBoard addChild:topScoreLabel];
        
        musicButton = [SKSpriteNode spriteNodeWithImageNamed:@"MusicOnButton"];
        musicButton.name = @"musicButton";
        musicButton.position = CGPointMake(PlayButton.size.width/2 + 17, 1.5);
        [self addChild:musicButton];
        
        self.score = 0;
        self.topScore = 0;
        self.touchable = YES;
        self.musicOn = YES;
    }
    return self;
}

-(void)setScore:(int)score
{
    _score = score;
    scoreLabel.text = [[NSNumber numberWithInt:score] stringValue];
    
}

- (void)setTopScore:(int)topScore
{
    _topScore = topScore;
    topScoreLabel.text = [[NSNumber numberWithInt:topScore] stringValue];
}

- (void)setMusicOn:(BOOL)musicOn
{
    _musicOn = musicOn;
    if(musicOn)
        musicButton.texture = [SKTexture textureWithImageNamed:@"MusicOnButton"];
    else
        musicButton.texture = [SKTexture textureWithImageNamed:@"MusicOffButton"];
}

- (void)hide
{
    self.touchable = NO;
    
    SKAction *animateMenu = [SKAction scaleTo:0.0 duration:0.5];
    animateMenu.timingMode = SKActionTimingEaseIn;
    [self runAction:animateMenu completion:^{
        self.hidden = YES;
        self.xScale = 1.0;
        self.yScale = 1.0;
    }];
}

- (void)show
{
    self.touchable = YES;
    self.hidden = NO;
    title.position = CGPointMake(0.0, 200.0);
    title.alpha = 0.0;
    
    SKAction *animateTitle = [SKAction group:@[[SKAction moveToY:140.0 duration:0.5], [SKAction fadeInWithDuration:0.5]]];
    animateTitle.timingMode = SKActionTimingEaseOut;
    [title runAction:animateTitle];
    
    scoreBoard.xScale = 4.0;
    scoreBoard.yScale = 4.0;
    scoreBoard.alpha = 0.0;
    SKAction *animateScoreBoard = [SKAction group:@[[SKAction scaleTo:1.0 duration:0.5], [SKAction fadeInWithDuration:0.5]]];
    animateTitle.timingMode = SKActionTimingEaseOut;
    [scoreBoard runAction:animateScoreBoard];
    
    PlayButton.alpha = 0.0;
    SKAction *animatePlayButton = [SKAction fadeInWithDuration:2.0];
    animatePlayButton.timingMode = SKActionTimingEaseIn;
    [PlayButton runAction:animatePlayButton completion:^{
        PlayButton.hidden = NO;
    }];
    
    musicButton.alpha = 0.0;
    SKAction *animateMusicButton = [SKAction fadeInWithDuration:2.0];
    animateMusicButton.timingMode = SKActionTimingEaseIn;
    [musicButton runAction:animateMusicButton completion:^{
        musicButton.hidden = NO;
    }];
}

@end

















































