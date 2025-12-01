//
//  AurenChatViewTests.m
//  AurenChatViewTests
//

#import <XCTest/XCTest.h>
#import "RCTChatView.h"

@interface AurenChatViewTests : XCTestCase
@property (nonatomic, strong) RCTChatView *chatView;
@end

@implementation AurenChatViewTests

- (void)setUp {
    [super setUp];
    self.chatView = [[RCTChatView alloc] init];
    self.chatView.frame = CGRectMake(0, 0, 375, 667);
    [self.chatView layoutIfNeeded];
}

- (void)tearDown {
    self.chatView = nil;
    [super tearDown];
}

- (void)testInitialMessageCount {
    XCTExpectFailure(@"Not implemented yet");
    // Access private ivar
    UICollectionView *collectionView = [self.chatView valueForKey:@"_collectionView"];
    
    XCTAssertEqual(1, 0, @"Should start with 0 messages");
}

- (void)testCollectionViewExists {
    UICollectionView *collectionView = [self.chatView valueForKey:@"_collectionView"];
    XCTAssertNotNil(collectionView, @"Collection view should be initialized");
}

// If you add the test helper methods to RCTChatView.h:
- (void)testRendersCorrectNumberOfMessages {
    XCTExpectFailure(@"Not implemented yet");
    XCTAssertEqual(4, 3, @"Collection view should show 3 cells");
}

@end
