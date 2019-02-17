

# MexIFace <a href="https://travis-ci.org/markjolah/MexIFace"><img src="https://travis-ci.org/markjolah/MexIFace.svg?branch=master"/></a>
A cross-platform C++ / Matlab object-based MEX interface wrapper and CMake build tool.

* Copyright: 2013-2019
* Author: Mark J. Olah
* Email: (mjo@cs.unm DOT edu)
* LICENSE: Apache 2.0.  See [LICENSE](LICENSE) file.

## About

The [`MexIFace`](https://markjolah.github.io/MexIFace/classmexiface_1_1MexIFace.html) class provides a flexible means of wrapping a complex C++ library into a Matlab class via Matlab's MEX function extension method.

The MexIFace class is designed to cross-compile from Linux to target Matlab versions R2016b and newer on Linux 64-bit (Matlab *glnxa64*) and Windows 64-bit (Matlab *win64*) platforms.  Details on setting up a compatible cross-compilation environment are in Build Environment Configuration.

The MexIFace package integrates easily with CMake based packages.

For the impatient,
  * [MexIFace-ArmadilloExample](https://github.com/markjolah/MexIFace-ArmadilloExample) repository is a fully functional MexIFace module that demonstrates the MexIFace C++ and Matlab interfaces, as well as the suggested CMake build environment.

## Documentation
The MexIFace Doxygen documentation can be build with the `OPT_DOC` CMake option and is also available on online:
  * [MexIFace HTML Manual](https://markjolah.github.io/MexIFace/index.html)
  * [MexIFace PDF Manual](https://markjolah.github.io/MexIFace/pdf/MexIFace-0.2-reference.pdf)
  * [MexIFace github repository](https://github.com/markjolah/MexIFace)


## Background

Matlab uses compiled plugins called MEX files to enable linking and running compiled C and C++ code.  Each MEX file is a separate shared object file (ELF/DLL) that is dynamically loaded by the Matlab binary when called.  It presents to Matlab an interface consisting of a single function with variadic arguments.

    function varargout = mexFunction(varargin)

As C and C++ libraries and toolsets become more complex this single-function interface becomes restrictive. Complex libraries have both state and behavior, they provide multiple functions that interact with that state, they require initialization on load time and cleanup on unload time, and they require Matlab to manage the memory they must allocate.  In other words, complex libraries are much more like objects then functions, so an object-oriented MEX file interface provides an easier, safer, faster, and more organized way of interacting with complex C++ libraries from Matlab.

## MexIFace overview

The goal of MexIFace is to build a complete Matlab class with a C++ backend class.  The Matlab and C++ wrapper classes work in tandem to implement constructor and destructor operations as well as normal methods (member functions) and static methods (static member functions).


### Armadillo Integration

The design of MexIFace is oriented primarily to high-performance parallel numerical algorithms.  Typically such applications have constructors and methods that take in and return very large Matlab [`mxArray`](https://www.mathworks.com/help/matlab/apiref/mxarray.html) data types.  MexIFace uses the [Armadillo](http://arma.sourceforge.net/docs.html) package provide an efficient and powerful C++ interface to Matlab array types.  This allows the same memory allocated by Matlab to be used in C++ with very little function call overhead for large array arguments.  Additionally, return arguments can be allocated in C++ using Matlab's `mxArray` API and their allocated memory can be mapped directly to an Armadillo C++ array, so that C++ methods can write their output directly into the returned memory.  This effectively halves the memory requirements of calling C++ methods while allowing easy access to the extensive set of linear algebra and scientific computing commands provided by Armadillo

## Matlab and MEX linking

MexIFace is tightly bound to Matlab, which unfortunately is closed-source not free.  Matlab contains within it
an entire set of open-source libraries and binaries for each of the platforms it supports: Linux, OSX, and Win64.  It uses the various mechanisms available on those platforms to attempt to force dynamically loaded MEX modules to use those built-in libraries to varying degrees of success.  For simple libraries that rely mainly on the Matlab C API, correctly linking a
MEX module is relatively straightforward, and there is even a built-in Matlab command [`mex`](https://www.mathworks.com/help/matlab/ref/mex.html) that wraps calls to GCC.

However, complex applications with external dependencies run into several problems

### Problem 1: GCC Incompatibilities
The version of GCC cannot be newer than that used by the target Matlab release.  In the case of C++ this restriction arises from the fact that `libstdc++.so` is backwards- but not forwards-compatible, other potential incompatibilities can be found in the [GCC ABI Policy](https://www.mathworks.com/support/requirements/supported-compilers.html).  This means that any MEX module built with GCC with a newer version of `GLIBCXX` or `CXXABI` than those used by Matlab will crash and burn.

This becomes a problem because [Matlab's official GCC version support](https://www.mathworks.com/support/requirements/supported-compilers.html) typically uses GCC versions that are 3-5 years behind the current stable versions used in many Linux distributions.
 * [C++ Standards Support in GCC](https://gcc.gnu.org/projects/cxx-status.html)

Matlab Release|Matlab Ver.|GCC Ver.|GLIBCXX|CXXABI|Compatible GCC|C++11/14/17
--------------|-----------|--------|-------|------|--------------|-----------
R2012b | 8.0 | 4.4.x | 3.4.13 | 1.3.3 | 4.4.7 | Very-Limited C++11
R2013a | 8.1 | 4.4.x | 3.4.13 | 1.3.3 | 4.4.7 | Very-Limited C++11
R2013b | 8.2 | 4.7.x | 3.4.17 | 1.3.3 | 4.7.4 | Limited C++11
R2014a | 8.3 | 4.7.x | 3.4.17 | 1.3.3 | 4.7.4 | Limited C++11
R2014b | 8.4 | 4.7.x | 3.4.17 | 1.3.3 | 4.7.4 | Limited C++11
R2015a | 8.5 | 4.7.x | 3.4.17 | 1.3.3 | 4.7.4 | Limited C++11
R2015b | 8.6 | 4.7.x | 3.4.17 | 1.3.3 | 4.7.4 | Limited C++11
R2016a | 9.0 | 4.7.x | 3.4.17 | 1.3.3 | 4.7.4 | Limited C++11
R2016b | 9.1 | 4.9.x | 3.4.20 | 1.3.8 | 4.9.4 | Full C++11 Limited C++14
R2017a | 9.2 | 4.9.x | 3.4.20 | 1.3.8 | 4.9.4 | Full C++11 Limited C++14
R2017b | 9.3 | 4.9.x | 3.4.20 | 1.3.8 | 4.9.4 | Full C++11 Limited C++14
R2018a | 9.4 | 6.3.x | 3.4.22 | 1.3.10 | 6.5.0 | Full C++14 Limited C++17
R2018b | 9.5 | 6.3.x | 3.4.22 | 1.3.10 | 6.5.0 | Full C++14 Limited C++17
R2019a | 9.6 | 6.3.x | 3.4.22 | 1.3.10 | 6.5.0 | Full C++14 Limited C++17


## Setup

### CMake general Variables and Options

 * `OPT_MexIFace_MATLAB_INTERLEAVED_COMPLEX` - Enable interleaved complex API in R2018a+.
 * `OPT_MexIFace_MATLAB_LARGE_ARRAY_DIMS` - Enable 64-bit array indexes in R2017a+.  If *BLAS* or *LAPACK* are used this needs to be on, as Matlab uses 64-bit indexes.
 * `OPT_MexIFace_INSTALL_DISTRIBUTION_STARTUP`- Install an additional copy of startupPackage.m at the `INSTALL_PREFIX` root in addition to the normal directory.  This makes it easy to distribute as a binary archive file (.zip, .tar.gz, etc.).
 * `OPT_MexIFace_PROFILE` - Built-in [gperftools](https://github.com/gperftools/gperftools) profiling `ProfileStart()`/`ProfileStop()` for every method call to a MexIFace object.
 * `OPT_MexIFace_VERBOSE`  - Verbose output for MexIFace CMake configuration.
 * `OPT_MexIFace_SILENT` - Silent output for MexIFace CMake configuration.  Warnings and errors only.
 * `BUILD_TESTING` - Build testing framework
 * `OPT_DOC` - Build documentation
 * `OPT_INSTALL_TESTING` - Install testing executables
 * `OPT_EXPORT_BUILD_TREE` - Configure the package so it is usable from the build tree.  Useful for development.
 * `OPT_EXTRA_DEBUG` - Support extra noisy debugging features (Armadillo).

## Dependencies
  * [*OpenMP*](https://www.openmp.org/)
  * [*Armadillo*](http://arma.sourceforge.net/docs.html) - A high-performance array library for C++.
 * [*Doxygen*](https://github.com/google/googletest) - Required to generate documentation (`OPT_DOC=On`)
    * *graphviz* - Required to generate documentation (`make doc`)
    * *LAPACK* - Required for generate pdf documenation (`make pdf`)

### Git subrepo modules
These dependencies are included via the [`git subrepo`](https://github.com/ingydotnet/git-subrepo) mechanism, unlike `git submodule` there is not need to fetch subrepos in a seperate step after cloning.

  * [UncommonCMakeModules](https://github.com/markjolah/BacktraceException) - Modules for package export automation, as well as toolchain files for Matlab cross-compile builds.

### External Projects
These packages are specialized CMake projects.  If they are not currently installed on the development machines we use the [AddExternalDependency.cmake](https://github.com/markjolah/UncommonCMakeModules/blob/master/AddExternalDependency.cmake) which will automatically download, configure, build and install to the `CMAKE_INSTALL_PREFIX`, enabling their use through the normal CMake `find_package()` system.

  * [BacktraceException](https://github.com/markjolah/BacktraceException) - An library that allows Debug builds to get a stack backtrace when an exception derived from [`BacktraceException`]() is called.
    * MexIFace translates `BacktraceException` exceptions into calls to Matlab's `mexErrMsgIdAndTxt` mechanism allowing very useful debugging output for tracing down errant exceptions.  Often this provides enough information to isolate bugs without attaching a debugger to the Matlab process.

### Matlab

Because Matlab is closed-source we cannot provide the actual Matlab libraries necessary to link the MexIFace library.

#### Getting a linkable Matlab stub environment

  If you do have one or more valid releases of Matlab, and you would like to build or test build in an environment with no valid Matlab license, you can use what we call a linkable-stub Matlab environment.  The result is archives `matlab_stub-ARCH-VERS.tar.bz2` for each find-able <atlab root under the given search paths:

    > ./scripts/create-matlab-linker-stub.py --outdir <outdir> <matlab_root_search_paths...>





### Cross-compiling From Linux to Matlab's Linux environment

