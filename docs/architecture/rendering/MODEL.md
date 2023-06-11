# Ferus rendering model

Rendering is done on a process seperate from Ferus' main process.
The main process is responsible for providing the renderer with a DOM, when it
requests it via the IPC pipeline command [-65526].

In order to minimize overhead, the rendering process is also responsible for
reflow and layout.
