//
//  XYZToDoItem.h
//  Prioritization App
//
//  Created by Carl Shan on 7/24/14.
//  Copyright (c) 2014 Carl Shan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XYZToDoItem : NSObject

@property NSString *itemName;
@property BOOL completed;
@property (readonly) NSDate *creationDate;
@property BOOL important;
@property BOOL urgent;


@end
