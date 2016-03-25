//
//  Camera.m
//  2
//
//  Created by Sean Wang on 2016-03-04.
//  Copyright © 2016 Sean Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Camera.h"

@implementation Camera

- (id)initUsing:(GLKView*)view
{
    self = [super init];
    
    if (self)
    {
        m_View = view;
        
        position = GLKVector3Make(0, 0, 5);
        rotation = GLKVector3Make(0, M_PI, 0);
        rotMat = GLKMatrix4Identity;
    }
    
    return self;
}

- (void)Translate:(id)sender
{
    UIPanGestureRecognizer* panGes = (UIPanGestureRecognizer*)sender;
    
    if ([panGes state] == UIGestureRecognizerStateBegan)
    {
        touchStartPosition = position;
    }
    if ([panGes state] == UIGestureRecognizerStateChanged)
    {
        CGPoint translatePoint = [(UIPanGestureRecognizer *)sender translationInView:m_View];
        
        GLKVector3 forwardTranslation = GLKVector3MultiplyScalar([self GetForward], translatePoint.y / 100.0f);
        forwardTranslation.y = 0;
        
        GLKVector3 rightTranslation = GLKVector3MultiplyScalar([self GetRight], -translatePoint.x / 100.0f);
        rightTranslation.y = 0;
        
        position = GLKVector3Add(touchStartPosition, GLKVector3Add(forwardTranslation, rightTranslation));
    }
}

- (void)Rotate:(id)sender
{
    UIPanGestureRecognizer* panGes = (UIPanGestureRecognizer*)sender;
    
    if ([panGes state] == UIGestureRecognizerStateBegan)
    {
        touchStartRotation = rotation;
    }
    
    if ([panGes state] == UIGestureRecognizerStateChanged)
    {
        CGPoint translatePoint = [(UIPanGestureRecognizer *)sender translationInView:m_View];
        rotation.y = touchStartRotation.y + GLKMathDegreesToRadians(translatePoint.x / 4.0);
        rotation.x = touchStartRotation.x + GLKMathDegreesToRadians(translatePoint.y / 4.0);
    }
}

- (void)Reset:(id)sender
{
    position = GLKVector3Make(0, 0, 0);
    rotation = GLKVector3Make(0, M_PI, 0);
    rotMat = GLKMatrix4Identity;
}

- (GLKMatrix4)GetViewMatrix
{
    GLKMatrix4 viewMatrix = GLKMatrix4Identity;
    
    viewMatrix = GLKMatrix4Multiply(viewMatrix, [self GetRotationMatrix]);
    viewMatrix = GLKMatrix4Multiply(viewMatrix, GLKMatrix4MakeTranslation(position.x, position.y, position.z));
    
    return viewMatrix;
}

- (GLKMatrix4)GetRotationMatrix
{
    bool isInvertible;
    
    rotMat = GLKMatrix4Identity;
    
    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(rotMat, &isInvertible), GLKVector3Make(1, 0, 0));
    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(rotMat, &isInvertible), GLKVector3Make(0, 1, 0));
    
    rotMat = GLKMatrix4Rotate(rotMat, rotation.x, xAxis.x, xAxis.y, xAxis.z);
    rotMat = GLKMatrix4Rotate(rotMat, rotation.y, yAxis.x, yAxis.y, yAxis.z);
    
    return rotMat;
}

- (GLKVector3)GetForward
{
    GLKMatrix4 viewMat = [self GetViewMatrix];
    
    GLKVector3 forward = GLKVector3Make(viewMat.m02, viewMat.m12, viewMat.m22);
    return GLKVector3Normalize(forward);
}

- (GLKVector3)GetRight
{
    GLKMatrix4 viewMat = [self GetViewMatrix];
    
    GLKVector3 right = GLKVector3Make(viewMat.m00, viewMat.m10, viewMat.m20);
    return GLKVector3Normalize(right);
}

@end