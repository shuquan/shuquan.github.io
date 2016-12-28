---
layout: post
title: "Playing with Keystone to Keystone Federation"
description: "Playing with Keystone to Keystone Federation"
tags: [federation, keystone, openstack, hybrid cloud]
---

### Environment

In the [previous post](http://shuquan.github.io/setting-up-keystone-to-keystone-federation/), I elaborated how to setup keystone to keystone federation with two devstacks. In this post, I'll use the similar environment except change the token from fernet to uuid for simplicity.

~~~ shell
+-------------------+     +------------------+
|                   |     |                  |
| IdP:172.16.40.113 |     | SP:172.16.40.114 |
|                   |     |                  |
+-------------------+     +------------------+
~~~

### Demo step

1. Get an unscoped token.[^1]
2. Scope the unscoped token with specific domain and project name.
3. Use the scoped token[^2] to achieve user list in SP.

[^1]:<http://docs.openstack.org/admin-guide/identity-tokens.html#unscoped-tokens>
[^2]:<http://docs.openstack.org/admin-guide/identity-tokens.html#project-scoped-tokens>

#### Get an unscoped token.

You have to use python client to get a unscoped token right now.

~~~ shell
$ cat v3rc
export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL=http://172.16.40.113:35357/v3
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_DEFAULT_DOMAIN=default
export OS_USERNAME=admin
export OS_PASSWORD=password
export OS_PROJECT_NAME=admin
export OS_PROJECT_ID=48614c49a38b4dfa919ab8fe3db7e702

$ source v3rc
$ python get-unscope-token.py

...
...
...

Unscoped token id: 114350fd00434c1b83838c65464aa7c8
~~~

{% highlight python %}
{% raw %}
import json
import os


from keystoneclient import session as ksc_session
from keystoneclient.auth.identity import v3
from keystoneclient.v3 import client as keystone_v3


class K2KClient(object):
    def __init__(self):
        # os sp id need set manually
        #self.sp_id = os.environ.get('OS_SP_ID')
        self.sp_id = 'mysp'
        self.token_id = os.environ.get('OS_TOKEN')
        self.auth_url = os.environ.get('OS_AUTH_URL')
        self.project_id = os.environ.get('OS_PROJECT_ID')
        self.username = os.environ.get('OS_USERNAME')
        self.password = os.environ.get('OS_PASSWORD')
        #self.domain_id = os.environ.get('OS_DOMAIN_ID')
        self.domain = os.environ.get('OS_DOMAIN')


    def v3_authenticate(self):
        auth = v3.Password(auth_url=self.auth_url,
                           username=self.username,
                           password=self.password,
                           user_domain_id='default',
                           project_id=self.project_id)
        self.session = ksc_session.Session(auth=auth, verify=False)
        self.session.auth.get_auth_ref(self.session)
        self.token = self.session.auth.get_token(self.session)


    def _generate_token_json(self):
        return {
            "auth": {
                "identity": {
                    "methods": [
                        "token"
                    ],
                    "token": {
                        "id": self.token
                        #"id": "23fd45092e434d529bc7bb5fa9bdb711"
                    }
                },
                "scope": {
                    "service_provider": {
                        "id": self.sp_id
                    }
                }
            }
        }


    def _check_response(self, response):
        if not response.ok:
            raise Exception("Something went wrong, %s" % response.__dict__)


    def get_saml2_ecp_assertion(self):
        """ Exchange a scoped token for an ECP assertion. """
        token = json.dumps(self._generate_token_json())
        url = self.auth_url + '/auth/OS-FEDERATION/saml2/ecp'
        r = self.session.post(url=url, data=token, verify=False)
        self._check_response(r)
        self.assertion = str(r.text)


    def _get_sp(self):
        url = self.auth_url + '/OS-FEDERATION/service_providers/' + self.sp_id
        r = self.session.get(url=url, verify=False)
        self._check_response(r)
        sp = json.loads(r.text)[u'service_provider']
        return sp


    def _handle_http_302_ecp_redirect(self, session, response, location, method, **kwargs):
        #return session.get(location, authenticated=False, data=self.assertion, **kwargs)
        return session.get(location, authenticated=False, **kwargs)
        #return session.request(location, method, authenticated=False,
        #                       **kwargs)


    def exchange_assertion(self):
        """Send assertion to a Keystone SP and get token."""
        sp = self._get_sp()

        # import pdb
        # pdb.set_trace()

        response = self.session.post(
            sp[u'sp_url'],
            headers={'Content-Type': 'application/vnd.paos+xml'},
            data=self.assertion,
            authenticated=False,
            redirect=False)
        self._check_response(response)

        #r = self._handle_http_302_ecp_redirect(r, sp[u'auth_url'],
        #                                       headers={'Content-Type':
        #                                       'application/vnd.paos+xml'})
        r = self._handle_http_302_ecp_redirect(self.session, response, sp[u'auth_url'],
                                               method='GET',
                                               headers={'Content-Type':
                                               'application/vnd.paos+xml'})
        self.fed_token_id = r.headers['X-Subject-Token']
        self.fed_token = r.text




def main():
    client = K2KClient()
    client.v3_authenticate()
    client.get_saml2_ecp_assertion()
    print('ECP wrapped SAML assertion: %s' % client.assertion)
    client.exchange_assertion()
    print('Unscoped token id: %s' % client.fed_token_id)


if __name__ == "__main__":
    main()
{% endraw %}
{% endhighlight %}

#### Scope the unscoped token with specific domain and project name.

{% highlight shell %}
{% raw %}
$ curl -X POST -H "Content-Type: application/json" -d '{"auth":{"identity":{"methods":["token"],"token":{"id":"114350fd00434c1b83838c65464aa7c8"}},"scope":{"project":{"domain": {"name": "Default"},"name":"admin"}}}}' -D - http://172.16.40.114:5000/v3/auth/tokens
{% endraw %}
{% endhighlight %}

And you'll get something that looks like this:

{% highlight shell %}
{% raw %}
HTTP/1.1 201 Created
Date: Tue, 20 Dec 2016 10:20:14 GMT
Server: Apache/2.4.7 (Ubuntu)
X-Subject-Token: 5f8e00d777754986a63dbab3431aa867
Vary: X-Auth-Token
x-openstack-request-id: req-cb7a71ec-4527-44d5-9ded-876b9166e951
Content-Length: 5659
Content-Type: application/json

{
    "token": {
        "audit_ids": [
            "5YphXnNoQj64-aaXBvDxcg"
        ],
        "catalog": [
            {
                "endpoints": [
                    {
                        "id": "0610fd8c59614b48a1984ea32ddaf534",
                        "interface": "public",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114/identity"
                    },
                    {
                        "id": "7c6ac5589b12416e894266246379a403",
                        "interface": "internal",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114/identity"
                    },
                    {
                        "id": "943df2eaacee4062b0849294099fdde8",
                        "interface": "admin",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114/identity_admin"
                    }
                ],
                "id": "463f1970c326420997bc16b0e9631eb2",
                "name": "keystone",
                "type": "identity"
            },
            {
                "endpoints": [
                    {
                        "id": "0535350a500c4d47b0414293ea7af1b7",
                        "interface": "internal",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8776/v1/df704be2e4d344519b674c6621b42ed3"
                    },
                    {
                        "id": "660c6fba4d4f47bbacad890d5a87fde0",
                        "interface": "public",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8776/v1/df704be2e4d344519b674c6621b42ed3"
                    },
                    {
                        "id": "7123c5f93d0b4691aaae599bfa990c44",
                        "interface": "admin",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8776/v1/df704be2e4d344519b674c6621b42ed3"
                    }
                ],
                "id": "481215d6de764c1c993633545c9ad0b7",
                "name": "cinder",
                "type": "volume"
            },
            {
                "endpoints": [
                    {
                        "id": "5cc44f18848b49808662ae491829502c",
                        "interface": "public",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:9696/"
                    },
                    {
                        "id": "5f0e5b329e93492cbfa7a268ee4cee63",
                        "interface": "internal",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:9696/"
                    },
                    {
                        "id": "dab46ac4d6084ec0a945c29c7a3761de",
                        "interface": "admin",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:9696/"
                    }
                ],
                "id": "558555396b0447a7b005c43ad56988f6",
                "name": "neutron",
                "type": "network"
            },
            {
                "endpoints": [
                    {
                        "id": "005b6eca401b4e8386e733d66db8abf3",
                        "interface": "internal",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:9292"
                    },
                    {
                        "id": "ad723da65ca747a49b34f73ebffda192",
                        "interface": "admin",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:9292"
                    },
                    {
                        "id": "f93a6d6820ff4b1ebda8f4a0d0cd0cd9",
                        "interface": "public",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:9292"
                    }
                ],
                "id": "599201c7e5aa4feeab5cee3f0232f728",
                "name": "glance",
                "type": "image"
            },
            {
                "endpoints": [
                    {
                        "id": "8504d494189d42659b8810f036a99ed5",
                        "interface": "public",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8774/v2/df704be2e4d344519b674c6621b42ed3"
                    },
                    {
                        "id": "8eaa24f979a84d0788b54d2eb45ee22c",
                        "interface": "internal",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8774/v2/df704be2e4d344519b674c6621b42ed3"
                    },
                    {
                        "id": "b99163261e564521ae9de32381c6f1dd",
                        "interface": "admin",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8774/v2/df704be2e4d344519b674c6621b42ed3"
                    }
                ],
                "id": "6118a293edca4afd90df8a1ad034745f",
                "name": "nova_legacy",
                "type": "compute_legacy"
            },
            {
                "endpoints": [
                    {
                        "id": "166ebfdd8f7648ac87ea77696d0ec2a8",
                        "interface": "public",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8776/v2/df704be2e4d344519b674c6621b42ed3"
                    },
                    {
                        "id": "3ddc632d3783491a99524170d0f9f4a5",
                        "interface": "admin",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8776/v2/df704be2e4d344519b674c6621b42ed3"
                    },
                    {
                        "id": "eb5432a5d8a74845a1e387189c43e81c",
                        "interface": "internal",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8776/v2/df704be2e4d344519b674c6621b42ed3"
                    }
                ],
                "id": "7473883c655f4f7c8f2154e76329bcb0",
                "name": "cinderv2",
                "type": "volumev2"
            },
            {
                "endpoints": [
                    {
                        "id": "6c8eaf362f9344388a1acd09c5852b36",
                        "interface": "internal",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8776/v3/df704be2e4d344519b674c6621b42ed3"
                    },
                    {
                        "id": "85811b68a145489695857735c7681c49",
                        "interface": "admin",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8776/v3/df704be2e4d344519b674c6621b42ed3"
                    },
                    {
                        "id": "b8a087d574f74f88a19a3f939082e286",
                        "interface": "public",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8776/v3/df704be2e4d344519b674c6621b42ed3"
                    }
                ],
                "id": "87a91a84d7c84c6aa0d156cbc1597e16",
                "name": "cinderv3",
                "type": "volumev3"
            },
            {
                "endpoints": [
                    {
                        "id": "308a0278d62e4b14bd873416b18957d2",
                        "interface": "internal",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8774/v2.1"
                    },
                    {
                        "id": "6ae89f4a60f94b6ba9616a39d748fabd",
                        "interface": "admin",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8774/v2.1"
                    },
                    {
                        "id": "be0d82d66d374497bca3474f23593926",
                        "interface": "public",
                        "region": "RegionOne",
                        "region_id": "RegionOne",
                        "url": "http://172.16.40.114:8774/v2.1"
                    }
                ],
                "id": "8bfdba065fae4298868453592b7d171f",
                "name": "nova",
                "type": "compute"
            }
        ],
        "expires_at": "2016-12-20T11:20:18.000000Z",
        "is_domain": false,
        "issued_at": "2016-12-20T10:20:18.000000Z",
        "methods": [
            "token"
        ],
        "project": {
            "domain": {
                "id": "default",
                "name": "Default"
            },
            "id": "df704be2e4d344519b674c6621b42ed3",
            "name": "admin"
        },
        "roles": [
            {
                "domain_id": null,
                "id": "0c2aa16148a64bc4b918f7b16afa8bf5",
                "name": "admin"
            },
            {
                "domain_id": null,
                "id": "0c2aa16148a64bc4b918f7b16afa8bf5",
                "name": "admin"
            }
        ],
        "user": {
            "OS-FEDERATION": {
                "groups": [
                    {
                        "id": "0c68765dc5764a30b673f32370e01983"
                    }
                ],
                "identity_provider": {
                    "id": "myidp"
                },
                "protocol": {
                    "id": "saml2"
                }
            },
            "domain": {
                "id": "Federated",
                "name": "Federated"
            },
            "id": "1933c49872d144bca5d9ce5d86cebae8",
            "name": "admin"
        }
    }
}
{% endraw %}
{% endhighlight %}

You can copy the scoped token from **X-Subject-Token** at the response header and use it in the next step.

#### Use the scoped token to achieve user list in SP.

Use the scoped token to interact with SP endpoints.

{% highlight shell %}
{% raw %}
$ curl -g  -X GET http://172.16.40.114:5000/v3/users -H "Accept: application/json" -H "X-Auth-Token: 5f8e00d777754986a63dbab3431aa867" | python -m json.tool

{
    "links": {
        "next": null,
        "previous": null,
        "self": "http://172.16.40.114/identity/v3/users"
    },
    "users": [
        {
            "domain_id": "default",
            "email": "alt_demo@example.com",
            "enabled": true,
            "id": "08e3136348284f218f841742bc12b7fd",
            "links": {
                "self": "http://172.16.40.114/identity/v3/users/08e3136348284f218f841742bc12b7fd"
            },
            "name": "alt_demo",
            "password_expires_at": null
        },
        {
            "domain_id": null,
            "enabled": true,
            "id": "1933c49872d144bca5d9ce5d86cebae8",
            "links": {
                "self": "http://172.16.40.114/identity/v3/users/1933c49872d144bca5d9ce5d86cebae8"
            },
            "name": "admin",
            "password_expires_at": null
        },
        {
            "domain_id": "default",
            "enabled": true,
            "id": "1df12ac7f6114779b6b68c4be30ae162",
            "links": {
                "self": "http://172.16.40.114/identity/v3/users/1df12ac7f6114779b6b68c4be30ae162"
            },
            "name": "neutron",
            "password_expires_at": null
        },
        {
            "domain_id": "default",
            "enabled": true,
            "id": "9ca3f32b99c24eb6933c95afd13ff140",
            "links": {
                "self": "http://172.16.40.114/identity/v3/users/9ca3f32b99c24eb6933c95afd13ff140"
            },
            "name": "glance",
            "password_expires_at": null
        },
        {
            "domain_id": "default",
            "enabled": true,
            "id": "a04f9ee0b24d4dceb695f2bd38e8cd7d",
            "links": {
                "self": "http://172.16.40.114/identity/v3/users/a04f9ee0b24d4dceb695f2bd38e8cd7d"
            },
            "name": "admin",
            "password_expires_at": null
        },
        {
            "domain_id": "default",
            "enabled": true,
            "id": "ad826ed2897f45b8858f953612a9588e",
            "links": {
                "self": "http://172.16.40.114/identity/v3/users/ad826ed2897f45b8858f953612a9588e"
            },
            "name": "user_in_sp",
            "password_expires_at": null
        },
        {
            "domain_id": "default",
            "email": "demo@example.com",
            "enabled": true,
            "id": "b39ec9e44b784c13aae015c7f49baccd",
            "links": {
                "self": "http://172.16.40.114/identity/v3/users/b39ec9e44b784c13aae015c7f49baccd"
            },
            "name": "demo",
            "password_expires_at": null
        },
        {
            "domain_id": "default",
            "enabled": true,
            "id": "e063a425d0c341b98ce449dd84f08a26",
            "links": {
                "self": "http://172.16.40.114/identity/v3/users/e063a425d0c341b98ce449dd84f08a26"
            },
            "name": "nova",
            "password_expires_at": null
        },
        {
            "domain_id": "default",
            "enabled": true,
            "id": "ec7df3dc3fe14b78bf2351994eca1a54",
            "links": {
                "self": "http://172.16.40.114/identity/v3/users/ec7df3dc3fe14b78bf2351994eca1a54"
            },
            "name": "cinder",
            "password_expires_at": null
        }
    ]
}
{% endraw %}
{% endhighlight %}

### Reference

* [Configure Keystone to Keystone Federation](http://blog.rodrigods.com/it-is-time-to-play-with-keystone-to-keystone-federation-in-kilo/)
* [Configure Keystone to Testshib Federation with SAML](https://bigjools.wordpress.com/2015/05/22/saml-federation-with-openstack/)
* [Configure Keystone federation with Kerberos](https://bigjools.wordpress.com/2015/04/27/federated-openstack-logins-using-kerberos/)
* [Configure Keystone federation with multi-IDP](https://zenodo.org/record/11982/files/CERN_openlab_Luca_Tartarini.pdf)
* [OpenStack Keystone Federated Identity](http://docs.openstack.org/developer/keystone/federation/federated_identity.html)
