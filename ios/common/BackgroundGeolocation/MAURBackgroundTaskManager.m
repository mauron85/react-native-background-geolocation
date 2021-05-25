//
//  MAURBackgroundTaskManager.m
//  BackgroundGeolocation
//
//  Created by Joel and Vomako (http://stackoverflow.com/a/27664620)
//

#import <UIKit/UIKit.h>
#import "MAURBackgroundTaskManager.h"

@interface MAURBackgroundTaskManager()

@property NSUInteger taskKeyCounter;
@property NSMutableDictionary *dictTaskIdentifiers;
@property NSMutableDictionary *dictTaskCompletionBlocks;

@end

@implementation MAURBackgroundTaskManager

+ (id)sharedTasks {
    static MAURBackgroundTaskManager *sharedTasks = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTasks = [[self alloc] init];
    });
    return sharedTasks;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        [self setTaskKeyCounter:0];
        [self setDictTaskIdentifiers:[NSMutableDictionary dictionary]];
        [self setDictTaskCompletionBlocks:[NSMutableDictionary dictionary]];
    }
    return self;
}

- (NSUInteger)beginTask
{
    return [self beginTaskWithCompletionHandler:nil];
}

- (NSUInteger)beginTaskWithCompletionHandler:(CompletionBlock)_completion;
{
    //read the counter and increment it
    NSUInteger taskKey;
    @synchronized(self) {
        
        taskKey = self.taskKeyCounter;
        self.taskKeyCounter++;
        
    }
    
    //tell the OS to start a task that should continue in the background if needed
    NSUInteger taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endTaskWithKey:taskKey];
    }];
    
    //add this task identifier to the active task dictionary
    [self.dictTaskIdentifiers setObject:[NSNumber numberWithUnsignedLong:taskId] forKey:[NSNumber numberWithUnsignedLong:taskKey]];
    
    //store the completion block (if any)
    if (_completion) [self.dictTaskCompletionBlocks setObject:_completion forKey:[NSNumber numberWithUnsignedLong:taskKey]];
    
    //return the dictionary key
    return taskKey;
}

- (void)endTaskWithKey:(NSUInteger)_key
{
    @synchronized(self.dictTaskCompletionBlocks) {
        
        //see if this task has a completion block
        CompletionBlock completion = [self.dictTaskCompletionBlocks objectForKey:[NSNumber numberWithUnsignedLong:_key]];
        if (completion) {
            
            //run the completion block and remove it from the completion block dictionary
            completion();
            [self.dictTaskCompletionBlocks removeObjectForKey:[NSNumber numberWithUnsignedLong:_key]];
            
        }
        
    }
    
    @synchronized(self.dictTaskIdentifiers) {
        
        //see if this task has been ended yet
        NSNumber *taskId = [self.dictTaskIdentifiers objectForKey:[NSNumber numberWithUnsignedLong:_key]];
        if (taskId) {
            
            //end the task and remove it from the active task dictionary
            [[UIApplication sharedApplication] endBackgroundTask:[taskId unsignedLongValue]];
            [self.dictTaskIdentifiers removeObjectForKey:[NSNumber numberWithUnsignedLong:_key]];
            
            NSLog(@"Task ended");
        }
        
    }
}

@end
