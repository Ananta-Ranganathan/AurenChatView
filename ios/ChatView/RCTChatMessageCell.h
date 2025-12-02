//
//  RCTChatMessageCell.h
//  AurenChatView
//
//  Created by Ananta Ranganathan on 12/2/25.
//

#ifndef RCTChatMessageCell_h
#define RCTChatMessageCell_h

#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCTChatMessageCell : UICollectionViewCell <UIContextMenuInteractionDelegate>

@property(nonatomic, strong) UIView *bubbleView;
@property(nonatomic, strong) UILabel *label;
@property(nonatomic, strong) NSLayoutConstraint *leadingConstraint;
@property(nonatomic, strong) NSLayoutConstraint *trailingConstraint;
@property(nonatomic, strong) NSLayoutConstraint *maxWidthConstraint;

- (void)configureWithText:(NSString *)text isUser:(BOOL)isUser;

@end

NS_ASSUME_NONNULL_END

#endif // !RCTChatMessageCell_h
