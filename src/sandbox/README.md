# Ferus Sandbox implementation

Sandboxing is a technique to isolate access to system resources by untrusted code (i.e the entirity of the internet)
Ferus implements this Blink-style for now, but there are plans to introduce build flags for different sandboxing strategies.

# Implementations
Since different kernels have different tools for this, code is partitioned per unique-kernel.
We use [Seccomp](https://en.wikipedia.org/wiki/Seccomp)
