#import "RCTTypingIndicatorCell.h"

@implementation RCTTypingIndicatorCell {
  UIView *_dot1;
  UIView *_dot2;
  UIView *_dot3;
  UIView *_dotsContainer;
  BOOL _isAnimating;
  NSLayoutConstraint *_leadingConstraint;
  NSLayoutConstraint *_trailingConstraint;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _bubbleView = [UIView new];
    _bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
    _bubbleView.layer.cornerRadius = 20.0;
    _bubbleView.layer.masksToBounds = YES;
    
    [self.contentView addSubview:_bubbleView];
    
    // Container for the dots (makes centering easier)
    _dotsContainer = [UIView new];
    _dotsContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [_bubbleView addSubview:_dotsContainer];
    
    // Create three dots
    _dot1 = [self createDot];
    _dot2 = [self createDot];
    _dot3 = [self createDot];
    
    [_dotsContainer addSubview:_dot1];
    [_dotsContainer addSubview:_dot2];
    [_dotsContainer addSubview:_dot3];
    
    CGFloat dotSize = 6.0;
    CGFloat dotSpacing = 6.0;
    CGFloat bubblePaddingH = 16.0;
    CGFloat bubblePaddingV = 10.0;
    
    _leadingConstraint = [_bubbleView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0];
    _trailingConstraint = [_bubbleView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0];
    
    [NSLayoutConstraint activateConstraints:@[
      // Bubble vertical positioning
      [_bubbleView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4.0],
      [_bubbleView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4.0],
      
      // Dots container inside bubble
      [_dotsContainer.leadingAnchor constraintEqualToAnchor:_bubbleView.leadingAnchor constant:bubblePaddingH],
      [_dotsContainer.trailingAnchor constraintEqualToAnchor:_bubbleView.trailingAnchor constant:-bubblePaddingH],
      [_dotsContainer.topAnchor constraintEqualToAnchor:_bubbleView.topAnchor constant:bubblePaddingV],
      [_dotsContainer.bottomAnchor constraintEqualToAnchor:_bubbleView.bottomAnchor constant:-bubblePaddingV],
      
      // Dot sizes
      [_dot1.widthAnchor constraintEqualToConstant:dotSize],
      [_dot1.heightAnchor constraintEqualToConstant:dotSize],
      [_dot2.widthAnchor constraintEqualToConstant:dotSize],
      [_dot2.heightAnchor constraintEqualToConstant:dotSize],
      [_dot3.widthAnchor constraintEqualToConstant:dotSize],
      [_dot3.heightAnchor constraintEqualToConstant:dotSize],
      
      // Horizontal layout within container
      [_dot1.leadingAnchor constraintEqualToAnchor:_dotsContainer.leadingAnchor],
      [_dot2.leadingAnchor constraintEqualToAnchor:_dot1.trailingAnchor constant:dotSpacing],
      [_dot3.leadingAnchor constraintEqualToAnchor:_dot2.trailingAnchor constant:dotSpacing],
      [_dot3.trailingAnchor constraintEqualToAnchor:_dotsContainer.trailingAnchor],
      
      // Vertical centering
      [_dot1.centerYAnchor constraintEqualToAnchor:_dotsContainer.centerYAnchor],
      [_dot2.centerYAnchor constraintEqualToAnchor:_dotsContainer.centerYAnchor],
      [_dot3.centerYAnchor constraintEqualToAnchor:_dotsContainer.centerYAnchor],
      
      // Container height from dots
      [_dotsContainer.heightAnchor constraintEqualToConstant:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].lineHeight],
    ]];
  }
  return self;
}

- (UIView *)createDot
{
  UIView *dot = [UIView new];
  dot.translatesAutoresizingMaskIntoConstraints = NO;
  dot.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
  dot.layer.cornerRadius = 3.0;
  dot.transform = CGAffineTransformMakeScale(0.0, 0.0);
  return dot;
}

- (void)configureWithIsUser:(BOOL)isUser
{
  if (isUser) {
    _leadingConstraint.active = NO;
    _trailingConstraint.active = YES;
    _bubbleView.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0];
  } else {
    _trailingConstraint.active = NO;
    _leadingConstraint.active = YES;
    _bubbleView.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:1.0 alpha:1.0];
  }
}

- (void)startAnimating
{
  if (_isAnimating) return;
  _isAnimating = YES;
  
  // Reset to scale 0
  _dot1.transform = CGAffineTransformMakeScale(0.0, 0.0);
  _dot2.transform = CGAffineTransformMakeScale(0.0, 0.0);
  _dot3.transform = CGAffineTransformMakeScale(0.0, 0.0);
  
  [self animateDot:_dot1 withDelay:0.0];
  [self animateDot:_dot2 withDelay:0.2];
  [self animateDot:_dot3 withDelay:0.4];
}

- (void)animateDot:(UIView *)dot withDelay:(NSTimeInterval)delay
{
  if (!_isAnimating) return;
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (!self->_isAnimating) return;
    [self runScaleCycleForDot:dot];
  });
}

- (void)runScaleCycleForDot:(UIView *)dot
{
  if (!_isAnimating) return;
  
  // Scale up with spring-like easing
  [UIView animateWithDuration:0.4
                        delay:0
       usingSpringWithDamping:0.6
        initialSpringVelocity:0
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^{
    dot.transform = CGAffineTransformMakeScale(1.0, 1.0);
  } completion:^(BOOL finished) {
    if (!self->_isAnimating) return;
    
    // Scale down
    [UIView animateWithDuration:0.4
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
      dot.transform = CGAffineTransformMakeScale(0.0, 0.0);
    } completion:^(BOOL finished) {
      if (!self->_isAnimating) return;
      
      // Repeat
      [self runScaleCycleForDot:dot];
    }];
  }];
}

- (void)stopAnimating
{
  _isAnimating = NO;
  _dot1.transform = CGAffineTransformMakeScale(0.0, 0.0);
  _dot2.transform = CGAffineTransformMakeScale(0.0, 0.0);
  _dot3.transform = CGAffineTransformMakeScale(0.0, 0.0);
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  [self stopAnimating];
}

@end
