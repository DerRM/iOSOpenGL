//
//  OpenGLView.m
//  iPhoneOpenGL
//
//  Created by Christopher Sierigk on 13.08.12.
//  Copyright (c) 2012 Christopher Sierigk. All rights reserved.
//

#import "OpenGLView.h"
#import "Matrix4.h"

//const Vertex Vertices[] = {
//    {{ 1, -1, 0}, {1, 0, 0, 1}},
//    {{ 1,  1, 0}, {0, 1, 0, 1}},
//    {{-1,  1, 0}, {0, 0, 1, 1}},
//    {{-1, -1, 0}, {0, 0, 0, 1}}
//};
//
//const GLubyte Indices[] = {
//    0, 1, 2,
//    2, 3, 0
//};
//
//const Vertex Vertices[] = {
//    {{ 1, -1, 0}, {1, 0, 0, 1}},
//    {{ 1,  1, 0}, {1, 0, 0, 1}},
//    {{-1,  1, 0}, {0, 1, 0, 1}},
//    {{-1, -1, 0}, {0, 1, 0, 1}},
//    {{ 1, -1, -1}, {1, 0, 0, 1}},
//    {{ 1,  1, -1}, {1, 0, 0, 1}},
//    {{-1,  1, -1}, {0, 1, 0, 1}},
//    {{-1, -1, -1}, {0, 1, 0, 1}}
//};
//
//const GLubyte Indices[] = {
//    0, 1, 2,
//    2, 3, 0,
//    4, 6, 5,
//    4, 7, 6,
//    2, 7, 3,
//    7, 6, 2,
//    0, 4, 1,
//    4, 1, 5,
//    6, 2, 1,
//    1, 6, 5,
//    0, 3, 7,
//    0, 7, 4
//};

@implementation OpenGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    mEaglLayer = (CAEAGLLayer*) self.layer;
    mEaglLayer.opaque = TRUE;
}

- (void)setupContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    mContext = [[EAGLContext alloc] initWithAPI:api];
    
    if (!mContext) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:mContext]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &mColorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, mColorRenderBuffer);
    [mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:mEaglLayer];
}

