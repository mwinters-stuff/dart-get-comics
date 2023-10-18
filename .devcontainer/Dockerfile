FROM mcr.microsoft.com/devcontainers/base:debian
ENV DART_HOME /opt/dart-sdk
ENV DART_ROOT /opt/dart-sdk
ENV VERSION 3.1.3
ENV PATH "$PATH:$DART_HOME/bin:$PUB_CACHE/bin"
ADD install.sh /install.sh
RUN /install.sh