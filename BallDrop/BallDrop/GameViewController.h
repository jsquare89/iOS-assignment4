//
//  GameViewController.h
//  BallDrop
//
//  Created by Jarred Jardine on 2016-03-24.
//  Copyright © 2016 Jarred Jardine. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "BaseEffect.h"
#import "Ball.h"
#import "Camera.h"


@interface GameViewController : GLKViewController
{
    @private BaseEffect* shader;
}

@end
