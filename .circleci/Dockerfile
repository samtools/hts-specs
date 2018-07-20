FROM blang/latex:ubuntu

MAINTAINER Louis Bergelson <louisb@broadinstitute.org>

RUN apt-get update -q && \
   apt-get install -qy nodejs npm curl && \
   rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ftilmann/latexdiff.git && \
    cd latexdiff && \
    git checkout 1.3.0 && \
    make distribution && \
    cd dist && \
    make install

RUN npm install --global circle-github-bot@2.0.1

ENV NODE_PATH=/usr/local/lib/node_modules
