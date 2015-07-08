//
//  GameScene.m
//  Space Cannon
//
//  Created by Abner Castro Aguilar on 02/01/15.
//  Copyright (c) 2015 Abner Castro Aguilar. All rights reserved.
//

#import "GameScene.h"
#import "Menu.h"
#import "Ball.h"
#import <AVFoundation/AVFoundation.h>

@implementation GameScene
{
    SKNode *mainLayer;
    SKSpriteNode *cannon;//The cannon that shoots the balls
    BOOL didShoot;
    
    SKSpriteNode *ammoDisplay;//The HUD that displays how much ammo we have
    SKLabelNode *scoreLabel; //The label that will display the user score
    
    //SKActions to hanlde the sounds in the game
    SKAction *bounceSound;
    SKAction *deepExplosionSound;
    SKAction *explosionSound;
    SKAction *laserSound;
    SKAction *zapSound;
    
    SKAction *shieldUpSound;
    
    //Menu
    Menu *menu;
    BOOL gameOver;
    
    NSUserDefaults *userDefaults;
    
    SKLabelNode *pointLabel;
    
    //We can increase performance of our games by initialising the objects we're going to need throughout a game prior to starting it
    NSMutableArray *shieldPool;
    
    int killCount;//Counter that goes counting (xD) the number of kills we make with a ball
    
    SKSpriteNode *pauseButton;
    SKSpriteNode *resumeButton;
    AVAudioPlayer *audioPlayer;
    
    
}

static const CGFloat SHOOT_SPEED = 1000.0f;

static const CGFloat kCCHaloLowAngle = 200.0 * M_PI / 180.0;
static const CGFloat kCCHaloHighAngle = 340.0 * M_PI / 180.0;
static const CGFloat kCCHaloSpeed = 100.0;

//BitMask categories
//This is to have an access to the collission and store categories at bit level
static const uint32_t kCCHaloCategory     =  0x1 << 0;
static const uint32_t kCCBulletCategory   =  0x1 << 1;
static const uint32_t kCCEdgeCategory     =  0x1 << 2;
static const uint32_t kCCShieldCategory   =  0x1 << 3;
static const uint32_t kCCLifeBarCategory  =  0x1 << 4;
static const uint32_t kCCShieldUpCategory  = 0x1 << 5;
static const uint32_t kCCMultiUpCategory   = 0x1 << 6;

//Value to access to the NSUserDefaults key
static NSString * const KCCKeyTopScore = @"TopScore";


