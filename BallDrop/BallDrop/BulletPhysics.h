//
//  BulletPhysics.h
//  BulletTest
//
//  Created by Borna Noureddin on 2015-03-20.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Ball.h"
#import "Plane.h"

@interface BulletPhysics: NSObject
- (instancetype)initWithBall:(Ball*)ball Plane:(Plane*)plane;
-(void)Update:(float)elapsedTime Ball:(Ball*)ball;

@end
