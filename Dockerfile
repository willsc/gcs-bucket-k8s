FROM ubuntu:18.04
RUN apt update
RUN apt-get install -y nfs-kernel-server nfs-common curl gnupg gnupg2  gnupg1 sudo
RUN mkdir -p /exports
ADD setup.sh /usr/local/bin/run_nfs.sh
RUN chmod +x /usr/local/bin/run_nfs.sh
RUN echo "deb http://packages.cloud.google.com/apt gcsfuse-bionic main" |sudo  tee /etc/apt/sources.list.d/gcsfuse.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg |  apt-key add -
RUN apt-get update
RUN apt-get -y  install gcsfuse 

# Expose volume
VOLUME /exports

# expose mountd 20048/tcp and nfsd 2049/tcp and rpcbind 111/tcp
EXPOSE 2049/tcp 20048/tcp 111/tcp 111/udp

ENTRYPOINT ["/usr/local/bin/run_nfs.sh"]

CMD ["/exports"]

