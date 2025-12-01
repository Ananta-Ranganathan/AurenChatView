//
//  RCTChatView.m
//  AurenChatView
//
//  Created by Ananta Ranganathan on 11/24/25.
//

#import <Foundation/Foundation.h>

#import "RCTChatView.h"

#import <react/renderer/components/AppSpec/ComponentDescriptors.h>
#import <react/renderer/components/AppSpec/EventEmitters.h>
#import <react/renderer/components/AppSpec/Props.h>
#import <react/renderer/components/AppSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

@interface RCTChatMessageCell : UICollectionViewCell

@property(nonatomic, strong) UIView *bubbleView;
@property(nonatomic, strong) UILabel *label;
@property(nonatomic, strong) NSLayoutConstraint *leadingConstraint;
@property(nonatomic, strong) NSLayoutConstraint *trailingConstraint;
@property(nonatomic, strong) NSLayoutConstraint *maxWidthConstraint;

@end

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

    _leadingConstraint = [_bubbleView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:bubbleHorizontal];
    _trailingConstraint = [_bubbleView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-bubbleHorizontal];

    [NSLayoutConstraint activateConstraints:@[
      [_bubbleView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:bubbleVertical],
      [_bubbleView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-bubbleVertical],
      [_label.topAnchor constraintEqualToAnchor:_bubbleView.topAnchor constant:labelPaddingVertical],
      [_label.bottomAnchor constraintEqualToAnchor:_bubbleView.bottomAnchor constant:-labelPaddingVertical],
      [_label.leadingAnchor constraintEqualToAnchor:_bubbleView.leadingAnchor constant:labelPaddingHorizontal],
      [_label.trailingAnchor constraintEqualToAnchor:_bubbleView.trailingAnchor constant:-labelPaddingHorizontal],
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

- (void)configureWithText:(NSString *)text isUser:(BOOL)isUser
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
}
@end

@interface RCTChatView ()
<RCTComponentViewProtocol, RCTTouchableComponentViewProtocol,
 UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@end

@implementation RCTChatView {
  UICollectionView *_collectionView;
  std::vector<AurenChatViewMessagesStruct> _messages;
  CGFloat _keyboardBottomInset;
}

- (instancetype)init
{
  if (self = [super init]) {
    NSLog(@"super init succeeded");

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    layout.minimumLineSpacing = 8.0;
    layout.sectionInset = UIEdgeInsetsZero;
    layout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize;
    layout.itemSize = UICollectionViewFlowLayoutAutomaticSize;

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero
                                         collectionViewLayout:layout];
    _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.alwaysBounceVertical = YES;
    _collectionView.dataSource = self;
    _collectionView.delegate = self;

    [_collectionView registerClass:[RCTChatMessageCell class]
        forCellWithReuseIdentifier:@"RCTChatMessageCell"];

    [self addSubview:_collectionView];

    // Pin collectionView to edges of self
    [NSLayoutConstraint activateConstraints:@[
      [_collectionView.topAnchor constraintEqualToAnchor:self.topAnchor],
      [_collectionView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
      [_collectionView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
      [_collectionView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ]];
    
    _keyboardBottomInset = 0;

    // Listen for keyboard frame changes
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(handleKeyboardNotification:)
                   name:UIKeyboardWillChangeFrameNotification
                 object:nil];
    [center addObserver:self
               selector:@selector(handleKeyboardNotification:)
                   name:UIKeyboardWillHideNotification
                 object:nil];
  }
  return self;
}
- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateProps:(Props::Shared const &)props
          oldProps:(Props::Shared const &)oldProps
{
  if (!props) {
    [super updateProps:props oldProps:oldProps];
    return;
  }

  const auto &newViewProps =
      *std::static_pointer_cast<AurenChatViewProps const>(props);

  // Copy messages into native storage
  _messages.clear();
  _messages.reserve(newViewProps.messages.size());
  for (const auto &msg : newViewProps.messages) {
    _messages.push_back(msg);
  }

  // For now, just reload everything. Later we will do diffing + batch updates.
  [_collectionView reloadData];

  [super updateProps:props oldProps:oldProps];
}



-(void)layoutSubviews
{
  [super layoutSubviews];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
  return (NSInteger)_messages.size();
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                          cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  RCTChatMessageCell *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:@"RCTChatMessageCell"
                                                forIndexPath:indexPath];

  const auto &msg = _messages[(size_t)indexPath.item];
  NSString *text = [NSString stringWithUTF8String:msg.text.c_str()];
  [cell configureWithText:text isUser:msg.isUser];

  return cell;
}

- (void)handleKeyboardNotification:(NSNotification *)notification
{
  NSDictionary *userInfo = notification.userInfo;
  if (!userInfo) {
    return;
  }

  NSTimeInterval duration =
      [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  UIViewAnimationOptions curve =
      ([userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);

  CGRect keyboardFrameScreen =
      [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

  // Convert keyboard frame into this view's coordinate space
  CGRect keyboardFrameInSelf = [self convertRect:keyboardFrameScreen
                                        fromView:nil];

  // How much of our bounds is covered by the keyboard?
  CGFloat overlap =
      CGRectGetMaxY(self.bounds) - CGRectGetMinY(keyboardFrameInSelf);
  CGFloat newBottomInset = MAX(overlap, 0.0);

  UIEdgeInsets oldContentInsets = _collectionView.contentInset;
  UIEdgeInsets oldIndicatorInsets = _collectionView.verticalScrollIndicatorInsets;

  // Compute whether we are currently at the bottom (before insets change)
  CGFloat contentHeight = _collectionView.contentSize.height;
  CGFloat visibleHeight = _collectionView.bounds.size.height;

  // Where is the bottom offset with the old insets?
  CGFloat oldBottomOffset =
      MAX(contentHeight + oldContentInsets.bottom - visibleHeight, -oldContentInsets.top);

  CGFloat currentOffsetY = _collectionView.contentOffset.y;
  BOOL wasAtBottom = fabs(currentOffsetY - oldBottomOffset) < 2.0; // small tolerance

  // New insets
  UIEdgeInsets newContentInsets = oldContentInsets;
  newContentInsets.bottom = newBottomInset;

  UIEdgeInsets newIndicatorInsets = oldIndicatorInsets;
  newIndicatorInsets.bottom = newBottomInset;

  CGFloat deltaBottom = newContentInsets.bottom - oldContentInsets.bottom;

  [UIView animateWithDuration:duration
                        delay:0
                      options:curve
                   animations:^{
                     if (!self) {
                       return;
                     }

                     self->_collectionView.contentInset = newContentInsets;
                     self->_collectionView.verticalScrollIndicatorInsets = newIndicatorInsets;

                     CGPoint offset = self->_collectionView.contentOffset;

                     if (wasAtBottom) {
                       // Stay pinned to bottom: recompute bottom with new insets
                       CGFloat newContentHeight = self->_collectionView.contentSize.height;
                       CGFloat newVisibleHeight = self->_collectionView.bounds.size.height;
                       CGFloat newBottomOffset =
                           MAX(newContentHeight + newContentInsets.bottom - newVisibleHeight,
                               -newContentInsets.top);
                       offset.y = newBottomOffset;
                     } else {
                       // Preserve relative position by shifting with the inset change
                       offset.y += deltaBottom;

                       // Clamp at top
                       if (offset.y < -newContentInsets.top) {
                         offset.y = -newContentInsets.top;
                       }
                     }

                     self->_collectionView.contentOffset = offset;
                     [self layoutIfNeeded];
                   }
                   completion:nil];
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)layout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *text = [NSString stringWithUTF8String:_messages[indexPath.item].text.c_str()];
  
  CGFloat contentWidth = collectionView.bounds.size.width;
  CGFloat maxBubbleWidth = contentWidth * 0.75;
  CGFloat labelPaddingHorizontal = 16.0;
  CGFloat labelPaddingVertical = 10.0;
  CGFloat maxLabelWidth = maxBubbleWidth - 2 * labelPaddingHorizontal;
  
  CGRect textRect = [text boundingRectWithSize:CGSizeMake(maxLabelWidth, CGFLOAT_MAX)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]}
                                       context:nil];
  
  CGFloat cellHeight = ceil(textRect.size.height) + 2 * labelPaddingVertical + 8; // 8 for bubble vertical margin
  
  return CGSizeMake(contentWidth, cellHeight);
}

+(ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<AurenChatViewComponentDescriptor>();
}
@end
