# How to compile Ferus?

Ferus is fairly lightweight right now. It takes a few seconds to compile.

# Downloading Ferus' source code
This is extremely easy, I have no clue why someone needs a tutorial for this, but here you go.
```bash
$ git clone https://github.com/xTrayambak/ferus.git
$ cd ferus
```

# Instructions (Linux)
Do NOT run `nimble build` as it will generate an incomplete build! Ferus will simply
crash when run, as it needs an extra binary to be generated called `libferuscli`.

Build (release build, for package maintainers or Ferus' official downloads)
```bash
$ nimble productionBuild
```
- In the bin/ folder, two binaries will be generated. They both must be shipped together.

Build (debug build, should never be packaged as it contains debug symbols)
```bash
$ nimble productionBuildDebug
```
- In the bin/ folder, two binaries will be generated. They both must be shipped together.

# Instructions (Windows)
Windows is not supported right now as I'm still figuring out the sandbox aspect.
Sorry!

# Instructions (Mac)
Mac is not supported right now as I'm still figuring out the sandbox aspect.
Sorry.
