# Ferus' IPC model
Ferus' IPC layer uses the `ferus_ipc` package. It is blocking by default, but can turn into an on-demand read system when needed (see: The renderer component which uses `ioctl` to not block).

It uses the traditional server-client architecture. The server must treat all client data with suspicion, and any exception is a bug unless stated otherwise.
