//
//  DZNSegmentedControl.m
//  DZNSegmentedControl
//
//  Created by Ignacio Romero Zurbuchen on 3/4/14.
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//  Licence: MIT-Licence
//

#import "DZNSegmentedControl.h"

@interface DZNSegmentedControl ()
@property (nonatomic, strong) UIView *selectionIndicator;
@property (nonatomic, strong) UIView *hairline;
@property (nonatomic, getter = isTransitioning) BOOL transitioning;
@end

@implementation DZNSegmentedControl
@synthesize items = _items;
@synthesize selectedSegmentIndex = _selectedSegmentIndex;
@synthesize barPosition = _barPosition;
@synthesize font = _font;

- (id)initWithItems:(NSArray *)items
{
    if (self = [super init]) {
        
        _selectedSegmentIndex = -1;
        _font = [UIFont fontWithName:@"HelveticaNeue" size:1];
        _height = 56.0;
        _selectionIndicatorHeight = 2.0;
        _animationDuration = 0.2;
        
        self.items = items;
    }
    return self;
}


#pragma mark - UIView Methods

- (CGSize)sizeThatFits:(CGSize)size
{
    return CGSizeMake(self.superview.frame.size.width, _height);
}

- (void)sizeToFit
{
    CGRect rect = self.frame;
    rect.size = [self sizeThatFits:rect.size];
    self.frame = rect;
}

- (void)didMoveToWindow
{
    [self sizeToFit];
    
    for (int i = 0; i < [self buttons].count; i++) {
        UIButton *button = [[self buttons] objectAtIndex:i];
        [button setFrame:CGRectMake(roundf(self.frame.size.width/self.numberOfSegments)*i, 0, roundf(self.frame.size.width/self.numberOfSegments), self.frame.size.height)];
    }
    
    if (_selectedSegmentIndex < 0) {
        self.selectedSegmentIndex = 0;
    }
    
    self.selectionIndicator.frame = [self selectionIndicatorRect];
    
    CGRect frame = CGRectMake(0, 0, self.frame.size.width, 0.5);
    frame.origin.y = (_barPosition > UIBarPositionBottom) ? 0 : self.frame.size.height;
    _hairline.frame = frame;
    
    for (UIButton *button in self.buttons) {
        CGFloat topInset = (_barPosition > UIBarPositionBottom) ? -4.0 : 4.0;
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, topInset, 0)];
    }
}


#pragma mark - Getter Methods

- (NSUInteger)numberOfSegments
{
    return _items.count;
}

- (NSArray *)buttons
{
    NSMutableArray *buttons = [NSMutableArray new];
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            [buttons addObject:view];
        }
    }
    return buttons;
}

- (UIButton *)buttonAtIndex:(NSUInteger)segment
{
    return (UIButton *)[[self buttons] objectAtIndex:segment];
}

- (UIButton *)selectedButton
{
    if (_selectedSegmentIndex >= 0) {
        return [self buttonAtIndex:_selectedSegmentIndex];
    }
    return nil;
}

- (NSString *)stringForSegmentAtIndex:(NSUInteger)segment
{
    UIButton *button = [self buttonAtIndex:segment];
    return [[button attributedTitleForState:UIControlStateNormal] string];
}

- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment
{
    NSString *title = [self stringForSegmentAtIndex:segment];
    NSArray *components = [title componentsSeparatedByString:@"\n"];
    return [components objectAtIndex:1];
}

- (NSNumber *)countForSegmentAtIndex:(NSUInteger)segment
{
    NSString *title = [self stringForSegmentAtIndex:segment];
    NSArray *components = [title componentsSeparatedByString:@"\n"];
    return @([[components firstObject] intValue]);
}

- (CGRect)selectionIndicatorRect
{
    UIButton *button = [self selectedButton];
    NSString *title = [self titleForSegmentAtIndex:button.tag];
    
    CGRect frame = self.selectionIndicator.frame;
    frame.size = CGSizeMake([title sizeWithAttributes:nil].width, _selectionIndicatorHeight);
    frame.origin.x = (button.frame.size.width*(_selectedSegmentIndex))+(button.frame.size.width-frame.size.width)/2;
    frame.origin.y = (_barPosition > UIBarPositionBottom) ? 0.0 : (button.frame.size.height-frame.size.height);
    
    return frame;
}


#pragma mark - Setter Methods

- (void)setItems:(NSArray *)items
{
    if (_items) {
        [self removeAllSegments];
        [self setItems:nil];
    }
    
    _items = [NSArray arrayWithArray:items];
    [self configure];
}

- (void)setDelegate:(id<DZNSegmentedControlDelegate>)delegate
{
    _delegate = delegate;
    _barPosition = [delegate positionForBar:self];
}

