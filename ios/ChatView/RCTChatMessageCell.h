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
@property (nonatomic, strong) NSLayoutConstraint *topConstraint;
@property (nonatomic, strong) UIImageView *readReceiptImageView;
@property (nonatomic, strong) NSLayoutConstraint *labelTrailingConstraint;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;


- (void)configureWithText:(NSString *)text isUser:(BOOL)isUser sameAsPrevious:(BOOL)sameAsPrevious readByCharacterAt:(double)readByCharacterAt gradientStart:(UIColor*)gradientStart gradientEnd:(UIColor*)gradientEnd;

@end

NS_ASSUME_NONNULL_END

#endif // !RCTChatMessageCell_h
