# 🐚 MyShell Project

## Overview
MyShell is a custom shell implementation that replicates many of the core functionalities of traditional Unix shells. It supports command parsing, execution, file redirection, piping, signal handling, subshells, and more advanced features like environment variable expansion, tilde expansion, and command history. This project showcases a deep understanding of systems programming, process management, and shell scripting.

## ✨ Features

### Part 1: Parsing and Executing Commands
1. **Parsing and Executing Commands**
   - **1A: Lex and Yacc** - The shell accepts more complex commands using Lex and Yacc for parsing.
   - **1B: Executing commands**
     - **1B.1: Simple command process creation and execution** - Executes basic shell commands by creating child processes.
     - **1B.2: File redirection** - Implements input (`<`) and output (`>`, `>>`) redirection.
     - **1B.3: Pipes** - Supports piping (`|`) between commands to chain their output and input.
     - **1B.4: isatty()** - Detects if input is from a terminal to support batch processing of commands.

### Part 2: Signal Handling, More Parsing, and Subshells
2. **Signal Handling, More Parsing, and Subshells**
   - **2.1: Ctrl-C** - Implements signal handling to gracefully terminate processes with Ctrl-C.
   - **2.2: Exit** - Supports the `exit` command to close the shell.
   - **2.3: Quotes** - Handles single (`'`) and double (`"`) quotes for argument parsing.
   - **2.4: Escaping** - Allows for escaping special characters using backslashes (`\`).
   - **2.5: Builtin Functions** - Includes shell built-in functions like `cd`, `echo`, etc.
   - **2.6: Zombie Elimination** - Ensures that all child processes are properly reaped to prevent zombie processes.
   - **2.7: Ctrl-Z (Extra Credit!)** - Adds support for job control by suspending processes with Ctrl-Z.
   - **2.8: Creating a Default Source File: ".shellrc"** - Loads a configuration file (`.shellrc`) on startup to set up environment variables and aliases.
   - **2.9: Subshells** - Supports command execution within subshells using parentheses (`()`).

### Part 3: Expansions, Wildcards, and Line Editing
3. **Expansions, Wildcards, and Line Editing**
   - **3.1: Environment variable expansion** - Expands environment variables (e.g., `$HOME`).
   - **3.2: Tilde expansion** - Expands tilde (`~`) to the user's home directory.
   - **3.3: Wildcarding** - Supports wildcard characters (`*`, `?`) for pattern matching in file names.
   - **3.4: Edit mode** - Provides line editing features for command input, similar to readline.
   - **3.5: History** - Implements command history, allowing users to navigate through previous commands.
   - **3.6: Path completion** - Supports auto-completion of file paths and commands.
   - **3.7: Variable prompt** - Customizable shell prompt with variable expansions.

# 🐚 MyShell Project

## Overview
MyShell is a custom shell implementation that replicates many of the core functionalities of traditional Unix shells. It supports command parsing, execution, file redirection, piping, signal handling, subshells, and more advanced features like environment variable expansion, tilde expansion, and command history. This project showcases a deep understanding of systems programming, process management, and shell scripting.

## ✨ Features

### Part 1: Parsing and Executing Commands
1. **Parsing and Executing Commands**
   - **1A: Lex and Yacc** - The shell accepts more complex commands using Lex and Yacc for parsing.
   - **1B: Executing commands**
     - **1B.1: Simple command process creation and execution** - Executes basic shell commands by creating child processes.
     - **1B.2: File redirection** - Implements input (`<`) and output (`>`, `>>`) redirection.
     - **1B.3: Pipes** - Supports piping (`|`) between commands to chain their output and input.
     - **1B.4: isatty()** - Detects if input is from a terminal to support batch processing of commands.

### Part 2: Signal Handling, More Parsing, and Subshells
2. **Signal Handling, More Parsing, and Subshells**
   - **2.1: Ctrl-C** - Implements signal handling to gracefully terminate processes with Ctrl-C.
   - **2.2: Exit** - Supports the `exit` command to close the shell.
   - **2.3: Quotes** - Handles single (`'`) and double (`"`) quotes for argument parsing.
   - **2.4: Escaping** - Allows for escaping special characters using backslashes (`\`).
   - **2.5: Builtin Functions** - Includes shell built-in functions like `cd`, `echo`, etc.
   - **2.6: Zombie Elimination** - Ensures that all child processes are properly reaped to prevent zombie processes.
   - **2.7: Ctrl-Z (Extra Credit!)** - Adds support for job control by suspending processes with Ctrl-Z.
   - **2.8: Creating a Default Source File: ".shellrc"** - Loads a configuration file (`.shellrc`) on startup to set up environment variables and aliases.
   - **2.9: Subshells** - Supports command execution within subshells using parentheses (`()`).

### Part 3: Expansions, Wildcards, and Line Editing
3. **Expansions, Wildcards, and Line Editing**
   - **3.1: Environment variable expansion** - Expands environment variables (e.g., `$HOME`).
   - **3.2: Tilde expansion** - Expands tilde (`~`) to the user's home directory.
   - **3.3: Wildcarding** - Supports wildcard characters (`*`, `?`) for pattern matching in file names.
   - **3.4: Edit mode** - Provides line editing features for command input, similar to readline.
   - **3.5: History** - Implements command history, allowing users to navigate through previous commands.
   - **3.6: Path completion** - Supports auto-completion of file paths and commands.
   - **3.7: Variable prompt** - Customizable shell prompt with variable expansions.

## 🚀 Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/itsJeetJayas7/MyShell.git
   ```
2. Navigate to the project directory:
   ```bash
   cd myshell
   ```
3. Build the shell using `make`:
   ```bash
   make
   ```

## 🛠️ Usage
Start the shell by running:
```bash
./myshell
```

Use the shell just like a regular Unix shell, with support for all the features listed above.

## 🎉 Extra Credit
- Implemented Ctrl-Z for job control.
- Created a customizable `.shellrc` file for setting up the shell environment.
