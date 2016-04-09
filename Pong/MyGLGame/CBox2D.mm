//
//  CBox2D.m
//  MyGLGame
//
//  Created by Borna Noureddin on 2015-03-17.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#include <Box2D/Box2D.h>
#include "CBox2D.h"
#include <OpenGLES/ES2/glext.h>
#include <stdio.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
//#define LOG_TO_CONSOLE



#pragma mark - Brick and ball physics parameters

#define BRICK_POS_X			10
#define BRICK2_POS_X        780
#define BRICK_POS_Y			400
#define BRICK_WIDTH			10.0f
#define BRICK_HEIGHT		100.0f
#define BRICK_WAIT			1.5f
#define BALL_POS_X			400
#define BALL_POS_Y			400
#define BALL_RADIUS			15.0f
#define BALL_VELOCITY		100000000.0f
#define BALL_SPHERE_SEGS	128

const float MAX_TIMESTEP = 1.0f/60.0f;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;


#pragma mark - Box2D contact listener class

class CContactListener : public b2ContactListener
{
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold){
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        if (state2[0] == b2_addState)
        {
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            CBox2D *parentObj = (__bridge CBox2D *)(bodyA->GetUserData());
            [parentObj RegisterHit];
            contact->SetEnabled(false);
        }
    };
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
};


#pragma mark - CBox2D

@interface CBox2D ()
{
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;
    b2BodyDef *groundBodyDef;
    b2Body *groundBody;
    b2PolygonShape *groundBox;
    b2Body *theBrick, *theBall, *theBrick2;
    CContactListener *contactListener;
    
    // GL-specific variables
    GLuint brickVertexArray, ballVertexArray, brick2VertexArray;
    int numBrickVerts, numBallVerts;
    GLKMatrix4 modelViewProjectionMatrix;

    bool ballHitBrick;
    bool ballLaunched;
    float totalElapsedTime;
    
    float brickDest, brick2Dest;
    
    @public int brickScore, brick2Score;
}
@end

@implementation CBox2D

- (instancetype)init
{
    self = [super init];
    if (self) {
        gravity = new b2Vec2(0.0f, 0.0f);
        world = new b2World(*gravity);
        
        // For HelloWorld
        groundBodyDef = NULL;
        groundBody = NULL;
        groundBox = NULL;

        // For brick & ball sample
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        b2BodyDef brickBodyDef;
        brickBodyDef.type = b2_dynamicBody;
        brickBodyDef.position.Set(BRICK_POS_X, BRICK_POS_Y);
        theBrick = world->CreateBody(&brickBodyDef);
        if (theBrick)
        {
            theBrick->SetUserData((__bridge void *)self);
            theBrick->SetAwake(false);
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            theBrick->CreateFixture(&fixtureDef);
            
            b2BodyDef ballBodyDef;
            ballBodyDef.type = b2_dynamicBody;
            ballBodyDef.position.Set(BALL_POS_X, BALL_POS_Y);
            theBall = world->CreateBody(&ballBodyDef);
            if (theBall)
            {
                theBall->SetUserData((__bridge void *)self);
                theBall->SetAwake(false);
                b2CircleShape circle;
                circle.m_p.Set(0, 0);
                circle.m_radius = BALL_RADIUS;
                b2FixtureDef circleFixtureDef;
                circleFixtureDef.shape = &circle;
                circleFixtureDef.density = 1.0f;
                circleFixtureDef.friction = 0.3f;
                circleFixtureDef.restitution = 1.0f;
                theBall->CreateFixture(&circleFixtureDef);
            }
        }
        
        b2BodyDef brick2BodyDef;
        brick2BodyDef.type = b2_dynamicBody;
        brick2BodyDef.position.Set(BRICK2_POS_X, BRICK_POS_Y);
        theBrick2 = world->CreateBody(&brick2BodyDef);
        if (theBrick2)
        {
            theBrick2->SetUserData((__bridge void *)self);
            theBrick2->SetAwake(false);
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            theBrick2->CreateFixture(&fixtureDef);
        }
        
        totalElapsedTime = 0;
        ballHitBrick = false;
        ballLaunched = false;
    }
    return self;
}

- (void)dealloc
{
    if (gravity) delete gravity;
    if (world) delete world;
    if (groundBodyDef) delete groundBodyDef;
    if (groundBox) delete groundBox;
    if (contactListener) delete contactListener;
}

