//
//  InfinityGameScene.m
//  GasGuzzler
//
//  Created by Raymond kennedy on 5/5/14.
//  Copyright (c) 2014 Raymond kennedy. All rights reserved.
//

#import "InfinityGameScene.h"
#import "SKSpriteButton.h"
#import "NSDate+Utils.h"
#import "MenuScene.h"
#import "UIColor+Extensions.h"

@interface InfinityGameScene () <SKSpriteButtonDelegate>

@property (nonatomic, strong) SKLabelNode *gameTimeLabel;
@property (nonatomic, strong) NSTimer *gameTimer;
@property (nonatomic, strong) NSDate *startTime;

@property (nonatomic) NSInteger secondsElapsed;
@property (nonatomic) NSInteger lastSecondHit;
@property (nonatomic) BOOL isOpenForHit;
@property (nonatomic) BOOL hasHitForSecond;

@property (nonatomic, strong) SKSpriteButton *tapButton;
@property (nonatomic, strong) SKSpriteButton *beginButton;
@property (nonatomic, strong) SKSpriteButton *backButton;


// Value in milliseconds
@property (nonatomic) NSInteger timeThreshold;

@end

@implementation InfinityGameScene

typedef enum gameEndings {
    kSkippedSecond,
    kMissedHit
} GameEnder;

static const NSInteger TIME_THRESHOLD = 100;

static const NSInteger TIMER_FONT_SIZE = 75;
static const NSInteger MILLISECONDS_IN_SECOND = 1000;
static const NSInteger TAP_BUTTON_HEIGHT = 15;

/*
 * Initialize the scene
 */
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        // Set the background color to white
        self.backgroundColor = [UIColor whiteColor];
        
        // Setup the timer label and count down label and the button
        [self setupGameTimeLabel];
        [self setupTapButton];
        [self setupBeginButton];
        [self setupBackButton];
        
        // Hide the tap button @ start
        [self.tapButton setHidden:NO];
        [self.beginButton setHidden:NO];
        
        // Set the time buffer to 100 milliseconds for now
        self.timeThreshold = TIME_THRESHOLD;
        
    }
    
    return self;
}

/*
 * Swaps the z-index of the tap button and begin button
 */
- (void)swapZs:(SKSpriteNode *)sprite1 withSprite:(SKSpriteNode *)sprite2
{
    int zIndex2 = sprite2.zPosition;
    sprite2.zPosition = sprite1.zPosition;
    sprite1.zPosition = zIndex2;
}

/*
 * Setup the timer label
 */
- (void)setupGameTimeLabel
{
    self.gameTimeLabel = [SKLabelNode labelNodeWithFontNamed:@"AmericanCaptain"];
    self.gameTimeLabel.text = @"00.00.00";
    self.gameTimeLabel.fontSize = TIMER_FONT_SIZE;
    CGSize textSize = [[self.gameTimeLabel text] sizeWithAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"AmericanCaptain" size:TIMER_FONT_SIZE]}];
    CGFloat strikeWidth = textSize.width;
    self.gameTimeLabel.position = CGPointMake(CGRectGetMidX(self.frame) - strikeWidth/2, CGRectGetMidY(self.frame));
    [self.gameTimeLabel setHorizontalAlignmentMode:SKLabelHorizontalAlignmentModeLeft];
    [self.gameTimeLabel setFontColor:[UIColor blackColor]];
    [self addChild:self.gameTimeLabel];
}

/*
 * Setup the tap button
 */
- (void)setupTapButton
{
    self.tapButton = [SKSpriteButton spriteButtonWithUpImage:@"tapButton" downImage:@"tapButtonPressed" disabledImage:nil buttonMode:kTouchDownInside];
    [self.tapButton setDelegate:self];
    NSInteger buttonHeight = [self.tapButton getHeight];
    [self.tapButton setPosition:CGPointMake(CGRectGetMidX(self.frame), TAP_BUTTON_HEIGHT + (buttonHeight/2))];
    [self.tapButton setEnabled:YES];
    [self.tapButton setName:@"tapButton"];
    [self.tapButton setZPosition:4.0f];
    [self addChild:self.tapButton];
}

