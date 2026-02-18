# when nvm is installed, this automatically detects node versions when switching projects that are unkown, 0 otherwise.
# when 0, it is still going to detect and switch node versions when project is known or project has a nvmrc file, but it won't try to detect the node version otherwise.
# default is 1
PUMP_AUTO_DETECT_NODE=1

# code editor to use for reviews.
# no default, will ask
PUMP_CODE_EDITOR=

# merge tool for conflict resolution for merge and rebase operations.
# no default, will ask
PUMP_MERGE_TOOL=

# 1 to add --no-verify by default to push and pushf commands to bypass the execution of Git hooks, 0 otherwise.
# no default, will ask
PUMP_PUSH_NO_VERIFY=1

# 1 to push to upstream by default, 0 otherwise.
# no default, will ask
PUMP_PUSH_SET_UPSTREAM=

# 1 to run PUMP_OPEN_COV_X configuration script after running test coverage, 0 otherwise.
# no default, will ask
PUMP_RUN_OPEN_COV=

# initial to use for the branch name when cloning a work item.
# no default, will ask
PUMP_USE_MONOGRAM=

# interval in minutes to run `gha`, `prs` and other commands.
PUMP_INTERVAL=20
