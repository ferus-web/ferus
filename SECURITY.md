# Bali's Security Policy
Bali is still unstable software, and is not advertised as being ready for production. As such, you are free to disclose any vulnerabilities in it publicly.

**The Ferus Authors reserve the right to amend the above statement at any given time.**

# What is a vulnerability, and what isn't.
- Any crash that happens in a debug build and doesn't occur in a release build is not a denial-of-service (DoS) vulnerability. Bali's interpreter deliberately also has a runtime-crashing opcode which only works in debug builds.

- Conformance issues are _NOT_ vulnerabilities!

- Incorrect code generation is a severe bug.

- Memory corruption is a severe bug.

- Buffer overflows are a severe bug.

# Vulnerabilities in dependencies
Bali, being a complex project, depends on a few third party projects like `simdutf` for dealing with Base64 and encoding/decoding.

- Such issues in third party libraries are _NOT_ to be reported to us! Report them to the concerned developers instead.
- If such an issue exists in a project that is maintained by the Ferus Project, then you are to report it to us in that repository's security listing.
