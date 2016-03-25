//
//  BaseEffect.m
//  2
//
//  Created by Sean Wang on 2016-02-24.
//  Copyright © 2016 Sean Wang. All rights reserved.
//

#import "BaseEffect.h"
#import "Vertex.h"

@implementation BaseEffect

- (id)init
{
    self = [super init];
    
    if (self)
    {
        isDay = true;
        
        [self loadShaders];
    }
    
    return self;
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, VertexAttribPosition, "position");
    glBindAttribLocation(_program, VertexAttribColor, "color");
    glBindAttribLocation(_program, VertexAttribTexCoord, "TexCoordIn");
    glBindAttribLocation(_program, VertexAttribNormal, "normal");

    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(_program, "Texture");
    uniforms[UNIFORM_DIFFUSE_COLOR] = glGetUniformLocation(_program, "diffuseColor");
    uniforms[UNIFORM_PLAYER_POSITION] = glGetUniformLocation(_program, "playerPosition");
    
    // Fail Case: Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (void)clear
{
    if (isDay)
    {
        glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    }
    else
    {
        glClearColor(0, 0, 0.1f, 1.0f);
    }
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glEnable(GL_BLEND);
}

- (void)render:(GameObject3D*)gameObject3D
{
    GLKMatrix4 cameraViewMatrix = GLKMatrix4Identity;
    
    //GLKMatrix4 cameraViewMatrix = GLKMatrix4MakeRotation(M_PI_2, 1, 0, 0);
    //cameraViewMatrix = GLKMatrix4Multiply(cameraViewMatrix, GLKMatrix4MakeTranslation(-2.0f, -5.0f, -2.0f));
    //cameraViewMatrix = GLKMatrix4Rotate(cameraViewMatrix, 0, 0.0f, 0.0f, 0.0f);
    
    cameraViewMatrix = GLKMatrix4Multiply(cameraViewMatrix, [camera GetViewMatrix]);
    cameraViewMatrix = GLKMatrix4Multiply(cameraViewMatrix, GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f));
    
    GLKMatrix4 modelViewMatrix = [gameObject3D GetModelViewMatrix];
    modelViewMatrix = GLKMatrix4Multiply(cameraViewMatrix, modelViewMatrix);
    
    GLKMatrix3 _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
    
    
    GLKMatrix4 _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    glUniform3fv(uniforms[UNIFORM_PLAYER_POSITION], 1, camera->position.v);
    
    if (isDay)
    {
        glUniform4fv(uniforms[UNIFORM_DIFFUSE_COLOR], 1, GLKVector4Make(1, 1, 1, 1).v);
    }
    else
    {
        glUniform4fv(uniforms[UNIFORM_DIFFUSE_COLOR], 1, GLKVector4Make(0.2f, 0.2f, 0.4f, 1).v);
    }
    
    glBindVertexArrayOES(gameObject3D->vao);
    
    // Load textures if available
    if (gameObject3D->texture)
    {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, gameObject3D->texture);
        glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    }
    
    // Check rendering mode of object
    switch (gameObject3D->renderMode)
    {
        case GL_TRIANGLES:
            glDrawArrays(gameObject3D->renderMode, 0, gameObject3D->vertexCount);
            break;
        case GL_LINES:
            glLineWidth(gameObject3D->lineWidth);
            glDrawArrays(gameObject3D->renderMode, 0, gameObject3D->vertexCount);
            break;
        case GL_LINE_LOOP:
            glDrawArrays(gameObject3D->renderMode, 0, gameObject3D->vertexCount);
            break;
    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindVertexArrayOES(0);
    
    for (GameObject3D *child in gameObject3D->children) {
        [self render:child];
    }
}

- (void)toggleDayNight:(id)sender;
{
    isDay = !isDay;
}

- (void)tearDown
{
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

@end