# MexIface

A Cross-Platform C++ / MEX Object-based interface wrapper and CMake build tool.

Copyright 2013-2017 
Author: Mark J. Olah 
Email: (mjo@cs.unm DOT edu)

## About

* The Mex_Iface class provides a generic means of wrapping a C++ class as a Matlab MEX function, that
 * can then be exposed as a Matlab class.  This flexibility allows the code to be used in an
 * object-oriented style either from other C++ code or from Matlab.
 *
 * This type of interface is necessary because a Matlab .mex plug-in can only act as a Matlab function, not
 * a Matlab class.  The Mex_Iface class exposes a mexFunction method which takes in a variable number of arguments
 * and returns a variable number of arguments.  The first input argument is always a string that gives the command name.
 * If it the special command "\@new" or "\@delete" a C++ instance is created or destroyed.  The \@new command
 * returns a unique handle (number)
 * which can be held onto by the Matlab IfaceMixin base class.  This C++ object then remains in memory until the
 * \@delete command is called on the Mex_Iface, which then frees the underlying C++ class from memory.
 *
 * The special command "\@static" allows static C++ methods to be called by the name passed as the second argument,
 * and there is no need to have a existing object to call the method on because it is static.
 * 
 * Otherwise the command is interpreted as a named method which is registered in the methodmap,
 * internal data structure which maps strings to callable member functions of the interface object which take in no
 * arguments and return no arguments.  The matlab arguments are passed to these functions through the internal storage of the
 * Mex_Iface object's rhs and lhs member variables.
 *
 * A C++ class is wrapped by creating a new Iface class that inherits from Mex_Iface.  At a minimum
 * the Iface class must define the pure virtual functions objConstruct(), objDestroy(), and getObjectFromHandle().  It also
 * must implement the interface for any of the methods and static methods that are required.  Each of these methods in the
 * Iface class must process the passed matlab arguments in the rhs member variable and save outputs in the lhs member variable.
 *
 * In general the Iface mex modules are not intended to be used directly, but rather are paired with a special Matlab
 * class that inherits from the IfaceMixin.m base class.
 *
 * Design decision:  Because of the complexities of inheriting from a templated base class with regard to name lookups
 * in superclasses, we chose to keep this Mex_Iface class non-templated.  For this reason any methods and member variables which
 * specifically mention the type of the wrapped class must be defined in the subclass of Mex_Iface.
 *
 * Finally we provide many get* and make* which allow the lhs and rhs arguments to be interpreted as armadillo arrays on the C++ side.
 * These methods are part of what makes this interface efficient as we don't need to create new storage and copy data, instead we just use
 * the matlab memory directly, and matlab does all the memory management of parameters passed in and out.
