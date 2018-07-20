FROM blang/latex:ubuntu

MAINTAINER Louis Bergelson <louisb@broadinstitute.org>

RUN apt-get update -q && \
   apt-get install -qy nodejs npm curl && \
   rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ftilmann/latexdiff.git && \
    cd latexdiff && \
    git checkout 3e56ad7cb8e7451322ce7478e7ebbd1e7be863e1 && \
    make distribution && \
    cd dist && \
    make install 
