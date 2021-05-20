FROM python:3.9.5-slim-buster

# Install all required dependencies
RUN apt-get update \
    && apt-get upgrade --no-install-recommends -y \
    && apt-get install --no-install-recommends -y \
        xvfb \
        xauth \
        x11-xserver-utils \
        wget \
        gnupg \
        gcc \
        cabextract \
    && wget -nc https://dl.winehq.org/wine-builds/winehq.key \
    && apt-key add winehq.key \
    && echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list.d/wine.list \
    && echo "deb https://dl.winehq.org/wine-builds/debian/ buster main" >> /etc/apt/sources.list.d/wine.list \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --install-recommends \
        wine-staging-i386 \
        wine-staging-amd64 \
        wine-staging \
        winehq-staging

ENV WINEARCH="win64"
ENV WINEPREFIX="/root/.wine64"
ENV WINESYSTEM32="/root/.wine64/drive_c/windows/system32"
ENV WINEDLLOVERRIDES="mscoree,mshtml="
ENV WINEDEBUG=-all

# Download winetricks and use it to install required C++ redistributables
RUN set -e \
    && mkdir -p $WINEPREFIX \
    && cd $WINEPREFIX \
    && wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
    && chmod +x winetricks \
    && xvfb-run wine wineboot --init \
    && xvfb-run wineserver -w \
    && xvfb-run sh ./winetricks -q vcrun2015

# Install Python using WinPython - Regular Python installer fails ¯\_(ツ)_/¯
RUN wget https://github.com/winpython/winpython/releases/download/4.1.20210417/Winpython64-3.9.4.0dot.exe \
    && xvfb-run wine Winpython64-3.9.4.0dot.exe -y -oC:/WP \
    && rm Winpython64-3.9.4.0dot.exe \
    && cd $WINEPREFIX/drive_c \
    && mv WP/*/python-3.9.4.amd64 Python \
    && rm -rf WP

# Create shell commands aliases:
# - winpy for Python in Wine
# - xwinpy for Python in Wine with Xvfb
RUN cd /usr/local/bin \
    && echo "#!/bin/bash -x" >> winpy \
    && echo "wine 'C:\\\\Python\\\\python.exe' $@" >> winpy \
    && echo "#!/bin/bash -x" >> xwinpy \
    && echo "xvfb-run winpy $@" >> xwinpy \
    && chmod +x *winpy

CMD ["winpy", "--version"]
