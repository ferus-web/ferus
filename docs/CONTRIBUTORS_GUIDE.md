# I want to contribute to Ferus.
Thanks for showing interest! Here's a """guide""" on how to, alongside some questions and their answers.

## But, I've never worked on a web engine!
Fun fact: Nor have I before this! Writing a browser from scratch isn't a trivial task, obviously, but it isn't rocket science either. You can read some specs, see how Ferus internally works and implement new features.

Currently, I'm mainly looking for contributions relating to JavaScript (Web APIs) and layout (flow layout).

### Contributing to the JavaScript layer
You can check out [this file](src/components/web/window.nim) which shows you how you can define a type and introduce it into a JavaScript runtime. This is glued in [here](src/components/js/process.nim#L34).

### Contributing to the layout engine
All of the things that you need are in [this directory](src/components/layout).

## What experience do I really need?
You just need to know Nim and need to take some time to see how the codebase works. I'm always ready to help anyone who's interested out. Feel free to ask me all your doubts via either mail (xtrayambak at disroot dot org) or Discord (xtrayambak). You can also just join the [Ferus Discord server](https://discord.gg/9MwfGn2Jkb)
