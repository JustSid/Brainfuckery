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
    uint8_t __tstorage;
    
    size_t heapSize;
    uint8_t *storage;
    uint8_t *heap; // used by type II
    
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
                
            case kBFExtendedInterpreterDialectTypeII:
            {
                NSMutableCharacterSet *characterSet = [[NSMutableCharacterSet characterSetWithCharactersInString:@"@$!{}~^&|?)(*/=_%"] retain];
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
                *storage = *pointer;
                return YES;
                
            case '!':
                *pointer = *storage;
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
                *pointer ^= *storage;
                return YES;
                
            case '&':
                *pointer &= *storage;
                return YES;
                
            case '|':
                *pointer |= *storage;
                return YES;
                
            default:
                break;
        }
    }
    
    if(type >= kBFExtendedInterpreterDialectTypeII)
    {
        switch(character)
        {
            case '[':
                if(*pointer == 0)
                {
                    uint8_t *tinstruction = instruction;
                    while(*(instruction ++) != ']')
                    {
                        if(*instruction == '@')
                        {
                            instruction = tinstruction;
                            break;
                        }
                    }
                }
                return YES;
                
            case '?':
                instruction = pointer;
                return YES;
                
            case ')':
            {
                size_t offset = pointer - heap;
                
                heapSize ++;
                heap = realloc(heap, heapSize);
                
                storage = heap;
                script = heap + 1;
                memory = heap + scriptSize + 1;
                memoryLimit = memory + memorySize;
                
                pointer = heap + offset;
                memmove(&heap[offset + 1], &heap[offset], heapSize - offset);
            }
                return YES;
                
            case '(':
            {
                size_t offset = pointer - heap;
                
                memmove(&heap[offset], &heap[offset + 1], heapSize - offset);
                heapSize --;
            }
                return YES;
                
            case '*':
                *pointer *= *storage;
                return YES;
                
            case '/':
                *pointer /= *storage;
                return YES;
                
            case '=':
                *pointer += *storage;
                return YES;
                
            case '_':
                *pointer -= *storage;
                return YES;
                
            case '%':
                *pointer %= *storage;
                return YES;
                
            default:
                break;
        }
    }
    
    return [super executeCharacter:character];
}


#pragma mark -
#pragma mark Init / Dealloc

- (void)setScript:(NSString *)tscript
{
    [super setScript:tscript];
    
    __tstorage = 0;
    storage = &__tstorage;
    
    if(type == kBFExtendedInterpreterDialectTypeII)
    {
        if(heap)
            free(heap);
        
        if(memory)
            free(memory);
        
        BOOL foundTerminator = NO;
        NSCharacterSet *characterSet = [self validCharacters];
        
        uint8_t *temp = script;
        size_t actualScriptSize = 0;
        
        scriptSize = 0;
        
        for(NSUInteger i=0; i<[tscript length]; i++)
        {
            unichar character = [tscript characterAtIndex:i];
            
            if(!foundTerminator && [characterSet characterIsMember:character])
            {
                *(temp ++) = (uint8_t)character;
                scriptSize ++;
                actualScriptSize ++;
                
                if(character == '@')
                    foundTerminator = YES;
            }
            else if(foundTerminator)
            {
                *(temp ++) = (uint8_t)character;
                actualScriptSize ++;
            }
        }
        
        
        heapSize = scriptSize + memorySize + 1;
        heap = malloc(heapSize);
        storage = heap;
        
        memory = heap + scriptSize + 1;
        memoryLimit = memory + memorySize;
        pointer = memory;
        
        memset(heap, 0, heapSize);
        memcpy(&heap[1], script, actualScriptSize);
        
        free(script);
        script = instruction = heap + 1;
    }
}

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
    if((self = [super init]))
    {
        type = dialect;
        [self setScript:tscript];
    }
    
    return self;
}
- (id)initWithScript:(NSString *)tscript memory:(size_t)size andDialect:(BFExtendedInterpreterType)dialect
{
    if((self = [super initWithMemory:size]))
    {
        type = dialect;
        [self setScript:tscript];
    }
    
    return self;
}

- (void)dealloc
{
    if(heap)
    {
        free(heap);
        memory = NULL;
        script = NULL;
    }
    
    [allowedCharacters release];
    [super dealloc];
}

@end
