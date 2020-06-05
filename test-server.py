#!/usr/bin/env python3

#
# Runs an inspircd/inspircd-docker Docker container for testing purposes.
# 
#   ./test-server.py [create|start|watch|stop|reset]
#
# When creating, you can optionally pass environment variables to the run
# command. This is particularly useful for setting a password on the server.
# For example:
#
#   ./test-server.py create -e "INSP_CONNECT_PASSWORD=s3cret"
# 

import argparse
import docker
import sys

IMAGE = 'inspircd/inspircd-docker'

class TestServerDriver:

    def __init__(self):
        self.docker_client = docker.from_env()

    def run(self):
        parser = argparse.ArgumentParser(description='Manage a test IRC server')
        parser.add_argument('command', 
                            choices=['create', 'start', 'watch', 'stop', 'reset'], 
                            help='The driver command')
        args = parser.parse_args(sys.argv[1:2])
        if not hasattr(self, '_' + args.command):
            print('Unrecognized command')
            parser.print_help()
            exit(1)
        getattr(self, '_' + args.command)()

    def _create(self):
        parser = argparse.ArgumentParser(description='Create and run a a test server')
        parser.add_argument('-e', nargs='*', help='An environment variable to pass to the server')
        args = parser.parse_args(sys.argv[2:])
        self.docker_client.containers.run(IMAGE,
                                          name='ircd', 
                                          ports={'6667/tcp':6667, '6697/tcp':'6697'},
                                          environment=args.e,
                                          detach=True)

    def _get_container(self, name):
        try:
            return self.docker_client.containers.get(name)
        except docker.errors.NotFound as e:
            print('No container found named {}'.format(name))
            exit(1)

    def _start(self):
        container = self._get_container('ircd')
        container.start()

    def _watch(self):
        container = self._get_container('ircd')
        try:
            for line in container.logs(stream=True, follow=True):
                print(line.decode('utf-8'), end='')
        except KeyboardInterrupt:
            stored_exception = sys.exc_info()
            print()

    def _stop(self):
        container = self._get_container('ircd')
        container.stop()

    def _reset(self):
        container = self._get_container('ircd')
        container.remove(force=True)

if __name__ == '__main__':
    TestServerDriver().run()
