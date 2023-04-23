# Ferus -- a prototype web engine written in the Nim programming language
Ferus is a small web rendering engine that is 100% independent (not based on WebKit, Blink or Gecko), fast, and (hopefully) secure. It aims to stand as an alternative to more popular web engines by providing full compatibility to how they work.

# Why? (Why not just make a WebKit/Blink browser?)
There's plenty of reasons.
- I dislike the Chromium monopoly (despite using a Chromium based browser) and I believe there should always be an alternative standard to everything, which invites community participation.
- This web engine aims to have as less code as humanly possible, in order to reduce the attack surface.
- Be extremely customizable. Seriously. The only thing that I dislike about Chromium feature-wise is the lack of customizability of UI via CSS.
- A side-aim, if you can call it that, is to increase the popularity of the Nim programming language. Seriously, it's awesome!

# Roadmap
- Basic HTML parser                                                               [V]
- Basic CSS parser                                                                [V]
- Basic compositing (ps. possibly via [pixie](https://github.com/treeform/pixie)) [X]
- Process isolation and sandboxing (Mozilla Ignition style sandboxing)            [X]
- HTML5 (WHATWG) & CSS3 support                                                   [X]
- Hardware accelerated video decode                                               [X]
- MV2-3 support (MV2 will never be deprecated here, once implemented)             [X]
- Windows and MacOS builds                                                        [X]
- BSD-family builds, should be trivial                                            [X]
- Android and iOS builds, probably will be hellish                                [X]
- ...Nintendo Switch builds, I suppose...?                                        [X]

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
$ nimble build
$ ./ferus
```
