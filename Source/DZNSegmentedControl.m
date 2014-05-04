//
//  DZNSegmentedControl.m
//  DZNSegmentedControl
//  https://github.com/dzenbot/DZNSegmentedControl
//
//  Created by Ignacio Romero Zurbuchen on 3/4/14.
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//  Licence: MIT-Licence
//

#import "DZNSegmentedControl.h"

@interface DZNSegmentedControl () {
    UIView* _selectionIndicator;
    UIView* _hairline;
    NSMutableDictionary* _colors;
    BOOL _isTransitioning;
    NSMutableArray* _buttons;
}

- (void)basicInit;

@end

@implementation DZNSegmentedControl

@synthesize barPosition = _barPosition;

- (void)basicInit {
    _selectedSegmentIndex = -1;
    _font = [UIFont systemFontOfSize:15.0];
    _selectionIndicatorHeight = 2.0;
    _animationDuration = 0.2;
    _showsCount = YES;
    _autoAdjustSelectionIndicatorWidth = YES;

    _selectionIndicator = [UIView new];
    _selectionIndicator.backgroundColor = self.tintColor;
    [self addSubview:_selectionIndicator];

    _hairline = [UIView new];
    _hairline.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:_hairline];

    _colors = [NSMutableDictionary new];

    _buttons = [@[] mutableCopy];
}

- (id)init {
    if (self = [super init]) {
        [self basicInit];
    }

    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self basicInit];
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self basicInit];
    }

    return self;
}

- (instancetype)initWithItems:(NSArray *)items {
    if (self = [self init]) {
        self.items = items;
    }
    return self;
}


#pragma mark - UIView Methods

- (void)sizeToFit {
    CGRect rect = self.frame;
    rect.size = [self sizeThatFits:rect.size];
    self.frame = rect;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self sizeToFit];

    if (_buttons.count == 0) {
        _selectedSegmentIndex = -1;
    }
    else if (_selectedSegmentIndex < 0) {
        _selectedSegmentIndex = 0;
    }

    const CGFloat width = CGRectGetWidth(self.bounds);

    for (NSUInteger i = 0; i < _buttons.count; ++i) {
        UIButton *button = _buttons[i];
        [button setFrame:CGRectMake(roundf(width / self.numberOfSegments) * i, 0, roundf(width / self.numberOfSegments), CGRectGetHeight(self.frame))];

        CGFloat topInset = (_barPosition > UIBarPositionBottom) ? -4.0 : 4.0;
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, topInset, 0)];

        if (i == _selectedSegmentIndex) {
            button.selected = YES;
        }
    }

    _selectionIndicator.frame = [self selectionIndicatorRect];
    _hairline.frame = [self hairlineRect];

    [self bringSubviewToFront:_selectionIndicator];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];

    [self layoutIfNeeded];
}

- (void)didMoveToWindow {
    if (!self.backgroundColor) {
        self.backgroundColor = [UIColor whiteColor];
    }

    [self configureAllSegments];

    [self layoutIfNeeded];
}


#pragma mark - Getter Methods

- (NSUInteger)numberOfSegments {
    return _items.count;
}

- (NSString *)stringForSegmentAtIndex:(NSUInteger)segment {
    UIButton *button = _buttons[segment];
    return [[button attributedTitleForState:UIControlStateNormal] string];
}

- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment {
    if (_showsCount) {
        NSString *title = [self stringForSegmentAtIndex:segment];
        NSArray *components = [title componentsSeparatedByString:@"\n"];

        if (components.count == 2) {
            return [components objectAtIndex:_inverseTitles ? 0 : 1];
        }
        else return nil;
    }
    return [_items objectAtIndex:segment];
}

- (NSNumber *)countForSegmentAtIndex:(NSUInteger)segment {
    NSString *title = [self stringForSegmentAtIndex:segment];
    NSArray *components = [title componentsSeparatedByString:@"\n"];

    if (components.count == 2) {
        return @([[components objectAtIndex:_inverseTitles ? 1 : 0] intValue]);
    }
    else return @0;
}

- (UIColor *)titleColorForState:(UIControlState)state {
    NSString *key = [NSString stringWithFormat:@"UIControlState%d", (int)state];
    UIColor *color = [_colors objectForKey:key];

    if (!color) {
        switch (state) {
            case UIControlStateNormal:              return [UIColor darkGrayColor];
            case UIControlStateHighlighted:         return self.tintColor;
            case UIControlStateDisabled:            return [UIColor lightGrayColor];
            case UIControlStateSelected:            return self.tintColor;
            default:                                return self.tintColor;
        }
    }

    return color;
}

