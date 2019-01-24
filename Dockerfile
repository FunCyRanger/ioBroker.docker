FROM debian:latest

MAINTAINER Andre Germann <https://buanet.de>

ENV DEBIAN_FRONTEND noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
        android-tools-adb \
        android-tools-fastboot \
        apt-utils \
        avahi-daemon \
        build-essential \
        curl \
        ffmpeg \
        git \
        gnupg2 \
        libavahi-compat-libdnssd-dev \
        libfontconfig \
        libpam0g-dev \
        libpcap-dev \
        libudev-dev \
        locales \
        procps \
        python \
        sudo \
        unzip \
        wget \
    && rm -rf /var/lib/apt/lists/*

# Install node8
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
RUN apt-get update && apt-get install -y \
        nodejs \
    && rm -rf /var/lib/apt/lists/*

# Configure avahi-daemon 
RUN sed -i '/^rlimit-nproc/s/^\(.*\)/#\1/g' /etc/avahi/avahi-daemon.conf

# Configure locales/ language/ timezone
RUN sed -i -e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen \
    && \dpkg-reconfigure --frontend=noninteractive locales \
    && \update-locale LANG=de_DE.UTF-8
ENV LANG de_DE.UTF-8 
RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime
ENV TZ Europe/Berlin

# Create scripts directory and copy scripts
RUN mkdir -p /opt/scripts/ \
    && chmod 777 /opt/scripts/
WORKDIR /opt/scripts/
ADD scripts/avahi_startup.sh avahi_startup.sh
ADD scripts/iobroker_startup.sh iobroker_startup.sh
RUN chmod +x avahi_startup.sh \
    && chmod +x iobroker_startup.sh \
    && mkdir /var/run/dbus/

# Install ioBroker
WORKDIR /
RUN echo $(hostname) > /opt/scripts/.install_host \
    && apt-get update \
    && curl -sL https://raw.githubusercontent.com/ioBroker/ioBroker/stable-installer/installer.sh | bash - \
    && rm -rf /var/lib/apt/lists/*

# Install node-gyp
WORKDIR /opt/iobroker/
RUN npm install node-gyp -g

# Backup initial ioBroker-folder
RUN tar -cf /opt/initial_iobroker.tar /opt/iobroker

# Some Testing
RUN echo 'iobroker ALL=(ALL) NOPASSWD: ALL' | EDITOR='tee -a' visudo \
    && echo "iobroker:iobroker" | chpasswd \
    && adduser iobroker sudo
USER iobroker

# Run startup-script
ENV DEBIAN_FRONTEND teletype
CMD ["sh", "/opt/scripts/iobroker_startup.sh"]
