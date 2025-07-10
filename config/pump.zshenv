# required
# short name for each project.
# make it short, use abbreviation and one word only, no spaces or special characters.
# example: pump
PUMP_SHORT_NAME_1=
PUMP_SHORT_NAME_2=
PUMP_SHORT_NAME_3=
PUMP_SHORT_NAME_4=
PUMP_SHORT_NAME_5=
PUMP_SHORT_NAME_6=
PUMP_SHORT_NAME_7=
PUMP_SHORT_NAME_8=
PUMP_SHORT_NAME_9=

# required
# path to each project folder.
# example: /Users/admin/Developer/pump-zsh
PUMP_FOLDER_1=
PUMP_FOLDER_2=
PUMP_FOLDER_3=
PUMP_FOLDER_4=
PUMP_FOLDER_5=
PUMP_FOLDER_6=
PUMP_FOLDER_7=
PUMP_FOLDER_8=
PUMP_FOLDER_9=

# required
# repository uri for each project.
PUMP_REPO_1=
PUMP_REPO_2=
PUMP_REPO_3=
PUMP_REPO_4=
PUMP_REPO_5=
PUMP_REPO_6=
PUMP_REPO_7=
PUMP_REPO_8=
PUMP_REPO_9=

# optional
# default: 0
# set to 1 for single project mode, 0 for multiple mode.
PUMP_SINGLE_MODE_1=
PUMP_SINGLE_MODE_2=
PUMP_SINGLE_MODE_3=
PUMP_SINGLE_MODE_4=
PUMP_SINGLE_MODE_5=
PUMP_SINGLE_MODE_6=
PUMP_SINGLE_MODE_7=
PUMP_SINGLE_MODE_8=
PUMP_SINGLE_MODE_9=

# optional
# default: npm
# options: npm, yarn, pnpm, bun, poe
# package manager for each project
PUMP_PKG_MANAGER_1=
PUMP_PKG_MANAGER_2=
PUMP_PKG_MANAGER_3=
PUMP_PKG_MANAGER_4=
PUMP_PKG_MANAGER_5=
PUMP_PKG_MANAGER_6=
PUMP_PKG_MANAGER_7=
PUMP_PKG_MANAGER_8=
PUMP_PKG_MANAGER_9=

# optional
# default: PUMP_PKG_MANAGER run setup
# script to run for command `setup`
PUMP_SETUP_1=
PUMP_SETUP_2=
PUMP_SETUP_3=
PUMP_SETUP_4=
PUMP_SETUP_5=
PUMP_SETUP_6=
PUMP_SETUP_7=
PUMP_SETUP_8=
PUMP_SETUP_9=

# optional
# default: PUMP_PKG_MANAGER run dev
# script to run for command `run` or `run dev`
PUMP_RUN_1=
PUMP_RUN_2=
PUMP_RUN_3=
PUMP_RUN_4=
PUMP_RUN_5=
PUMP_RUN_6=
PUMP_RUN_7=
PUMP_RUN_8=
PUMP_RUN_9=

# optional
# default: PUMP_PKG_MANAGER run stage
# script to run for command `run stage`
PUMP_RUN_STAGE_1=
PUMP_RUN_STAGE_2=
PUMP_RUN_STAGE_3=
PUMP_RUN_STAGE_4=
PUMP_RUN_STAGE_5=
PUMP_RUN_STAGE_6=
PUMP_RUN_STAGE_7=
PUMP_RUN_STAGE_8=
PUMP_RUN_STAGE_9=

# optional
# default: PUMP_PKG_MANAGER run prod
# script to run for command `run prod`
PUMP_RUN_PROD_1=
PUMP_RUN_PROD_2=
PUMP_RUN_PROD_3=
PUMP_RUN_PROD_4=
PUMP_RUN_PROD_5=
PUMP_RUN_PROD_6=
PUMP_RUN_PROD_7=
PUMP_RUN_PROD_8=
PUMP_RUN_PROD_9=

