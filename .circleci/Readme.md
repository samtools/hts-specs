We use [circle-ci](https://circleci.com/gh/samtools/hts-specs) to build the pdfs and highlight the differences for each pull-request. This is done at several steps.

1. Circle-ci runs `make` and copies the pdfs and log files to an "artifacts" directory for that build. 
2. Circle-ci runs `make diffs` on the tex files that correspond to tex files that changed since the "merge base" (defined as the most recent common ancestor of the HEAD and master branches)  
3. Circle-ci was provided with a Token to a user (circle-ci-bot). This Token has been given permission to make comments on the github repository. 

Files:
- scripts/makediff.sh  -- runs latexdiff on the given file producing a pdf in the diffs/ directory
- pdf_comment.js       -- looks for pdfs in the diffs/ directory and if it finds any, posts a comment in the github PR with links to the appropriate files
- Dockerfile           -- a description of the container used for running the latex and the javascript. The container itself is htsspecs/circle-ci-image:0.3 
- .circleci/config.yml -- the configuration file that is run by circle-ci
- .circleci/Readme.md  -- this document


