# stole from https://hub.docker.com/r/thinca/vim/dockerfile
FROM alpine:3.9 AS iconv

RUN apk add --no-cache curl g++ make
RUN curl -SL http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz | tar -xz
WORKDIR libiconv-1.15
RUN ./configure
RUN make
RUN make install


FROM alpine:3.9

LABEL maintainer="thinca <thinca+vim@gmail.com>"

ARG VIM_VERSION=master
ARG LUA_VERSION="5.3"

COPY --from=iconv /usr/local/include /usr/local/include/
COPY --from=iconv /usr/local/lib /usr/local/lib/

RUN apk add --no-cache --virtual .build \
        git \
        gcc \
        libc-dev \
        make \
        gettext \
        ncurses-dev \
        gtk+3.0-dev libxmu-dev \
 && apk add --no-cache \
        ncurses \
        acl-dev \
        diffutils \
        gtk+3.0-dev libxpm-dev \
        perl-dev \
        python-dev \
        python3-dev \
        ruby ruby-dev \
 && git -c advice.detachedHead=false \
        clone --quiet --depth 1 --branch "${VIM_VERSION}" \
        https://github.com/vim/vim.git /usr/src/vim \
 && cd /usr/src/vim \
 && ./configure \
        --with-features=huge \
        --enable-gui=gtk3 \
        --enable-perlinterp \
        --enable-pythoninterp \
        --enable-python3interp \
        --enable-rubyinterp \
        --enable-fail-if-missing \
 && make \
 && make install \
 && cd /root \
 && rm -fr /usr/src/vim \
 && apk del --purge .build \
        ruby \
# test
 && vim -es \
        ${VIM_ENABLE_PERL:+-c 'verbose perl print("Perl $^V")'} \
        ${VIM_ENABLE_PYTHON:+-c 'verbose python import platform;print("Python v" + platform.python_version())'} \
        ${VIM_ENABLE_PYTHON3:+-c 'verbose python3 import platform;print("Python3 v" + platform.python_version())'} \
        ${VIM_ENABLE_RUBY:+-c 'verbose ruby puts "Ruby v#{RUBY_VERSION}"'} \
        -c q

COPY vimrc /usr/local/share/vim/vimrc

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/vim"]
