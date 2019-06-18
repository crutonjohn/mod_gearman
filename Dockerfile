FROM centos:centos7.5.1804

COPY entrypoint.sh worker.conf /tmp/

# install deps
RUN yum install -y cpan make sharutils libaio tar gcc wget python36 && \
yum install -y epel-release && \
yum install -y nagios-plugins-* && \
rpm -Uvh https://repo.nagios.com/nagios/7/nagios-repo-7-3.el7.noarch.rpm && \
yum install -y mod_gearman-3.0.7-1.el7.x86_64 && \
kill $(cat /var/mod_gearman/mod_gearman_worker.pid) && \
chmod +x /tmp/entrypoint.sh

ENTRYPOINT [ "/tmp/entrypoint.sh" ]
