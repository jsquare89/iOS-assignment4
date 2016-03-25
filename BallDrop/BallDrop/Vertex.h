//
//  Vertex.h
//  2
//
//  Created by Sean Wang on 2016-02-24.
//  Copyright © 2016 Sean Wang. All rights reserved.
//

#ifndef Vertex_h
#define Vertex_h

typedef enum {
    VertexAttribPosition = 0,
    VertexAttribColor,
    VertexAttribTexCoord,
    VertexAttribNormal
} VertexAttributes;

typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2];
    float Normal[3];
} Vertex;

#endif /* Vertex_h */