# optional
# default: PUMP_PKG_MANAGER run fix
# script to run for command `fix`
PUMP_FIX_1=
PUMP_FIX_2=
PUMP_FIX_3=
PUMP_FIX_4=
PUMP_FIX_5=
PUMP_FIX_6=
PUMP_FIX_7=
PUMP_FIX_8=
PUMP_FIX_9=

# optional
# default: empty (will ask)
# code editor for reviews of each project
PUMP_CODE_EDITOR_1=
PUMP_CODE_EDITOR_2=
PUMP_CODE_EDITOR_3=
PUMP_CODE_EDITOR_4=
PUMP_CODE_EDITOR_5=
PUMP_CODE_EDITOR_6=
PUMP_CODE_EDITOR_7=
PUMP_CODE_EDITOR_8=
PUMP_CODE_EDITOR_9=

# optional
# default: empty (no ask)
# script to run after command `clone`
# example: echo 'Clone completed!'
PUMP_CLONE_1=
PUMP_CLONE_2=
PUMP_CLONE_3=
PUMP_CLONE_4=
PUMP_CLONE_5=
PUMP_CLONE_6=
PUMP_CLONE_7=
PUMP_CLONE_8=
PUMP_CLONE_9=

# optional
# default: empty (no ask)
# script to run after `pro` command
# example: nvm use 18
PUMP_PRO_1=
PUMP_PRO_2=
PUMP_PRO_3=
PUMP_PRO_4=
PUMP_PRO_5=
PUMP_PRO_6=
PUMP_PRO_7=
PUMP_PRO_8=
PUMP_PRO_9=

# optional
# default: node
# options: node, deno, bun
# runtime environment for each project.
PUMP_USE_1=
PUMP_USE_2=
PUMP_USE_3=
PUMP_USE_4=
PUMP_USE_5=
PUMP_USE_6=
PUMP_USE_7=
PUMP_USE_8=
PUMP_USE_9=

# optional
# default: PUMP_PKG_MANAGER run test
# script to run for command `test`
PUMP_TEST_1=
PUMP_TEST_2=
PUMP_TEST_3=
PUMP_TEST_4=
PUMP_TEST_5=
PUMP_TEST_6=
PUMP_TEST_7=
PUMP_TEST_8=
PUMP_TEST_9=

# optional
# default: 0
# set to 1 to re-try tests if they fail, 0 to not re-try.
PUMP_RETRY_TEST_1=
PUMP_RETRY_TEST_2=
PUMP_RETRY_TEST_3=
PUMP_RETRY_TEST_4=
PUMP_RETRY_TEST_5=
PUMP_RETRY_TEST_6=
PUMP_RETRY_TEST_7=
PUMP_RETRY_TEST_8=
PUMP_RETRY_TEST_9=

# optional
# default: PUMP_PKG_MANAGER run test:coverage
# script to run for command `cov`
PUMP_COV_1=
PUMP_COV_2=
PUMP_COV_3=
PUMP_COV_4=
PUMP_COV_5=
PUMP_COV_6=
PUMP_COV_7=
PUMP_COV_8=
PUMP_COV_9=

# optional
# script to run after PUMP_COV has executed, usually to open the coverage report
PUMP_OPEN_COV_1=
PUMP_OPEN_COV_2=
PUMP_OPEN_COV_3=
PUMP_OPEN_COV_4=
PUMP_OPEN_COV_5=
PUMP_OPEN_COV_6=
PUMP_OPEN_COV_7=
PUMP_OPEN_COV_8=
PUMP_OPEN_COV_9=

# optional
# default: PUMP_PKG_MANAGER run test:watch
# script to run for command `testw`
PUMP_TEST_WATCH_1=
PUMP_TEST_WATCH_2=
PUMP_TEST_WATCH_3=
PUMP_TEST_WATCH_4=
PUMP_TEST_WATCH_5=
PUMP_TEST_WATCH_6=
PUMP_TEST_WATCH_7=
PUMP_TEST_WATCH_8=
PUMP_TEST_WATCH_9=

