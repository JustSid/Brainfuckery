//
//  BFExtendedInterpreter.h
//  Brainfuckery
//
//  Created by Sidney Just on 14.11.12.
//  Copyright (c) 2012 widerwille. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BFInterpreter.h"

typedef enum
{
    kBFExtendedInterpreterDialectClassic,
    kBFExtendedInterpreterDialectTypeI, // http://esolangs.org/wiki/Extended_Brainfuck#Extended_Type_I
    kBFExtendedInterpreterDialectTypeII, // http://esolangs.org/wiki/Extended_Brainfuck#Extended_Type_II
} BFExtendedInterpreterType;

@interface BFExtendedInterpreter : BFInterpreter

- (id)initWithDialect:(BFExtendedInterpreterType)dialect;
- (id)initWithMemory:(size_t)size andDialect:(BFExtendedInterpreterType)dialect;
- (id)initWithScript:(NSString *)script andDialect:(BFExtendedInterpreterType)dialect;
- (id)initWithScript:(NSString *)script memory:(size_t)size andDialect:(BFExtendedInterpreterType)dialect;

@end
