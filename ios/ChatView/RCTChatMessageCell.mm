//
//  RCTMessageCell.m
//  AurenChatView
//
//  Created by Ananta Ranganathan on 12/2/25.
//

#import <Foundation/Foundation.h>

#import "RCTChatMessageCell.h"

#import <react/renderer/components/AppSpec/ComponentDescriptors.h>
#import <react/renderer/components/AppSpec/EventEmitters.h>
#import <react/renderer/components/AppSpec/Props.h>
#import <react/renderer/components/AppSpec/RCTComponentViewHelpers.h>

@implementation RCTChatMessageCell

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    _bubbleView = [UIView new];
    _bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
    _bubbleView.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:1.0 alpha:1.0];
    _bubbleView.layer.cornerRadius = 20.0;
    _bubbleView.layer.masksToBounds = YES;

    _label = [UILabel new];
    _label.translatesAutoresizingMaskIntoConstraints = NO;
    _label.textColor = [UIColor whiteColor];
    _label.numberOfLines = 0;
    _label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];

    // Make bubble prefer to be as small as its contents allow
    [_bubbleView setContentHuggingPriority:UILayoutPriorityRequired
                                   forAxis:UILayoutConstraintAxisHorizontal];
    [_bubbleView setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                 forAxis:UILayoutConstraintAxisHorizontal];

    // (optional, but usually good)
    [_label setContentHuggingPriority:UILayoutPriorityRequired
                               forAxis:UILayoutConstraintAxisHorizontal];
    [_label setContentCompressionResistancePriority:UILayoutPriorityRequired
                                             forAxis:UILayoutConstraintAxisHorizontal];
    _maxWidthConstraint = [_bubbleView.widthAnchor constraintLessThanOrEqualToConstant:1000];
    _maxWidthConstraint.active = YES;
    _minWidthConstraint = [_bubbleView.widthAnchor constraintGreaterThanOrEqualToConstant:200.0];
    _minWidthConstraint.active = NO;
    _imageStackView = [[UIStackView alloc] init];
    _imageStackView.translatesAutoresizingMaskIntoConstraints = NO;
    _imageStackView.axis = UILayoutConstraintAxisVertical;
    _imageStackView.spacing = 4.0;
    _imageStackView.alignment = UIStackViewAlignmentTrailing;
    [self.contentView addSubview:_imageStackView];

    [_bubbleView addSubview:_label];
    [self.contentView addSubview:_bubbleView];

    const CGFloat bubbleVertical = 4.0;
    const CGFloat bubbleHorizontal = 16.0;
    const CGFloat labelPaddingVertical = 10.0;
    const CGFloat labelPaddingHorizontal = 16.0;

    _leadingConstraint = [_bubbleView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:bubbleHorizontal];
    _trailingConstraint = [_bubbleView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-bubbleHorizontal];

    [NSLayoutConstraint activateConstraints:@[
      [_bubbleView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-bubbleVertical],
      [_imageStackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:bubbleVertical],
      [_imageStackView.leadingAnchor constraintEqualToAnchor:_bubbleView.leadingAnchor],
      [_imageStackView.trailingAnchor constraintEqualToAnchor:_bubbleView.trailingAnchor],
      // Bubble sits below images
      [_bubbleView.topAnchor constraintEqualToAnchor:_imageStackView.bottomAnchor constant:0],
      // Label at top of bubble (no longer relative to imageStack)
      [_label.topAnchor constraintEqualToAnchor:_bubbleView.topAnchor constant:labelPaddingVertical],
      [_label.bottomAnchor constraintEqualToAnchor:_bubbleView.bottomAnchor constant:-labelPaddingVertical],
      [_label.leadingAnchor constraintEqualToAnchor:_bubbleView.leadingAnchor constant:labelPaddingHorizontal],
    ]];
    _labelTrailingConstraint = [_label.trailingAnchor constraintEqualToAnchor:_bubbleView.trailingAnchor constant:-labelPaddingHorizontal];
    _labelTrailingConstraint.active = YES;
    
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.cornerRadius = 20.0;
    [_bubbleView.layer insertSublayer:self.gradientLayer atIndex:0];
    
    _readReceiptImageView = [UIImageView new];
    _readReceiptImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _readReceiptImageView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    _readReceiptImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_bubbleView addSubview:_readReceiptImageView];

    [NSLayoutConstraint activateConstraints:@[
      [_readReceiptImageView.trailingAnchor constraintEqualToAnchor:_bubbleView.trailingAnchor constant:-8.0],
      [_readReceiptImageView.centerYAnchor constraintEqualToAnchor:_label.lastBaselineAnchor constant:-5.0],
      [_readReceiptImageView.widthAnchor constraintEqualToConstant:14.0],
      [_readReceiptImageView.heightAnchor constraintEqualToConstant:14.0],
    ]];
  }
  return self;
}

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:
    (UICollectionViewLayoutAttributes *)layoutAttributes
{
  return layoutAttributes;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  NSLog(@"layoutSubviews bubbleView.bounds: %@", NSStringFromCGRect(_bubbleView.bounds));

  CGFloat contentWidth = self.contentView.bounds.size.width;
  CGFloat maxBubbleWidth = contentWidth * 0.75;
  CGFloat labelPaddingHorizontal = 16.0;

  self.label.preferredMaxLayoutWidth =
      maxBubbleWidth - 2 * labelPaddingHorizontal;
  
  self.gradientLayer.frame = _bubbleView.bounds;
}

