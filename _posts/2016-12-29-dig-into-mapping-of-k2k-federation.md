---
layout: post
title: "Dig into Mapping of K2K Federation"
description: "Dig into Mapping of K2K Federation"
tags: [federation, keystone, openstack, hybrid cloud]
---

After I setup the keystone federation feature, it's nice to go with the examples in [official docs](http://docs.openstack.org/developer/keystone/federation/federated_identity.html). However, I want to see more from it. :) First thing is that how do the rules to map **federation protocol attributes** to **Identity API objects** and how does SP manage the mapping users.  

### What's Mapping

>A mapping is a set of rules to map federation protocol attributes to Identity API objects. An Identity Provider can have a single mapping specified per protocol. A mapping is simply a list of rules.

As a simple example, if keystone is your IdP, you can map a few known remote users to the group you already created:

{% highlight html %}
{% raw %}
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
                "type": "openstack_user",
                "any_one_of": [
                    "demo",
                    "alt_demo"
                ]
            }
        ]
    }
]
EOF
$ openstack mapping create --rules rules.json myidp_mapping
{% endraw %}
{% endhighlight %}

### Value Setting in Mapping rules

A rule hierarchy looks as follows:

{% highlight html %}
{% raw %}
{
    "rules": [
        {
            "local": [
                {
                    "<user> or <group>"
                }
            ],
            "remote": [
                {
                    "<condition>"
                }
            ]
        }
    ]
}
{% endraw %}
{% endhighlight %}

* rules: top-level list of rules.
* local: a rule containing information on what local attributes will be mapped.
* remote: a rule containing information on what remote attributes will be mapped.
* condition: contains information on conditions that allow a rule, can only be set in a remote rule.

**Note:** You can not set value arbitrary in remote rule. All the value must follow **federation protocol attributes** and the key should be *type*.

#### What's Federation Protocol Attributes

Federation protocol attributes is the assertion sent by IdP. Normally You can see it in SP logs, and you can find *openstack_user* inside. It's why we have to have "type": "openstack_user" in the rule. Please refer to this if you want to have other values, such as SERVER_NAME, SERVER_PORT, etc.

{% highlight html %}
{% raw %}
2016-12-30 08:45:48.234 13923 DEBUG keystone.federation.utils [req-2d12dd32-a563-409d-92b3-f84d20c817c4 - - - - -] assertion: {'AUTH_TYPE': [u'shibboleth'], 'mod_wsgi.listener_port': [u'5000'], 'HTTP_COOKIE': [u'_shibsession_64656661756c74687474703a2f2f3137322e31362e34302e3131322f73686962626f6c657468=_d88c6c214f5deb51aa78e4a3e0062d75'], 'CONTEXT_DOCUMENT_ROOT': [u'/var/www'], 'SERVER_SOFTWARE': [u'Apache/2.4.7 (Ubuntu)'], 'SCRIPT_NAME': [u'/v3'], 'mod_wsgi.enable_sendfile': [u'0'], 'mod_wsgi.handler_script': [u''], 'SERVER_SIGNATURE': [u'<address>Apache/2.4.7 (Ubuntu) Server at 172.16.40.112 Port 5000</address>\\n'], 'REQUEST_METHOD': [u'GET'], 'PATH_INFO': [u'/OS-FEDERATION/identity_providers/myidp/protocols/saml2/auth'], 'SERVER_PROTOCOL': [u'HTTP/1.1'], 'QUERY_STRING': [u''], 'openstack_user': [u'mike'], 'HTTP_USER_AGENT': [u'python-keystoneclient'], 'HTTP_CONNECTION': [u'keep-alive'], 'SERVER_NAME': [u'172.16.40.112'], 'REMOTE_PORT': [u'45344'], 'mod_wsgi.queue_start': [u'1483087544870780'], 'Shib-AuthnContext-Class': [u'urn:oasis:names:tc:SAML:2.0:ac:classes:Password'], 'mod_wsgi.request_handler': [u'wsgi-script'], 'wsgi.url_scheme': [u'http'], 'Shib-Authentication-Method': [u'urn:oasis:names:tc:SAML:2.0:ac:classes:Password'], 'openstack_user_domain': [u'Default'], 'PATH_TRANSLATED': [u'/usr/local/bin/keystone-wsgi-public/v3/OS-FEDERATION/identity_providers/myidp/protocols/saml2/auth'], 'SERVER_PORT': [u'5000'], 'mod_wsgi.input_chunked': [u'0'], 'openstack_roles': [u'admin'], 'SERVER_ADDR': [u'172.16.40.112'], 'DOCUMENT_ROOT': [u'/var/www'], 'mod_wsgi.process_group': [u'keystone-public'], 'Shib-Authentication-Instant': [u'2016-12-30T08:45:44Z'], 'SCRIPT_FILENAME': [u'/usr/local/bin/keystone-wsgi-public'], 'openstack_project_domain': [u'Default'], 'SERVER_ADMIN': [u'[no address given]'], 'REMOTE_USER': [u''], 'HTTP_HOST': [u'172.16.40.112:5000'], 'CONTEXT_PREFIX': [u''], 'mod_wsgi.callable_object': [u'application'], 'Shib-Session-Index': [u'd7371f4d5d3547c3b61560c80fc0bc05'], 'REQUEST_URI': [u'/v3/OS-FEDERATION/identity_providers/myidp/protocols/saml2/auth'], 'HTTP_ACCEPT': [u'*/*'], 'openstack.request_id': [u'req-2d12dd32-a563-409d-92b3-f84d20c817c4'], 'Shib-Application-ID': [u'default'], 'GATEWAY_INTERFACE': [u'CGI/1.1'], 'REMOTE_ADDR': [u'172.16.40.115'], 'mod_wsgi.listener_host': [u''], 'REQUEST_SCHEME': [u'http'], 'Shib-Identity-Provider': [u'http://172.16.40.115/v3/OS-FEDERATION/saml2/idp'], 'openstack_project': [u'demo'], 'CONTENT_TYPE': [u'application/vnd.paos+xml'], 'mod_wsgi.application_group': [u''], 'Shib-Session-ID': [u'_d88c6c214f5deb51aa78e4a3e0062d75'], 'mod_wsgi.script_reloading': [u'1'], 'HTTP_ACCEPT_ENCODING': [u'gzip, deflate']} process /opt/stack/keystone/keystone/federation/utils.py:489
{% endraw %}
{% endhighlight %}

