// RemoteMenu.m
// Floating mod menu for Animal Company Companion.
// Built as an arm64 iOS dylib and injected into the IPA (Sideloadly handles injection).
// The circle is draggable; a tap (not a drag) toggles the menu with a spring animation.
// Toggle state is persisted in NSUserDefaults and exposed via modTestEnabled / modPrefabEnabled
// so future hooks can read it.

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <math.h>

BOOL modTestEnabled = NO;
BOOL modPrefabEnabled = NO;

@interface FloatingMenuWindow : UIWindow
@property (nonatomic, strong) UIView *circle;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, assign) BOOL open;
@property (nonatomic, assign) CGFloat dragDistance;
+ (void)install;
- (void)toggleMenu;
@end

@implementation FloatingMenuWindow

+ (void)install {
    UIWindowScene *scene = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]] && s.activationState == UISceneActivationStateForegroundActive) {
            scene = (UIWindowScene *)s;
            break;
        }
    }
    if (!scene) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [FloatingMenuWindow install];
        });
        return;
    }

    FloatingMenuWindow *window = [[FloatingMenuWindow alloc] initWithWindowScene:scene];
    window.windowLevel = UIWindowLevelAlert + 100.0;
    window.backgroundColor = UIColor.clearColor;

    CGFloat screenW = scene.coordinateSpace.bounds.size.width;

    // --- movable circle (top of screen) ---
    UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(screenW / 2 - 30, 70, 60, 60)];
    circle.backgroundColor = [UIColor colorWithRed:0.15 green:0.85 blue:0.35 alpha:1.0];
    circle.layer.cornerRadius = 30;
    circle.layer.borderWidth = 2.5;
    circle.layer.borderColor = [UIColor whiteColor].CGColor;
    circle.layer.shadowColor = [UIColor blackColor].CGColor;
    circle.layer.shadowOpacity = 0.5;
    circle.layer.shadowRadius = 6;
    circle.layer.shadowOffset = CGSizeZero;

    UILabel *icon = [[UILabel alloc] initWithFrame:circle.bounds];
    icon.text = [NSString stringWithFormat:@"%C", (unichar)0x2261]; // triple bar
    icon.font = [UIFont boldSystemFontOfSize:30];
    icon.textColor = UIColor.whiteColor;
    icon.textAlignment = NSTextAlignmentCenter;
    [circle addSubview:icon];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:window action:@selector(circleDragged:)];
    [circle addGestureRecognizer:pan];

    window.circle = circle;
    [window addSubview:circle];

    [window buildPanel];

    window.hidden = NO;
}

- (void)buildPanel {
    CGFloat w = 260;
    CGFloat h = 170;

    UIView *panel = [[UIView alloc] initWithFrame:CGRectMake(20, 150, w, h)];
    panel.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.97];
    panel.layer.cornerRadius = 18;
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.15].CGColor;
    panel.clipsToBounds = YES;
    panel.hidden = YES;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, w - 32, 24)];
    title.text = @"MOD MENU";
    title.font = [UIFont boldSystemFontOfSize:17];
    title.textColor = [UIColor colorWithRed:0.3 green:1.0 blue:0.5 alpha:1.0];
    title.textAlignment = NSTextAlignmentCenter;
    [panel addSubview:title];

    UILabel *testLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 58, 160, 30)];
    testLabel.text = @"Test";
    testLabel.font = [UIFont systemFontOfSize:16];
    testLabel.textColor = UIColor.whiteColor;
    [panel addSubview:testLabel];

    UISwitch *testSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(w - 78, 54, 51, 31)];
    testSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"rn_test"];
    testSwitch.onTintColor = [UIColor colorWithRed:0.15 green:0.85 blue:0.35 alpha:1.0];
    [testSwitch addTarget:self action:@selector(testChanged:) forControlEvents:UIControlEventValueChanged];
    [panel addSubview:testSwitch];

    UILabel *prefabLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 104, 160, 30)];
    prefabLabel.text = @"Prefab";
    prefabLabel.font = [UIFont systemFontOfSize:16];
    prefabLabel.textColor = UIColor.whiteColor;
    [panel addSubview:prefabLabel];

    UISwitch *prefabSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(w - 78, 100, 51, 31)];
    prefabSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"rn_prefab"];
    prefabSwitch.onTintColor = [UIColor colorWithRed:0.15 green:0.85 blue:0.35 alpha:1.0];
    [prefabSwitch addTarget:self action:@selector(prefabChanged:) forControlEvents:UIControlEventValueChanged];
    [panel addSubview:prefabSwitch];

    self.panel = panel;
    [self addSubview:panel];
}

- (void)testChanged:(UISwitch *)sw {
    modTestEnabled = sw.on;
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@"rn_test"];
}

- (void)prefabChanged:(UISwitch *)sw {
    modPrefabEnabled = sw.on;
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@"rn_prefab"];
}

- (void)circleDragged:(UIPanGestureRecognizer *)pan {
    CGPoint t = [pan translationInView:self];
    if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint center = self.circle.center;
        center.x += t.x;
        center.y += t.y;
        center.x = MAX(34, MIN(self.bounds.size.width - 34, center.x));
        center.y = MAX(34, MIN(self.bounds.size.height - 34, center.y));
        self.circle.center = center;
        self.dragDistance += sqrt(t.x * t.x + t.y * t.y);
        [pan setTranslation:CGPointZero inView:self];
    } else if (pan.state == UIGestureRecognizerStateEnded) {
        if (self.dragDistance < 12) {
            [self toggleMenu];
        }
        self.dragDistance = 0;
    }
}

- (void)toggleMenu {
    self.open = !self.open;
    if (self.open) {
        self.panel.hidden = NO;
        self.panel.transform = CGAffineTransformMakeScale(0.05, 0.05);
        self.panel.alpha = 0.0;
        [UIView animateWithDuration:0.4
                              delay:0.0
             usingSpringWithDamping:0.65
              initialSpringVelocity:0.4
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.panel.transform = CGAffineTransformIdentity;
            self.panel.alpha = 1.0;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
            self.panel.transform = CGAffineTransformMakeScale(0.05, 0.05);
            self.panel.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.panel.hidden = YES;
            self.panel.transform = CGAffineTransformIdentity;
            self.panel.alpha = 1.0;
        }];
    }
}

// Pass touches through to the game except on the circle or the open menu.
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(self.circle.frame, point)) {
        return [super hitTest:point withEvent:event];
    }
    if (self.open && CGRectContainsPoint(self.panel.frame, point)) {
        return [super hitTest:point withEvent:event];
    }
    return nil;
}

@end

__attribute__((constructor))
static void rn_init(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [FloatingMenuWindow install];
    });
}