-(void)Update:(float)elapsedTime
{
    
    if (world)
    {
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
        }
        
        if (elapsedTime > 0.0f)
        {
            world->Step(elapsedTime, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
        }
    }


    glEnable(GL_DEPTH_TEST);

    if (theBrick)
    {
        if(theBrick->GetPosition().y > brickDest-5 && theBrick->GetPosition().y < brickDest+5){
            theBrick->SetLinearVelocity(b2Vec2(0,0));
        }
        
        glGenVertexArraysOES(1, &brickVertexArray);
        glBindVertexArrayOES(brickVertexArray);
        
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];
        int k = 0;
        numBrickVerts = 0;
        vertPos[k++] = theBrick->GetPosition().x - BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = theBrick->GetPosition().x + BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = theBrick->GetPosition().x + BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = theBrick->GetPosition().x - BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = theBrick->GetPosition().x + BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = theBrick->GetPosition().x - BRICK_WIDTH/2;
        vertPos[k++] = theBrick->GetPosition().y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribPosition);
        glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        GLfloat vertCol[18];
        for (k=0; k<numBrickVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribColor);
        glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        glBindVertexArrayOES(0);
    }
    
    if (theBrick2)
    {
        if(theBrick2->GetPosition().y > brick2Dest-5 && theBrick2->GetPosition().y < brick2Dest+5){
            theBrick2->SetLinearVelocity(b2Vec2(0,0));
        }
        
        glGenVertexArraysOES(1, &brick2VertexArray);
        glBindVertexArrayOES(brick2VertexArray);
        
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];
        int k = 0;
        vertPos[k++] = theBrick2->GetPosition().x - BRICK_WIDTH/2;
        vertPos[k++] = theBrick2->GetPosition().y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        
        vertPos[k++] = theBrick2->GetPosition().x + BRICK_WIDTH/2;
        vertPos[k++] = theBrick2->GetPosition().y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        
        vertPos[k++] = theBrick2->GetPosition().x + BRICK_WIDTH/2;
        vertPos[k++] = theBrick2->GetPosition().y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        
        vertPos[k++] = theBrick2->GetPosition().x - BRICK_WIDTH/2;
        vertPos[k++] = theBrick2->GetPosition().y + BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        
        vertPos[k++] = theBrick2->GetPosition().x + BRICK_WIDTH/2;
        vertPos[k++] = theBrick2->GetPosition().y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        
        vertPos[k++] = theBrick2->GetPosition().x - BRICK_WIDTH/2;
        vertPos[k++] = theBrick2->GetPosition().y - BRICK_HEIGHT/2;
        vertPos[k++] = 10;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribPosition);
        glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        GLfloat vertCol[18];
        for (k=0; k<numBrickVerts*3; k+=3)
        {
            vertCol[k] = 1.0f;
            vertCol[k+1] = 0.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribColor);
        glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        glBindVertexArrayOES(0);
    }

    
    if (theBall)
    {
        if(theBall->GetPosition().y < 15 || theBall->GetPosition().y > 785){
            b2Vec2 ballV = theBall->GetLinearVelocity();
            theBall->SetLinearVelocity(b2Vec2(ballV.x, -ballV.y));
        }
        if(theBall->GetPosition().x < 1){
            brick2Score++;
            [self ResetBall];
        }else if(theBall->GetPosition().x > 785){
            brickScore++;
            [self ResetBall];
        }
        
        glGenVertexArraysOES(1, &ballVertexArray);
        glBindVertexArrayOES(ballVertexArray);
        
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[3*(BALL_SPHERE_SEGS+2)];
        int k = 0;
        vertPos[k++] = theBall->GetPosition().x;
        vertPos[k++] = theBall->GetPosition().y;
        vertPos[k++] = 0;
        numBallVerts = 1;
        for (int n=0; n<=BALL_SPHERE_SEGS; n++)
        {
            float const t = 2*M_PI*(float)n/(float)BALL_SPHERE_SEGS;
            vertPos[k++] = theBall->GetPosition().x + sin(t)*BALL_RADIUS;
            vertPos[k++] = theBall->GetPosition().y + cos(t)*BALL_RADIUS;
            vertPos[k++] = 0;
            numBallVerts++;
        }
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribPosition);
        glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        GLfloat vertCol[numBallVerts*3];
        for (k=0; k<numBallVerts*3; k+=3)
        {
            vertCol[k] = 0.0f;
            vertCol[k+1] = 1.0f;
            vertCol[k+2] = 0.0f;
        }
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertCol), vertCol, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribColor);
        glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        glBindVertexArrayOES(0);
        
    }

    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, 800, 0, 600, -10, 100);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
}

-(void)ResetBall{
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody;
    ballBodyDef.position.Set(BALL_POS_X, BALL_POS_Y);
    theBall = world->CreateBody(&ballBodyDef);
    if (theBall)
    {
        theBall->SetUserData((__bridge void *)self);
        theBall->SetAwake(false);
        b2CircleShape circle;
        circle.m_p.Set(0, 0);
        circle.m_radius = BALL_RADIUS;
        b2FixtureDef circleFixtureDef;
        circleFixtureDef.shape = &circle;
        circleFixtureDef.density = 1.0f;
        circleFixtureDef.friction = 0.3f;
        circleFixtureDef.restitution = 1.0f;
        theBall->CreateFixture(&circleFixtureDef);
    }
    ballLaunched = false;
}

