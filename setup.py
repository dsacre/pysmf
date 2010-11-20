#!/usr/bin/env python
# -*- coding: utf-8 -*-

from distutils.core import setup, Extension
import sys
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

include_dirs = []
libraries = []
library_dirs = []

pkgconfig('smf')


setup (
    name = 'pysmf',
    version = '0.1.0',
    author = 'Dominic Sacre',
    author_email = 'dominic.sacre@gmx.de',
    url = 'http://das.nasophon.de/pysmf/',
    description = 'A module for reading and writing standard MIDI files, based on libsmf',
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
    cmdclass = {'build_ext': build_ext} if with_cython else {},
)
