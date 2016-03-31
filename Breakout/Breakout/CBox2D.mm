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

// Set up brick and ball physics parameters here:
//   position, width+height (or radius), velocity,
//   and how long to wait before dropping brick

#define PADDLE_POS_X		400
#define PADDLE_POS_Y        10
#define PADDLE_WIDTH        76.0f
#define PADDLE_HEIGHT       10.0f
#define BRICK_WIDTH			96.0f
#define BRICK_HEIGHT		16.0f
#define BRICK_WAIT			1.5f
#define BALL_POS_X			400
#define BALL_POS_Y			40
#define BALL_RADIUS			15.0f
#define BALL_VELOCITY		100000.0f
#define BALL_SPHERE_SEGS	128
#define BRICK_NUM           8

const float MAX_TIMESTEP = 1.0f/60.0f;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;
const b2Vec2 VELOCITY_SCALE = b2Vec2(3,0);


struct bodyUserData
{
    CBox2D *selfBox;
    int entityType;
    int brickTag;
};

typedef enum
{
    PADDLE = 0,
    BALL,
    BRICKS,
    WALLS
}EntityType;

#pragma mark - Box2D contact listener class

class CContactListener : public b2ContactListener
{
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        if (state2[0] == b2_addState)
        {
            // Use contact->GetFixtureA()->GetBody() to get the body
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            CBox2D *parentObj = (__bridge CBox2D *)(bodyA->GetUserData());
        
            // Call RegisterHit (assume CBox2D object is in user data)
            [parentObj RegisterHit];
        }
    }
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
    b2Body *thePaddle, *theBall;
    b2Fixture *bottomFixture, *topfixture;
    CContactListener *contactListener;
    
    // GL-specific variables
    // You will need to set up 2 vertex arrays (for brick and ball)
    GLuint brickVertexArray, ballVertexArray, bricksVertexArray;
    int numBrickVerts, numBallVerts;
    GLKMatrix4 modelViewProjectionMatrix;
    
    // You will also need some extra variables here
    bool ballHitBrick;
    bool ballLaunched;
    float totalElapsedTime;
    
    // Bricks to hit
    NSMutableArray *mutableBrickArray;
    int currentTotalBricks;
    int brickNumHit;
    int bricksDrawn;
    
    float brickDest;
}
@end

@implementation CBox2D