#pragma mark Override Methods
- (id)initWithSize:(CGSize)size
{
    self = [super initWithSize:size];
    if(self)
    {
        //Turn off gravity
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        self.physicsWorld.contactDelegate = self;
        
        //Add background
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
        background.name = @"background";
        background.position = CGPointZero;
        background.anchorPoint = CGPointZero;
        background.blendMode = SKBlendModeReplace;
        [self addChild:background];
        
        //Add edges to the scene
        SKNode *leftEdge = [[SKNode alloc] init];
        leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100.0)];
        leftEdge.position = CGPointZero;
        leftEdge.physicsBody.categoryBitMask = kCCEdgeCategory;
        [self addChild:leftEdge];
        
        SKNode *rightEdge = [[SKNode alloc] init];
        rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height + 100.0)];
        rightEdge.position = CGPointMake(self.size.width, 0.0);
        rightEdge.physicsBody.categoryBitMask = kCCEdgeCategory;
        [self addChild:rightEdge];
        
        //Add layer
        mainLayer = [[SKNode alloc] init];
        [self addChild:mainLayer];
        
        //Add cannon
        cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
        cannon.name = @"cannon";
        cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
        [self addChild:cannon];
        
        //Create rotation actions
        SKAction *rotate = [SKAction rotateByAngle:M_PI duration:2.0];
        SKAction *rotateBack = [SKAction rotateByAngle:-M_PI duration:2.0];
        NSArray *sequence = [NSArray arrayWithObjects:rotate,rotateBack, nil];
        [cannon runAction:[SKAction repeatActionForever:[SKAction sequence:sequence]]];
        
        //Create spawn halo actions
        SKAction *waitAction = [SKAction waitForDuration:2.0 withRange:1.0];
        SKAction *createHalo = [SKAction performSelector:@selector(spawnHalo) onTarget:self];
        NSArray *spawnSequence = [NSArray arrayWithObjects:waitAction, createHalo, nil];
        SKAction *spawnHalo = [SKAction sequence:spawnSequence];
        SKAction *spawnHaloForever = [SKAction repeatActionForever:spawnHalo];
        //we see how we use the speed property of an action to modify how fast it runs. We set the speed of our action that spawns our halos so that the game gets harder the longer the player survives.
        [self runAction:spawnHaloForever withKey:@"SpawnHalo"];
        
        //Create shield power up!!
        SKAction *spawnShieldPowerUp = [SKAction sequence:@[[SKAction waitForDuration:15 withRange:4], [SKAction performSelector:@selector(spawnShieldPowerUp) onTarget:self]]];
        [self runAction:[SKAction repeatActionForever:spawnShieldPowerUp]];
        
        //Set up ammo
        ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
        ammoDisplay.name = @"ammoDisplay";
        ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
        ammoDisplay.position = cannon.position;
        [self addChild:ammoDisplay];
        
        //Actions to increment ammo (because tit decrements itself when the user shots
        SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1.0], [SKAction runBlock:^{
            if(!self.multiMode){
                self.ammo++;
            }
            
        }]]];
        [self runAction:[SKAction repeatActionForever:incrementAmmo]];
        
        //Setup shield pool
        shieldPool = [[NSMutableArray alloc] init];
        
        //Set up shields. We'll add 6 of these
        for(int i = 0; i < 6; i++)
        {
            SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
            shield.name = @"shield";
            shield.position = CGPointMake(35.0 + (50.0 * i), 90.0);
            shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(shield.size.width, shield.size.height)];
            shield.physicsBody.categoryBitMask = kCCShieldCategory;
            shield.physicsBody.collisionBitMask = 0; //It is not neccessary to collide with the other objects. Just notify when have contact with halo
            
            //Intead of setting these on the main layer. We put them in the pool
            [shieldPool addObject:shield];
        }
        
        //Setup pause button
        pauseButton = [SKSpriteNode spriteNodeWithImageNamed:@"PauseButton"];
        pauseButton.position = CGPointMake(self.size.width - 30, 20);
        [self addChild:pauseButton];
        pauseButton.hidden = YES;
        
        //Setup resume button
        resumeButton = [SKSpriteNode spriteNodeWithImageNamed:@"ResumeButton"];
        resumeButton.position = CGPointMake(self.size.width/2, self.size.height/2);
        resumeButton.hidden = YES;
        [self addChild:resumeButton];
        
        //Set up score label
        scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        scoreLabel.position = CGPointMake(15, 10);
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        scoreLabel.fontSize = 15;
        [self addChild:scoreLabel];
        
        //Setup multiplier label
        pointLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        pointLabel.position = CGPointMake(15, 30);
        pointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        pointLabel.fontSize = 15;
        [self addChild:pointLabel];
        
        //Setup sounds
        bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
        explosionSound = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
        deepExplosionSound = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
        laserSound = [SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO];
        zapSound = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
        shieldUpSound = [SKAction playSoundFileNamed:@"ShieldUp.caf" waitForCompletion:NO];
        
        //Setup Menu
        menu = [[Menu alloc] init];
        menu.position = CGPointMake(self.size.width/2, self.size.height - 220);
        [self addChild:menu];
        
        //Set initial values
        gameOver = YES;
        self.ammo = 5;
        self.score = 0;
        scoreLabel.hidden = YES;
        pointLabel.hidden = YES;
        
        //Load top score
        userDefaults = [NSUserDefaults standardUserDefaults];
        menu.topScore =  (int)[userDefaults integerForKey:KCCKeyTopScore];
        
        self.pointValue = 1;
        killCount = 0;
        
        //Load music
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"ObservingTheStar" withExtension:@"caf"];
        NSError *error;
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        if(!audioPlayer){
            NSLog(@"Error loading audio player: %@", error);
        }
        else{
            audioPlayer.numberOfLoops = -1;
            audioPlayer.volume = 0.3;
            [audioPlayer play];
        }
        
        
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *touch in touches)
    {
        if(!gameOver && !self.gamePaused){
            if(![pauseButton containsPoint:[touch locationInNode:pauseButton.parent]]){
                didShoot = YES;
            }
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        if(gameOver && menu.touchable)
        {
            SKNode *n = [menu nodeAtPoint:[touch locationInNode:menu]];
            if([n.name isEqualToString:@"play"]){
                [self newGame];
            }
            if([n.name isEqualToString:@"musicButton"]){
                if(menu.musicOn){
                    menu.musicOn = NO;
                    [audioPlayer stop];
                }
                else{
                    menu.musicOn = YES;
                    [audioPlayer play];
                }
            }
        }
        else if(!gameOver)
        {
            if(self.gamePaused){
                if([resumeButton containsPoint:[touch locationInNode:resumeButton.parent]]){
                    self.gamePaused = NO;
                }
            }
            else{
                if([pauseButton containsPoint:[touch locationInNode:pauseButton.parent]]){
                    self.gamePaused = YES;
                }
            }
        }
    }
}

