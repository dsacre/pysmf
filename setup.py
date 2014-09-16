#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys

try:
    from setuptools import setup, Extension
    from setuptools.command.test import test as TestCommand
    have_setuptools = True
except ImportError:
    from distutils.core import setup, Extension
    have_setuptools = False

if sys.version_info >= (3,):
    from subprocess import getstatusoutput
else:
    from commands import getstatusoutput

try:
    from Cython.Distutils import build_ext
    with_cython = True
except:
    with_cython = False


def pkgconfig(pkg):
    status, output = getstatusoutput('pkg-config --libs --cflags %s' % pkg)
    if status:
        sys.exit("couldn't find package '%s'" % pkg)
    for token in output.split():
        opt, val = token[:2], token[2:]
        if opt == '-I':
            include_dirs.append(val)
        elif opt == '-l':
            libraries.append(val)
        elif opt == '-L':
            library_dirs.append(val)

cmdclass = {'build_ext': build_ext} if with_cython else {}

if have_setuptools:
    class PyTest(TestCommand):
        def finalize_options(self):
            TestCommand.finalize_options(self)
            self.test_args = []
            self.test_suite = True
        def run_tests(self):
            #import here, cause outside the eggs aren't loaded
            import pytest
            pytest.main(self.test_args)

    cmdclass['test'] = PyTest
    extra_setup_opts = {'tests_require': ['pytest']}
else:
    extra_setup_opts = {}


include_dirs = []
libraries = []
library_dirs = []

pkgconfig('smf')


setup(
    name = 'pysmf',
    version = '0.1.1',
    author = 'Dominic Sacre',
    author_email = 'dominic.sacre@gmx.de',
    url = 'http://das.nasophon.de/pysmf/',
    description = 'a Python module for standard MIDI files, based on libsmf',
    license = 'BSD',
    ext_modules = [
        Extension(
            name = 'smf',
            sources = ['src/smf.pyx'] if with_cython else ['src/smf.c'],
            include_dirs = include_dirs,
            libraries = libraries,
            library_dirs = library_dirs,
            extra_compile_args = ['-Werror-implicit-function-declaration'],
        )
    ],
    cmdclass = cmdclass,
    **extra_setup_opts
)