/*
 * Sets up the begin button / (tap button)
 */
- (void)setupBeginButton
{
    self.beginButton = [SKSpriteButton spriteButtonWithUpImage:@"beginButton" downImage:@"beginButtonPressed" disabledImage:nil buttonMode:kTouchUpInside];
    [self.beginButton setDelegate:self];
    NSInteger buttonHeight = [self.beginButton getHeight];
    [self.beginButton setPosition:CGPointMake(CGRectGetMidX(self.frame), TAP_BUTTON_HEIGHT + (buttonHeight/2))];
    [self.beginButton setEnabled:YES];
    [self.beginButton setName:@"beginButton"];
    [self.beginButton setZPosition:5.0f];
    [self addChild:self.beginButton];
}

/*
 * Add the back button
 */
- (void)setupBackButton
{
    self.backButton = [SKSpriteButton spriteButtonWithUpImage:@"backButton" downImage:@"backButtonPressed" disabledImage:nil buttonMode:kTouchUpInside];
    [self.backButton setDelegate:self];
    [self.backButton setPosition:CGPointMake(self.tapButton.frame.size.width + 50, self.frame.size.height - (self.tapButton.frame.size.height/2) - 60) ];
    [self.backButton setEnabled:YES];
    [self.backButton setName:@"backButton"];
    
    [self addChild:self.backButton];
}

/*
 * Start the game
 */