- (CGRect)selectionIndicatorRect {
    CGRect frame = CGRectZero;

    if (_selectedSegmentIndex < 0) return frame;

    UIButton *button = _buttons[_selectedSegmentIndex];
    NSString *title = [self titleForSegmentAtIndex:_selectedSegmentIndex];

    if (title.length == 0) {
        return frame;
    }

    frame.origin.y = (_barPosition > UIBarPositionBottom) ? 0.0 : (button.frame.size.height-_selectionIndicatorHeight);

    if (_autoAdjustSelectionIndicatorWidth) {

        id attributes = nil;

        if (!_showsCount) {

            NSAttributedString *attributedString = [button attributedTitleForState:UIControlStateSelected];

            if (attributedString.string.length == 0) {
                return CGRectZero;
            }

            NSRangePointer range = nil;
            attributes = [attributedString attributesAtIndex:0 effectiveRange:range];
        }

        frame.size = CGSizeMake([title sizeWithAttributes:attributes].width, _selectionIndicatorHeight);
        frame.origin.x = (button.frame.size.width*(_selectedSegmentIndex))+(button.frame.size.width-frame.size.width)/2;
    }
    else {
        frame.size = CGSizeMake(button.frame.size.width, _selectionIndicatorHeight);
        frame.origin.x = (button.frame.size.width*(_selectedSegmentIndex));
    }

    return frame;
}

- (UIColor *)hairlineColor {
    return _hairline.backgroundColor;
}

- (CGRect)hairlineRect {
    CGRect frame = CGRectMake(0, 0, self.frame.size.width, 0.5);
    frame.origin.y = (_barPosition > UIBarPositionBottom) ? 0 : self.frame.size.height;

    return frame;
}


#pragma mark - Setter Methods

- (void)setTintColor:(UIColor *)color {
    [super setTintColor:color];

    [self setTitleColor:color forState:UIControlStateHighlighted];
    [self setTitleColor:color forState:UIControlStateSelected];
}

- (void)setItems:(NSArray *)items {
    if (_items) {
        [self removeAllSegments];
    }

    if (items) {
        _items = [items copy];

        for (NSUInteger i = 0; i < self.numberOfSegments; ++i) {
            [_buttons addObject:[self addButtonForSegment:i]];
        }
    }
}

- (void)setDelegate:(id<DZNSegmentedControlDelegate>)delegate {
    _delegate = delegate;
    _barPosition = [delegate positionForBar:self];
}

- (void)setSelectedSegmentIndex:(NSInteger)segment {
    if (segment > self.numberOfSegments - 1) {
        segment = 0;
    }

    [self setSelected:YES forSegmentAtIndex:segment];
}

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment {
    NSAssert(segment < self.numberOfSegments && segment >= 0, @"Cannot assign a title to non-existing segment.");

    NSMutableArray* mutableItems = [_items mutableCopy];
    [mutableItems replaceObjectAtIndex:segment withObject:title];

    _items = [mutableItems copy];

    if (_showsCount) {
        [self setCount:@(0) forSegmentAtIndex:segment];
    } else {
        [self setAttributedTitle:[[NSAttributedString alloc] initWithString:title] forSegmentAtIndex:segment];
    }
}

- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)segment {
    NSAssert(segment >= 0, @"Cannot assign a title to negative segment.");

    NSUInteger cntb4 = _items.count;

    NSMutableArray* mutableItems = [_items mutableCopy];

    NSUInteger insertIndex = segment;

    if (segment >= cntb4) {
        [mutableItems insertObject:title atIndex:cntb4];
        [_buttons addObject: [self addButtonForSegment:cntb4]];

        insertIndex = cntb4;
        _items = [mutableItems copy];
    } else {
        [mutableItems addObject:@0]; // dummy
        [_buttons addObject:@0]; // dummy

        NSInteger intSegment = segment;

        for (NSInteger s = cntb4 - 1; s >= intSegment; --s) {
            [_buttons replaceObjectAtIndex:s + 1 withObject:_buttons[s]];
            [mutableItems replaceObjectAtIndex:s + 1 withObject:mutableItems[s]];
        }

        [mutableItems replaceObjectAtIndex:segment withObject:title];
        [_buttons replaceObjectAtIndex:segment withObject:[self addButtonForSegment:segment]];

        _items = [mutableItems copy];

        if (_selectedSegmentIndex >= segment) {
            [self setSelectedSegmentIndex:_selectedSegmentIndex + 1];
        }
    }

    if (_showsCount) {
        [self setCount:@0 forSegmentAtIndex:insertIndex];
    } else {
        [self setAttributedTitle:[[NSAttributedString alloc] initWithString:title] forSegmentAtIndex:insertIndex];
    }

    [self layoutSubviews];
}

