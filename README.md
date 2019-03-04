
<a href="https://travis-ci.org/markjolah/MexIFace"><img src="https://travis-ci.org/markjolah/MexIFace.svg?branch=master"/></a>
# MexIFace
A C++/Matlab object-based interface library and cross-platform CMake build system for creating interactive Matlab MEX modules with persistent state and complex behavior.


## About
<img align="right" width="450px" alt="MexIFace diagram" src="http://raw.github.com/markjolah/MexIFace/master/doc/images/mexiface_diagram.png">

The [`MexIFace`](https://markjolah.github.io/MexIFace/classmexiface_1_1MexIFace.html) class provides a flexible means of wrapping a complex C++ library into a Matlab class via Matlab's [MEX function](https://www.mathworks.com/help/matlab/call-mex-files-1.html) extension method.  A standard Matlab MEX module implements a single function API, with no obvious way to manage shared state across one or more interacting MEX components.  A MexIFace generated MEX module is wrapped in a regular [Matlab handle class](https://www.mathworks.com/help/matlab/handle-classes.html) interface with normal Matlab properties and methods.  MexIFace Matlab objects have associated C++ state that is persistent across method calls into the MEX module.

Instead of the procedural workflow implied by the static `mexFunction()` interface, a MexIFace wrapped class can be used interactively.  Multiple objects of the wrapped type can be created and accessed independently using the same MEX module.  Each instantiated object has its own persistent state; and when Matlab garbage collects a MexIFace object, it's C++ resources are freed as well.

### Other important features:
* A MexIFace wrapper can be created for any C++ class(es) without requiring any changes to the C++ library itself.
* MexIFace provides transparent (i.e., no-copy) access to Matlab [`mxArray`](https://www.mathworks.com/help/matlab/apiref/mxarray.html) objects as C++ [Armadillo](http://arma.sourceforge.net/) objects.  This makes it possible to directly share multidimensional array data.  (see: [Armadillo and mxArrays](#armadillo-and-mxArrays))
* The CMake build system manages correctly linking to the 64-bit integer BLAS and LAPACK libraries required by Matlab, and enables the armadillo BLAS and LAPACK integration. (See: [BLAS and LAPACK](#blas-and-lapack))
* Parallelization for C++ code can easily be implemented with [OpenMP](https://www.openmp.org/specifications/).
* Supports for C++11/14/17 is possible depending on the Matlab release targeted (see: [Matlab and MEX linking](#matlab-and-mex-linking))
* The MexIFace CMake build system can cross-compile from Linux hosts to target Matlab Linux (`glnxa64`) and Windows (`win64`) environments
    * See: [Cross-compiling to Linux Targets](#cross-compiling-to-linux-targets)
    * See: [Cross-compiling to Windows Targets](#cross-compiling-to-windows-targets)



### Quick Start
  * [MexIFace-ArmadilloExample](https://github.com/markjolah/MexIFace-ArmadilloExample) - A fully functional MexIFace module that demonstrates the MexIFace C++ and Matlab interfaces, as well as the suggested CMake build environment, and github repository layout.

## Documentation
The MexIFace Doxygen documentation can be build with the `OPT_DOC` CMake option and is also available online:
  * [MexIFace HTML Manual](https://markjolah.github.io/MexIFace/index.html)
  * [MexIFace PDF Manual](https://markjolah.github.io/MexIFace/doc/MexIFace-0.2-reference.pdf)
  * [MexIFace github repository](https://github.com/markjolah/MexIFace)


## Motivation

Matlab uses compiled plugins called MEX files to enable linking and running C and C++ code.  A MEX file is a shared object file (ELF on Linux and DLL on Windows) that is dynamically loaded by the Matlab binary when the function it names is called.  Each MEX file presents to Matlab an interface consisting of exactly one function with variable input and output arguments.
~~~Matlab
function varargout = mexFunction(varargin)
~~~
Separate MEX functions have no direct way to communicate with this API, and as C and C++ libraries become more complex this isolated, static function interface becomes increasingly restrictive.

Complex simulations an analysis libraries have more demanding requirements; they must:
 * manage persistent state
 * provide multiple functions that interact with that state
 * require coordination with Matlab to manage shared data(memory)
 * require initialization at load time
 * require cleanup when their data is no longer needed
 * may require the creation of multiple independent realizations with independent state

In other words, **complex libraries are much more like objects than functions**.  An object-oriented MEX file interface provides an easier, safer, faster, and more organized way of interacting with complex C++ libraries from Matlab.

### Armadillo and mxArrays

MexIFace uses the [Armadillo](http://arma.sourceforge.net/docs.html) package to provide an efficient and powerful C++ interface to Matlab array types.  Passing and returning large array data between C++ and Matlab can be very inefficient if data needs to be copied repeatedly.  The Armadillo [auxillary-memory constructors](http://arma.sourceforge.net/docs.html#Mat) allow C++ Armadillo arrays to transparently manipulate Matlab `mxArray` raw data, as both use [column-major](https://en.wikipedia.org/wiki/Row-_and_column-major_order) layouts.

This allows the same memory allocated by Matlab to be used in C++ with very little overhead incurred when passing large array arguments.  Return arguments can also be allocated from C++ into Matlab managed memory using Matlab's `mxArray` API, then mapped directly to an Armadillo C++ array used as output.

The mexiface::MexIFace class implements templated methods to succinctly convert data views between `mxArray` and armadillo array data types,
~~~.cpp
mxArray *matlab_vec, *matlab_mat, *matlab_cube;
...
//Interpreting matlab arrays as armadillo arrays
arma::vec cxx_vec = getVec(matlab_vec);
arma::mat cxx_mat = getMat(matlab_mat);
arma::cube cxx_cube = getCube(matlab_cube);

//Writing armadillo arrays to new matlab mxArrays
mxArray *out_vec = toMXArray(cxx_vec)
mxArray *out_mat = toMXArray(cxx_mat)
mxArray *out_cube = toMXArray(cxx_cube)

//Creating an output matlab array buffer to write into
//Each armadillo array points to matlab mxArray memory
arma::vec buf_vec = makeOutputArray(nelem);
arma::mat buf_mat = makeOutputArray(nrows,ncols);
arma::cube buf_cube = makeOutputArray(nrows,ncols,nslices);

~~~

# Building and Installing
 MexIFace uses the `MATLAB_ROOT` and `MATLAB_ROOTS` environment variables to find Matlab installations.  For each Matlab release found, the build system creates a CMake`MexIFace::MexIFaceX_Y` target corresponding to a `libMexIFaceX_Y.so` library, where `X_Y` is the numerical release code for each Matlab as returned by Matlab `version` command.  Each Matlab release has potentially incompatible dependency and linking requirements, so a MexIFace library must be produced for each Matlab release that will be targeted.

## Quick scripts
* First, set `MATLAB_ROOTS` environment variable to list (';' or ':' separated) of matlab root directories or a folder containing them.

~~~.sh
export MATLAB_ROOTS=/opt/matlab:$HOME/opt/matlab:...
~~~

**Native Linux build**
~~~.sh
./scripts/build.sh
export MATLABPATH=$(pwd)/_install/lib/MexIFace/matlab:$MATLABPATH
~~~

**Matlab `glnxa64 R2016b+:`** Linux `gcc-4.9.4` environment cross-compile.
~~~.sh
export X86_64_GCC4_9_LINUX_GNU_ROOT=...
./scripts/build.gcc4_9.sh
export MATLABPATH=$(pwd)/_gcc4_9.install/lib/MexIFace/matlab:$MATLABPATH
~~~

**Matlab `glnxa64 R2018a+:`** Linux `gcc-6.5.0` environment cross-compile.
~~~.sh
export X86_64_GCC6_5_LINUX_GNU_ROOT=...
./scripts/build.gcc6_5.sh
export MATLABPATH=$(pwd)/_gcc6_5.install/lib/MexIFace/matlab:$MATLABPATH
~~~

**Matlab `win64 R2016b+:`** Windows MXE-MexIFace `mingw-w64`/`gcc-4.9.4` environment cross-compile
~~~.sh
export MXE_ROOT=...
./scripts/build.wim64.sh
export MATLABPATH=$(pwd)/_win64.install/lib/MexIFace/matlab:$MATLABPATH
~~~

**Run Matlab unit tests on command line**
~~~.sh
matlab -nodesktop -r "startupMexIFace();run(MexIFace.Test.TestMexIFace)"
~~~

**Setup MexIFace paths from inside matlab**
~~~.matlab
cd('install_dir/lib/MexIFace/matlab')
startupMexIFace()
results = run(MexIFace.Test.TestMexIFace)
~~~


<!--MexIFace is designed to build from Linux to either Linux `glnxa64` or Windows `win64` Matlab environments.  The build system hides most of the details involved in the MEX building and linking process.-->
## Core Dependencies

 * [Matlab](https://www.mathworks.com/) - Set environment variables `MATLAB_ROOT` or `MATLAB_ROOTS` to any directory containing Matlab roots.  A MexIFace library will be created for each supported release root found.

 * BLAS and LAPACK 64-bit Integer ABI
 * [*Armadillo*](http://arma.sourceforge.net/docs.html) - A high-performance array library for C++.

## Matlab and GCC Compatibility

In order to build for a particular Matlab target environment, the development machine must have system libraries and all relevant dependencies built with the correct version of GCC.

 * [Matlab and MEX linking](doc/text/matlab-mex-linking.md) - More than you wanted to know about Matlab and MEX linking.

For C++, the most important restriction involves [`libsdtc++` versioning](https://gcc.gnu.org/onlinedocs/libstdc++/manual/abi.html), which prevents the use of a GCC with a `CXXABI` version newer than that used by the Matlab release targeted.  Currently the following GCC versions are supported for use with MexIFace.

| GCC Version | Compatible Matlab Releases |
--------------|----------------------------|
| gcc-4.9.4   | R2016b+ |
| gcc-6.5.0   | R2018a+ |

 * MexIFace requires C++11 so releases prior to R2016b are not supported, as they require `gcc<=4.7` which has an incomplete C++11 implementation.
 * Compatibility for cross-compiling with `mingw-w64` for Windows targets is subject to the same GCC version restrictions.

## BLAS and LAPACK
The [BLAS](https://en.wikipedia.org/wiki/Basic_Linear_Algebra_Subprograms) and [LAPACK](https://en.wikipedia.org/wiki/LAPACK) libraries are common numerical dependencies.  Matlab includes internal BLAS and LAPACK libraries that used 64-bit integers for array indexing.  Many commonly available BLAS and LAPACK implementations instead use an incompatible 32-bit integer ABI.  To make dual-use C++ and Matlab libraries it necessary to have system versions of the 64-bit BLAS and LAPACK.

* [MexIFace BLAS and LAPACK 64-bit Integer Setup](doc/text/mexiface-blas-and-lapack.md)


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

### Other Dependencies
 * Documentation building with `OPT_DOC`
    * [*Doxygen*](https://github.com/google/googletest)
    * [*graphviz*](https://www.graphviz.org/)
    * [*LaTeX*](https://www.latex-project.org/get/) - Required to generate pdf documenation (`make pdf`)
 * gentoo:

#### Git subrepo modules
These dependencies are included via the [`git subrepo`](https://github.com/ingydotnet/git-subrepo) mechanism, unlike `git submodule` there is not need to fetch subrepos in a seperate step after cloning.

  * [UncommonCMakeModules](https://github.com/markjolah/BacktraceException) - Modules for package export automation, as well as toolchain files for Matlab cross-compile builds.
  * [ci-numerical-dependencies](https://github.com/markjolah/ci-numerical-dependencies) - Scripts for installing Armadillo, BLAS and LAPACK with 64-bit integer support on TravisCI or Ubuntu/Debian systems.

#### External Projects
These packages are specialized CMake projects.  If they are not currently installed on the development machines we use the [AddExternalDependency.cmake](https://github.com/markjolah/UncommonCMakeModules/blob/master/AddExternalDependency.cmake) module which will automatically download, configure, build and install the CMake-based dependency to the `CMAKE_INSTALL_PREFIX`.  The dependency can then be found through the normal CMake `find_package()` system.

* [BacktraceException](https://github.com/markjolah/BacktraceException) - An library that allows Debug builds to get a stack backtrace when an exception derived from [`BacktraceException`]() is called. MexIFace translates `BacktraceException` exceptions into calls to Matlab's `mexErrMsgIdAndTxt` mechanism allowing very useful debugging output for tracing down errant exceptions.  Often this provides enough information to isolate bugs without attaching a debugger to the Matlab process.

#### Getting a linkable Matlab stub environment

  Because Matlab is closed-source we cannot provide the actual Matlab libraries necessary to link the MexIFace library.
  If you do have one or more valid releases of Matlab, and you would like to build or test build in an environment with no valid Matlab license, you can use what we call a linkable-stub Matlab environment.  The result is archives `matlab_stub-ARCH-VERS.tar.bz2` for each find-able <atlab root under the given search paths:

    > ./scripts/create-matlab-linker-stub.py --outdir <outdir> <matlab_root_search_paths...>

## LICENSE

* Copyright: 2013-2019
* Author: Mark J. Olah
* Email: (mjo@cs.unm DOT edu)
* LICENSE: Apache 2.0.  See [LICENSE](https://github.com/markjolah/MexIFace/blob/master/LICENSE) file.
