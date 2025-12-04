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

    [_bubbleView addSubview:_label];
    [self.contentView addSubview:_bubbleView];

    const CGFloat bubbleVertical = 4.0;
    const CGFloat bubbleHorizontal = 16.0;
    const CGFloat labelPaddingVertical = 10.0;
    const CGFloat labelPaddingHorizontal = 16.0;

    
    _topConstraint = [_bubbleView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:bubbleVertical];
    _leadingConstraint = [_bubbleView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:bubbleHorizontal];
    _trailingConstraint = [_bubbleView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-bubbleHorizontal];

    [NSLayoutConstraint activateConstraints:@[
      _topConstraint,
      [_bubbleView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-bubbleVertical],
      [_label.topAnchor constraintEqualToAnchor:_bubbleView.topAnchor constant:labelPaddingVertical],
      [_label.bottomAnchor constraintEqualToAnchor:_bubbleView.bottomAnchor constant:-labelPaddingVertical],
      [_label.leadingAnchor constraintEqualToAnchor:_bubbleView.leadingAnchor constant:labelPaddingHorizontal],
    ]];
    _labelTrailingConstraint = [_label.trailingAnchor constraintEqualToAnchor:_bubbleView.trailingAnchor constant:-labelPaddingHorizontal];
    _labelTrailingConstraint.active = YES;
    UIContextMenuInteraction *interaction =
        [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [_bubbleView addInteraction:interaction];
    
    _readReceiptImageView = [UIImageView new];
    _readReceiptImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _readReceiptImageView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.7];
    _readReceiptImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_bubbleView addSubview:_readReceiptImageView];

    [NSLayoutConstraint activateConstraints:@[
      [_readReceiptImageView.trailingAnchor constraintEqualToAnchor:_bubbleView.trailingAnchor constant:-8.0],
      [_readReceiptImageView.bottomAnchor constraintEqualToAnchor:_bubbleView.bottomAnchor constant:-6.0],
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

  CGFloat contentWidth = self.contentView.bounds.size.width;
  CGFloat maxBubbleWidth = contentWidth * 0.75;
  CGFloat labelPaddingHorizontal = 16.0;

  self.label.preferredMaxLayoutWidth =
      maxBubbleWidth - 2 * labelPaddingHorizontal;
}

- (void)configureWithText:(NSString *)text isUser:(BOOL)isUser sameAsPrevious:(BOOL)sameAsPrevious readByCharacterAt:(double)readByCharacterAt
{
  self.label.text = text;
  self.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
  
  if (isUser) {
    self.leadingConstraint.active = NO;
    self.trailingConstraint.active = YES;
    self.bubbleView.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0]; // Green for user
  } else {
    self.leadingConstraint.active = YES;
    self.trailingConstraint.active = NO;
    self.bubbleView.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:1.0 alpha:1.0]; // Blue for assistant
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

}

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction
                        configurationForMenuAtLocation:(CGPoint)location
{
    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
                    previewProvider:nil
                     actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
        UIAction *copy = [UIAction actionWithTitle:@"Copy"
                                             image:[UIImage systemImageNamed:@"doc.on.doc"]
                                        identifier:nil
                                           handler:^(UIAction *action) {
            UIPasteboard.generalPasteboard.string = self.label.text;
        }];
        return [UIMenu menuWithTitle:@"" children:@[copy]];
    }];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.alpha = 0;
    self.transform = CGAffineTransformMakeTranslation(20, 0);
}

@end
