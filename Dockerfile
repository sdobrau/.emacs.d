FROM debian:sid as builder
# essential deps
ENV CC="/usr/bin/gcc-11"
ENV CXX="/usr/bn/g++-11"
ENV CFLAGS="-O2 -pipe -mtune=native -march=native -fomit-frame-pointer"
ENV DOCKER_BUILD="1"
ENV IN_DOCKER="1"
RUN useradd -m emacs && apt-get update -y && apt-get install -y git \
    build-essential \
    texinfo \
    libgnutls28-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff5-dev \
    libgif-dev \
    libxpm-dev \
    libncurses-dev \
    libgtk-3-dev \
    libtree-sitter-dev \
    libmagick++-dev \
    libjansson4 libjansson-dev \
    # build deps
    gcc-11 \
    g++-11 \
    libgccjit0 \
    libgccjit-11-dev \
    autoconf \
    # dev deps
    pipx \
    npm \
    ansible-lint \
    yamllint \
    mypy \
    rubocop \
    golang

USER emacs
WORKDIR /tmp
RUN git clone git://git.git.savannah.gnu.org/emacs.git
WORKDIR /tmp/emacs
RUN ./autogen.sh && \
    ./configure \
    --with-native-compilation \
    --without-pgtk \
    --with-tree-sitter \
    --with-wide-int \
    --with-json \
    --with-modules \
    --with-gnutls \
    --without-mailutils \
    --without-pop \
    --without-cairo \
    --without-imagemagick && \
    make -j$(nproc --ignore=2) NATIVE_FULL_AOT=1
USER root
RUN make install && rm -rf /tmp/emacs && \
    apt-get remove -y \
    gcc-11 \
    g++-11 \
    libgccjit-11-dev \
    autoconf

# cleanup

USER emacs
WORKDIR /home/emacs
RUN rm -rf .emacs.d && \
    git clone https://github.com/sdobrau/.emacs.d
# init emacs to download packages, install treesit grammars
WORKDIR /home/emacs/.emacs.d
# add this directory otherwise emacs errors out
RUN mkdir -p packages/quelpa/build && \
    emacs --batch -l early-init.el -l init.el --eval \
    "(progn (treesit-auto-install-all) (ghostel-download-module))" && \
    # Ensure pipx in path and install pipx deps
    pipx ensurepath && \
    . ~/.bashrc && \
    pipx install zuban && \
    pipx install black

USER root
RUN npm install -g jsfmt # js
ENV DOCKER_BUILD="0"
# final
FROM scratch
COPY --from=builder / /
ENV IN_DOCKER="1"
USER emacs
WORKDIR /home/emacs
ENTRYPOINT ["emacs"]
