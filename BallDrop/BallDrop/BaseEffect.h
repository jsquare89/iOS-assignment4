//
//  BaseEffect.h
//  2
//
//  Created by Sean Wang on 2016-02-24.
//  Copyright © 2016 Sean Wang. All rights reserved.
//

#ifndef BaseEffect_h
#define BaseEffect_h

#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>
#import "GameObject3D.h"
#import "Camera.h"
#import <OpenGLES/ES2/glext.h>

@interface BaseEffect : NSObject
{
    // Uniform index.
    enum
    {
        UNIFORM_MODELVIEWPROJECTION_MATRIX,
        UNIFORM_NORMAL_MATRIX,
        UNIFORM_TEXTURE,
        UNIFORM_DIFFUSE_COLOR,
        UNIFORM_PLAYER_POSITION,
        NUM_UNIFORMS
    };
    
@public GLuint _program;
@public Camera* camera;
@public GLKMatrix4 projectionMatrix;
@public bool isDay;
    
@private GLint uniforms[NUM_UNIFORMS];
@private GLint texCoordBuffer;
}


- (id)init;

- (void)toggleDayNight:(id)sender;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

- (void)clear;
- (void)render:(GameObject3D*)gameObject3D;

- (void)tearDown;

@end


#endif /* BaseEffect_h */
