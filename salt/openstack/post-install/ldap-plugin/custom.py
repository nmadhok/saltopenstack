from __future__ import absolute_import

import copy
import ldap
import functools
import logging

from keystone import clean
from keystone import exception
from keystone import identity
from keystone.common import sql
from keystone.common import utils
from keystone.identity.backends.sql import *


def _check_password(self, password, user_ref):
        """
        Check the specified password against the data store.
        """
        LDAP_URI = "ldaps://ldap.domain.com"
        DN_MAPPING = "cn=%s,ou=users,ou=people,o=myorganization"
        name = user_ref.get('name')
        if not password:
            return False

        if (name.find('@') == -1):
            return utils.check_password(password, user_ref.get('password'))

        username,domain = name.split('@')
        if (domain == 'admin.domain.com' or domain == 'domain.com'):
          try:
             ldap.set_option(ldap.OPT_X_TLS_REQUIRE_CERT,ldap.OPT_X_TLS_NEVER)
             l = ldap.initialize(LDAP_URI)
             l.simple_bind_s(DN_MAPPING % (username), password)
             return True
          except ldap.INVALID_CREDENTIALS:
             return False
        
        return False

Identity._check_password = _check_password
