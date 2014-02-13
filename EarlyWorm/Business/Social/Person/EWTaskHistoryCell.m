//
//  EWTaskHistoryCell.m
//  EarlyWorm
//
//  Created by Lei on 2/9/14.
//  Copyright (c) 2014 Shens. All rights reserved.
//

#import "EWTaskHistoryCell.h"

@implementation EWTaskHistoryCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)drawRect:(CGRect)rect{
    // Get the contextRef
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    
    CGFloat r = 20;
    CGRect bounds = self.bounds;
    CGPoint center;
    center.x = bounds.origin.x + bounds.size.width / 2.0;
    center.y = bounds.origin.y + bounds.size.height /2.0;
    CGRect frame = CGRectMake(center.x - r, center.y - r, 2*r, 2*r);

    //Draw a circle
    
    // Set the border width
    CGContextSetLineWidth(contextRef, 1.0);
    
    // Set the circle fill color to GREEN
    CGContextSetRGBFillColor(contextRef, 1.0, 1.0, 1.0, 0.3);
    
    // Set the cicle border color to BLUE
    CGContextSetRGBStrokeColor(contextRef, 1.0, 1.0, 1.0, 0.4);
    
    // Fill the circle with the fill color
    CGContextFillEllipseInRect(contextRef, frame);
    
    // Draw the circle border
    CGContextStrokeEllipseInRect(contextRef, frame);
    
    //draw the dotted line
    
    // Set the cicle border color to BLUE
    CGContextSetRGBStrokeColor(contextRef, 1.0, 1.0, 1.0, 0.7);
    
    CGFloat pattern[2] = {2.0, 4.0};
    CGContextSetLineDash(contextRef, 0, pattern, 2);
    CGContextMoveToPoint(contextRef, center.x, 0.0);
	CGContextAddLineToPoint(contextRef, center.x, center.y - r);
    CGContextMoveToPoint(contextRef, center.x, center.y + r +1);
	CGContextAddLineToPoint(contextRef, center.x, self.bounds.size.height);
    
    //draw
    CGContextStrokePath(contextRef);
}

@end
