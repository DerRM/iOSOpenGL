//
//  OpenGLView.h
//  iPhoneOpenGL
//
//  Created by Christopher Sierigk on 13.08.12.
//  Copyright (c) 2012 Christopher Sierigk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import "Math.h"

typedef struct {
    float Position[3];
    //float Color[4];
} Vertex;

typedef struct {
    float Direction[3];
} Normal;

@interface OpenGLView : UIView {
    CAEAGLLayer* mEaglLayer;
    EAGLContext* mContext;
    GLuint mColorRenderBuffer;
    GLuint mPositionHandle;
    GLuint mNormalHandle;
    GLuint mColorHandle;
    GLuint mMVPMatrixHandle;
    GLuint mMVMatrixHandle;
    GLuint mLightPosHandle;
    float mCurrentRotation;
    GLuint mDepthRenderBuffer;
    unsigned int numVertices;
    unsigned int numNormals;
    Vertex* Vertices;
    Normal* Normals;
    unsigned int numIndices;
    GLushort* Indices;
    Matrix4* mVMatrix;
    Matrix4* mRotationMatrix;
    Matrix4* mModelMatrix;
    Vector4* mLightPosInModelSpace;
    GLuint mPositionBuffer;
    GLuint mNormalBuffer;
    GLuint mIndexBuffer;
}

@end
