# Base for all policyman policies, OS-agnostic

Permissions:
- r: read
- w: write
- i: ipc (talk to main Ferus process)
- g: gpu (compute/parallelisation)
- n: network

| ProcessType    | Permissions | Job                                                  | 
| -------------- | ----------- | ---------------------------------------------------- |
| Net            | n           | Fetch data from the web (also WebSockets)            |
| Broker         | rwign       | Control processes below, talk to main Ferus process  |
| Renderer       | g           | Render to the screen                                 |
| HTMLParser     | none        | Parse HTML source code                               |
| CSSParser      | none        | Parse CSS source code                                |
| BaliRuntime    | as required | JS runtime                                           |

Each tab will run 5 processes in Ferus for maximum security and isolation.
