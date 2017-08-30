#!/plone/instance/bin/python

import os


class Environment(object):
    """ Configure container via environment variables
    """

    def __init__(self, env=os.environ,
                 zeoserver_conf="/opt/zeoserver/parts/zeoserver/etc/zeo.conf"
                 ):
        self.env = env
        self.zeoserver_conf = zeoserver_conf

    def zeoserver(self):
        """ ZEO Server
        """
        pack_keep_old = self.env.get("ZEO_PACK_KEEP_OLD", '')
        if pack_keep_old.lower() in ("false", "no", "0", "n", "f"):
            with open(self.zeoserver_conf, 'r') as cfile:
                text = cfile.read()
                if 'pack-keep-old' not in text:
                    text = text.replace(
                        '</filestorage>',
                        '  pack-keep-old false\n</filestorage>'
                    )

            with open(self.zeoserver_conf, 'w') as cfile:
                cfile.write(text)

    def setup(self, **kwargs):
        self.zeoserver()

    __call__ = setup


def initialize():
    """ Configure ZEOSERVER
    """
    environment = Environment()
    environment.setup()


if __name__ == "__main__":
    initialize()