- (void)startGame
{
    self.startTime = [NSDate date];
    self.secondsElapsed = 0;
    self.lastSecondHit = 0;
    self.isOpenForHit = NO;
    self.hasHitForSecond = NO;
    
    // change the font color
    [self.gameTimeLabel setFontColor:[UIColor blackColor]];
    
    // Unhide the tap button
    [self.tapButton setHidden:NO];
    [self.beginButton setHidden:YES];
    [self swapZs:self.tapButton withSprite:self.beginButton];
    
    self.gameTimer = [NSTimer timerWithTimeInterval:0.01 target:self selector:@selector(updateGameTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.gameTimer forMode:NSDefaultRunLoopMode];
    [self.gameTimer fire];
}

/*
 * Updates the timer displayed on the screen
 */
- (void)updateGameTimer:(NSTimer *)timer {
    
    // Get the current time on the timer
    NSDate *currentTime = [NSDate date];
    NSTimeInterval timeInterval = [currentTime timeIntervalSinceDate:self.startTime];
    NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    
    NSString *timeString = [timerDate getTimerString];
    NSInteger currentMilliseconds = [[timeString substringFromIndex:[timeString length] - 2] integerValue];
    currentMilliseconds *= 10;
    
    [self.gameTimeLabel setText:timeString];
    
    // Set the elapsed seconds
    if (self.secondsElapsed != (int)timeInterval) {
        self.secondsElapsed = (int)timeInterval;
    }
    
    if (self.secondsElapsed == 0 && (currentMilliseconds >= MILLISECONDS_IN_SECOND - self.timeThreshold)) {
        self.isOpenForHit = YES;
    } else if ((currentMilliseconds >= MILLISECONDS_IN_SECOND - self.timeThreshold) || (currentMilliseconds <= self.timeThreshold)) {
        self.isOpenForHit = YES;
    } else {
        self.isOpenForHit = NO;
        if (self.secondsElapsed - 1 >= self.lastSecondHit) {
            [self triggerGameEndFrom:kSkippedSecond];
        }
    }
    
}

/*
 * Trigger game end
 */
- (void)triggerGameEndFrom:(GameEnder)reason
{
    [self.gameTimer invalidate];
    [self.gameTimeLabel setFontColor:[UIColor gameEndingRed]];
    [self.beginButton setHidden:NO];
    [self.tapButton setHidden:YES];
    [self swapZs:self.tapButton withSprite:self.beginButton];
    

    
    if (reason == kMissedHit) {
        
    } else if (reason == kSkippedSecond) {
        
    }
    
    
    NSLog(@"GAME OVER");
}

/*
 * Register Tap Button hit
 */
- (void)registerTapButtonHit
{
    NSString *hitTimeString = [self.gameTimeLabel text];

    NSInteger currentMilliseconds = [[hitTimeString substringFromIndex:[hitTimeString length] - 2] integerValue];
    NSInteger currentSecond = [[[hitTimeString substringFromIndex:3] substringToIndex:2] integerValue];
    NSInteger currentMinute = [[[hitTimeString substringFromIndex:0] substringToIndex:2] integerValue];
    NSInteger totalSeconds = (currentMinute * 60) + currentSecond;
    currentMilliseconds *= 10;
    
    // Find the hit color for the floaty text
    UIColor *hitColor;
    hitColor = [UIColor colorWithRed:0.91 green:0.3 blue:0.24 alpha:1];
    
    // From 900--0 or 0-100
    if (self.isOpenForHit) {
        
        if (currentMilliseconds == 0) {
            
            self.lastSecondHit = totalSeconds;
            NSLog(@"Perfect Hit at %d millisecond(s)!", (int)currentMilliseconds);
        } else if (currentMilliseconds >= MILLISECONDS_IN_SECOND - self.timeThreshold) {
            
            self.lastSecondHit = totalSeconds + 1;
            NSLog(@"Under Hit at %d millisecond(s)!", (int)currentMilliseconds);
        } else {
            
            self.lastSecondHit = totalSeconds;
            NSLog(@"Over Hit at %d millisecond(s)!", (int)currentMilliseconds);
        }
        
        hitColor = [UIColor colorWithRed:0.18 green:0.8 blue:0.44 alpha:1];
        self.hasHitForSecond = YES;
    } else {
        [self triggerGameEndFrom:kMissedHit];
        return;
    }
    
    
    // Spawn a sprite of the time
    SKLabelNode *hitTimeLabel = [SKLabelNode labelNodeWithFontNamed:@"AmericanCaptain"];
    hitTimeLabel.text = hitTimeString;
    hitTimeLabel.fontSize = TIMER_FONT_SIZE;
    hitTimeLabel.position = CGPointMake(CGRectGetMidX(self.frame) - 115, CGRectGetMidY(self.frame) + 50);
    [hitTimeLabel setHorizontalAlignmentMode:SKLabelHorizontalAlignmentModeLeft];
    [hitTimeLabel setFontColor:hitColor];
    [hitTimeLabel setZPosition:-1];
    [self addChild:hitTimeLabel];
    
    SKAction *fadeOut = [SKAction fadeOutWithDuration:1.3f];
    SKAction *moveUp = [SKAction moveByX:0.0f y:150.0f duration:1.3f];
    SKAction *tween = [SKAction group:[NSArray arrayWithObjects:fadeOut, moveUp, nil]];
    [hitTimeLabel runAction:tween completion:^{
        [hitTimeLabel removeFromParent];
    }];
}

/*
 * Delegate for skspritebutton when the tap button is hit
 */
- (void)buttonHit:(SKSpriteButton *)button
{
    if ([button.name isEqualToString:@"tapButton"]) {
        [self registerTapButtonHit];
    } else if ([button.name isEqualToString:@"backButton"]) {
        [self leaveScene];
    } else if ([button.name isEqualToString:@"beginButton"]) {
        // start the game
        [self startGame];
    }
}

/*
 * Leave scene
 */
- (void)leaveScene
{
    // Invalidate the timers before leavint the scene
    [self.gameTimer invalidate];
    
    // Present the menu scene again
    MenuScene *ms = [[MenuScene alloc] initWithSize:self.frame.size];
    SKTransition *transition = [SKTransition pushWithDirection:SKTransitionDirectionRight duration:0.3f];
    [self.view presentScene:ms transition:transition];
}

@end

