ARG UPSTREAM_IMAGE_TAG
FROM postgres:${UPSTREAM_IMAGE_TAG}
LABEL maintainer="Mingjun Cao <me@caomingjun.com>"
LABEL description="PostgreSQL with pg_jieba"

# the version of PostgreSQL to use, should be the same as the upstream image major version
ARG PG_APT_VERSION

# Install prerequisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential git ca-certificates make curl wget libssl-dev libpq-dev postgresql-server-dev-${PG_APT_VERSION} && \
    apt-get autoremove -y && \
    apt-get clean

# Install newest CMake (from source instead of apt-get)
WORKDIR /tmp/cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v3.27.6/cmake-3.27.6.tar.gz && \
    tar -zxvf cmake-3.27.6.tar.gz && \
    cd cmake-3.27.6 && \
    ./bootstrap && \
    make && \
    make install

# Install pg_jieba
WORKDIR /tmp/
RUN git clone https://github.com/jaiminpan/pg_jieba
WORKDIR /tmp/pg_jieba
RUN git submodule update --init --recursive && \
    mkdir build
WORKDIR /tmp/pg_jieba/build
RUN cmake .. && \
    make && \
    make install
WORKDIR /
RUN rm -rf /tmp/pg_jieba

# Change settings
RUN sed -i "/^#shared_preload_libraries/c\shared_preload_libraries = 'pg_jieba.so'" /usr/share/postgresql/postgresql.conf.sample && \
    sed -i "/^#default_text_search_config/c\default_text_search_config = 'jiebacfg'" /usr/share/postgresql/postgresql.conf.sample