-(void)Render:(int)mvpMatPtr
{
#ifdef LOG_TO_CONSOLE
    if (theBall)
        printf("Ball: (%5.3f,%5.3f)\t",
               theBall->GetPosition().x, theBall->GetPosition().y);
    if (theBrick)
        printf("Brick: (%5.3f,%5.3f)",
               theBrick->GetPosition().x, theBrick->GetPosition().y);
    printf("\n");
#endif
    
    glClearColor(0, 0, 0, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUniformMatrix4fv(mvpMatPtr, 1, 0, modelViewProjectionMatrix.m);

    glBindVertexArrayOES(brickVertexArray);
    if (theBrick && numBrickVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numBrickVerts);
    
    glBindVertexArrayOES(ballVertexArray);
    if (theBall && numBallVerts > 0)
        glDrawArrays(GL_TRIANGLE_FAN, 0, numBallVerts);
    
    glBindVertexArrayOES(brick2VertexArray);
    if (theBrick2 && numBrickVerts > 0)
        glDrawArrays(GL_TRIANGLE_FAN, 0, numBrickVerts);
}

-(void)RegisterHit
{
    b2Vec2 ballV = theBall->GetLinearVelocity();
    theBall->SetLinearVelocity(b2Vec2(-ballV.x, ballV.y));
}

-(void)LaunchBall : (CGPoint)pos
{
    if(!ballLaunched){
        ballLaunched = true;
        float angle = GLKMathDegreesToRadians(-60);
        theBall->ApplyLinearImpulse(b2Vec2(sin(angle) * BALL_VELOCITY, cos(angle) * BALL_VELOCITY), theBall->GetPosition(), true);
        theBall->SetActive(true);
    }else{
        //NSLog(@"%f, %f", theBrick->GetPosition().y, pos.y);
        if(pos.x <= 400){
            if (pos.y < theBrick->GetPosition().y) {
                theBrick->ApplyLinearImpulse(b2Vec2(0,-BALL_VELOCITY), theBrick->GetPosition(), true);
            }else{
                theBrick->ApplyLinearImpulse(b2Vec2(0,BALL_VELOCITY), theBrick->GetPosition(), true);
            }
            brickDest = pos.y;
        }else{
            if (pos.y < theBrick2->GetPosition().y) {
                theBrick2->ApplyLinearImpulse(b2Vec2(0,-BALL_VELOCITY), theBrick2->GetPosition(), true);
            }else{
                theBrick2->ApplyLinearImpulse(b2Vec2(0,BALL_VELOCITY), theBrick2->GetPosition(), true);
            }
            brick2Dest = pos.y;
        }
    }
}



-(void)HelloWorld
{
    groundBodyDef = new b2BodyDef;
    groundBodyDef->position.Set(0.0f, -10.0f);
    groundBody = world->CreateBody(groundBodyDef);
    groundBox = new b2PolygonShape;
    groundBox->SetAsBox(50.0f, 10.0f);
    
    groundBody->CreateFixture(groundBox, 0.0f);
    
    // Define the dynamic body. We set its position and call the body factory.
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(0.0f, 4.0f);
    b2Body* body = world->CreateBody(&bodyDef);
    
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(1.0f, 1.0f);
    
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &dynamicBox;
    
    // Set the box density to be non-zero, so it will be dynamic.
    fixtureDef.density = 1.0f;
    
    // Override the default friction.
    fixtureDef.friction = 0.3f;
    
    // Add the shape to the body.
    body->CreateFixture(&fixtureDef);
    
    // Prepare for simulation. Typically we use a time step of 1/60 of a
    // second (60Hz) and 10 iterations. This provides a high quality simulation
    // in most game scenarios.
    float32 timeStep = 1.0f / 60.0f;
    int32 velocityIterations = 6;
    int32 positionIterations = 2;
    
    // This is our little game loop.
    for (int32 i = 0; i < 60; ++i)
    {
        // Instruct the world to perform a single step of simulation.
        // It is generally best to keep the time step and iterations fixed.
        world->Step(timeStep, velocityIterations, positionIterations);
        
        // Now print the position and angle of the body.
        b2Vec2 position = body->GetPosition();
        float32 angle = body->GetAngle();
        
        printf("%4.2f %4.2f %4.2f\n", position.x, position.y, angle);
    }
}

-(int)score1{
    return brickScore;
}

-(int)score2{
    return brick2Score;
}
@end