- (void)setSelectedSegmentIndex:(NSInteger)segment
{
    if (segment > self.numberOfSegments-1) {
        segment = 0;
    }
    
    [self setSelected:YES forSegmentAtIndex:segment];
    
    UIButton *button = [self buttonAtIndex:segment];
    button.highlighted = YES;
}

- (void)setTintColor:(UIColor *)color
{
    if (!color) {
        return;
    }
    
    [super setTintColor:color];
    
    [self setTitleColor:color forState:UIControlStateHighlighted];
    [self setTitleColor:color forState:UIControlStateSelected];
    [self.selectionIndicator setBackgroundColor:color];
}

- (void)setCount:(NSNumber *)count forSegmentAtIndex:(NSUInteger)segment
{
    if (!count) {
        return;
    }
    
    NSAssert(segment < self.items.count, @"Cannot assign a count to non-existing segment.");
    
    NSString *title = [NSString stringWithFormat:@"%@\n%@", count ,[_items objectAtIndex:segment]];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:title];
    [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:_font.fontName size:19.0] range:[title rangeOfString:[count stringValue]]];
    
    UIButton *button = [self buttonAtIndex:segment];
    [button setAttributedTitle:string forState:UIControlStateNormal];
    [button setAttributedTitle:string forState:UIControlStateHighlighted];
    [button setAttributedTitle:string forState:UIControlStateSelected];
    [button setAttributedTitle:string forState:UIControlStateDisabled];
    
    [self setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self setTitleColor:self.tintColor forState:UIControlStateHighlighted];
    [self setTitleColor:self.tintColor forState:UIControlStateSelected];
    [self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
}

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state
{
    for (UIButton *button in [self buttons]) {
        
        
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[button attributedTitleForState:state]];
        
        NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
        style.alignment = NSTextAlignmentCenter;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        style.minimumLineHeight = 16.0;
        
        [attributedString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, attributedString.string.length)];
        
        if (state == UIControlStateNormal) {
            
            NSArray *components = [attributedString.string componentsSeparatedByString:@"\n"];
            NSString *count = [components objectAtIndex:0];
            NSString *title = [components objectAtIndex:1];
            
            [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, count.length)];
            [attributedString addAttribute:NSForegroundColorAttributeName value:[color colorWithAlphaComponent:0.5] range:NSMakeRange(count.length, title.length+1)];
        }
        else {
            [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, attributedString.string.length)];
        }
        
        [button setAttributedTitle:attributedString forState:state];
    }
}

- (void)setSelected:(BOOL)selected forSegmentAtIndex:(NSUInteger)segment
{
    for (UIButton *_button in [self buttons]) {
        _button.highlighted = NO;
        _button.selected = NO;
        _button.userInteractionEnabled = YES;
    }
    
    if (_selectedSegmentIndex == segment || self.isTransitioning) {
        return;
    }
    
    _selectedSegmentIndex = segment;
    _transitioning = YES;
    
    UIButton *button = [self buttonAtIndex:segment];
    CGFloat duration = CGRectEqualToRect(self.selectionIndicator.frame, CGRectZero) ? 0.0 : _animationDuration;
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.selectionIndicator.frame = [self selectionIndicatorRect];
                     }
                     completion:^(BOOL finished) {
                         button.userInteractionEnabled = NO;
                         self.transitioning = NO;
                     }];
    
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment
{
    UIButton *button = [self buttonAtIndex:segment];
    button.enabled = enabled;
}


#pragma mark - DZNSegmentedControl Methods

- (void)configure
{
    self.backgroundColor = [UIColor whiteColor];
    
    for (int i = 0; i < self.numberOfSegments; i++) {
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [button setTitle:[self.items objectAtIndex:i] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(willSelectedButton:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(didSelectedButton:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
        
        button.backgroundColor = self.backgroundColor;
        button.titleLabel.font = [UIFont fontWithName:_font.fontName size:12.0];
        button.titleLabel.numberOfLines = 2;
        button.tag = i;
        
        [self addSubview:button];
        
        [self setCount:@(0) forSegmentAtIndex:i];
    }
    
    self.selectionIndicator = [UIView new];
    [self addSubview:self.selectionIndicator];
    
    _hairline = [UIView new];
    _hairline.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:_hairline];
}

- (void)willSelectedButton:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    if (!self.isTransitioning) {
        self.selectedSegmentIndex = button.tag;
    }
}

- (void)didSelectedButton:(id)sender
{
    UIButton *button = (UIButton *)sender;
    
    if (button.tag != _selectedSegmentIndex) {
        return;
    }
    
    if (!button.selected && self.isTransitioning) {
        button.selected = YES;
    }
}

- (void)removeAllSegments
{
    if (self.isTransitioning) {
        return;
    }
    
    for (UIButton *_button in [self buttons]) {
        [_button removeFromSuperview];
    }
    
    _selectedSegmentIndex = -1;
}

@end