- (void)setupDepthBuffer {
    glGenBuffers(1, &mDepthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, mDepthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

- (void)setupFrameBuffer {
    GLuint frameBuffer;
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, mColorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, mDepthRenderBuffer);
}

- (void)render:(CADisplayLink*)displayLink {
    glClearColor(0.0f, 0.0f, 0.0f, 0.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    
    mVMatrix = [Matrix4 lookAtEyeX:0.0f EyeY:0.0f EyeZ:-0.5f CenterX:0.0f CenterY:0.0f CenterZ:-5.0f UpX:0.0f UpY:1.0f UpZ:0.0f];
    mRotationMatrix = [Matrix4 rotateByYXZwithX:90.f Y:0.f Z:0.f];
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    float ratio = self.frame.size.width / self.frame.size.height;
    Matrix4* projection = [Matrix4 frustumWithLeft:-ratio Right:ratio Top:1.0f Bottom:-1.0f Near:1.0f Far:1000.0f];
    
    Matrix4* lightModelMatrix = [[Matrix4 alloc] initAsIdentity];
    lightModelMatrix = [Matrix4 translationMatrix: lightModelMatrix WithX:0.0f Y:0.0f Z:-5.0f];
    mLightPosInModelSpace = [[Vector4 alloc] initWithX:0.0f Y:0.0f Z:0.0f W:1.0f];
    Vector4* lightPosInWorldSpace = [Matrix4 multiplyMatrix:lightModelMatrix WithVector:mLightPosInModelSpace];
    Vector4* lightPosInEyeSpace = [Matrix4 multiplyMatrix:mVMatrix WithVector:lightPosInWorldSpace];
    
    mModelMatrix = [[Matrix4 alloc] initAsIdentity];
    mModelMatrix = [Matrix4 translationMatrix: mModelMatrix WithX:0.0f Y:-4.0f Z:-5.5f];
    
    mCurrentRotation += displayLink.duration * 30;
    //mCurrentRotation = -90.0f;
    //modelView = [Matrix4 multiply:modelView With:[Matrix4 rotateByYXZwithX:mCurrentRotation Y:0 Z:0]];
    
    mRotationMatrix = [Matrix4 rotateByYXZwithX:-90.0f Y:mCurrentRotation Z:0.0f];
    
    mModelMatrix = [Matrix4 multiply:mModelMatrix With:mRotationMatrix];
    
    Matrix4* mvpMatrix = [Matrix4 multiply:mVMatrix With:mModelMatrix];
    
    glUniformMatrix4fv(mMVMatrixHandle, 1, false, mvpMatrix.array);
    
    mvpMatrix = [Matrix4 multiply:projection With:mvpMatrix];
        
    glUniformMatrix4fv(mMVPMatrixHandle, 1, false, mvpMatrix.array);
    
    glUniform3f(mLightPosHandle, lightPosInEyeSpace.x, lightPosInEyeSpace.y, lightPosInEyeSpace.z);

    float color[] = {1, 0, 0, 0};
    glUniform4fv(mColorHandle, 1, color);
    
    glBindBuffer(GL_ARRAY_BUFFER, mPositionBuffer);
    glVertexAttribPointer(mPositionHandle, 3, GL_FLOAT, false, sizeof(Vertex), 0);
    glEnableVertexAttribArray(mPositionHandle);
    
    glBindBuffer(GL_ARRAY_BUFFER, mNormalBuffer);
    glVertexAttribPointer(mNormalHandle, 3, GL_FLOAT, false, sizeof(Normal), 0);
    glEnableVertexAttribArray(mNormalHandle);

    for (int i = 0; i < numTriangleGroups; i++) {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIndexBuffer[i]);
        glDrawElements(GL_TRIANGLES, numIndices[i], GL_UNSIGNED_SHORT, 0);
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    [mContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)compileShader: (NSString*)shaderName withType:(GLenum)shaderType {
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
}

- (void)compileShaders {
    GLuint vertexShader = [self compileShader:@"simpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"simpleFragment" withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    mPositionHandle = glGetAttribLocation(programHandle, "aPosition");
    //glEnableVertexAttribArray(mPositionHandle);
    
    mNormalHandle = glGetAttribLocation(programHandle, "aNormal");
    //glEnableVertexAttribArray(mNormalHandle);

    mColorHandle = glGetUniformLocation(programHandle, "uSourceColor");
    mMVPMatrixHandle = glGetUniformLocation(programHandle, "uMVPMatrix");
    mMVMatrixHandle = glGetUniformLocation(programHandle, "uMVMatrix");
    mLightPosHandle = glGetUniformLocation(programHandle, "uLightPos");
}

- (char) readCharFromFile: (NSFileHandle*)file {
    char charValue;
    memcpy(&charValue, [[file readDataOfLength:1] bytes], 1);
    return charValue;
}

- (float) readFloatFromFile: (NSFileHandle*) file {
    float floatValue;
    memcpy(&floatValue, [[file readDataOfLength:4] bytes], 4);
    return floatValue;
}

- (unsigned int) readIntFromFile: (NSFileHandle*) file {
    unsigned int intValue;
    memcpy(&intValue, [[file readDataOfLength:4] bytes], 4);
    return intValue;
}

- (unsigned short) readShortFromFile: (NSFileHandle*) file {
    unsigned short shortValue;
    memcpy(&shortValue, [[file readDataOfLength:2] bytes], 2);
    return shortValue;
}

- (void) loadModel {
    NSString* modelPath = [[NSBundle mainBundle] pathForResource:@"Test" ofType:@"scf"];
    NSFileHandle* file = [NSFileHandle fileHandleForReadingAtPath:modelPath];
    
    for (int i = 0; i < 4; i++) {
        printf("%c", [self readCharFromFile:file]);
    }
    
    printf("\n");
        
    for (int i = 0; i < 7; i++) {
        
        if (i == 4) {
            numTriangleGroups = [self readIntFromFile:file];
            printf("No Triangle Group: %i", numTriangleGroups);
            printf("\n");
        } else {
            printf("%i", [self readIntFromFile:file]);
            printf("\n");
        }
    }
    
    unsigned int length = [self readIntFromFile:file];
    numVertices = length / 3;
    
    printf("Num Vertices: %d\n", length);
    
    Vertices = (Vertex*) malloc((length / 3) * sizeof(Vertex));
    
    for (int i = 0; i < length / 3; i++) {
        float x = [self readFloatFromFile:file];
        float y = [self readFloatFromFile:file];
        float z = [self readFloatFromFile:file];
        Vertices[i].Position[0] = x;
        Vertices[i].Position[1] = y;
        Vertices[i].Position[2] = z;
    }
    
    length = [self readIntFromFile:file];
    numNormals = length / 3;
    
    Normals = (Normal*) malloc((length / 3) * sizeof(Normal));
    printf("Num Normals: %d\n", length);
    
    for (int i = 0; i < length / 3; i++) {
        float x = [self readFloatFromFile:file];
        float y = [self readFloatFromFile:file];
        float z = [self readFloatFromFile:file];
        Normals[i].Direction[0] = x;
        Normals[i].Direction[1] = y;
        Normals[i].Direction[2] = z;
    }
    
    length = [self readIntFromFile:file];
    numTexCoords = length;
    
    TexCoords = (TexCoord*) malloc(length * sizeof(TexCoord));
    printf("Num TexCoords: %d\n", length);
    
    for (int i = 0; i < length; i++) {
        float u = [self readFloatFromFile:file];
        float v = [self readFloatFromFile:file];
        TexCoords[i].Coord[0] = u;
        TexCoords[i].Coord[1] = v;
    }
        
    posIndices = (GLushort**) malloc(numTriangleGroups * sizeof(GLushort*));
    numPosIndices = (unsigned int*) malloc(numTriangleGroups * sizeof(unsigned int));
    
    normalIndices = (GLushort**) malloc(numTriangleGroups * sizeof(GLushort*));
    numNormalIndices = (unsigned int*) malloc(numTriangleGroups * sizeof(unsigned int));
    
    texCoordIndices = (GLushort**) malloc(numTriangleGroups * sizeof(GLushort*));
    numTexCoordIndices = (unsigned int*) malloc(numTriangleGroups * sizeof(unsigned int));
    
    for (int i = 0; i < numTriangleGroups; i++) {
        length = [self readIntFromFile:file];
        printf("Num Indices in Group %d: %d\n", i, length);
        
        numPosIndices[i] = length;
        posIndices[i] = (GLushort*) malloc(length * 3 * sizeof(GLushort));
        
        numNormalIndices[i] = length;
        normalIndices[i] = (GLushort*) malloc(length * 3 * sizeof(GLushort));
        
        numTexCoordIndices[i] = length;
        texCoordIndices[i] = (GLushort*) malloc(length * 3 * sizeof(GLushort));
        
        for (int j = 0; j < length; j++) {
            int index = j * 3;
            
            posIndices[i][index] = [self readShortFromFile:file];
            posIndices[i][index + 1] = [self readShortFromFile:file];
            posIndices[i][index + 2] = [self readShortFromFile:file];
            
            normalIndices[i][index] = [self readShortFromFile:file];
            normalIndices[i][index + 1] = [self readShortFromFile:file];
            normalIndices[i][index + 2] = [self readShortFromFile:file];
            
            texCoordIndices[i][index] = [self readShortFromFile:file];
            texCoordIndices[i][index + 1] = [self readShortFromFile:file];
            texCoordIndices[i][index + 2] = [self readShortFromFile:file];
        }
    }
    
    [self rearrangeIndices];
}

- (void) rearrangeIndices {
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    NSMutableArray* keyArray = [[NSMutableArray alloc] init];
    
    int index = 0;
    
    indices = (GLushort**) malloc(numTriangleGroups * sizeof(GLushort*));
    numIndices = (unsigned int*) malloc(numTriangleGroups * sizeof(unsigned int));
    
    for (int i = 0; i < numTriangleGroups; i++) {
                
        NSMutableArray* indexArray = [[NSMutableArray alloc] init];
        
        for (int j = 0; j < numPosIndices[i]; j++) {
            GLushort positionIndex = posIndices[i][j];
            GLushort normalIndex = normalIndices[i][j];
            GLushort texCoordIndex = texCoordIndices[i][j];
            
            NSString* key = [NSString stringWithFormat:@"%d.%d.%d", positionIndex, normalIndex, texCoordIndex];
            
            if ([dictionary objectForKey:key] == nil) {
               // NSLog(@"key doesn't exists: %@", key);
                Vertex3* vertex = [[Vertex3 alloc] init];
                vertex.index = index;
                vertex.posIndex = positionIndex;
                vertex.normalIndex = normalIndex;
                vertex.texCoordIndex = texCoordIndex;
                [dictionary setObject:vertex forKey:key];
                [keyArray addObject:key];
                [indexArray addObject:[[NSNumber alloc] initWithInt:index]];
                index++;
            } else {
               // NSLog(@"key exists: %@", key);
                Vertex3* vertex = (Vertex3*)[dictionary objectForKey:key];
                [indexArray addObject:[[NSNumber alloc] initWithInt:vertex.index]];
            }
        }
        
        indices[i] = (GLushort*) malloc([indexArray count] * sizeof(GLushort));
        numIndices[i] = [indexArray count];
        
        NSEnumerator* e = [indexArray objectEnumerator];
        NSNumber* object;
        int indicesCount = 0;
        while (object = [e nextObject]) {
            //NSLog(@"Index: %@", object);
            indices[i][indicesCount] = [object shortValue];
            indicesCount++;
        }
    }
    
    int length = [keyArray count];
    newVertices = (Vertex*) malloc(length * 3 * sizeof(Vertex));
    newNormals = (Normal*) malloc(length * 3 * sizeof(Normal));
    newTexCoords = (TexCoord*) malloc(length * 2 * sizeof(TexCoord));
    
    NSEnumerator* enu = [keyArray objectEnumerator];
    
    numNewVertices = 0;
    NSString* key;
    while (key = [enu nextObject]) {
        Vertex3* vertex3 = [dictionary objectForKey:key];
        GLushort positionIndex = vertex3.posIndex;
        GLushort normalIndex = vertex3.normalIndex;
        GLushort texCoordIndex = vertex3.texCoordIndex;
        
        //NSLog(@"Pos: %d Normal: %d TexCoord: %d", positionIndex, normalIndex, texCoordIndex);
        
        newVertices[numNewVertices] = Vertices[positionIndex];
        newNormals[numNewVertices] = Normals[normalIndex];
        newTexCoords[numNewVertices] = TexCoords[texCoordIndex];
        
        numNewVertices++;
    }
}

- (void) setupVBOs {
    glGenBuffers(1, &mPositionBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, mPositionBuffer);
    glBufferData(GL_ARRAY_BUFFER, numNewVertices * 3 * sizeof(float), newVertices, GL_STATIC_DRAW);
    
    
    //GLuint normalBuffer;
    glGenBuffers(1, &mNormalBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, mNormalBuffer);
    glBufferData(GL_ARRAY_BUFFER, numNewVertices * 3 * sizeof(float), newNormals, GL_STATIC_DRAW);
    //printf("Size of Vertices: %d \n", sizeof(Vertices));
    
    mIndexBuffer = (GLuint*) malloc(numTriangleGroups * sizeof(GLuint));
    glGenBuffers(numTriangleGroups, mIndexBuffer);
    
    for (int i = 0; i < numTriangleGroups; i++){
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIndexBuffer[i]);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, numIndices[i] * sizeof(GLushort), indices[i], GL_STATIC_DRAW);
    }
}

- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShaders];
        [self loadModel];
        [self setupVBOs];
        [self setupDisplayLink];
    }
    
    return self;
}

- (void)dealloc {
    [mContext release];
    mContext = nil;
    [super dealloc];
}

@end
