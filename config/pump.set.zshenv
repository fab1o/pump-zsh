# PUMP_PUSH_NO_VERIFY
# 1 to add --no-verify by default to push and pushf commands to bypass the execution of Git hooks, 0 otherwise
# no default, will ask
PUMP_PUSH_NO_VERIFY=1

# PUMP_PUSH_SET_UPSTREAM
# 1 to push to upstream by default, 0 otherwise
# no default, will ask
PUMP_PUSH_SET_UPSTREAM=

# PUMP_RUN_OPEN_COV
# 1 to run PUMP_OPEN_COV_X configuration script after running test coverage, 0 otherwise
# no default, will ask
PUMP_RUN_OPEN_COV=

# PUMP_USE_MONOGRAM
# 1 to use machine logged in user initial for the branch name when cloning and starting a job, 0 otherwise
# no default, will ask
PUMP_USE_MONOGRAM=

# PUMP_PR_TITLE_FORMAT
# Format for PR title. Available variables: <jira_key>, <commit_message>
# default: "<jira_key> <commit_message>"
PUMP_PR_TITLE_FORMAT="<jira_key> <commit_message>"
