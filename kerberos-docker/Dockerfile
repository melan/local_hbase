FROM centos:7

RUN yum install -y krb5-libs krb5-server krb5-workstation nc; yum clean all

COPY config/krb5.conf /etc/krb5.conf
COPY config/kdc.conf /var/kerberos/krb5kdc/kdc.conf
COPY entrypoint.sh /

RUN mkdir /etc/krb5kdc

EXPOSE 88

HEALTHCHECK --interval=20s --timeout=5s --start-period=30s --retries=3 \
        CMD /usr/bin/ncat 127.0.0.1 88 < /dev/null > /dev/null && echo "yes"

ENTRYPOINT ["/entrypoint.sh"]
