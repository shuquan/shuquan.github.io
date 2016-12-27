---
layout: post
title: Setting up Keystone to Keystone Federation
description: "Setting up Keystone to Keystone Federation"
modified: 2016-02-01
tags: [federation, keystone, openstack, hybrid cloud]
---

### Reference

* [Configure Keystone to Keystone Federation](http://blog.rodrigods.com/it-is-time-to-play-with-keystone-to-keystone-federation-in-kilo/)
* [Configure Keystone to Testshib Federation with SAML](https://bigjools.wordpress.com/2015/05/22/saml-federation-with-openstack/)
* [Configure Keystone federation with Kerberos](https://bigjools.wordpress.com/2015/04/27/federated-openstack-logins-using-kerberos/)
* [Configure Keystone federation with multi-IDP](https://zenodo.org/record/11982/files/CERN_openlab_Luca_Tartarini.pdf)
* [OpenStack Keystone Federated Identity](http://docs.openstack.org/developer/keystone/federation/federated_identity.html)

### Environment

1. I setup the keystone to keystone federation with two devstacks as below. Please pay attention that this guide is based on devstack which assumes keystone is running under Apache already.
2. Use SAML2 as the federation protocol.
3. It only works in CLI. No horizon SSO enabled in this guide right now.
4. Software Versions

| Software               | Version            | Description                                              
|:-----------------------|:------------------:| :--------------------------------------------------------  |
| OS                     | Ubuntu 14.04.3 LTS |                                                            |
| -----
| libapache2-mod-shib2   | 2.5.2+dfsg-2       | Federated web single sign-on system (Apache module)        |
| -----
| liblog4shib1:amd64     | 1.0.8-1            | log4j-style configurable logging library for C++ (runtime) |
| -----
| libshibsp6:amd64       | 2.5.2+dfsg-2       | Federated web single sign-on system (runtime)              |
| -----
| shibboleth-sp2-schemas | 2.5.2+dfsg-2       | Federated web single sign-on system (schemas)              |
| -----
| xmlsec1                | 1.2.18-2ubuntu1    | XML security command line processor                        |
| -----
| libxmlsec1             | 1.2.18-2ubuntu1    | XML security library                                       |
| -----
| libxmlsec1-openssl     | 1.2.18-2ubuntu1    | Openssl engine for the XML security library                |
|=====
{: rules="groups"}            

~~~ shell
+-------------------+     +------------------+
|                   |     |                  |
| IdP:172.16.40.115 |     | SP:172.16.40.112 |
|                   |     |                  |
+-------------------+     +------------------+
~~~

### Keystone as a Service Provider (SP)

Finish the following configuration in SP:172.16.40.112.

1. [Setup Shibboleth](http://docs.openstack.org/developer/keystone/federation/shibboleth.html)
2. [Configure Federation in Keystone](http://docs.openstack.org/developer/keystone/federation/federated_identity.html#configure-federation-in-keystone)

After the configuration, the total changes in my /etc is shown below.

~~~ shell
ubuntu@shuquan-devstack-sp:/etc$ sudo git status
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

	modified:   apache2/sites-available/keystone.conf
	modified:   keystone/keystone.conf
	modified:   shibboleth/attribute-map.xml
	modified:   shibboleth/shibboleth2.xml

Untracked files:
  (use "git add <file>..." to include in what will be committed)

	shibboleth/sp-cert.pem
	shibboleth/sp-key.pem

no changes added to commit (use "git add" and/or "git commit -a")
~~~

#### Setup Shibboleth

Just follow the instruction of the official docs and nothing specific. :) My changes are shown below.

* /etc/shibboleth/shibboleth2.xml

{% highlight html %}
{% raw %}
ubuntu@shuquan-devstack-sp:/etc$ sudo git diff shibboleth/shibboleth2.xml
diff --git a/shibboleth/shibboleth2.xml b/shibboleth/shibboleth2.xml
index 1a4b4b8..c8268e1 100644
--- a/shibboleth/shibboleth2.xml
+++ b/shibboleth/shibboleth2.xml
@@ -20,8 +20,7 @@
     -->

     <!-- The ApplicationDefaults element is where most of Shibboleth's SAML bits are defined. -->
-    <ApplicationDefaults entityID="https://sp.example.org/shibboleth"
-                         REMOTE_USER="eppn persistent-id targeted-id">
+    <ApplicationDefaults entityID="http://172.16.40.112/shibboleth">

         <!--
         Controls session lifetimes, address checks, cookie handling, and the protocol handlers.
@@ -41,8 +40,7 @@
             (Set discoveryProtocol to "WAYF" for legacy Shibboleth WAYF support.)
             You can also override entityID on /Login query string, or in RequestMap/htaccess.
             -->
-            <SSO entityID="https://idp.example.org/idp/shibboleth"
-                 discoveryProtocol="SAMLDS" discoveryURL="https://ds.example.org/DS/WAYF">
+            <SSO entityID="http://172.16.40.115/v3/OS-FEDERATION/saml2/idp">
               SAML2 SAML1
             </SSO>

@@ -78,6 +76,7 @@
             <MetadataFilter type="Signature" certificate="fedsigner.pem"/>
         </MetadataProvider>
         -->
+        <MetadataProvider type="XML" uri="http://172.16.40.115:5000/v3/OS-FEDERATION/saml2/metadata"/>

         <!-- Example of locally maintained metadata. -->
{% endraw %}
{% endhighlight %}

* /etc/shibboleth/attribute-map.xml

{% highlight html %}
{% raw %}
ubuntu@shuquan-devstack-sp:/etc$ sudo git diff shibboleth/attribute-map.xml
diff --git a/shibboleth/attribute-map.xml b/shibboleth/attribute-map.xml
index 8dd4073..7a6bd93 100644
--- a/shibboleth/attribute-map.xml
+++ b/shibboleth/attribute-map.xml
@@ -140,5 +140,9 @@
     <Attribute name="urn:oid:2.5.4.15" id="businessCategory"/>
     <Attribute name="urn:oid:2.5.4.19" id="physicalDeliveryOfficeName"/>
     -->
-
+    <Attribute name="openstack_user" id="openstack_user"/>
+    <Attribute name="openstack_roles" id="openstack_roles"/>
+    <Attribute name="openstack_project" id="openstack_project"/>
+    <Attribute name="openstack_user_domain" id="openstack_user_domain"/>
+    <Attribute name="openstack_project_domain" id="openstack_project_domain"/>
 </Attributes>
{% endraw %}
{% endhighlight %}

* /etc/apache2/sites-available/keystone.conf

{% highlight html %}
{% raw %}
ubuntu@shuquan-devstack-sp:/etc$ sudo git diff apache2/sites-available/keystone.conf
diff --git a/apache2/sites-available/keystone.conf b/apache2/sites-available/keystone.conf
index 9c347c5..6015bd0 100644
--- a/apache2/sites-available/keystone.conf
+++ b/apache2/sites-available/keystone.conf
@@ -1,12 +1,14 @@
 Listen 5000
 Listen 35357
 LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\" %D(us)" keystone_combined
+ServerName 172.16.40.112

 <Directory /usr/local/bin>
     Require all granted
 </Directory>

 <VirtualHost *:5000>
+    WSGIScriptAliasMatch ^(/v3/OS-FEDERATION/identity_providers/.*?/protocols/.*?/auth)$ /usr/local/bin/keystone-wsgi-public/$1
     WSGIDaemonProcess keystone-public processes=5 threads=1 user=ubuntu display-name=%{GROUP}
     WSGIProcessGroup keystone-public
     WSGIScriptAlias / /usr/local/bin/keystone-wsgi-public
@@ -59,3 +61,19 @@ Alias /identity_admin /usr/local/bin/keystone-wsgi-admin
     WSGIApplicationGroup %{GLOBAL}
     WSGIPassAuthorization On
 </Location>
+
+<Location /Shibboleth.sso>
+    SetHandler shib
+</Location>
+
+<Location /v3/OS-FEDERATION/identity_providers/myidp/protocols/saml2/auth>
+    ShibRequestSetting requireSession 1
+    AuthType shibboleth
+    ShibExportAssertion Off
+    Require valid-user
+
+    <IfVersion < 2.4>
+        ShibRequireSession On
+        ShibRequireAll On
+   </IfVersion>
+</Location>
{% endraw %}
{% endhighlight %}

#### Configure Federation in Keystone

Please pay attention to **idp_entity_id**. It has to be identical in SP & IdP. You will use it when you config the Identity Provider in Keystone’s [saml]/idp_entity_id option in IdP.

> idp_entity_id is the unique identifier for the Identity Provider in Keystone’s [saml]/idp_entity_id option in IdP. This value should be the same in SSO entityID in /etc/shibboleth/shibboleth2.xml and use this command `openstack identity provider create --remote-id https://myidp.example.com/v3/OS-FEDERATION/saml2/idp myidp` when you create idp in SP.

* /etc/keystone/keystone.conf

{% highlight html %}
{% raw %}
ubuntu@shuquan-devstack-sp:/etc$ sudo git diff keystone/keystone.conf
diff --git a/keystone/keystone.conf b/keystone/keystone.conf
index f80907f..a6d8745 100644
--- a/keystone/keystone.conf
+++ b/keystone/keystone.conf
@@ -398,7 +398,7 @@ driver = sql
 #

 # Allowed authentication methods. (list value)
-#methods = external,password,token,oauth1
+methods = external,password,token,oauth1,saml2

 # Entry point for the password auth plugin module in the
 # `keystone.auth.password` namespace. You do not need to set this unless you
@@ -864,7 +864,7 @@ connection = mysql+pymysql://root:password@127.0.0.1/keystone?charset=utf8
 # environment. For `mod_shib`, this would be `Shib-Identity-Provider`. For For
 # `mod_auth_openidc`, this could be `HTTP_OIDC_ISS`. For `mod_auth_mellon`,
 # this could be `MELLON_IDP`. (string value)
-#remote_id_attribute = <None>
+remote_id_attribute = Shib-Identity-Provider

 # An arbitrary domain name that is reserved to allow federated ephemeral users
 # to have a domain concept. Note that an admin will not be able to create a
@@ -2790,3 +2790,7 @@ provider = fernet
 # Keystone only provides a `sql` driver, so there is no reason to change this
 # unless you are providing a custom entry point. (string value)
 #driver = sql
+
+[saml2]
+
+remote_id_attribute = Shib-Identity-Provider
{% endraw %}
{% endhighlight %}

#### Create keystone groups and assign roles

Make sure you're using v3 right now.

{% highlight html %}
{% raw %}
ubuntu@shuquan-devstack-sp:~$ cat v3rc
# OS_AUTH_URL must point to /v3 not /v2.0
export OS_AUTH_URL=http://172.16.40.112:5000/v3
# OS_PROJECT_NAME instead of OS_TENANT_NAME
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_IDENTITY_API_VERSION=3
export OS_USERNAME=admin
export OS_PASSWORD=password
{% endraw %}
{% endhighlight %}

{% highlight html %}
{% raw %}
$ openstack domain create federated_domain
$ openstack project create federated_project --domain federated_domain
$ openstack group create federated_users
$ openstack role add --group federated_users --domain federated_domain Member
$ openstack role add --group federated_users --project federated_project Member
{% endraw %}
{% endhighlight %}

#### Add Identity Provider(s), Mapping(s), and Protocol(s)

{% highlight html %}
{% raw %}
$ openstack identity provider create --remote-id http://172.16.40.115/v3/OS-FEDERATION/saml2/idp myidp
$ cat > rules.json <<EOF
[
    {
        "local": [
            {
                "user": {
                    "name": "{0}"
                },
                "group": {
                    "domain": {
                        "name": "Default"
                    },
                    "name": "federated_users"
                }
            }
        ],
        "remote": [
            {
                "type": "openstack_user"
            }
        ]
    }
]
EOF
$ openstack mapping create --rules rules.json myidp_mapping
$ openstack federation protocol create mapped --mapping myidp_mapping --identity-provider myidp
{% endraw %}
{% endhighlight %}

### Keystone as a Identity Provider (IdP)

Finish the following configuration in IdP:172.16.40.115.

1. Package Installation.
2. [Configure Federation in Keystone](http://docs.openstack.org/developer/keystone/federation/federated_identity.html#keystone-as-an-identity-provider-idp)

After the configuration, the total changes in my /etc is shown below.

~~~ shell
ubuntu@shuquan-devstack-idp:/etc$ sudo git status
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

	modified:   apache2/sites-available/default-ssl.conf
	modified:   apache2/sites-available/keystone.conf
	modified:   keystone/keystone.conf

Untracked files:
  (use "git add <file>..." to include in what will be committed)

	keystone/saml2_idp_metadata.xml
	keystone/ssl/

no changes added to commit (use "git add" and/or "git commit -a")
~~~

#### Package Installation

The only package need to install is **xmlsec1**.

~~~ shell
$ apt-get install xmlsec1
~~~

#### Configure Federation in Keystone

1. Enable IdP is easier because you don't need to deal with Shibboleth. Before following the official documentation, you should generate a self-signed cert-key pair for signing in the future and configure it properly in keystone and apache configure file.

{% highlight html %}
{% raw %}
$ openssl req -x509 -newkey rsa:2048 -keyout /etc/keystone/ssl/private/signing_key.pem -out /etc/keystone/ssl/certs/signing_cert.pem -days 9999 -nodes
{% endraw %}
{% endhighlight %}

2. Please pay attention to the SP creation. I made a mistake here and spent some time on debugging. The key is that you don't need to use entityID of shibboleth2.xml in SP for --service-provider-url setting. **http://172.16.40.112/Shibboleth.sso/SAML2/ECP** is fine because IdP will send SAML assertion to this link and the entityID may not resolve to anything. Surely, you can set these two value identical.

* /etc/apache2/sites-available/default-ssl.conf
{% highlight html %}
{% raw %}
ubuntu@shuquan-devstack-idp:/etc$ sudo git diff apache2/sites-available/default-ssl.conf
diff --git a/apache2/sites-available/default-ssl.conf b/apache2/sites-available/default-ssl.conf
index 432b965..00e3b92 100644
--- a/apache2/sites-available/default-ssl.conf
+++ b/apache2/sites-available/default-ssl.conf
@@ -1,5 +1,6 @@
 <IfModule mod_ssl.c>
        <VirtualHost _default_:443>
+               ServerName 172.16.40.115
                ServerAdmin webmaster@localhost

                DocumentRoot /var/www/html
@@ -29,8 +30,8 @@
                #   /usr/share/doc/apache2/README.Debian.gz for more info.
                #   If both key and certificate are stored in the same file, only the
                #   SSLCertificateFile directive is needed.
-               SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem
-               SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
+               SSLCertificateFile      /etc/keystone/ssl/certs/signing_cert.pem
+               SSLCertificateKeyFile   /etc/keystone/ssl/private/signing_key.pem

                #   Server Certificate Chain:
                #   Point SSLCertificateChainFile at a file containing the
{% endraw %}
{% endhighlight %}
* /etc/apache2/sites-available/keystone.conf
{% highlight html %}
{% raw %}
ubuntu@shuquan-devstack-idp:/etc$ sudo git diff apache2/sites-available/keystone.conf
diff --git a/apache2/sites-available/keystone.conf b/apache2/sites-available/keystone.conf
index 9c347c5..b44aa67 100644
--- a/apache2/sites-available/keystone.conf
+++ b/apache2/sites-available/keystone.conf
@@ -1,6 +1,7 @@
 Listen 5000
 Listen 35357
 LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\" %D(us)" keystone_combined
+ServerName 172.16.40.115

 <Directory /usr/local/bin>
     Require all granted
{% endraw %}
{% endhighlight %}
* /etc/keystone/keystone.conf
{% highlight html %}
{% raw %}
ubuntu@shuquan-devstack-idp:/etc$ sudo git diff keystone/keystone.conf
diff --git a/keystone/keystone.conf b/keystone/keystone.conf
index e1fd8d8..21ef281 100644
--- a/keystone/keystone.conf
+++ b/keystone/keystone.conf
@@ -2371,24 +2371,24 @@ driver = sql

 # Absolute path to the public certificate file to use for SAML signing. The
 # value cannot contain a comma (`,`). (string value)
-#certfile = /etc/keystone/ssl/certs/signing_cert.pem
+certfile = /etc/keystone/ssl/certs/signing_cert.pem

 # Absolute path to the private key file to use for SAML signing. The value
 # cannot contain a comma (`,`). (string value)
-#keyfile = /etc/keystone/ssl/private/signing_key.pem
+keyfile = /etc/keystone/ssl/private/signing_key.pem

 # This is the unique entity identifier of the identity provider (keystone) to
 # use when generating SAML assertions. This value is required to generate
 # identity provider metadata and must be a URI (a URL is recommended). For
 # example: `https://keystone.example.com/v3/OS-FEDERATION/saml2/idp`. (uri
 # value)
-#idp_entity_id = <None>
+idp_entity_id = http://172.16.40.115/v3/OS-FEDERATION/saml2/idp

 # This is the single sign-on (SSO) service location of the identity provider
 # which accepts HTTP POST requests. A value is required to generate identity
 # provider metadata. For example: `https://keystone.example.com/v3/OS-
 # FEDERATION/saml2/sso`. (uri value)
-#idp_sso_endpoint = <None>
+idp_sso_endpoint = http://172.16.40.115/v3/OS-FEDERATION/saml2/sso

 # This is the language used by the identity provider's organization. (string
 # value)
@@ -2432,7 +2432,7 @@ driver = sql
 # Absolute path to the identity provider metadata file. This file should be
 # generated with the `keystone-manage saml_idp_metadata` command. There is
 # typically no reason to change this value. (string value)
-#idp_metadata_path = /etc/keystone/saml2_idp_metadata.xml
+idp_metadata_path = /etc/keystone/saml2_idp_metadata.xml

 # The prefix of the RelayState SAML attribute to use when generating enhanced
 # client and proxy (ECP) assertions. In a typical deployment, there is no
{% endraw %}
{% endhighlight %}
* Service Provider (SP) Detail.
{% highlight html %}
{% raw %}
ubuntu@shuquan-devstack-idp:~$ openstack service provider list
+------+---------+-------------+------------------------------------------------------------------------------------------+
| ID   | Enabled | Description | Auth URL                                                                                 |
+------+---------+-------------+------------------------------------------------------------------------------------------+
| mysp | True    | None        | http://172.16.40.112:5000/v3/OS-FEDERATION/identity_providers/myidp/protocols/saml2/auth |
+------+---------+-------------+------------------------------------------------------------------------------------------+
ubuntu@shuquan-devstack-idp:~$ openstack service provider show mysp
+--------------------+------------------------------------------------------------------------------------------+
| Field              | Value                                                                                    |
+--------------------+------------------------------------------------------------------------------------------+
| auth_url           | http://172.16.40.112:5000/v3/OS-FEDERATION/identity_providers/myidp/protocols/saml2/auth |
| description        | None                                                                                     |
| enabled            | True                                                                                     |
| id                 | mysp                                                                                     |
| relay_state_prefix | ss:mem:                                                                                  |
| sp_url             | http://172.16.40.112/Shibboleth.sso/SAML2/ECP                                            |
+--------------------+------------------------------------------------------------------------------------------+
{% endraw %}
{% endhighlight %}
