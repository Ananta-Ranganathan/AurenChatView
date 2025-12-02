//
//  RCTChatView.m
//  AurenChatView
//
//  Created by Ananta Ranganathan on 11/24/25.
//

#import <Foundation/Foundation.h>

#import "RCTChatView.h"
#import "RCTChatMessageCell.h"

#import <react/renderer/components/AppSpec/ComponentDescriptors.h>
#import <react/renderer/components/AppSpec/EventEmitters.h>
#import <react/renderer/components/AppSpec/Props.h>
#import <react/renderer/components/AppSpec/RCTComponentViewHelpers.h>

using namespace facebook::react;

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
    
    _collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOutside:)];
    tap.cancelsTouchesInView = NO;
    [_collectionView addGestureRecognizer:tap];
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
  CGPoint newOffset = _collectionView.contentOffset;

  if (wasAtBottom) {
      CGFloat newBottomOffset =
          MAX(contentHeight + newContentInsets.bottom - visibleHeight,
              -newContentInsets.top);
      newOffset.y = newBottomOffset;
  } else {
      newOffset.y += deltaBottom;
      if (newOffset.y < -newContentInsets.top) {
          newOffset.y = -newContentInsets.top;
      }
  }

  [UIView animateWithDuration:duration
                        delay:0
                      options:curve
                   animations:^{
                       self->_collectionView.contentInset = newContentInsets;
                       self->_collectionView.verticalScrollIndicatorInsets = newIndicatorInsets;
                       self->_collectionView.contentOffset = newOffset;
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

- (void)handleTapOutside:(UITapGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:_collectionView];
    NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:location];
    
    if (indexPath == nil) {
      NSLog(@"indexpath is nil, TODO REQUEST DISMISS KEYBOARD");
        return;
    }
    
    RCTChatMessageCell *cell = (RCTChatMessageCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    CGPoint pointInCell = [recognizer locationInView:cell];
    
    if (![cell.bubbleView pointInside:[cell.bubbleView convertPoint:pointInCell fromView:cell] withEvent:nil]) {
      NSLog(@"tap was not inside a bubble TODO REQUEST DISMISS KEYBOARD");
    } else {
      NSLog(@"tap was inside a bubble");
    }
}

+(ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<AurenChatViewComponentDescriptor>();
}
@end
