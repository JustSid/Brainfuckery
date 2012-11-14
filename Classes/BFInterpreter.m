//
//  BFInterpreter.m
//  Brainfuckery
//
//  Created by Sidney Just
//  Copyright (c) 2012 by Sidney Just
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
//  and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
//  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
//  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "BFInterpreter.h"

@interface BFLoopEntry : NSObject
{
    NSUInteger begin;
    NSUInteger end;
}

@property (nonatomic, readonly) NSUInteger begin;
@property (nonatomic, readonly) NSUInteger end;

- (id)initWithScript:(NSString *)script index:(NSUInteger)index andInterpreter:(BFInterpreter *)interpreter;

@end

@interface BFInterpreter ()
{
    BOOL executing;
    NSMutableArray *loopEntries;
    
    id<BFInterpreterDelegate> delegate;
    BOOL delegateSupportsWillInterpret;
    BOOL delegateSupportsGeneratedOutput;
    
    BFInterpreterChracterOutputBlock willInterpret;
    BFInterpreterChracterOutputBlock generatedOutput;
    BFInterpreterCharacterInputBlock needsInput;
}
@end


@implementation BFInterpreter
@synthesize script, delegate;
@synthesize willInterpret, generatedOutput, needsInput;

#pragma mark -
#pragma mark Interpreter

- (NSCharacterSet *)validCharacters
{
    static dispatch_once_t token;
    static NSCharacterSet *characters;
    
    dispatch_once(&token, ^{
        characters = [NSCharacterSet characterSetWithCharactersInString:@"><-+.,[]"];
    });
    
    return characters;
}

- (unichar)advanceToNextCharacter
{
    unichar character;
    NSCharacterSet *characters = [self validCharacters];
    
    do {
        if(index >= [script length])
            return '\0';
        
        character = [script characterAtIndex:index ++];
    } while(![characters characterIsMember:character]);
    
    return character;
}

- (BOOL)executeCharacter:(unichar)character
{
    switch(character)
    {
        case '>':
            pointer ++;
            NSAssert(pointer < memoryLimit, @"BFInterpreter, pointer moved outside of memory region!");
            break;
            
        case '<':
            pointer --;
            NSAssert(pointer >= memory, @"BFInterpreter, pointer moved outside of memory region!");
            break;
            
        case '+':
            (*pointer) ++;
            break;
            
        case '-':
            (*pointer) --;
            break;
            
        case '.':
        {
            char output = *pointer;
            
            if(delegateSupportsGeneratedOutput)
                [delegate interpreter:self generatedOutput:output];
            
            if(generatedOutput)
                generatedOutput(output);
            
            if(!delegateSupportsGeneratedOutput && !generatedOutput)
                putc(output, stdout);
        }
            break;
            
        case ',':
            NSAssert(delegate || needsInput, @"BFInterpreter requires input, but neither a delegate nor a needsInput block are present!");
            
            if(needsInput)
            {
                char input = needsInput();
                *pointer = (uint8_t)input;
            }
            else
                if(delegate)
                {
                    char input = [delegate interpreterNeedsInput:self];
                    *pointer = (uint8_t)input;
                }
            break;
            
        case '[':
        {
            BFLoopEntry *entry = [[BFLoopEntry alloc] initWithScript:script index:index andInterpreter:self];
            
            if(*pointer)
            {
                index = [entry begin];
                
                [loopEntries addObject:entry];
                [entry release];
                
                break;
            }
            
            index = [entry end];
            [entry release];
        }
            break;
            
        case ']':
        {
            BFLoopEntry *entry = [loopEntries lastObject];
            NSAssert(entry, @"BFInterpreter encountered ']' but no loop entry found!");
            
            if(*pointer)
            {
                index = [entry begin];
                break;
            }
            
            [loopEntries removeLastObject];
        }
            break;
            
        case '\0':
            return NO;
            
        default:
            NSLog(@"Unknown character %c", character);
            return NO;
    }
    
    return YES;
}

- (BOOL)executeStep
{
    NSAssert(script, @"BFInterpeter needs a script to execute!");
    
    @synchronized(self)
    {
        unichar character = [self advanceToNextCharacter];
        if(character != '\0')
        {
            if(delegateSupportsWillInterpret)
                [delegate interpreter:self willInterpretCharacter:character];
            
            if(willInterpret)
                willInterpret((char)character);
        }
        
        return [self executeCharacter:character];
    }
}

- (void)execute
{
    executing = YES;
    
    while([self executeStep])
    {}
    
    executing = NO;
}

- (void)executeAsync
{
    [self retain];
    
    dispatch_queue_t queue = dispatch_queue_create("com.widerwille.brainfuckery.interpreter", NULL);
    dispatch_async(queue, ^{
        [self execute];
        [self release];
        
        dispatch_release(queue);
    });
}


#pragma mark -
#pragma mark Getter / Setter

- (void)setDelegate:(id<BFInterpreterDelegate>)tdelegate
{
    delegate = tdelegate;
    
    delegateSupportsWillInterpret = [delegate respondsToSelector:@selector(interpreter:willInterpretCharacter:)];
    delegateSupportsGeneratedOutput = [delegate respondsToSelector:@selector(interpreter:generatedOutput:)];
}

- (void)setScript:(NSString *)tscript
{
    NSAssert(!executing, @"setScript: must not be called while executing script!");
    
    @synchronized(self)
    {
        [script release];
        script = [tscript copy];
        index = 0;
        
        pointer = memory;
        memset(memory, 0, memorySize);
    }
}

#pragma mark -
#pragma mark Init / Dealloc

- (id)init
{
    return [self initWithMemory:30000];
}

- (id)initWithMemory:(size_t)size
{
    if((self = [super init]))
    {
        memorySize = size;
        memory = pointer = malloc(memorySize);
        memoryLimit = memory + memorySize;
        
        loopEntries = [[NSMutableArray alloc] init];
        
        if(!memory)
        {
            [self release];
            return nil;
        }
    }
    
    return self;
}

- (id)initWithScript:(NSString *)tscript
{
    if((self = [self init]))
    {
        [self setScript:tscript];
    }
    
    return self;
}

- (id)initWithScript:(NSString *)tscript andMemory:(size_t)size
{
    if((self = [self initWithMemory:size]))
    {
        [self setScript:tscript];
    }
    
    return self;
}

- (void)dealloc
{
    if(memory)
        free(memory);
    
    [script release];
    [loopEntries release];
    
    Block_release(willInterpret);
    Block_release(generatedOutput);
    Block_release(needsInput);
    
    [super dealloc];
}

@end

#pragma mark -
#pragma mark BFLoopEntry

@implementation BFLoopEntry
@synthesize begin, end;

- (id)initWithScript:(NSString *)script index:(NSUInteger)index andInterpreter:(BFInterpreter *)interpreter
{
    if((self = [super init]))
    {
        NSCharacterSet *characterSet = [interpreter validCharacters];
        uint32_t openingBrackets = 1;
        unichar character;
        
        begin = index;
        character = [script characterAtIndex:begin];
        
        while(![characterSet characterIsMember:character])
        {
            begin ++;
            character = [script characterAtIndex:begin];
        }
        
        for(end = begin; ; end++)
        {
            NSAssert(end < [script length], @"BFLoopEntry could not find closing ']' in script");
            character = [script characterAtIndex:end];
            
            switch (character)
            {
                case '[':
                    openingBrackets ++;
                    break;
                    
                case ']':
                    openingBrackets --;
                    if(openingBrackets == 0)
                    {
                        return self;
                    }
                    
                    break;
                    
                default:
                    break;
            }
        }
    }
    
    return self;
}

@end
