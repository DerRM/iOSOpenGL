//
//  OpenGLView.m
//  iPhoneOpenGL
//
//  Created by Christopher Sierigk on 13.08.12.
//  Copyright (c) 2012 Christopher Sierigk. All rights reserved.
//

#import "OpenGLView.h"

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

- (float*)frustumWithLeft: (float)left Right:(float)right Top:(float)top Bottom:(float)bottom Near:(float)near Far:(float)far {
    
    float *projection = (float *)malloc(16 * sizeof(float));
    projection[0] = (2.0f * near) / (right - left);
    projection[1] = 0;
    projection[2] = 0;
    projection[3] = 0;
    
    projection[4] = 0;
    projection[5] = (2.0f * near) / (top - bottom);
    projection[6] = 0;
    projection[7] = 0;
    
    projection[8] = (right + left) / (right - left);
    projection[9] = (top + bottom) / (top - bottom);
    projection[10] = -(far + near) / (far - near);
    projection[11] = -1.0f;
    
    projection[12] = 0;
    projection[13] = 0;
    projection[14] = -(2.0f * far * near) / (far - near);
    projection[15] = 0;
    
    return projection;
}

- (float*)translationWithX:(float)x Y:(float)y Z:(float)z {
    
    float *translation = (float*) malloc(16 * sizeof(float));
    translation[0] = 1;
    translation[1] = 0;
    translation[2] = 0;
    translation[3] = 0;
    
    translation[4] = 0;
    translation[5] = 1;
    translation[6] = 0;
    translation[7] = 0;
    
    translation[8] = 0;
    translation[9] = 0;
    translation[10] = 1;
    translation[11] = 0;
    
    translation[12] = x;
    translation[13] = y;
    translation[14] = z;
    translation[15] = 1;
    
    return translation;
}

#define DegreesToRadiansFactor 0.017453292519943f
#define RadiansToDegreesFactor 57.29577951308232f
#define DegreesToRadians(D) ((D) * DegreesToRadiansFactor)
#define RadiansToDegrees(R) ((R) * RadiansToDegreesFactor)

- (float*)rotateByYXZwithX:(float)x Y:(float)y Z:(float)z {
    float *rotation = (float*) malloc(16 * sizeof(float));
    
    float xRadians = DegreesToRadians(x);
    float yRadians = DegreesToRadians(y);
    float zRadians = DegreesToRadians(z);
    
    float cx = cosf(xRadians);
    float cy = cosf(yRadians);
    float cz = cosf(zRadians);
    
    float sx = sinf(xRadians);
    float sy = sinf(yRadians);
    float sz = sinf(zRadians);
    
    rotation[0] = (cy * cz) + (sx * sy * sz);
    rotation[1] = cx * sz;
    rotation[2] = (cy * sx * sz) - (cz * sy);
    rotation[3] = 0.0;
    
    rotation[4] = (cz * sx * sy) - (cy * sz);
    rotation[5] = cx * cz;
    rotation[6] = (cy * cz * sx) + (sy * sz);
    rotation[7] = 0.0;
    
    rotation[8] = cx * sy;
    rotation[9] = -sx;
    rotation[10] = cx * cy;
    rotation[11] = 0.0;
    
    rotation[12] = 0.0;
    rotation[13] = 0.0;
    rotation[14] = 0.0;
    rotation[15] = 1.0;
    
    return rotation;
}

