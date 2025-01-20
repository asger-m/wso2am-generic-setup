FROM ubuntu

RUN apt-get update -y && \
    apt-get install -y openssh-server && \
    apt-get install -y pwgen net-tools curl wget && \
    apt-get install -y unzip iputils-ping telnet && \
    apt-get clean all

RUN mkdir /var/run/sshd \
    && echo 'root:root' | chpasswd \
    && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

#ENV NOTVISIBLE="in users profile"
#RUN echo "export VISIBLE=now" >> /etc/profile

RUN ln -sf /usr/share/zoneinfo/Europe/Copenhagen /etc/localtime

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]

#
# docker build -t ubuntu_new_ssh .
#

# docker run --detach --publish 2222:22 --name dev-api01 --network jysk.netic.dk ubuntu_ssh
# docker run --detach --publish 2223:22 --name dev-api02 --network jysk.netic.dk ubuntu_ssh
#
