//
//  Shader.vsh
//  Breakout
//
//  Created by Jarred Jardine on 2016-03-25.
//  Copyright © 2016 Jarred Jardine. All rights reserved.
//

attribute vec4 position;
attribute vec4 inColor;

varying lowp vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;

void main()
{
    colorVarying = inColor;
    
    gl_Position = modelViewProjectionMatrix * position;
}
