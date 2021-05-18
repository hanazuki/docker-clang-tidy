# syntax=docker/dockerfile:1

FROM ubuntu:20.04 as download
SHELL ["/bin/bash", "-ec"]

ARG CLANG_VERSION

WORKDIR /tmp/work
RUN apt-get update -qq && apt-get install -y --no-install-recommends ca-certificates curl gpg gpg-agent xz-utils

ENV DEBIANFRONTENT=noninteractive

COPY keyring.asc ./
RUN gpg --import < keyring.asc

RUN curl -LOfsS https://github.com/llvm/llvm-project/releases/download/llvmorg-"${CLANG_VERSION}"/clang+llvm-"${CLANG_VERSION}"-x86_64-linux-gnu-ubuntu-20.04.tar.xz.sig
RUN curl -LOfsS https://github.com/llvm/llvm-project/releases/download/llvmorg-"${CLANG_VERSION}"/clang+llvm-"${CLANG_VERSION}"-x86_64-linux-gnu-ubuntu-20.04.tar.xz
RUN gpg --verify clang+llvm-"${CLANG_VERSION}"-x86_64-linux-gnu-ubuntu-20.04.tar.xz.sig

RUN mkdir -p /tmp/clang
RUN tar xvf clang+llvm-"${CLANG_VERSION}"-x86_64-linux-gnu-ubuntu-20.04.tar.xz -C /tmp/clang --strip=1 -- clang+llvm-"${CLANG_VERSION}"-x86_64-linux-gnu-ubuntu-20.04/{bin/{clang-apply-replacements,clang-tidy},share/clang/{run-clang-tidy.py,clang-tidy-diff.py}}

WORKDIR /tmp/clang

RUN sed -i '1 s/python\b/python3/' share/clang/*.py
RUN for f in share/clang/*.py; do ln -s ../"$f" bin/"$(basename -s .py "$f")"; done

FROM ubuntu:20.04
RUN apt-get update -qq && apt-get install -y --no-install-recommends python3

COPY --from=download /tmp/clang/ /opt/clang/
ENV PATH=/opt/clang/bin:$PATH
