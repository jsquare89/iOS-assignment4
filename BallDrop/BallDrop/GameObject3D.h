//
//  3DGameObject.h
//  Crescendo
//
//  Created by Sean Wang on 2016-02-11.
//  Copyright © 2016 Equalizer. All rights reserved.
//

#ifndef GameObject3D_h
#define GameObject3D_h

#import <Foundation/Foundation.h>
#import "Vertex.h"

@class BaseEffect;
#import <GLKit/GLKit.h>

@interface GameObject3D : NSObject
{
@public GLKVector3 worldPosition;
@public GLKVector3 rotation;
@public GLKVector3 scale;
@private GLKMatrix4 rotMat;
@public GLuint vao;
@public unsigned int vertexCount;
@public NSMutableArray* children;
@public GLuint texture;
@public GLenum renderMode;  // Determines how object is rendered.
@public GLfloat lineWidth;  // Only used for GL_LINES rendering mode.
    
@public GLKVector3 endPointLeft;
@public GLKVector3 endPointRight;
@public GLKVector3 normal;
@public GLKVector3 center;
}

- (instancetype)initWithName:(char *)name shader:(BaseEffect *)shader vertices:(Vertex *)vertices vertexCount:(unsigned int)vertexCount;
- (void)CleanUp;

-(GLKVector3)GetUp;
-(GLKVector3)GetRight;
-(GLKVector3)GetForward;
-(GLKVector3)GetPosition;

- (void)updateTime:(float)deltaTime;

- (void)loadTexture:(NSString *)filename;

-(GLKMatrix4)GetModelViewMatrix;
-(GLKMatrix4)GetTranslationMatrix;
-(GLKMatrix4)GetRotationMatrix;
-(GLKMatrix4)GetScaleMatrix;

- (void)updateWallCollisionInfo;

@end

#endif