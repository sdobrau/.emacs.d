FROM debian:sid as builder
# essential deps
ENV CC /usr/bin/gcc-11
ENV CXX /usr/bn/g++-11
ENV CFLAGS "-O2 -pipe -mtune=native -march=native -fomit-frame-pointer"
RUN useradd -m emacs
RUN apt update -y && apt install -y git \
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
    libjansson4 libjansson-dev
# build deps
RUN apt install -y gcc-11 \
    g++-11 \
    libgccjit0 \
    libgccjit-11-dev \
    autoconf
#RUN apt build-dep -y emacs
USER emacs
WORKDIR /tmp
RUN git clone git://git.git.savannah.gnu.org/emacs.git
WORKDIR emacs
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
RUN make install

# cleanup
RUN rm -rf /tmp/emacs
RUN apt remove -y \
    gcc-11 \
    g++-11 \
    libgccjit-11-dev \
    autoconf
USER emacs
WORKDIR /home/emacs
RUN rm -rf .emacs.d
RUN git clone https://github.com/sdobrau/.emacs.d
# init emacs to download packages, install treesit grammars
WORKDIR /home/emacs/.emacs.d
RUN emacs --batch -l early-init.el -l init.el --eval \
    "(progn (treesit-auto-install-all) (ghostel-download-module))"

ENTRYPOINT ["emacs"]