- (instancetype)init
{
    self = [super init];
    if (self) {
        gravity = new b2Vec2(0.0f, -10.0f);
        world = new b2World(*gravity);
        
        // For HelloWorld
        groundBodyDef = NULL;
        groundBody = NULL;
        groundBox = NULL;
        
        // For brick & ball sample
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Set up the brick and ball objects for Box2D
        b2BodyDef paddleBodyDef;
        paddleBodyDef.type = b2_dynamicBody;
        paddleBodyDef.position.Set(PADDLE_POS_X, PADDLE_POS_Y);
        thePaddle = world->CreateBody(&paddleBodyDef);
        if (thePaddle)
        {
            thePaddle->SetUserData((__bridge void *)self);
            thePaddle->SetAwake(false);
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            thePaddle->CreateFixture(&fixtureDef);
            
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
    // Check here if we need to launch the ball
    //  and if so, use ApplyLinearImpulse() and SetActive(true)
    if (ballLaunched)
    {
        theBall->ApplyLinearImpulse(b2Vec2(0, BALL_VELOCITY), theBall->GetPosition(), true);
        theBall->SetActive(true);
#ifdef LOG_TO_CONSOLE
        NSLog(@"Applying impulse %f to ball\n", BALL_VELOCITY);
#endif
        ballLaunched = false;
    }
    
    /*
    // Check if it is time yet to drop the brick, and if so
    //  call SetAwake()
    totalElapsedTime += elapsedTime;
    if ((totalElapsedTime > BRICK_WAIT) && thePaddle)
        thePaddle->SetAwake(true);
    
    // If the last collision test was positive,
    //  stop the ball and destroy the brick
    if (ballHitBrick)
    {
        //theBall->SetLinearVelocity(b2Vec2(0, 0));
        //theBall->SetAngularVelocity(0);
        //theBall->SetActive(false);
        world->DestroyBody(thePaddle);
        thePaddle = NULL;
        ballHitBrick = false;
    }
    */
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
    
    
    // Set up vertex arrays and buffers for the brick and ball here
    
    glEnable(GL_DEPTH_TEST);
    
    if (thePaddle)
    {
        glGenVertexArraysOES(1, &brickVertexArray);
        glBindVertexArrayOES(brickVertexArray);
        
        GLuint vertexBuffers[2];
        glGenBuffers(2, vertexBuffers);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers[0]);
        GLfloat vertPos[18];
        int k = 0;
        numBrickVerts = 0;
        vertPos[k++] = thePaddle->GetPosition().x - PADDLE_WIDTH/2;
        vertPos[k++] = thePaddle->GetPosition().y + PADDLE_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = thePaddle->GetPosition().x + PADDLE_WIDTH/2;
        vertPos[k++] = thePaddle->GetPosition().y + PADDLE_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = thePaddle->GetPosition().x + PADDLE_WIDTH/2;
        vertPos[k++] = thePaddle->GetPosition().y - PADDLE_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = thePaddle->GetPosition().x - PADDLE_WIDTH/2;
        vertPos[k++] = thePaddle->GetPosition().y + PADDLE_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = thePaddle->GetPosition().x + PADDLE_WIDTH/2;
        vertPos[k++] = thePaddle->GetPosition().y - PADDLE_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        vertPos[k++] = thePaddle->GetPosition().x - PADDLE_WIDTH/2;
        vertPos[k++] = thePaddle->GetPosition().y - PADDLE_HEIGHT/2;
        vertPos[k++] = 10;
        numBrickVerts++;
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertPos), vertPos, GL_STATIC_DRAW);
        glEnableVertexAttribArray(VertexAttribPosition);
        glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(GLfloat), BUFFER_OFFSET(0));
        
        GLfloat vertCol[numBrickVerts*3];
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
    
    // For now assume simple ortho projection since it's only 2D
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0, 800, 0, 600, -10, 100);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
}