#### How does keystone process mappings?

The main entry is from 'keystone/federation/core.py' and 'keystone/federation/utils.py' finishes the jobs. Take a look at the *process* function of *RuleProcessor* class, *_verify_all_requirements* function and *_update_local_mapping* function in *utils.py*.

why we have to use 'type'? keystone will use 'type' as the key to get the value from assertion. If it's None, it will cause a final failed in *_transform* function.

~~~ python
def _verify_all_requirements(self, requirements, assertion):
    """Compare remote requirements of a rule against the assertion.

    If a value of ``None`` is returned, the rule with this assertion
    doesn't apply.
    If an array of zero length is returned, then there are no direct
    mappings to be performed, but the rule is valid.
    Otherwise, then it will first attempt to filter the values according
    to blacklist or whitelist rules and finally return the values in
    order, to be directly mapped.

    :param requirements: list of remote requirements from rules
    :type requirements: list

    Example requirements::

        [
            {
                "type": "UserName"
            },
            {
                "type": "orgPersonType",
                "any_one_of": [
                    "Customer"
                ]
            },
            {
                "type": "ADFS_GROUPS",
                "whitelist": [
                    "g1", "g2", "g3", "g4"
                ]
            }
        ]

    :param assertion: dict of attributes from an IdP
    :type assertion: dict

    Example assertion::

        {
            'UserName': ['testacct'],
            'LastName': ['Account'],
            'orgPersonType': ['Tester'],
            'Email': ['testacct@example.com'],
            'FirstName': ['Test'],
            'ADFS_GROUPS': ['g1', 'g2']
        }

    :returns: identity values used to update local
    :rtype: keystone.federation.utils.DirectMaps or None

    """
    direct_maps = DirectMaps()

    for requirement in requirements:
        requirement_type = requirement['type']
        direct_map_values = assertion.get(requirement_type)
        regex = requirement.get('regex', False)

        if not direct_map_values:
            return None

        any_one_values = requirement.get(self._EvalType.ANY_ONE_OF)
        if any_one_values is not None:
            if self._evaluate_requirement(any_one_values,
                                          direct_map_values,
                                          self._EvalType.ANY_ONE_OF,
                                          regex):
                continue
            else:
                return None

        not_any_values = requirement.get(self._EvalType.NOT_ANY_OF)
        if not_any_values is not None:
            if self._evaluate_requirement(not_any_values,
                                          direct_map_values,
                                          self._EvalType.NOT_ANY_OF,
                                          regex):
                continue
            else:
                return None

        # If 'any_one_of' or 'not_any_of' are not found, then values are
        # within 'type'. Attempt to find that 'type' within the assertion,
        # and filter these values if 'whitelist' or 'blacklist' is set.
        blacklisted_values = requirement.get(self._EvalType.BLACKLIST)
        whitelisted_values = requirement.get(self._EvalType.WHITELIST)

        # If a blacklist or whitelist is used, we want to map to the
        # whole list instead of just its values separately.
        if blacklisted_values is not None:
            direct_map_values = [v for v in direct_map_values
                                 if v not in blacklisted_values]
        elif whitelisted_values is not None:
            direct_map_values = [v for v in direct_map_values
                                 if v in whitelisted_values]

        direct_maps.add(direct_map_values)

        LOG.debug('updating a direct mapping: %s', direct_map_values)

    return direct_maps
~~~

### Reference

* [Mapping Combinations](http://docs.openstack.org/developer/keystone/federation/mapping_combinations.html)
* [Mappings API](http://developer.openstack.org/api-ref/identity/v3-ext/#mappings)
