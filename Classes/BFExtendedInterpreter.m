//
//  BFExtendedInterpreter.m
//  Brainfuckery
//
//  Created by Sidney Just on 14.11.12.
//  Copyright (c) 2012 widerwille. All rights reserved.
//

#import "BFExtendedInterpreter.h"

@interface BFExtendedInterpreter ()
{
    uint8_t storage;
    
    NSCharacterSet *allowedCharacters;
    BFExtendedInterpreterType type;
}
@end

@implementation BFExtendedInterpreter

#pragma mark -
#pragma mark Interpreter

- (NSCharacterSet *)validCharacters
{
    if(!allowedCharacters)
    {     
        switch(type)
        {
            case kBFExtendedInterpreterDialectTypeI:
                {
                    NSMutableCharacterSet *characterSet = [[NSMutableCharacterSet characterSetWithCharactersInString:@"@$!{}~^&|"] retain];
                    [characterSet formUnionWithCharacterSet:[super validCharacters]];
                    
                    allowedCharacters = characterSet;
                }
                break;
                
            default:
                allowedCharacters = [[super validCharacters] retain];
                break;
        }
    }
    
    return allowedCharacters;
}

- (BOOL)executeCharacter:(unichar)character
{
    if(type >= kBFExtendedInterpreterDialectTypeI)
    {
        switch(character)
        {
            case '@':
                return NO;
                
            case '$':
                storage = *pointer;
                return YES;
                
            case '!':
                *pointer = storage;
                return YES;
                
            case '}':
                *pointer >>= 1;
                return YES;
                
            case '{':
                *pointer <<= 1;
                return YES;
                
            case '~':
                *pointer = ~*pointer;
                return YES;
                
            case '^':
                *pointer ^= storage;
                return YES;
                
            case '&':
                *pointer &= storage;
                return YES;
                
            case '|':
                *pointer |= storage;
                return YES;
                
            default:
                break;
        }
    }
    
    return [super executeCharacter:character];
}


#pragma mark -
#pragma mark Init / Dealloc

- (id)initWithMemory:(size_t)size
{
    return [self initWithMemory:size andDialect:kBFExtendedInterpreterDialectTypeI];
}

- (id)initWithDialect:(BFExtendedInterpreterType)dialect
{
    if((self = [super init]))
    {
        type = dialect;
    }
    
    return self;
}
- (id)initWithMemory:(size_t)size andDialect:(BFExtendedInterpreterType)dialect
{
    if((self = [super initWithMemory:size]))
    {
        type = dialect;
    }
    
    return self;
}
- (id)initWithScript:(NSString *)tscript andDialect:(BFExtendedInterpreterType)dialect
{
    if((self = [super initWithScript:tscript]))
    {
        type = dialect;
    }
    
    return self;
}
- (id)initWithScript:(NSString *)tscript memory:(size_t)size andDialect:(BFExtendedInterpreterType)dialect
{
    if((self = [super initWithScript:tscript andMemory:size]))
    {
        type = dialect;
    }
    
    return self;
}

- (void)dealloc
{
    [allowedCharacters release];
    [super dealloc];
}

@end