- (void)didSimulatePhysics
{
    if(didShoot){
        if(self.ammo > 0){
            self.ammo--;
            [self shoot];
            
            if(self.multiMode){
                for(int i = 1; i < 5; i++){
                    [self performSelector:@selector(shoot) withObject:nil afterDelay:0.1 * i];
                }
                if(self.ammo == 0){
                    self.multiMode = 0;
                    self.ammo = 5;
                }
            }
        }
        didShoot = NO;
    }
    
    [mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        //Now we have to update the ball trail created in our new ball class
        if([node respondsToSelector:@selector(updateTrail)])
            [node performSelector:@selector(updateTrail) withObject:nil];
        
        if(!CGRectContainsPoint(self.frame, node.position)){
            self.pointValue = 1;
            [node removeFromParent];
        }
    }];
    //we clean up halos that drop below the bottom of the screen
    [mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        if(node.position.y + node.frame.size.height < 0)
            [node removeFromParent];
    }];
    
    //Now when the shields leaves the screen we just remove them from parent
    [mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        if(node.position.x + node.frame.size.width < 0){
            [node removeFromParent];
        }
    }];
    
    //Now we remove the multiup when they leave the screen
    [mainLayer enumerateChildNodesWithName:@"multiUp" usingBlock:^(SKNode *node, BOOL *stop) {
        if(node.position.x - node.frame.size.width > self.size.width){
            [node removeFromParent];
        }
    }];
}

- (void)setPointValue:(int)pointValue
{
    _pointValue = pointValue;
    pointLabel.text = [NSString stringWithFormat:@"Point: x%d", pointValue];
}

#pragma mark Methods Created
- (void)shoot
{
        
    Ball *ball = [Ball spriteNodeWithImageNamed:@"Ball"];
    ball.name = @"ball";
    CGVector rotationVector = radiansToVector(cannon.zRotation);
    ball.position = CGPointMake(cannon.position.x + (cannon.size.width * 0.5 * rotationVector.dx), cannon.position.y + (cannon.size.width * 0.5 * rotationVector.dy));
    //This adds physics body to the sprite. It means, it has now physics properties
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
    //The velocity of the sprite when it appears on the scene
    ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
    //How much energy the phicis body loses when it bounces off another object.
    ball.physicsBody.restitution = 1.0;
    //this reduces body's rotational velocity. This property is used to simulate fluid or air friction forces on the body
    ball.physicsBody.linearDamping = 0.0;
    //The friction applied on the sprite whe it is contact with another body
    ball.physicsBody.friction = 0.0;
    
    ball.physicsBody.categoryBitMask = kCCBulletCategory;
    //This property is to define which is the body who will react the ball when collide. Only with the edges. When collide with the halos, it will not affect his movement.
    ball.physicsBody.collisionBitMask = kCCEdgeCategory;
    
    ball.physicsBody.contactTestBitMask = kCCEdgeCategory | kCCShieldUpCategory | kCCMultiUpCategory;
    [mainLayer addChild:ball];
    
    [self runAction:laserSound];
    
    //Create ball trail
    NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"RailTrail" ofType:@"sks"];
    SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
    ballTrail.targetNode = mainLayer;//The node where the emitter node will emitte particles
    [mainLayer addChild:ballTrail];
    ball.trail = ballTrail; //New trail
    [ball updateTrail];
}

