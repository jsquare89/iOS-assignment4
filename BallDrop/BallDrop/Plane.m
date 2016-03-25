//
//  Plane.m
//  BallDrop
//
//  Created by Jarred Jardine on 2016-03-25.
//  Copyright © 2016 Jarred Jardine. All rights reserved.
//

#import "Plane.h"
#import "Model/Plane/plane.h"

@implementation Plane

- (instancetype)init{
    if ((self = [super initWithName:"plane" shader:nil vertices:(Vertex*)plane_Vertices vertexCount:sizeof(plane_Vertices) / sizeof(plane_Vertices[0])])) {
        
        self->worldPosition = GLKVector3Make(2, -4, 10);
        self->scale = GLKVector3Make(1, 1, 1);
        self->rotation = GLKVector3Make(1.5, 0, 0);
        
        // Specify Drawing Mode
        renderMode = GL_TRIANGLES;
 
    }
    return self;
}

-(void)updatePosition:(GLKVector3)position
{
    self->worldPosition = position;
}
@end
