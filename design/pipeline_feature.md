# Feature development pipeline

# Pipeline Steps

## Preparation Steps
The user must provide the feature description. It will be one of the files in the `design\future_plans` folder.
1. Read the feature description file to understand the problem and the possible solution.
2. Read `design\future_plans\README.md` to know what was already implemented.
3. Read `docs\V6CBuildGuide.md` to build steps and mirroring.
4. Learn the code base to verify the solution.
5. Follow design\feature_plan_prompt.md and create a feature implementation plan.
7. Follow `Preparation steps` from `tests\features\README.md`
8. Inform the user about what was done.
9. Pause to let the user check new resources.

## Impllementation cycles

### Build Cycle
1. Follow the feature implementation plan one step
2. Build
3. If the bug was found, fix it, then go back to 2.

### Analisys
1. Run tests
2. Analize the result.
3. Explain the solution to the user
4. Follow `Verification assembly steps` from `tests\features\README.md`
5. Mark the plan complete
6. Mark the featuire complete in `design\future_plans\README.md`
7. Update docs