//
//  RCTChatView.m
//  AurenChatView
//
//  Created by Ananta Ranganathan on 11/24/25.
//

#import <Foundation/Foundation.h>

#import "RCTChatView.h"
#import "RCTChatMessageCell.h"
#import "RCTTypingIndicatorCell.h"

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
    [_collectionView registerClass:[RCTTypingIndicatorCell class]
        forCellWithReuseIdentifier:@"RCTTypingIndicatorCell"];

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

  // Build new messages vector
  std::vector<AurenChatViewMessagesStruct> newMessages;
  newMessages.reserve(newViewProps.messages.size());
  for (const auto &msg : newViewProps.messages) {
    newMessages.push_back(msg);
  }

  // Check if we're at the bottom before changes
  CGFloat contentHeight = _collectionView.contentSize.height;
  CGFloat visibleHeight = _collectionView.bounds.size.height;
  UIEdgeInsets insets = _collectionView.contentInset;
  CGFloat bottomOffset = MAX(contentHeight + insets.bottom - visibleHeight, -insets.top);
  CGFloat currentOffsetY = _collectionView.contentOffset.y;
  BOOL wasAtBottom = (contentHeight <= visibleHeight) || (currentOffsetY >= bottomOffset - 2.0);

  // Build UUID lookup for old messages
  std::unordered_map<std::string, NSInteger> oldIndexByUUID;
  for (NSInteger i = 0; i < (NSInteger)_messages.size(); i++) {
    oldIndexByUUID[_messages[i].uuid] = i;
  }

  // Build UUID lookup for new messages
  std::unordered_map<std::string, NSInteger> newIndexByUUID;
  for (NSInteger i = 0; i < (NSInteger)newMessages.size(); i++) {
    newIndexByUUID[newMessages[i].uuid] = i;
  }

  // Find deletes, inserts, and reloads
  NSMutableArray<NSIndexPath *> *toDelete = [NSMutableArray new];
  NSMutableArray<NSIndexPath *> *toInsert = [NSMutableArray new];
  NSMutableArray<NSIndexPath *> *toReload = [NSMutableArray new];

  // Check for deletions (in old but not in new)
  for (NSInteger i = 0; i < (NSInteger)_messages.size(); i++) {
    if (newIndexByUUID.find(_messages[i].uuid) == newIndexByUUID.end()) {
      [toDelete addObject:[NSIndexPath indexPathForItem:i inSection:0]];
    }
  }

  // Check for insertions and updates
  for (NSInteger i = 0; i < (NSInteger)newMessages.size(); i++) {
    auto it = oldIndexByUUID.find(newMessages[i].uuid);
    if (it == oldIndexByUUID.end()) {
      // New message
      [toInsert addObject:[NSIndexPath indexPathForItem:i inSection:0]];
    } else {
      // Existing message - check if text changed (will have to check read receipts or reactions and stuff soon)
      NSInteger oldIndex = it->second;
      if (_messages[oldIndex].text != newMessages[i].text ||
          _messages[oldIndex].isTypingIndicator != newMessages[i].isTypingIndicator) {
        [toReload addObject:[NSIndexPath indexPathForItem:i inSection:0]];
      }
    }
  }

  if (toDelete.count > 0 || toInsert.count > 0 || toReload.count > 0) {
    NSLog(@"before performBatchUpdates");
    [_collectionView performBatchUpdates:^{
      NSLog(@"inside batch update block");
      self->_messages = std::move(newMessages);
      
      if (toDelete.count > 0) {
        [self->_collectionView deleteItemsAtIndexPaths:toDelete];
      }
      if (toInsert.count > 0) {
        [self->_collectionView insertItemsAtIndexPaths:toInsert];
      }
      if (toReload.count > 0) {
        [self->_collectionView reloadItemsAtIndexPaths:toReload];
      }
    } completion:^(BOOL finished) {
      NSLog(@"completion block fired");

    }];
    NSLog(@"after performBatchUpdates");
    if (wasAtBottom && self->_messages.size() > 0) {
        CGFloat newContentHeight = self->_collectionView.contentSize.height;
        CGFloat newVisibleHeight = self->_collectionView.bounds.size.height;
        
        // Only scroll if content is taller than visible area
        if (newContentHeight > newVisibleHeight) {
          NSLog(@"scrolling because newcontent height %f is higher than new visible height %f", newContentHeight, newVisibleHeight);
            UIEdgeInsets newInsets = self->_collectionView.contentInset;
            CGFloat newBottomOffset = newContentHeight + newInsets.bottom - newVisibleHeight;
            [self->_collectionView setContentOffset:CGPointMake(0, newBottomOffset) animated:YES];
        }
    }
  } else {
    _messages = std::move(newMessages);
  }

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
  const auto &msg = _messages[(size_t)indexPath.item];
  
  if (msg.isTypingIndicator) {
    RCTTypingIndicatorCell *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:@"RCTTypingIndicatorCell"
                                                  forIndexPath:indexPath];
    [cell configureWithIsUser:msg.isUser];
    [cell startAnimating];
    return cell;
  }
  
  RCTChatMessageCell *cell =
      [collectionView dequeueReusableCellWithReuseIdentifier:@"RCTChatMessageCell"
                                                forIndexPath:indexPath];

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
  const auto &msg = _messages[(size_t)indexPath.item];
    CGFloat contentWidth = collectionView.bounds.size.width;
    
  if (msg.isTypingIndicator) {
    CGFloat textHeight = [UIFont preferredFontForTextStyle:UIFontTextStyleBody].lineHeight;
    CGFloat cellHeight = ceil(textHeight) + 2 * 10.0 + 8.0;
    return CGSizeMake(contentWidth, cellHeight);
  }
    
    NSString *text = [NSString stringWithUTF8String:msg.text.c_str()];
    
    CGFloat maxBubbleWidth = contentWidth * 0.75;
    CGFloat labelPaddingHorizontal = 16.0;
    CGFloat labelPaddingVertical = 10.0;
    CGFloat maxLabelWidth = maxBubbleWidth - 2 * labelPaddingHorizontal;
    
    CGRect textRect = [text boundingRectWithSize:CGSizeMake(maxLabelWidth, CGFLOAT_MAX)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]}
                                         context:nil];
    
    CGFloat cellHeight = ceil(textRect.size.height) + 2 * labelPaddingVertical + 8;
    
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

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
  NSLog(@"willDisplayCell fired for index %ld", (long)indexPath.item);

    cell.alpha = 0;
    CGAffineTransform t = CGAffineTransformMakeScale(0.5, 0.5);
    AurenChatViewMessagesStruct message = _messages[indexPath.item];
  if (message.isUser) {
    cell.transform = CGAffineTransformConcat(t, CGAffineTransformMakeTranslation(-20, 0));
  } else {
    cell.transform = CGAffineTransformConcat(t, CGAffineTransformMakeTranslation(20, 0));
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    cell.alpha = 0;
      [UIView animateWithDuration:0.25
                            delay:0
                          options:UIViewAnimationOptionCurveEaseOut
                       animations:^{
          cell.alpha = 1;
        cell.transform = CGAffineTransformIdentity;
      } completion:^(BOOL finished) {
        NSLog(@"cell animation finished for index %ld", (long)indexPath.item);
    }];
  });
}

+(ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<AurenChatViewComponentDescriptor>();
}
@end
