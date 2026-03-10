# when nvm is installed, this automatically detects node versions when switching projects that are unkown, 0 otherwise.
# when 0, it is still going to detect and switch node versions when project is known or project has a nvmrc file, but it won't try to detect the node version otherwise.
# default: empty (will ask)
PUMP_SKIP_DETECT_NODE=

# when 1, automatically accepts the current node version if its major and minor versions are the same as the major and minor versions specified in the nvmrc file
# when 0, automatically accept the current node version if its major version is the same as the major version specified in the nvmrc file, but it won't check for minor versions.
# default: 1
PUMP_NODE_REQ_SAME_MINOR=1

# number of times user is alerted to install jira cli
# default: 0
PUMP_JIRA_ALERT=0

# code editor to use for reviews.
# default: empty (will ask)
PUMP_CODE_EDITOR=

# merge tool for conflict resolution for merge and rebase operations.
# default: empty (will ask)
PUMP_MERGE_TOOL=

# 1 to add --no-verify by default to push and pushf commands to bypass the execution of Git hooks, 0 otherwise.
# default: empty (will ask)
PUMP_PUSH_NO_VERIFY=1

# 1 to run PUMP_OPEN_COV_X configuration script after running test coverage, 0 otherwise.
# default: empty (will ask)
PUMP_RUN_OPEN_COV=

# initial to use for the branch name when cloning a work item.
# default: empty (will ask)
PUMP_USE_MONOGRAM=

# interval in minutes to run `gha`, `prs` and other commands.
# default: 20 (will ask)
PUMP_INTERVAL=20

# day to check for updates, 1-7 (Monday-Sunday), 0 to disable.
# default: empty
PUMP_UPDATE_DAY=
