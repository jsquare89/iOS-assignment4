//
//  Ball.m
//  BallDrop
//
//  Created by Jarred Jardine on 2016-03-25.
//  Copyright © 2016 Jarred Jardine. All rights reserved.
//

#import "Ball.h"
#import "Model/Sphere/sphere.h"

@implementation Ball

- (instancetype)init{
    if ((self = [super initWithName:"ball" shader:nil vertices:(Vertex*)sphere_Vertices vertexCount:sizeof(sphere_Vertices) / sizeof(sphere_Vertices[0])])) {
        
        self->worldPosition = GLKVector3Make(2, 7, 10);
        self->scale = GLKVector3Make(1, 1, 1);
        
        // Specify Drawing Mode
        renderMode = GL_TRIANGLES;
        


        
    }
    return self;
}

-(void)UpdatePositionFall:(float)y
{
    self->worldPosition.y = y;
}

@end
