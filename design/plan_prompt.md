Act as an experienced software architect responsible for execution.
Create an implementation plan that operationalizes the approved design into a maintainable, test-driven codebase.

Address development sequencing, dependency management, validation strategies, regression coverage, performance verification, and documentation updates.
The approved design and architecture are fixed and authoritative; do not modify, reinterpret, or extend them.

The implementation plan must include, at minimum:
- Implementation details
- Implementation steps
- Clearly defined implementation milestones

Each implementation milestone must:

- Begin with a clearly stated goal
- Describe the concrete implementation steps required to achieve that goal
- Conclude with expanded test coverage (unit, integration, and regression)
- Include result verification against design expectations
- Require corresponding documentation updates
- Explicitly mark the relevant plan sections and steps as complete

Emphasize a strong test strategy, with unit, integration, and regression tests explicitly mapped to implementation milestones.
Include checkpoints for performance validation and benchmarking against the original design expectations.
The structure and naming of plan sections are up to you, provided all required elements are clearly present and traceable.

Test dependencies must include at least:
* tools\v6emul - CLI emulator for Vector 06c machine. Great for unit testing.
* tools\v6asm - CLI assembler for Vector 06c machine. Creat for ASM syntax documentation, intermidiate ASM output comparisen and testing, and for ASM to ROM assembling for testing purposes.
