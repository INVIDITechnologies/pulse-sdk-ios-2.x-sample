//
//  PassView.m
//  PulsePlayer
//
//  Created by Jacques du Toit on 28/06/16.
//  Copyright © 2016 Ooyala. All rights reserved.
//

#import "PassView.h"

@implementation PassView

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
  for (UIView *view in self.subviews) {
    if (!view.hidden
        && view.alpha > 0
        && view.userInteractionEnabled
        && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
      return YES;
  }
  return NO;
}
@end
