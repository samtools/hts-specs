[The CircleCI web hook has been deactivated in favour of GitHub Actions. This legacy infrastructure will be removed once that has bedded in.]

We use [circle-ci](https://circleci.com/gh/samtools/hts-specs) to build the pdfs and highlight the differences for each pull-request. This is done at several steps.

1. Circle-ci runs `make` and copies the pdfs and log files to an "artifacts" directory for that build.
1. Circle-ci runs `make diff` on the tex files that correspond to tex files that changed since the "merge base" (defined as the most recent common ancestor of the HEAD and master branches).
1. Circle-ci was provided with a Token form a user (hts-specs-bot).
1. This Token has been given permission to make comments on the github repository.


## All about the hts-specs-bot:

The [hts-specs-bot](https://github.com/hts-specs-bot) is a github account used to comment on hts-specs pull requests.

## If a key needs to be rotated:
-  Sign into the bot account. You can do this in an incognito window to avoid signing out of your existing github account.
   -    username: `hts-specs-bot`
   -  password: Is kept in a the hts-specs-bot google group. (See "Bot Password" below)
-  Navigate to Settings > Developer Settings > Personal access tokens
-  Delete the existing token
-  Generate a new token with the `public_repo` scope.
    - In addition to allowing the bot to make comments on pull requests, this scope allows write access to all public repos that the bot account can access.  For that reason it is **very important** not to give this bot write access to anything.
-  Update the existing token in circle-ci by navigating to [Settings -> Environment Variables](https://circleci.com/gh/samtools/hts-specs/edit#env-vars) and replacing the existing token there with the newly generated one.

### Bot Password
If the bot account password is lost it can be recovered by sending a recovery email to hts-specs-bot@broadinstitute.org.
Spec maintainers should be owners of that [private google group](https://groups.google.com/a/broadinstitute.org/forum/#!forum/hts-specs-bot)

### Circle-CI docker image
The docker image used by the Circle-CI build is hosted on docker under [htsspecs/circle-ci-image](https://hub.docker.com/r/htsspecs/circle-ci-image/).
Spec maintianers should be made owners of that repository.


## Files

- .circleci/config.yml -- the configuration file that is run by circle-ci
- .circleci/Dockerfile -- a description of the container used for running the latex and the javascript. It also has an updated version of latexdiff (githash 3e56ad7cb8e7, not an official release.) The container itself is currently htsspecs/circle-ci-image:0.4
- .circleci/pdf_comment.js -- looks for pdfs in the diff/ directory and if it finds any, posts a comment in the github PR with links to the appropriate files
- .circleci/Readme.md  -- this document
