# Best Code Practices for contributing to Ferus

In order to keep the codebase unconvoluted, there are now to be a few guidelines
regarding how code should be written. These won't necessarily dictate that your PRs
get rejected, but they are recommended to be followed.

# Function/variable/attribute naming
As per how Nim is written, camelCase is recommended to maintain uniformity in
the browser's APIs. If you attempt to push code with snake_case or PascalCase
in it, it will be rejected on the spot. The only place where this is not the case
are constant variables.

```nim
const MY_FANCY_VALUE = 84    # This is perfectly fine.
const myFancyValue = 84      # This is not fine. Constants must use snake_case.
const MyFancyValue = 84      # This is not fine. PascalCase is not allowed.

# This is perfectly fine.
proc epicFunction: int =
    MY_FANCY_VALUE + 4

# This is not fine.
proc epic_function: int =
    MY_FANCY_VALUE + 4

# This is not fine either.
proc EpicFunction: int =
    MY_FANCY_VALUE + 4
```

# Logging
Code must be logged, but not too much (not something like "creating variable xyz"). No logging library other than [chronicles](https://github.com/status-im/nim-chronicles)
is permitted. This is how you should write logs.
```
info "[src/{directory to source file of log}] Doing the dishes"
```

# Dependencies
- You cannot add any new dependencies without explaining them fully and the reasoning,
and why they could not be implemented in the codebase itself. Refrain from segregating
the engine into seperate Nimble dependencies (for now).

- Try to use "pure" libraries (Nim's way of saying libraries written in any language 
other than Nim). Only critical libraries such as GLFW (windowing) and 
OpenAL/miniaudio (audio, duh) are allowed as no such implementation exists in Nim
that is as good as them yet.

# Pointers and Threads
- Try to avoid pointers as if they're the plague, unless your hand is forced into them
via an impure library/wrapper.
- Threading is encouraged, but do not create 80 threads per process.