# optional
# default: PUMP_PKG_MANAGER run test:e2e
# script to run for command `e2e`
PUMP_E2E_1=
PUMP_E2E_2=
PUMP_E2E_3=
PUMP_E2E_4=
PUMP_E2E_5=
PUMP_E2E_6=
PUMP_E2E_7=
PUMP_E2E_8=
PUMP_E2E_9=

# optional
# default: PUMP_PKG_MANAGER run test:e2e-ui
# script to run for command `e2eui`
PUMP_E2EUI_1=
PUMP_E2EUI_2=
PUMP_E2EUI_3=
PUMP_E2EUI_4=
PUMP_E2EUI_5=
PUMP_E2EUI_6=
PUMP_E2EUI_7=
PUMP_E2EUI_8=
PUMP_E2EUI_9=

# optional
# default: .github/pull_request_template.md
# pull request template file of each project.
PUMP_PR_TEMPLATE_FILE_1=
PUMP_PR_TEMPLATE_FILE_2=
PUMP_PR_TEMPLATE_FILE_3=
PUMP_PR_TEMPLATE_FILE_4=
PUMP_PR_TEMPLATE_FILE_5=
PUMP_PR_TEMPLATE_FILE_6=
PUMP_PR_TEMPLATE_FILE_7=
PUMP_PR_TEMPLATE_FILE_8=
PUMP_PR_TEMPLATE_FILE_9=

# optional
# default: empty (no ask)
# text to be matched in the PR template to append commit messages with command: pr
PUMP_PR_REPLACE_1=
PUMP_PR_REPLACE_2=
PUMP_PR_REPLACE_3=
PUMP_PR_REPLACE_4=
PUMP_PR_REPLACE_5=
PUMP_PR_REPLACE_6=
PUMP_PR_REPLACE_7=
PUMP_PR_REPLACE_8=
PUMP_PR_REPLACE_9=

# optional
# default 0
# set to 0 to replace PUMP_PR_REPLACE with PR_BODY (created by the pr function) or 1 to append.
PUMP_PR_APPEND_1=
PUMP_PR_APPEND_2=
PUMP_PR_APPEND_3=
PUMP_PR_APPEND_4=
PUMP_PR_APPEND_5=
PUMP_PR_APPEND_6=
PUMP_PR_APPEND_7=
PUMP_PR_APPEND_8=
PUMP_PR_APPEND_9=

# optional
# default: empty (no ask)
# Minimum number of approvals required to merge a PR.
PUMP_PR_APPROVAL_MIN_1=
PUMP_PR_APPROVAL_MIN_2=
PUMP_PR_APPROVAL_MIN_3=
PUMP_PR_APPROVAL_MIN_4=
PUMP_PR_APPROVAL_MIN_5=
PUMP_PR_APPROVAL_MIN_6=
PUMP_PR_APPROVAL_MIN_7=
PUMP_PR_APPROVAL_MIN_8=
PUMP_PR_APPROVAL_MIN_9=

# optional
# default empty (will ask)
# set to 1 to add all changes to index before commit and recommit, 0 to not do anything.
PUMP_COMMIT_ADD_1=
PUMP_COMMIT_ADD_2=
PUMP_COMMIT_ADD_3=
PUMP_COMMIT_ADD_4=
PUMP_COMMIT_ADD_5=
PUMP_COMMIT_ADD_6=
PUMP_COMMIT_ADD_7=
PUMP_COMMIT_ADD_8=
PUMP_COMMIT_ADD_9=

# optional
# default empty (will ask)
# set to 1 to sign off all commits, 0 to not sign off.
PUMP_COMMIT_SIGNOFF_1=
PUMP_COMMIT_SIGNOFF_2=
PUMP_COMMIT_SIGNOFF_3=
PUMP_COMMIT_SIGNOFF_4=
PUMP_COMMIT_SIGNOFF_5=
PUMP_COMMIT_SIGNOFF_6=
PUMP_COMMIT_SIGNOFF_7=
PUMP_COMMIT_SIGNOFF_8=
PUMP_COMMIT_SIGNOFF_9=