- (void)spawnHalo
{
    //we see how we use the speed property of an action to modify how fast it runs. We set the speed of our action that spawns our halos so that the game gets harder the longer the player survives.
    //Increase spawn speed
    //We retreive the action stored with this key so we can know all bout this action with her key
    SKAction *spawnHaloAction = [self actionForKey:@"SpawnHalo"];
    if(spawnHaloAction.speed < 1.5)
        spawnHaloAction.speed = spawnHaloAction.speed + 0.01;
    
    //Create Halo
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.name = @"halo";
    halo.position = CGPointMake(randomInRange(halo.size.width / 2, self.size.width - (halo.size.width / 2)), self.size.height + halo
                                .size.height/2);
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:halo.size.height/2];
    
    //We create a vector directon in the rectangle scene with random numbers
    CGVector direction = radiansToVector(randomInRange(kCCHaloLowAngle, kCCHaloHighAngle));
    halo.physicsBody.velocity = CGVectorMake(direction.dx * kCCHaloSpeed, direction.dy *kCCHaloSpeed);
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    
    halo.physicsBody.categoryBitMask = kCCHaloCategory;
    //This property is to define which is the body who will react the ball when collide. Only with the edges. When collide with the balls, it will not affect his movement.
    halo.physicsBody.collisionBitMask = kCCEdgeCategory;
    //This is to notify with a delegate the collision with the body specified. In this case, halos with balls
    //Also, we need to know when halos make contact with the shield. So we add an OR
    //Also, we nee to know the halos make contact with the life bar, So we add an OR
    halo.physicsBody.contactTestBitMask = kCCBulletCategory | kCCShieldCategory | kCCLifeBarCategory | kCCEdgeCategory;
    
    //Now we create a bomb halo. A bomb halo appears when there are 4 halos on screen. So, the bomb halo is the 5th.
    int haloCount = 0;
    for (SKNode *node in [mainLayer children])
    {
        if([node.name isEqualToString:@"halo"])
            haloCount++;
    }
    if(haloCount == 4){
        halo.texture = [SKTexture textureWithImageNamed:@"HaloBomb"];
        halo.userData = [[NSMutableDictionary alloc] init];
        [halo.userData setValue:@YES forKey:@"BomB"];
    }
     //Random point multiplier
    else if(!gameOver && arc4random_uniform(6) == 0){
        halo.texture = [SKTexture textureWithImageNamed:@"HaloX"];
        halo.userData = [[NSMutableDictionary alloc] init];//We take advantage of this property to handle the multiplier so we don't have to do another bitmask
        [halo.userData setValue:@YES forKey:@"Multiplier"];
    }
    
    
    [mainLayer addChild:halo];
    
}

- (void)addExplosion:(CGPoint)position withName:(NSString *)name
{
    NSString *explosionPath = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    
    /*//Create SKEmitterNode manually
    SKEmitterNode *explosion = [SKEmitterNode node];
    explosion.particleTexture = [SKTexture textureWithImageNamed:@"spark"];
    explosion.particleLifetime = 1.0;
    explosion.particleBirthRate = 2000.0;
    explosion.numParticlesToEmit = 100;
    explosion.emissionAngleRange = 360.0;
    explosion.particleScale = 0.2;
    explosion.particleScaleSpeed = -0.2;
    explosion.particleSpeed = 200.0;*/
    
    explosion.position = position;
    [mainLayer addChild:explosion];
    
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5], [SKAction removeFromParent]]];
    [explosion runAction:removeExplosion];
    
}

//Whenever the ammo changes, we have to change the ammo display to notify the user about his ammo.
- (void)setAmmo:(int)ammo
{
    if (ammo >= 0 && ammo <= 5) {
        _ammo = ammo;
        ammoDisplay.texture = [SKTexture textureWithImageNamed:[NSString stringWithFormat:@"Ammo%d", ammo]];
    }
}

- (void)setScore:(int)score
{
    _score = score;
    scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
}

- (void)setMultiMode:(BOOL)multiMode
{
    _multiMode = multiMode;
    if(multiMode)
        cannon.texture = [SKTexture textureWithImageNamed:@"GreenCannon"];
    else
        cannon.texture = [SKTexture textureWithImageNamed:@"Cannon"];
}