- (void)configureWithText:(NSString *)text isUser:(BOOL)isUser sameAsPrevious:(BOOL)sameAsPrevious readByCharacterAt:(double)readByCharacterAt gradientStart:(UIColor *)gradientStart gradientEnd:(UIColor *)gradientEnd
{
  NSLog(@"configure bubbleView.bounds: %@", NSStringFromCGRect(_bubbleView.bounds));

  self.label.text = text;
  self.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
  
  if (isUser) {
    self.leadingConstraint.active = NO;
    self.trailingConstraint.active = YES;
    self.gradientLayer.hidden = YES;
    self.bubbleView.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:1.0 alpha:1.0];
  } else {
    self.leadingConstraint.active = YES;
    self.trailingConstraint.active = NO;
    self.gradientLayer.hidden = NO;
    self.bubbleView.backgroundColor = [UIColor clearColor];
    self.gradientLayer.colors = @[
        (id)gradientStart.CGColor,
        (id)gradientEnd.CGColor,
    ];
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 1);
  }
  if (isUser) {
    self.readReceiptImageView.hidden = NO;
    NSString *imageName = (readByCharacterAt != 0.0) ? @"checkmark.circle.fill" : @"checkmark.circle";
    self.readReceiptImageView.image = [UIImage systemImageNamed:imageName];
  } else {
    self.readReceiptImageView.hidden = YES;
  }
  self.labelTrailingConstraint.constant = isUser ? -24.0 : -16.0;
  self.topConstraint.constant = sameAsPrevious ? 2.0 : 12.0;

  [self layoutIfNeeded];
  self.gradientLayer.frame = _bubbleView.bounds;
  NSLog(@"configure bubbleView.bounds: %@", NSStringFromCGRect(_bubbleView.bounds));
}


- (void)configureWithImage:(NSDictionary * _Nullable)image
{
  // Clear existing image views
  for (UIView *subview in [_imageStackView.arrangedSubviews copy]) {
    [_imageStackView removeArrangedSubview:subview];
    [subview removeFromSuperview];
  }
  
  BOOL hasImage = (image != nil);
  _minWidthConstraint.active = hasImage;

  if (!hasImage) {
    return;
  }
  
  NSString *urlString = image[@"public_url"];
  if (!urlString) {
    return;
  }

  UIImageView *imageView = [[UIImageView alloc] init];
  imageView.translatesAutoresizingMaskIntoConstraints = NO;
  imageView.contentMode = UIViewContentModeScaleAspectFill;
  imageView.clipsToBounds = YES;
  imageView.userInteractionEnabled = YES;
  imageView.tag = 0; // Only one image now
  [imageView.widthAnchor constraintEqualToConstant:200.0].active = YES;
  [imageView.heightAnchor constraintEqualToConstant:200.0].active = YES;
  imageView.layer.cornerRadius = 20.0;
  imageView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;

  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageTap:)];
  [imageView addGestureRecognizer:tap];
  [_imageStackView addArrangedSubview:imageView];

  NSURL *url = [NSURL URLWithString:urlString];
  NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    if (data && !error) {
      UIImage *downloadedImage = [UIImage imageWithData:data];
      dispatch_async(dispatch_get_main_queue(), ^{
        imageView.image = downloadedImage;
      });
    }
  }];
  [task resume];
}

- (void)handleImageTap:(UITapGestureRecognizer *)recognizer
{
  UIView *imageView = recognizer.view;
  NSInteger index = imageView.tag;
  
  // Convert frame to window coordinates (like your JS measure callback)
  UIWindow *window = self.window;
  CGRect frameInWindow = [imageView convertRect:imageView.bounds toView:window];
  
  if (self.onImageTapped) {
    self.onImageTapped(index, frameInWindow);
  }
}

@end
