# Ferus is getting redesigned!
For the past few months, I've been writing a CSS3 parser, a HTTP client, a bytecode interpreter, and a renderer for Ferus. It's about time to start assembling everything into one (if you want to be accurate, two) binaries! Everything's getting reworked.

There's also a Nix shell available with all the foreign dependencies Ferus needs.

So far,
- The old, error prone IPC layer has been replaced with a new IPC library as well!
- The old firejail-based sandbox has been replaced with Seccomp instead!

# Roadmap for the overall project
- Implementing `spawn<XYZ>` functions in the master process
- Implementing the worker process component
- Implementing the network process component
- Implementing the renderer process component
- Implementing the HTML parser process component
- Implementing the CSS parser process component
- Plugging the layout engine with ferusgfx
- Getting Mirage up to speed
- Finalizing Stylus' API
- Layout compliance
- Implementing the JavaScript runtime process component

2024 is gonna be ~~painful~~ fun for me :)

# Hacking on Ferus
For details on building/hacking on Ferus, consult the BUILDING.md document.
