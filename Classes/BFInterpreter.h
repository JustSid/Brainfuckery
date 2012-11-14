//
//  BFInterpreter.h
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

#import <Foundation/Foundation.h>

typedef void(^BFInterpreterChracterOutputBlock)(char output);
typedef char(^BFInterpreterCharacterInputBlock)();

@protocol BFInterpreterDelegate;
@interface BFInterpreter : NSObject
{
@protected
    uint8_t *memory;
    uint8_t *memoryLimit;
    
    uint8_t *pointer;
    size_t memorySize;
    
    NSString *script;
    NSUInteger index;
}

@property (nonatomic, assign) id<BFInterpreterDelegate> delegate;
@property (nonatomic, copy) NSString *script;

@property (nonatomic, copy) BFInterpreterChracterOutputBlock willInterpret;
@property (nonatomic, copy) BFInterpreterChracterOutputBlock generatedOutput;
@property (nonatomic, copy) BFInterpreterCharacterInputBlock needsInput;

- (void)execute;
- (void)executeAsync;

- (BOOL)executeStep;

- (id)init;
- (id)initWithMemory:(size_t)size; // Designated initializer
- (id)initWithScript:(NSString *)script;
- (id)initWithScript:(NSString *)script andMemory:(size_t)size;

@end

@protocol BFInterpreterDelegate <NSObject>
@optional

- (void)interpreter:(BFInterpreter *)interpreter willInterpretCharacter:(unichar)character;
- (void)interpreter:(BFInterpreter *)interpreter generatedOutput:(char)output;

@required
- (char)interpreterNeedsInput:(BFInterpreter *)interpreter;

@end

@interface BFInterpreter (SubclassOverride)
- (NSCharacterSet *)validCharacters; // Return a character set with valid characters for the dialect. All other characters will be ignored when interpreting the script
- (BOOL)executeCharacter:(unichar)character; // Execute the action associated with the given character. Return NO to stop execution, YES to advance to the next character.
@end
