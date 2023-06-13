# Ferus -- a prototype web engine written in the Nim programming language
Ferus is a small web rendering engine that is 100% independent (not based on WebKit, Blink or Gecko), fast, and (hopefully) secure. It aims to stand as an alternative to more popular web engines by providing full compatibility to how they work.\
Ferus also stands for "Fast Engine (for) Rendering Ur Site", if you'd prefer that. :)\
It currently stands at 2519 lines of code, and has process isolation, simple compositing, a WIP layout engine, an incomplete DOM and HTML/CSS parsers ready.

# Why? (Why not just make a WebKit/Blink browser?)
There's plenty of reasons.
- I dislike the Chromium monopoly (despite using a Chromium based browser) and I believe there should always be an alternative standard to everything, which invites community participation.
- This web engine aims to have as less code as humanly possible, in order to reduce the attack surface.
- Be extremely customizable. Seriously. The only thing that I dislike about Chromium feature-wise is the lack of customizability of UI via CSS.
- A side-aim, if you can call it that, is to increase the popularity of the Nim programming language. Seriously, it's awesome!

# Contributions
Please read the best code practices in the documentation and follow basic human etiquette.
Helping out is more than appreciated!

You can join the Discord server for more in-depth discussion on Ferus: https://discord.gg/Cz5uRWsR
If you don't like Discord (for obvious reasons) then you can just make issues.

# Aim
- To work as a usable web engine/browser for my personal usage.
- To do what every other engine isn't doing, that is, full utilization of system cores (not as in Chrome's memory hog, but lenient utilization of cores). All modern web engines were built with 1 or 2 cores in mind, Ferus will use a good parallelization library for Nim called [weave](https://github.com/mratsim/weave) for parallelizing everything.

# Roadmap (P = Partially done)
- [X] Basic HTML parser
- [X] Basic CSS parser
- [X] Basic compositing
- [X] Process isolation and sandboxing (Chromium style sandboxing)
- [X] HTML5 (WHATWG) & CSS3 support
- [ ] Layout
- [ ] Hardware accelerated video decode
- [ ] MV2-3 support (MV2 will never be deprecated here, once implemented)
- [ ] Windows and MacOS builds
- [ ] BSD-family builds, should be trivial
- [ ] Android and iOS builds, probably will be hellish
- [ ] ...Nintendo Switch builds, I suppose...?

# When will it be complete?
Like all free and open source software, there is no set date for release 1.0
However, once you are able to open up web pages, please, for the love of God himself, do *NOT*
go log into your bank account with Ferus.

# Okay, but how do I run it?
Ferus does not have any proper releases yet, just random tomfoolery and testing is currently going on. To try it out, execute the following (tested on Linux only, because Windows sucks for anything besides gaming).
Anything beyond Nim 1.6 should do. Nimble is also required.
```bash
$ git clone https://github.com/xTrayambak/ferus.git
$ cd ferus
$ nimble productionBuild # Package maintainers: use this, there is debugBuild, but it is only for Ferus developers and it produces bloated binaries
$ cd bin
$ ./ferus
```

To run Ferus in Docker:
```bash
$ docker-compose build
$ docker compose run ferus /bin/bash
$ nimble productionBuild
$ cd bin
$ ./ferus
```

# Attributions
[SHA256 implementation](https://github.com/jangko/nimSHA2/)