# optional
# default: 0
# set 1 to display README after cloning (requires glow), 0 to not display.
PUMP_PRINT_README_1=1
PUMP_PRINT_README_2=1
PUMP_PRINT_README_3=1
PUMP_PRINT_README_4=1
PUMP_PRINT_README_5=1
PUMP_PRINT_README_6=1
PUMP_PRINT_README_7=1
PUMP_PRINT_README_8=1
PUMP_PRINT_README_9=1

# optional
# default: empty (will ask)
# 0 or empty to look for Node.js version in project's engine and nvm list, 1 to skip lookup.
# if skipped, you can manually set the version in PUMP_NVM_USE_V or set PUMP_PRO
PUMP_NVM_SKIP_LOOKUP_1=
PUMP_NVM_SKIP_LOOKUP_2=
PUMP_NVM_SKIP_LOOKUP_3=
PUMP_NVM_SKIP_LOOKUP_4=
PUMP_NVM_SKIP_LOOKUP_5=
PUMP_NVM_SKIP_LOOKUP_6=
PUMP_NVM_SKIP_LOOKUP_7=
PUMP_NVM_SKIP_LOOKUP_8=
PUMP_NVM_SKIP_LOOKUP_9=

# optional
# default: empty (will ask)
# Node.js version to use with nvm (requires nvm and the Node.js version pre-installed).
PUMP_NVM_USE_V_1=
PUMP_NVM_USE_V_2=
PUMP_NVM_USE_V_3=
PUMP_NVM_USE_V_4=
PUMP_NVM_USE_V_5=
PUMP_NVM_USE_V_6=
PUMP_NVM_USE_V_7=
PUMP_NVM_USE_V_8=
PUMP_NVM_USE_V_9=

# optional
# package.json name
PUMP_PKG_NAME_1=
PUMP_PKG_NAME_2=
PUMP_PKG_NAME_3=
PUMP_PKG_NAME_4=
PUMP_PKG_NAME_5=
PUMP_PKG_NAME_6=
PUMP_PKG_NAME_7=
PUMP_PKG_NAME_8=
PUMP_PKG_NAME_9=

# optional
# default empty (will ask)
# column name for the project in the Jira board.
PUMP_JIRA_IN_PROGRESS_1=
PUMP_JIRA_IN_PROGRESS_2=
PUMP_JIRA_IN_PROGRESS_3=
PUMP_JIRA_IN_PROGRESS_4=
PUMP_JIRA_IN_PROGRESS_5=
PUMP_JIRA_IN_PROGRESS_6=
PUMP_JIRA_IN_PROGRESS_7=
PUMP_JIRA_IN_PROGRESS_8=
PUMP_JIRA_IN_PROGRESS_9=

# optional
# default empty (will ask)
# column name for the project in the Jira board.
PUMP_JIRA_IN_REVIEW_1=
PUMP_JIRA_IN_REVIEW_2=
PUMP_JIRA_IN_REVIEW_3=
PUMP_JIRA_IN_REVIEW_4=
PUMP_JIRA_IN_REVIEW_5=
PUMP_JIRA_IN_REVIEW_6=
PUMP_JIRA_IN_REVIEW_7=
PUMP_JIRA_IN_REVIEW_8=
PUMP_JIRA_IN_REVIEW_9=

# optional
# default empty (will ask)
# column name for the project in the Jira board.
PUMP_JIRA_DONE_1=
PUMP_JIRA_DONE_2=
PUMP_JIRA_DONE_3=
PUMP_JIRA_DONE_4=
PUMP_JIRA_DONE_5=
PUMP_JIRA_DONE_6=
PUMP_JIRA_DONE_7=
PUMP_JIRA_DONE_8=
PUMP_JIRA_DONE_9=
