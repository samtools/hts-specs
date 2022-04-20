This repository uses GitHub Actions to build draft PDFs and comment on pull requests.

Several workflows are defined, using GitHub's recommended [two-part approach] to separate building the PDFs (which runs in the PR branch's context and has only a read-only GH token) from commenting on the PR (which runs on the **master** branch and has write access to the repository).

* _pr-pdf.yaml_ runs on `*.tex`-modifying pull requests, and runs LaTeX using the _texlive_ action defined in this repository.
* _pr-comment.yaml_ runs on completion of _pr-pdf.yaml_, and comments on the PR.
* _pr-pdfs-close.yaml_ runs when a PR is merged or closed, and removes the Git reference to the draft PDF commits so they will eventually be garbage-collected.


[two-part approach]: https://securitylab.github.com/research/github-actions-preventing-pwn-requests/
