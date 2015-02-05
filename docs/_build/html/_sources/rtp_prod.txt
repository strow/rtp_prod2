rtp-prod
========

Introduction
------------

Junk filler

Radiative transfer
------------------

More Junk filler

Some Math
---------

Finite difference column jacobians can be obtained from the (gas)
layer analytic jacobians using


.. math::

    \delta r = \frac{\partial r}{\partial q_1} \delta q_1 + 
               \frac{\partial r}{\partial q_2} \delta q_2 + ... + 
               \frac{\partial r}{\partial q_N} \delta q_N

or



.. math::

    \delta r = J_{1} \delta q_1 + J_{2} \delta q_2 + ...
                   J_{N} \delta q_N

Installation
------------

This is for the user that wants to install and use kCARTA as quickly as
possible. We purposely keep this user manual short, and ask the user to
examine the ``user_set*.m`` codes in the ``Test`` subdirectory in orderto
understand how to use the package.

The distribution is divided into three parts :

- Matlab source on `github <http://github.com/strow/kcarta-matlab>`_.

- kCompressed Database: about 600Mb, supplied via our ftp site. We
  supply two versions, big or little endian.

The ``Test`` directory contains ``matlab_test_desert_0725_2004.mat`` which
is a radiance computation coming from running the ``dokcarta_downlook.m``
in that directory.

.. figure:: ./desert_rtp.png
 
   Sample output from ``desert_op.rtp`` convolved with AIRS SRFs
