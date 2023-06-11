# Ferus workers

Workers are similar to the sandboxed model Ferus adopts, but their lifespan is limited
to what work they have to perform unlike the rendering/html/css processes which live
as long as the tab is opened. This is a simple representational flowchart.

SERVER (main process) -> Summon worker ->
                                WORKER PROCESS -> Do task -> Send it via IPC -> Die