- (void)setGamePaused:(BOOL)gamePaused
{
    if(!gameOver){
        _gamePaused = gamePaused;
        pauseButton.hidden = gamePaused;
        resumeButton.hidden = !gamePaused;
        self.paused = gamePaused;
    }
    
}

//Game Over!!!!
-(void)gameOver
{
    scoreLabel.hidden = YES;
    pointLabel.hidden = YES;
    pauseButton.hidden = YES;
    
    [mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    [mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    [mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [shieldPool addObject:node];
        [node removeFromParent];
    }];
    
    [mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    [mainLayer enumerateChildNodesWithName:@"multiUp" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    menu.score = self.score;
    if(self.score > menu.topScore){
        [userDefaults setInteger:self.score forKey:KCCKeyTopScore];
        [userDefaults synchronize];
        menu.topScore = self.score;
    }
    gameOver = YES;
    [self runAction:[SKAction waitForDuration:1.0] completion:^{
        [menu show];
    }];
}

- (void)newGame
{
    
    [mainLayer removeAllChildren];
    
    //Doing this we put the dhields in the main layer and remove them form the array (shield pool)
    while (shieldPool.count > 0) {
        [mainLayer addChild:[shieldPool objectAtIndex:0]];
        [shieldPool removeObjectAtIndex:0];
    }
    
    //Set up life bar
    SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    lifeBar.position = CGPointMake(self.size.width / 2, 70.0);
    lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width, 0.0) toPoint:CGPointMake(lifeBar.size.width, 0.0)];
    lifeBar.physicsBody.categoryBitMask = kCCLifeBarCategory;
    [mainLayer addChild:lifeBar];
    
    //Set initial values
    //we see how we use the speed property of an action to modify how fast it runs. We set the speed of our action that spawns our halos so that the game gets harder the longer the player survives.
    [self actionForKey:@"SpawnHalo"].speed = 1.0;
    
    self.pointValue = 1;
    
    self.ammo = 5;
    self.score = 0;
    scoreLabel.hidden = NO;
    [menu hide];
    gameOver = NO;
    
    pointLabel.hidden = NO;
    
    killCount = 0;
    
    self.multiMode = NO;
    
    pauseButton.hidden = NO;
    
    
}

- (void)spawnShieldPowerUp
{
    if(shieldPool.count > 0){
        SKSpriteNode *shieldUp = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shieldUp.name = @"shieldUp";
        shieldUp.position = CGPointMake(self.size.width + shieldUp.size.width, randomInRange(150, self.size.height - 100));
        shieldUp.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(shieldUp.size.width, shieldUp.size.height)];
        shieldUp.physicsBody.categoryBitMask = kCCShieldUpCategory;
        shieldUp.physicsBody.collisionBitMask = 0; //It is not neccessary to collide with the other objects. Just notify when have contact with halo
        shieldUp.physicsBody.velocity = CGVectorMake(-100, randomInRange(-40, 40));
        shieldUp.physicsBody.angularVelocity = M_PI;
        shieldUp.physicsBody.linearDamping = 0.0;
        shieldUp.physicsBody.angularDamping = 0.0;
        [mainLayer addChild:shieldUp];
    }
}

- (void)spawnMultiShotPowerUp
{
    SKSpriteNode *multiUp = [SKSpriteNode spriteNodeWithImageNamed:@"MultiShotPowerUp"];
    multiUp.name = @"multiUp";
    multiUp.position = CGPointMake(-multiUp.size.width, randomInRange(150, self.size.height - 100));
    multiUp.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:multiUp.frame.size.width/2];
    multiUp.physicsBody.categoryBitMask = kCCMultiUpCategory;
    multiUp.physicsBody.collisionBitMask = 0;
    multiUp.physicsBody.velocity = CGVectorMake(100.0, randomInRange(-40, 40));
    multiUp.physicsBody.angularVelocity = M_PI;
    multiUp.physicsBody.linearDamping = 0.0;
    multiUp.physicsBody.angularDamping = 0.0;
    [mainLayer addChild:multiUp];
    
}

