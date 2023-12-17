# Base for all policyman policies, OS-agnostic

Permissions:
- r: read
- w: write
- i: ipc (talk to main Ferus process)
- g: gpu (compute/parallelisation)
- n: network

| ProcessType    | Permissions | Job                                                  | 
| -------------- | ----------- | ---------------------------------------------------- |
| Net            | ni          | Fetch data from the web (also WebSockets)            |
| Broker         | rwign       | Control processes below, talk to main Ferus process  |
| Renderer       | gi          | Render to the screen                                 |
| HTMLParser     | i           | Parse HTML source code                               |
| CSSParser      | i           | Parse CSS source code                                |
| BaliRuntime    | as required | JS runtime                                           |

Each tab will run 5 processes in Ferus for maximum security and isolation.