-(void)Render:(int)mvpMatPtr
{
#ifdef LOG_TO_CONSOLE
    if (theBall)
        printf("Ball: (%5.3f,%5.3f)\t",
               theBall->GetPosition().x, theBall->GetPosition().y);
    if (thePaddle)
        printf("Brick: (%5.3f,%5.3f)",
               thePaddle->GetPosition().x, thePaddle->GetPosition().y);
    printf("\n");
#endif
    
    glClearColor(0, 0, 0, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUniformMatrix4fv(mvpMatPtr, 1, 0, modelViewProjectionMatrix.m);
    
    // Bind each vertex array and call glDrawArrays
    //  for each of the ball and brick
    
    glBindVertexArrayOES(brickVertexArray);
    if (thePaddle && numBrickVerts > 0)
        glDrawArrays(GL_TRIANGLES, 0, numBrickVerts);
    
    glBindVertexArrayOES(ballVertexArray);
    if (theBall && numBallVerts > 0)
        glDrawArrays(GL_TRIANGLE_FAN, 0, numBallVerts);
}

-(void)RegisterHit
{
    // Set some flag here for processing later...
    ballHitBrick = true;
}

-(void)LaunchBall
{
    if(!ballLaunched){
        ballLaunched = true;
        float angle = GLKMathDegreesToRadians(30);
        theBall->ApplyLinearImpulse(b2Vec2(sin(angle) * BALL_VELOCITY, cos(angle) * BALL_VELOCITY), theBall->GetPosition(), true);
        theBall->SetActive(true);
    }
}

-(void)movePaddle:(CGPoint)location
{

}

-(void) GenerateBricks
{
    currentTotalBricks = BRICK_NUM;
    for(int i = 0; i < BRICK_NUM; i++)
    {
        static int padding=100;
        
        int xOffset = padding+ BRICK_WIDTH / 2 + ((BRICK_WIDTH +10)*i);
        
        // Create block body
        b2BodyDef blockBodyDef;
        blockBodyDef.type = b2_staticBody;
        blockBodyDef.position.Set(xOffset, 350);
        b2Body *blockBody = world->CreateBody(&blockBodyDef);
        
        // Set user data with some custom info
        bodyUserData* myStruct = new bodyUserData;
        myStruct->selfBox = self;
        myStruct->entityType = BRICKS;
        myStruct->brickTag = i;
        blockBody->SetUserData(myStruct);
        
        // Create block shape
        b2PolygonShape blockShape;
        blockShape.SetAsBox(BRICK_WIDTH / 2, BRICK_HEIGHT / 2);
        
        // Create shape definition and add to body
        b2FixtureDef blockShapeDef;
        blockShapeDef.shape = &blockShape;
        blockShapeDef.density = 10.0;
        blockShapeDef.friction = 0.0;
        blockShapeDef.restitution = 0.1f;
        blockBody->CreateFixture(&blockShapeDef);
        NSValue *bodyVal = [NSValue valueWithPointer:blockBody];
        [mutableBrickArray addObject:bodyVal];
    }
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

-(void)CreateBrick:(b2Vec2)brick
{
    GLfloat vertPos[36];
    int k = 0;
    numBrickVerts = 0;
    vertPos[k++] = brick.x - BRICK_WIDTH/2;
    vertPos[k++] = brick.y + BRICK_HEIGHT/2;
    vertPos[k++] = 10;
    vertPos[k++] = 1.0f;
    vertPos[k++] = 0.0f;
    vertPos[k++] = 0.0f;
    numBrickVerts++;
    vertPos[k++] = brick.x + BRICK_WIDTH/2;
    vertPos[k++] = brick.y + BRICK_HEIGHT/2;
    vertPos[k++] = 10;
    vertPos[k++] = 1.0f;
    vertPos[k++] = 0.0f;
    vertPos[k++] = 0.0f;
    numBrickVerts++;
    vertPos[k++] = brick.x + BRICK_WIDTH/2;
    vertPos[k++] = brick.y - BRICK_HEIGHT/2;
    vertPos[k++] = 10;
    vertPos[k++] = 1.0f;
    vertPos[k++] = 0.0f;
    vertPos[k++] = 0.0f;
    numBrickVerts++;
    vertPos[k++] = brick.x - BRICK_WIDTH/2;
    vertPos[k++] = brick.y + BRICK_HEIGHT/2;
    vertPos[k++] = 10;
    vertPos[k++] = 1.0f;
    vertPos[k++] = 0.0f;
    vertPos[k++] = 0.0f;
    numBrickVerts++;
    vertPos[k++] = brick.x + BRICK_WIDTH/2;
    vertPos[k++] = brick.y - BRICK_HEIGHT/2;
    vertPos[k++] = 10;
    vertPos[k++] = 1.0f;
    vertPos[k++] = 0.0f;
    vertPos[k++] = 0.0f;
    numBrickVerts++;
    vertPos[k++] = brick.x - BRICK_WIDTH/2;
    vertPos[k++] = brick.y - BRICK_HEIGHT/2;
    vertPos[k++] = 10;
    vertPos[k++] = 1.0f;
    vertPos[k++] = 0.0f;
    vertPos[k++] = 0.0f;
    numBrickVerts++;
    glBufferSubData(GL_ARRAY_BUFFER, bricksDrawn * sizeof(vertPos), sizeof(vertPos), vertPos);
    bricksDrawn++;
}
-(void)UpdateBricks
{
    if((b2Body*) [[mutableBrickArray objectAtIndex:0] pointerValue])
    {
        
        glGenVertexArraysOES(1, &bricksVertexArray);
        glBindVertexArrayOES(bricksVertexArray);
        
        GLuint vertexBuffers;
        glGenBuffers(1, &vertexBuffers);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffers);
        glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat[36]) * currentTotalBricks, 0, GL_STATIC_DRAW);
        
        glEnableVertexAttribArray(VertexAttribPosition);
        glVertexAttribPointer(VertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), BUFFER_OFFSET(0));
        glEnableVertexAttribArray(VertexAttribColor);
        glVertexAttribPointer(VertexAttribColor, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), BUFFER_OFFSET(12));
        
        for (int i = 0; i < currentTotalBricks; i++)
        {
            b2Body *theBody = (b2Body*) [[mutableBrickArray objectAtIndex:i] pointerValue];
            [self CreateBrick:theBody->GetPosition()];
        }
        bricksDrawn = 0;
        
        glBindVertexArrayOES(0);
    }
}




@end
