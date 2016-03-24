//
//  Shader.fsh
//  Pong
//
//  Created by Jarred Jardine on 2016-03-24.
//  Copyright © 2016 Jarred Jardine. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
