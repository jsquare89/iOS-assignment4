//
//  Camera.h
//  2
//
//  Created by Sean Wang on 2016-03-04.
//  Copyright © 2016 Sean Wang. All rights reserved.
//

#ifndef Camera_h
#define Camera_h

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface Camera : NSObject
{
@public GLKVector3 position;
@public GLKVector3 rotation;
    
@private GLKMatrix4 rotMat;
@private GLKView* m_View;
    
@private GLKVector3 touchStartPosition;
@private GLKVector3 touchStartRotation;
}

- (id)initUsing: (GLKView*)view;

- (void)Translate:(id)sender;
- (void)Rotate:(id)sender;
- (void)Reset:(id)sender;

- (GLKMatrix4)GetViewMatrix;
- (GLKMatrix4)GetRotationMatrix;

- (GLKVector3)GetForward;
- (GLKVector3)GetRight;

@end

#endif /* Camera_h */
