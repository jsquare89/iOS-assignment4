//
//  CBox2D.h
//  MyGLGame
//
//  Created by Borna Noureddin on 2015-03-17.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#ifndef MyGLGame_CBox2D_h
#define MyGLGame_CBox2D_h


#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

enum
{
    VertexAttribPosition,
    VertexAttribColor,
    NumVertexAttribs
};

@interface CBox2D : NSObject 

-(void) LaunchBall;
-(void) Update:(float)elapsedTime;
-(void) Render:(int)mvpMatPtr;
-(void)RegisterHit:(int)brickCount;

-(void)movePaddle:(CGPoint)pos;




@end

#endif
