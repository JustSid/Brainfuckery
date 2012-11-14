Brainfuckery is a extendable Brainfuck interpreter written in Objective-C. In theory, Brainfuckery can be taught all Brainfuck dialects by subclassing the `BFInterpreter` class and overwriting the `executeCharacter:` and `validCharacters` methods. There is a subclass implementing Extended Brainfuck Type I and Type II as an example for this.

## Example
The classical Brainfuck hello world script

	NSString *script = @"++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.+++.";

	BFInterpreter *interpreter = [[BFInterpreter alloc] initWithScript:script];
	[interpreter execute];
	[interpreter release];

Hello world in Extended Brainfuck Type I

	NSString *script = @"++++{+{{{.$>-}}^>++{{{++$<^.$>[-]++{{+^..$>+++|.>++{{{{.<<<<$>>>>>-}}}^.<<.+++.<.<-.>>>+.>>+++++{.@";

	BFInterpreter *interpreter = [[BFExtendedInterpreter alloc] initWithScript:script andDialect:kBFExtendedInterpreterDialectTypeI];
	[interpreter execute];
	[interpreter release];

## License
MIT license. If you actually manage to do something useful with this, let me know.