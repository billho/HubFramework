#import <XCTest/XCTest.h>

#import "HUBComponentImageDataBuilderImplementation.h"
#import "HUBComponentImageDataImplementation.h"
#import "HUBJSONSchemaImplementation.h"
#import "HUBComponentImageDataJSONSchema.h"
#import "HUBComponentDefaults+Testing.h"
#import "HUBIconImageResolverMock.h"
#import "HUBIcon.h"

@interface HUBComponentImageDataBuilderTests : XCTestCase

@property (nonatomic, strong) HUBComponentImageDataBuilderImplementation *builder;
@property (nonatomic, strong) HUBJSONSchemaImplementation *schema;

@end

@implementation HUBComponentImageDataBuilderTests

#pragma mark - XCTestCase

- (void)setUp
{
    [super setUp];
    
    HUBComponentDefaults * const componentDefaults = [HUBComponentDefaults defaultsForTesting];
    id<HUBIconImageResolver> const iconImageResolver = [HUBIconImageResolverMock new];
    id<HUBJSONSchema> const JSONSchema = [[HUBJSONSchemaImplementation alloc] initWithComponentDefaults:componentDefaults
                                                                                      iconImageResolver:iconImageResolver];
    
    self.builder = [[HUBComponentImageDataBuilderImplementation alloc] initWithJSONSchema:JSONSchema iconImageResolver:iconImageResolver];
}

#pragma mark - Tests

- (void)testPropertyAssignment
{
    self.builder.style = HUBComponentImageStyleCircular;
    self.builder.URL = [NSURL URLWithString:@"cdn.spotify.com/hub"];
    self.builder.localImage = [UIImage new];
    self.builder.placeholderIconIdentifier = @"placeholder";
    
    NSString * const identifier = @"identifier";
    HUBComponentImageType const type = HUBComponentImageTypeCustom;
    
    HUBComponentImageDataImplementation * const imageData = [self.builder buildWithIdentifier:identifier type:type];
    
    XCTAssertEqual(imageData.identifier, identifier);
    XCTAssertEqual(imageData.type, type);
    XCTAssertEqual(imageData.style, self.builder.style);
    XCTAssertEqualObjects(imageData.URL, self.builder.URL);
    XCTAssertEqual(imageData.localImage, self.builder.localImage);
    XCTAssertEqualObjects(imageData.placeholderIcon.identifier, @"placeholder");
}

- (void)testEmptyBuilderProducingNil
{
    XCTAssertNil([self.builder buildWithIdentifier:nil type:HUBComponentImageTypeMain]);
}

- (void)testOnlyURLNotProducingNil
{
    self.builder.URL = [NSURL URLWithString:@"cdn.spotify.com/hub"];
    XCTAssertNotNil([self.builder buildWithIdentifier:nil type:HUBComponentImageTypeMain]);
}

- (void)testLocalImageOnlyNotProducingNil
{
    self.builder.localImage = [UIImage new];
    XCTAssertNotNil([self.builder buildWithIdentifier:nil type:HUBComponentImageTypeMain]);
}

- (void)testOnlyPlaceholderIconIdentifierNotProducingNil
{
    self.builder.placeholderIconIdentifier = @"placeholder";
    XCTAssertNotNil([self.builder buildWithIdentifier:nil type:HUBComponentImageTypeMain]);
}

- (void)testNilIconImageResolverAlwaysResultingInNilPlaceholderIcon
{
    HUBComponentDefaults * const componentDefaults = [HUBComponentDefaults defaultsForTesting];
    id<HUBJSONSchema> const JSONSchema = [[HUBJSONSchemaImplementation alloc] initWithComponentDefaults:componentDefaults
                                                                                      iconImageResolver:nil];
    
    self.builder = [[HUBComponentImageDataBuilderImplementation alloc] initWithJSONSchema:JSONSchema iconImageResolver:nil];
    self.builder.placeholderIconIdentifier = @"placeholder";
    
    // Since icon is now nil, the builder itself should also return nil (since it doesn't contain any other data)
    XCTAssertNil([self.builder buildWithIdentifier:nil type:HUBComponentImageTypeMain]);
    
    self.builder.localImage = [UIImage new];
    HUBComponentImageDataImplementation * const imageData = [self.builder buildWithIdentifier:nil type:HUBComponentImageTypeMain];
    XCTAssertNotNil(imageData);
    XCTAssertNil(imageData.placeholderIcon);
}

- (void)testAddingJSONData
{
    NSURL * const imageURL = [NSURL URLWithString:@"http://cdn.spotify.com/image"];
    
    NSDictionary * const dictionary = @{
        @"style": @"circular",
        @"uri": imageURL.absoluteString,
        @"placeholder": @"place_holder"
    };
    
    [self.builder addDataFromJSONDictionary:dictionary];
    
    XCTAssertEqual(self.builder.style, HUBComponentImageStyleCircular);
    XCTAssertEqualObjects(self.builder.URL, imageURL);
    XCTAssertEqualObjects(self.builder.placeholderIconIdentifier, @"place_holder");
}

- (void)testAddingNonDictionaryJSONDataReturnsError
{
    NSData * const stringData = [@"Not a dictionary" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNotNil([self.builder addJSONData:stringData]);
    
    NSData * const arrayData = [NSJSONSerialization dataWithJSONObject:@[] options:(NSJSONWritingOptions)0 error:nil];
    XCTAssertNotNil([self.builder addJSONData:arrayData]);
}

- (void)testInvalidImageStyleStringProducingRectangularStyle
{
    [self.builder addDataFromJSONDictionary:@{}];
    XCTAssertEqual(self.builder.style, HUBComponentImageStyleRectangular);
    
    [self.builder addDataFromJSONDictionary:@{@"style" : @"invalid"}];
    XCTAssertEqual(self.builder.style, HUBComponentImageStyleRectangular);
}

- (void)testProtectionAgainstInvalidImageStyleEnumValues
{
    self.schema.componentImageDataSchema.styleStringMap = @{@"invalid": @(99)};
    [self.builder addDataFromJSONDictionary:@{@"style" : @"invalid"}];
    XCTAssertEqual(self.builder.style, HUBComponentImageStyleRectangular);
}

- (void)testCopying
{
    UIImage * const localImage = [UIImage new];
    
    self.builder.style = HUBComponentImageStyleCircular;
    self.builder.URL = [NSURL URLWithString:@"cdn.spotify.com/hub"];
    self.builder.localImage = localImage;
    self.builder.placeholderIconIdentifier = @"placeholder";
    
    HUBComponentImageDataBuilderImplementation * const builderCopy = [self.builder copy];
    XCTAssertNotEqual(self.builder, builderCopy);
    
    XCTAssertEqual(builderCopy.style, HUBComponentImageStyleCircular);
    XCTAssertEqualObjects(builderCopy.URL, [NSURL URLWithString:@"cdn.spotify.com/hub"]);
    XCTAssertEqualObjects(builderCopy.localImage, localImage);
    XCTAssertEqualObjects(builderCopy.placeholderIconIdentifier, @"placeholder");
}

@end
