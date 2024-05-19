# Stage: build
FROM ghcr.io/vanilla-os/desktop:main AS build
LABEL maintainer='Bloom Perez'
ARG DEBIAN_FRONTEND=noninteractive
RUN echo 'APT::Install-Recommends "1";' > /etc/apt/apt.conf.d/01norecommends
ADD includes.container /
ADD sources /sources
RUN lpkg --unlock && apt-get update
RUN bash /deb-pkgs/install-debs.sh && rm -rf /deb-pkgs
RUN bash /install-deno/install.sh && rm -rf /install-deno
RUN IMAGE_NAME="$(cat /image-info/image-name)" && echo custom image name "$IMAGE_NAME" && IMAGE_NAME_ESCAPED="$(echo $IMAGE_NAME | sed 's/\//\\\//g')" && sed -i "s/changed_automatically_by_vib/$IMAGE_NAME_ESCAPED/g" /usr/share/abroot/abroot.json && rm -rf /image-info
RUN apt-get autoremove -y && apt-get clean && lpkg --lock
RUN rm -rf /FsGuard && rm -f ./minisign.pub ./minisign.key && chmod +x /usr/sbin/init && mkdir /FsGuard && chmod +x /sources/fsguard/genfilelist.py && minisign -WG -s ./minisign.key && python3 /sources/fsguard/genfilelist.py /usr/bin /FsGuard/filelist /usr/sbin/FsGuard && minisign -Sm /FsGuard/filelist -p .//minisign.pub -s .//minisign.key && touch /FsGuard/signature && echo -n "----begin attach----" >> /FsGuard/signature && cat /FsGuard/filelist.minisig >> /FsGuard/signature && echo -n "----begin second attach----" >> /FsGuard/signature && tail -n1 .//minisign.pub >> /FsGuard/signature && cat /FsGuard/signature >> /sources/FsGuard && mv /sources/FsGuard /usr/sbin/FsGuard && rm ./minisign.key ./minisign.pub
RUN rm -rf /tmp/* && rm -rf /var/tmp/* && rm -rf /sources
