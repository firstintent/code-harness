# Tasks

Write tasks here. Claude will execute them in order, skipping blocked ones.

## Format

```
- [ ] T<id>: <description> [mode: single|parallel|team|swarm]
      Optional: owns: <file patterns>  (for multi-machine)
      Optional: subtasks for parallel/team mode
      Optional: [blocked by D<id>]
      Optional: [claimed: <machine>, since: <ISO time>]

- [~] means in progress (claimed)
- [x] means done
```

## Active

<!-- Add your tasks here. Example:

- [ ] T001: Set up project scaffold with basic routing [mode: single]
- [ ] T002: Implement user authentication [mode: single]
- [ ] T003: Build dashboard with charts [mode: parallel]
      subtasks:
        - api: Dashboard data endpoints (~10 min)
        - ui: Dashboard components (~10 min)

-->

## Backlog

<!-- Lower priority tasks go here -->

## Done

<!-- Completed tasks are moved here -->