#pragma mark Contact Delegate
- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    if(contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask){
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    //Collision halo vs ball (notification with visual effects and other implementations
    if(firstBody.categoryBitMask == kCCHaloCategory && secondBody.categoryBitMask == kCCBulletCategory)
    {
        self.score = self.score + self.pointValue;
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        
        //Add a sound effect is easy. We just have to add the caf file as an SKAction to run run it
        [self runAction:explosionSound];
        
        //increment the killer count
        killCount++;
        if(killCount % 10 == 0){
            [self spawnMultiShotPowerUp];
        }
        
        //Now we handle the moment when we have a halo multiplier
        if([[firstBody.node.userData valueForKey:@"Multiplier"] boolValue]){
            self.pointValue++;
        }
        //Now, when we collide with a bomb halo we explote the other halos on the screen and remove them
        else if([[firstBody.node.userData valueForKey:@"BomB"] boolValue]){
            //Doing this, we avoid to set to explosions with the halo that has previously exploted
            firstBody.node.name = nil;
            [mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
                [self addExplosion:node.position withName:@"HaloExplosion"];
                [node removeFromParent];
            }];
        }
        
        [[firstBody node] removeFromParent];
        [[secondBody node] removeFromParent];
    }
    //Collision halo vs shields with explosion and removing of the shields
    if(firstBody.categoryBitMask == kCCHaloCategory && secondBody.categoryBitMask == kCCShieldCategory)
    {
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        
        //Add a sound effect is easy. We just have to add the caf file as an SKAction to run run it
        [self runAction:explosionSound];
        
        //Here, when the bomb halo collides with one shield, then all of them disappers
        if([[firstBody.node.userData valueForKey:@"BomB"] boolValue]){
            [mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
                [shieldPool addObject:node];
                [node removeFromParent];
            }];
        }
        else
            [shieldPool addObject:secondBody.node];
        
        //We also prevent halos from destroying more than one shield by setting their categoryBitMask property when a contact occurs
        firstBody.categoryBitMask = 0;
        [[firstBody node] removeFromParent];
        
        [[secondBody node] removeFromParent];
    }
    //Collision between halo and life bar
    if(firstBody.categoryBitMask == kCCHaloCategory && secondBody.categoryBitMask == kCCLifeBarCategory)
    {
        [self addExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self addExplosion:firstBody.node.position withName:@"LifeBarExplosion"];
        
        //Adding the deep explosion
        [self runAction:deepExplosionSound];
        
        [[firstBody node] removeFromParent];
        [[secondBody node] removeFromParent];
        [self gameOver];
    }
    //Collision between ball and edge
    if(firstBody.categoryBitMask == kCCBulletCategory && secondBody.categoryBitMask == kCCEdgeCategory)
    {
        //Here, we implement the limit bouncing
        if([firstBody.node isKindOfClass:[Ball class]]){
            ((Ball *)firstBody.node).bounces++;
            if(((Ball *)firstBody.node).bounces > 3){
                [firstBody.node removeFromParent];
                self.pointValue = 1;
            }
        }
        [self addExplosion:contact.contactPoint withName:@"BounceExplosion"];
        [self runAction:bounceSound];
    }
    //Collision between halo vs edge
    if(firstBody.categoryBitMask == kCCHaloCategory && secondBody.categoryBitMask == kCCEdgeCategory)
        [self runAction:zapSound];
    
    //Collision ball vs shieldUp
    if(firstBody.categoryBitMask == kCCBulletCategory && secondBody.categoryBitMask == kCCShieldUpCategory){
        if(shieldPool.count > 0){
            int randomIndex = arc4random_uniform((int)shieldPool.count);
            [mainLayer addChild:[shieldPool objectAtIndex:randomIndex]];
            [shieldPool removeObjectAtIndex:randomIndex];
            [self runAction:shieldUpSound];
        }
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    //Collision multiUp vs ball
    if(firstBody.categoryBitMask == kCCBulletCategory && secondBody.categoryBitMask == kCCMultiUpCategory){
        self.multiMode = YES;
        [self runAction:shieldUpSound];
        self.ammo = 5;
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
}

#pragma mark Special Methods

static inline CGVector radiansToVector(CGFloat radians)
{
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

//This method is to generate a random number so we can get a scalar that we can multily by the directon vector
//
static inline CGFloat randomInRange(CGFloat low, CGFloat high)
{
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
    return value * (high - low) + low;
}

@end












































































































































