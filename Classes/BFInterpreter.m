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
    uint8_t *begin;
    uint8_t *end;
}

@property (nonatomic, readonly) uint8_t *begin;
@property (nonatomic, readonly) uint8_t *end;

- (id)initWithBegin:(uint8_t *)tbegin andEnd:(uint8_t *)tend;

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
@synthesize delegate;
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

- (BOOL)executeCharacter:(char)character
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
            uint8_t *i = instruction;
            while(*(i ++) != ']')
            {}
            
            if(*pointer)
            {
                BFLoopEntry *entry = [[BFLoopEntry alloc] initWithBegin:instruction andEnd:i];

                [loopEntries addObject:entry];
                [entry release];
                
                break;
            }
            
            instruction = i;
        }
            break;
            
        case ']':
        {
            BFLoopEntry *entry = [loopEntries lastObject];
            NSAssert(entry, @"BFInterpreter encountered ']' but no loop entry found!");
            
            if(*pointer)
            {
                instruction = [entry begin];
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
        char character = (char)*(instruction ++);
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
        if(script)
            free(script);
        
        pointer = memory;
        memset(memory, 0, memorySize);
        
        script = malloc([tscript length] + 1);
        instruction = script;
        
        NSCharacterSet *allowedCharacters = [self validCharacters];
        for(NSUInteger i=0; i<[tscript length]; i++)
        {
            unichar character = [tscript characterAtIndex:i];
            
            if([allowedCharacters characterIsMember:character])
            {
                *instruction ++ = (uint8_t)character;
            }
        }
        
        instruction = script;
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
    
    if(script)
        free(script);
    
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

- (id)initWithBegin:(uint8_t *)tbegin andEnd:(uint8_t *)tend
{
    if((self = [super init]))
    {
        begin = tbegin;
        end = tend;
    }
    
    return self;
}

@end