- (void)removeSegmentAtIndex:(NSUInteger)segment {
    NSAssert(segment < self.numberOfSegments && segment >= 0, @"Cannot remove non-existing segment. Number of segments: %@. Requested index for remove: %@", @(self.numberOfSegments), @(segment));

    NSUInteger cntb4 = _items.count;

    NSMutableArray* mutableItems = [_items mutableCopy];

    UIButton* button4Remove = _buttons[segment];

    if (segment != (cntb4 - 1)) { // not last
        for (NSUInteger s = segment; s < cntb4 - 1; ++s) {
            [_buttons replaceObjectAtIndex:s withObject:_buttons[s + 1]];
            [mutableItems replaceObjectAtIndex:s withObject:mutableItems[s + 1]];
        }
    }

    if (_selectedSegmentIndex > segment || _selectedSegmentIndex == segment) {
        [self setSelectedSegmentIndex:_selectedSegmentIndex - 1];
    }

    [button4Remove removeFromSuperview];

    [_buttons removeLastObject];
    [mutableItems removeLastObject];

    _items = [mutableItems copy];

    [self layoutSubviews];
}

- (void)setCount:(NSNumber *)count forSegmentAtIndex:(NSUInteger)segment {
    NSAssert(segment < self.numberOfSegments, @"Cannot assign a count to non-existing segment.");
    NSAssert(segment >= 0, @"Cannot assign a title to a negative segment.");

    NSString *title = _items[segment];

    if (_showsCount) {
        NSString *breakString = @"\n";
        NSString *resultString = _inverseTitles ? [breakString stringByAppendingString:count.stringValue] : [count.stringValue stringByAppendingString:breakString];

        title = _inverseTitles ? [title stringByAppendingString:resultString] : [resultString stringByAppendingString:title];
    }

    [self setAttributedTitle:[[NSAttributedString alloc] initWithString:title] forSegmentAtIndex:segment];
}

- (void)setAttributedTitle:(NSAttributedString *)attributedString forSegmentAtIndex:(NSUInteger)segment {
    UIButton *button = _buttons[segment];
    button.titleLabel.numberOfLines = (_showsCount) ? 2 : 1;

    [button setAttributedTitle:attributedString forState:UIControlStateNormal];
    [button setAttributedTitle:attributedString forState:UIControlStateHighlighted];
    [button setAttributedTitle:attributedString forState:UIControlStateSelected];
    [button setAttributedTitle:attributedString forState:UIControlStateDisabled];

    [self setTitleColor:[self titleColorForState:UIControlStateNormal] forState:UIControlStateNormal];
    [self setTitleColor:[self titleColorForState:UIControlStateHighlighted] forState:UIControlStateHighlighted];
    [self setTitleColor:[self titleColorForState:UIControlStateDisabled] forState:UIControlStateDisabled];
    [self setTitleColor:[self titleColorForState:UIControlStateSelected] forState:UIControlStateSelected];

    _selectionIndicator.frame = [self selectionIndicatorRect];
}

- (void)setTitleColor:(UIColor *)color forState:(UIControlState)state {
    NSAssert([color isKindOfClass:[UIColor class]], @"Cannot assign a title color with an unvalid color object.");

    for (UIButton *button in _buttons) {

        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[button attributedTitleForState:state]];
        NSString *string = attributedString.string;

        NSMutableParagraphStyle *style  = [[NSMutableParagraphStyle alloc] init];
        style.alignment = NSTextAlignmentCenter;
        style.lineBreakMode = (_showsCount) ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail;
        style.lineBreakMode = NSLineBreakByWordWrapping;
        style.minimumLineHeight = 16.0;

        [attributedString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, string.length)];

        if (_showsCount) {

            NSArray *components = [attributedString.string componentsSeparatedByString:@"\n"];

            if (components.count < 2) {
                return;
            }

            NSString *count = [components objectAtIndex:_inverseTitles ? 1 : 0];
            NSString *title = [components objectAtIndex:_inverseTitles ? 0 : 1];

            [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:_font.fontName size:19.0] range:[string rangeOfString:count]];
            [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:_font.fontName size:12.0] range:[string rangeOfString:title]];

            if (state == UIControlStateNormal) {

                UIColor *topColor = _inverseTitles ? [color colorWithAlphaComponent:0.5] : color;
                UIColor *bottomColor = _inverseTitles ? color : [color colorWithAlphaComponent:0.5];

                NSUInteger topLength = _inverseTitles ? title.length : count.length;
                NSUInteger bottomLength = _inverseTitles ? count.length : title.length;

                [attributedString addAttribute:NSForegroundColorAttributeName value:topColor range:NSMakeRange(0, topLength)];
                [attributedString addAttribute:NSForegroundColorAttributeName value:bottomColor range:NSMakeRange(topLength, bottomLength+1)];
            }
            else {
                [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, string.length)];

                if (state == UIControlStateSelected) {
                    _selectionIndicator.backgroundColor = color;
                }
            }
        } else {
            [attributedString addAttribute:NSFontAttributeName value:_font range:NSMakeRange(0, attributedString.string.length)];
            [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, attributedString.string.length)];
        }

        [button setAttributedTitle:attributedString forState:state];
    }

    NSString *key = [NSString stringWithFormat:@"UIControlState%d", (int)state];
    [_colors setObject:color forKey:key];
}

