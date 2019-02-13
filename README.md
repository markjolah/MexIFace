
A Cross-Platform C++ / MEX Object-based interface wrapper and CMake build tool.

Copyright 2013-2019
Author: Mark J. Olah
Email: (mjo@cs.unm DOT edu)

## About

The MexIFace class provides a flexible means of wrapping a complex C++ library into a Matlab class via Matlab's MEX function
extension method.  The MexIFace package provides efficient means of passing Matlab arrays to transparently as C++ Armadillo arrays,
allowing the same memory to be safely shared between each end of the interface.

The MexIFace class is designed to cross-compile from Linux to target Matlab versions R2016b and newer on Linux (`glnxa64`) and Windows 64-bit (`win64`)
platforms.  Details on setting up a compatible cross-compilation environment are in Build Environment Configuration.

The MexIFace package integrates easily with CMake based packages.
For the impatient, the MexIFace-ArmadilloExample repository is a fully functional MexIFace module that demonstrates the MexIFace C++ and Matlab interfaces,
as well as the suggested CMake build environment.

## Background

Matlab uses compiled plugins called MEX files to enable linking and running compiled C and C++ code.
Each MEX file is a separate shared object file (ELF/DLL) that is dynamically loaded by the Matlab
binary when called.  It presents to Matlab an interface consisting of a single function with variadic arguments.

> function varargout = mexFunction(varargin)

As C and C++ libraries and toolsets become more complex this single-function interface becomes restrictive.
Complex libraries have both state and behavior, they provide multiple functions that interact with that state,
they require initialization on load time and cleanup on unload time, and they require Matlab to manage
the memory they must allocate.  In other words, complex libraries are much more like objects then functions, so an object-oriented
MEX file interface provides an easier, safer, faster, and more organized way of interacting with complex C++ libraries from Matlab.

### MexIFace overview

The goal of MexIFace is to build a complete Matlab class with a C++ backend class.  The Matlab and C++ wrapper classes work in tandem
to implement constructor and destructor operatrions as well as normal methods (member functions) and static methods (static member functions).
When a MexIFace object is created in matlab,
the constructor arguments are passed to a designated method of a C++ backend class that can use MexIFace methods to easily read and
it can be given arbitrary constructor arguments, and those arguments can be used to initialize C++ data structures.

and utilizing matlab's
built-in object-oriented programming support is a much more natural and fluid way




Matlab MEX files are compiled

This type of interface is necessary because a Matlab .mex plug-in can only act as a Matlab function,
not
a Matlab class.  The Mex_Iface class exposes a mexFunction method which takes in a variable number
of arguments
and returns a variable number of arguments.  The first input argument is always a string that gives
the command name.
If it the special command "\@new" or "\@delete" a C++ instance is created or destroyed.  The \@new
command
returns a unique handle (number)
which can be held onto by the Matlab IfaceMixin base class.  This C++ object then remains in memory
until the
\@delete command is called on the Mex_Iface, which then frees the underlying C++ class from memory.

The special command "\@static" allows static C++ methods to be called by the name passed as the
second argument,
and there is no need to have a existing object to call the method on because it is static.

Otherwise the command is interpreted as a named method which is registered in the methodmap,
internal data structure which maps strings to callable member functions of the interface object
which take in no
arguments and return no arguments.  The matlab arguments are passed to these functions through the
internal storage of the
Mex_Iface object's rhs and lhs member variables.

A C++ class is wrapped by creating a new Iface class that inherits from Mex_Iface.  At a minimum
the Iface class must define the pure virtual functions objConstruct(), objDestroy(), and
getObjectFromHandle().  It also
must implement the interface for any of the methods and static methods that are required.  Each of
these methods in the
Iface class must process the passed matlab arguments in the rhs member variable and save outputs in
the lhs member variable.

In general the Iface mex modules are not intended to be used directly, but rather are paired with a
special Matlab
class that inherits from the IfaceMixin.m base class.

Design decision:  Because of the complexities of inheriting from a templated base class with regard
to name lookups
in superclasses, we chose to keep this Mex_Iface class non-templated.  For this reason any methods
and member variables which
specifically mention the type of the wrapped class must be defined in the subclass of Mex_Iface.

Finally we provide many get* and make* which allow the lhs and rhs arguments to be interpreted as
armadillo arrays on the C++ side.
These methods are part of what makes this interface efficient as we don't need to create new storage
and copy data, instead we just use
the matlab memory directly, and matlab does all the memory management of parameters passed in and
out.