- (float*) multiply:(float*) matrixA With:(float*) matrixB {
    float *result = (float*) malloc(16 * sizeof(float));

    result[0] = matrixA[0] * matrixB[0] + matrixA[4] * matrixB[1] + matrixA[8] * matrixB[2] + matrixA[12] * matrixB[3];
    result[1] = matrixA[1] * matrixB[0] + matrixA[5] * matrixB[1] + matrixA[9] * matrixB[2] + matrixA[13] * matrixB[3];
    result[2] = matrixA[2] * matrixB[0] + matrixA[6] * matrixB[1] + matrixA[10] * matrixB[2] + matrixA[14] * matrixB[3];
    result[3] = matrixA[3] * matrixB[0] + matrixA[7] * matrixB[1] + matrixA[11] * matrixB[2] + matrixA[15] * matrixB[3];
    
    result[4] = matrixA[0] * matrixB[4] + matrixA[4] * matrixB[5] + matrixA[8] * matrixB[6] + matrixA[12] * matrixB[7];
    result[5] = matrixA[1] * matrixB[4] + matrixA[5] * matrixB[5] + matrixA[9] * matrixB[6] + matrixA[13] * matrixB[7];
    result[6] = matrixA[2] * matrixB[4] + matrixA[6] * matrixB[5] + matrixA[10] * matrixB[6] + matrixA[14] * matrixB[7];
    result[7] = matrixA[3] * matrixB[4] + matrixA[7] * matrixB[5] + matrixA[11] * matrixB[6] + matrixA[15] * matrixB[7];
    
    result[8] = matrixA[0] * matrixB[8] + matrixA[4] * matrixB[9] + matrixA[8] * matrixB[10] + matrixA[12] * matrixB[11];
    result[9] = matrixA[1] * matrixB[8] + matrixA[5] * matrixB[9] + matrixA[9] * matrixB[10] + matrixA[13] * matrixB[11];
    result[10] = matrixA[2] * matrixB[8] + matrixA[6] * matrixB[9] + matrixA[10] * matrixB[10] + matrixA[14] * matrixB[11];
    result[11] = matrixA[3] * matrixB[8] + matrixA[7] * matrixB[9] + matrixA[11] * matrixB[10] + matrixA[15] * matrixB[11];
    
    result[12] = matrixA[0] * matrixB[12] + matrixA[4] * matrixB[13] + matrixA[8] * matrixB[14] + matrixA[12] * matrixB[15];
    result[13] = matrixA[1] * matrixB[12] + matrixA[5] * matrixB[13] + matrixA[9] * matrixB[14] + matrixA[13] * matrixB[15];
    result[14] = matrixA[2] * matrixB[12] + matrixA[6] * matrixB[13] + matrixA[10] * matrixB[14] + matrixA[14] * matrixB[15];
    result[15] = matrixA[3] * matrixB[12] + matrixA[7] * matrixB[13] + matrixA[11] * matrixB[14] + matrixA[15] * matrixB[15];
    
    return result;
}


- (void)render:(CADisplayLink*)displayLink {
    glClearColor(0.0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    float h = 4.0f * self.frame.size.height / self.frame.size.width;
    float *projection = [self frustumWithLeft:-2 Right:2 Top:h/2 Bottom:-h/2 Near:0.5f Far:100.0f];
    
    glUniformMatrix4fv(mProjectionUniform, 1, false, projection);
    
    float *modelView = [self translationWithX:0 Y:0 Z:-4];
    
    mCurrentRotation += displayLink.duration * 30;
    modelView = [self multiply:modelView With:[self rotateByYXZwithX:mCurrentRotation Y:0 Z:0]];
    
    glUniformMatrix4fv(mModelViewUniform, 1, false, modelView);
    float color[] = {1, 0, 0, 0};
    glUniform4fv(mColorSlot, 1, color);
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    glVertexAttribPointer(mPositionSlot, 3, GL_FLOAT, false, sizeof(Vertex), 0);
    //glVertexAttribPointer(mColorSlot, 4, GL_FLOAT, false, sizeof(Vertex), (GLvoid*) (sizeof(float) * 3));

    //glDrawArrays(GL_TRIANGLES, 0, numVertices);
    glDrawElements(GL_TRIANGLES, numIndices * 3, GL_UNSIGNED_SHORT, 0);
    
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
    
    mPositionSlot = glGetAttribLocation(programHandle, "aPosition");
    glEnableVertexAttribArray(mPositionSlot);

    mColorSlot = glGetUniformLocation(programHandle, "uSourceColor");
    mProjectionUniform = glGetUniformLocation(programHandle, "uProjection");
    mModelViewUniform = glGetUniformLocation(programHandle, "uModelView");
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
        printf("%i", [self readIntFromFile:file]);
        printf("\n");
    }
    
    unsigned int length = [self readIntFromFile:file];
    numVertices = length / 3;
    
    printf("%d\n", length);
    
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
    
    Normals = (Normal*) malloc((length / 3) * sizeof(Normal));
    
    for (int i = 0; i < length / 3; i++) {
        float x = [self readFloatFromFile:file];
        float y = [self readFloatFromFile:file];
        float z = [self readFloatFromFile:file];
        Normals[i].Direction[0] = x;
        Normals[i].Direction[1] = y;
        Normals[i].Direction[2] = z;
    }
        
    for (int i = 0; i < 4; i++) {
        length = [self readIntFromFile:file];
        printf("%d\n", length);
        numIndices = length;
        
        Indices = (GLushort*) malloc(length * 3 * sizeof(GLushort));
        
        int index = 0;
        
        for (int j = 0; j < length * 6; j += 6) {
            Indices[index] = [self readShortFromFile:file];
            Indices[index + 1] = [self readShortFromFile:file];
            Indices[index + 2] = [self readShortFromFile:file];
            
            index += 3;
            
            [self readShortFromFile:file];
            [self readShortFromFile:file];
            [self readShortFromFile:file];
        }
        
        //[indexArray addObject:Indices];
    }
}

- (void) setupVBOs {
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, numVertices * 3 * sizeof(float), Vertices, GL_STATIC_DRAW);
    
    //printf("Size of Vertices: %d \n", sizeof(Vertices));
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, numIndices * 3 * sizeof(GLushort), Indices, GL_STATIC_DRAW);
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