- (void)setSelected:(BOOL)selected forSegmentAtIndex:(NSUInteger)segment {
    if (_selectedSegmentIndex == segment || _isTransitioning) {
        return;
    }

    for (UIButton *_button in _buttons) {
        _button.highlighted = NO;
        _button.selected = NO;
        _button.userInteractionEnabled = YES;
    }

    CGFloat duration = (_selectedSegmentIndex < 0) ? 0.0 : _animationDuration;

    _selectedSegmentIndex = segment;
    _isTransitioning = YES;

    UIButton *button = _buttons[_selectedSegmentIndex];

    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _selectionIndicator.frame = [self selectionIndicatorRect];
                     }
                     completion:^(BOOL finished) {
                         button.userInteractionEnabled = NO;
                         _isTransitioning = NO;
                     }];

    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)setFont:(UIFont *)font {
    if ([_font.fontName isEqualToString:font.fontName]) {
        return;
    }

    _font = font;

    for (int i = 0; i < _buttons.count; i++) {
        [self configureButtonForSegment:i];
    }

    _selectionIndicator.frame = [self selectionIndicatorRect];
}

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment {
    [(UIButton*)_buttons[segment] setEnabled:enabled];
}

- (void)setHairlineColor:(UIColor *)color {
    _hairline.backgroundColor = color;
}


#pragma mark - DZNSegmentedControl Methods

- (UIButton*)addButtonForSegment:(NSUInteger)segment {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

    [button addTarget:self action:@selector(willSelectedButton:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(didSelectedButton:) forControlEvents:UIControlEventTouchDragOutside|UIControlEventTouchDragInside|UIControlEventTouchDragEnter|UIControlEventTouchDragExit|UIControlEventTouchCancel|UIControlEventTouchUpInside|UIControlEventTouchUpOutside];

    button.backgroundColor = nil;
    button.opaque = YES;
    button.clipsToBounds = YES;
    button.adjustsImageWhenHighlighted = NO;
    button.adjustsImageWhenDisabled = NO;
    button.exclusiveTouch = YES;

    [self addSubview:button];

    return button;
}

- (void)configureAllSegments {
    for (NSUInteger i = 0; i < _buttons.count; ++i) {
        NSAttributedString *attributedString = [(UIButton*)_buttons[i] attributedTitleForState:UIControlStateNormal];

        if (attributedString.string.length > 0) {
            continue;
        }

        [self configureButtonForSegment:i];
    }

    _selectionIndicator.frame = [self selectionIndicatorRect];
    _selectionIndicator.backgroundColor = self.tintColor;
}

- (void)configureButtonForSegment:(NSUInteger)segment {
    if (_showsCount) {
        [self setCount:[self countForSegmentAtIndex:segment] forSegmentAtIndex:segment];
    }
    else {
        [self setTitle:[_items objectAtIndex:segment] forSegmentAtIndex:segment];
    }
}

- (void)willSelectedButton:(UIButton*)button {
    if (_isTransitioning == NO) {
        self.selectedSegmentIndex = [_buttons indexOfObject:button];
    }
}

- (void)didSelectedButton:(UIButton*)button {
    button.highlighted = NO;
    button.selected = YES;
}

- (void)removeAllSegments {
    if (_isTransitioning) {
        return;
    }

    for (UIButton *_button in _buttons) {
        [_button removeFromSuperview];
    }

    [_buttons removeAllObjects];

    _items = nil;
}

@end
