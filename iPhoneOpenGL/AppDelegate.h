//
//  AppDelegate.h
//  iPhoneOpenGL
//
//  Created by Christopher Sierigk on 13.08.12.
//  Copyright (c) 2012 Christopher Sierigk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenGLView.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    OpenGLView* mGlView;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) IBOutlet OpenGLView *glView;

@end
