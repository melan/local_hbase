# Container to generate keytabs or serve as kerberos infrastructure 

Two folders should be mounted into the containers:

* /etc/krb5kdc - here the service stores a database with principals
* /etc/keytabs - here it stores generated keytabs

## Generate keytabs 

```bash
docker run -it --rm -v `pwd`/keytabs:/etc/keytabs -v `pwd`/krb5kdc:/etc/krb5kdc melan/kerberos generate root foo bar buz
```

This container supports 3 different versions of keytabs:

1. user keytab: `generate <user_name>`
2. service keytab: `generate <service_name>/<host_name>`
3. service keytab with an alternative host name: `generate <service_name>/<host_name>|<alt.host.name>`

## Run kerberos infra

```bash
docker run -it --rm -v `pwd`/krb5kdc:/etc/krb5kdc melan/kerberos serve
```

The container will listed on port 88 for requests
