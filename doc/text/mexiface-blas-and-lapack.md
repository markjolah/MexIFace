# MexIFace BLAS and LAPACK 64-bit Integer Setup
<!-- Optimized for Doxygen Markdown support. -->

[TOC]

Matlab includes internal BLAS and LAPACK libraries (`libmwblas`, `libmwlapack`, and the [intel MKL](https://software.intel.com/en-us/mkl)) that are compiled with 64-bit integer indexing, making them incompatible with the more common 32-bit integer indexed BLAS and LAPACK libraries.

Technically, it is possible to build a library that links directly to Matlab's internal `libmwblas` and `libmwlapack` libraries without a system-provided 64-bit BLAS or LAPACK, however such a library would not be usable outside of Matlab by other C++ applications or executables, including those necessary to test the library.

Building a dual-use C++ library that will link against Matlab MEX modules requires a development environment with 64-bit integer ABI versions of BLAS and LAPACK libraries.

# BLAS and LAPACK CMake Find Modules

The MexIFace CMake build system uses customized BLAS and LAPACK find modules from the [UncommonCMakeModules](https://github.com/markjolah/UncommonCMakeModules) package.
 * [`FindArmadillo.cmake`](https://github.com/markjolah/UncommonCMakeModules/blob/master/FindArmadillo.cmake)
 * [`FindBLAS.cmake`](https://github.com/markjolah/UncommonCMakeModules/blob/master/FindBLAS.cmake)
 * [`FindLAPACK.cmake`](https://github.com/markjolah/UncommonCMakeModules/blob/master/FindLAPACK.cmake)
    * [`MakePkgConfigTarget.cmake`](https://github.com/markjolah/UncommonCMakeModules/blob/master/MakePkgConfigTarget.cmake)

These modules accept a `BLAS_INT64` COMPONENT argument to [`find_package()`](https://cmake.org/cmake/help/latest/command/find_package.html),  which enables detection of both 32-bit and 64-bit CMake imported interface targets:
 * 32-bit Integer ABI targets
    * `Blas::Blas`
    * `Lapack::Lapack`
 * 64-bit Integer ABI targets
    * `Blas::BlasInt64`
    * `Lapack::LapackInt64`

By using an `OPT_BLAS_INT64` CMake option to switch between these different target names, it is possible to easily build either 32-bit and 64-bit integer ABI versions of a C++ library.  Any Matlab modules must link against the 64-bit ABI version. The [MexIFace-Example](https://github.com/markjolah/MexIFace-Example) project demonstrates this approach.

## pkg-config files

The `FindBLAS.cmake` and `FindLAPACK.cmake` modules use [`pkg-config`](https://people.freedesktop.org/~dbn/pkg-config-guide.html) files to locate the 32-bit and 64-bit versions of BLAS, CBLAS, and LAPACK.

 * 32-bit Integer ABI targets
    *  `blas.pc` or `openblas.pc`
    *  `lapack.pc`
 * 64-bit Integer ABI targets
    *  `blas-int64.pc` or `openblas-int64.pc`
    *  `lapack-int64.pc`

Normally these files are at `/usr/lib/pkgconfig`, but they can be anywhere on `PKG_CONFIG_PATH`.  If your system does not provide 64-bit versions use one of the [example pkg-config setups](#example-pkg-config-setups).

# Installing BLAS and LAPACK with 64-bit integer support

## Gentoo

The [Gentoo science overlay](https://github.com/gentoo/sci) provides the ability to simultaneously install multiple BLAS and LAPACK packages and variants on those packages using different integer size and threading options.  Each variant will have distinct shared and static library names and corresponding `pkg-config` files which describe how to link against them.

1. Use [layman](https://wiki.gentoo.org/wiki/Layman) to add the science overlay,
~~~
layman -a science
~~~
2. Follow the [science overlay README](https://github.com/gentoo/sci#blas-and-lapack-migration) migration directions.  This is necessary to update the `eselect` configuration tool to be aware of the different BLAS and LAPACK variants.

3. Modify`/etc/portage/package.use`  to enable the `int64` use flag for relevent BLAS and LAPACK packages which builds 64-bit integer ABI versions alongside the normal 32-bit versions.
~~~
sci-libs/blas-reference int64
sci-libs/lapack-reference int64
~~~
4. Emerge or re-emerge the reference packages
~~~
emerge blas-reference  lapack-reference
~~~
5. Use `eselect` to check the status of the system default packages.
~~~
eselect blas list
eselect blas-int64 list
eselect lapack list
eselect lapack-int64 list
~~~

This basic setup is sufficient for simple projects.  For BLAS and LAPACK critical workloads however, other implementations with superior performance exist.
* `sci-libs/gotoblas2` [BLAS] (Available USE flags: `int64`, `openmp`, `threads`)
* `sci-libs/openblas` [BLAS] (Available USE flags: `int64`, `openmp`, `threads`)
* `sci-libs/gsl` [CBLAS]
* `sci-libs/mkl` [BLAS/CBLAS/LAPACK] (Available USE flags: `int64`)

Notes:
 * After using `eselect` to change `blas` or `blas-int64`, LAPACK libraries will require rebuilding for the change in BLAS dependencies to become transitive.

## Debian/Ubuntu
Debian and Ubuntu variants only have 32-bit integer BLAS and LAPACK packages available as the packages [`libblas-dev`](https://packages.ubuntu.com/search?suite=all&keywords=libblas-dev) and [`liblapack-dev`](https://packages.ubuntu.com/search?suite=all&keywords=liblapack-dev).

 * [DebianScience Lapack/Blas libraries](https://wiki.debian.org/DebianScience/LinearAlgebraLibraries) has 64-bit MKL packages links but these are *non-free*.

## Building manually

Building the reference BLAS and LAPACK with 64-bit integer support is not difficult if there is no easier way to get the libraries for your distribution:
1. Use the latest [lapack-release](https://github.com/Reference-LAPACK/lapack-release) from github
2. Set the gfortran `-fdefault-int-8` to force 64-bit integer support.
3. create proper pkg-config files at `/usr/lib/pkgconfig/blas-int64.pc` and `/usr/lib/pkgconfig/lpack-int64.pc`.

Example Ubuntu/TravisCI scripts are available in the  [ci-numerical-dependencies](https://github.com/markjolah/ci-numerical-dependencies) git subrepo.
* [install-blas-lapack.sh](https://github.com/markjolah/ci-numerical-dependencies/blob/master/install-blas-lapack.sh) - Set environment variable `BLAS_INT64=1`
* [install-armadillo.sh](https://github.com/markjolah/ci-numerical-dependencies/blob/master/install-armadillo.sh) - Installs more recent [armadillo](https://gitlab.com/conradsnicta/armadillo-code) for optimal use of BLAS/LAPACK operations.


<a name="example-pkg-config-setups"></a>
# Example pkg config setups
Each system may name the BLAS/LAPACK libraries differently, especially in the case of multiple packages and multiple ABI variants (int64, threads, OpenMP, etc. ).  At a minimum MexIFace requires that proper `blas-int64.pc` and `lapack-int64.pc` configuration files exist on the `PKG_CONFIG_PATH`.
## Reference BLAS/LAPACK int64 pkg-config
The simplest  64-bit Integer ABI setup uses the [reference BLAS/LAPACK](http://www.netlib.org/lapack/).  The following example MexIFace-compatible pkg-config setup can be modified as required.

### Libraries
* `/usr/lib/librefblas_int64.so`
* `/usr/lib/libreflapack_int64.so`

### pkg-config outputs

~~~
$ pkg-config --libs --cflags --static lapack-int64
-lreflapack_int64 -lrefblas_int64
$ pkg-config --libs --cflags blas-int64
-lrefblas_int64
~~~

### pkg-config files

#### `/usr/lib/pkgconfig/blas-int64.pc`

~~~
libdir=/usr/lib64
includedir=/usr/include

Name: BLAS-int64
Version: 3.8.0
Libs: -L${libdir} -lrefblas_int64
~~~

#### `/usr/lib/pkgconfig/lapack-int64.pc`

~~~
libdir=/usr/lib64
includedir=/usr/include

Name: LAPACK-int64
Version: 3.8.0
Libs: -L${libdir} -lreflapack_int64
Requires.private: blas-int64
~~~



## OpenBlas / Reference LAPACK int64 pkg-config
For some BLAS and LAPACK workloads better performance can be achieved with the [OpenBLAS](https://www.openblas.net/) package.  A MexIFace-compatible reference setup is:

On an openblas/reference-lapack system the following output will be functional:

### Libraries
* `/usr/lib/libopenblas_int64.so`
* `/usr/lib/libreflapack_int64.so`

### pkg-config outputs

    $ pkg-config --libs --cflags --static blas-int64
    -DARCH_X86_64=1 -DOPENBLAS___64BIT__=1 -DOPENBLAS_USE64BITINT -I/usr/include/openblas -lopenblas_int64 -lm
    $ pkg-config --libs --cflags --static lapack-int64
    -DOPENBLAS___64BIT__=1 -DOPENBLAS_USE64BITINT -I/usr/include/openblas -lreflapack_int64 -lopenblas_int64 -lm

### pkg-config files

#### `/usr/lib/pkgconfig/blas-int64.pc`

~~~
libdir="/usr/lib64"
includedir="/usr/include"

Name: openblas-int64
Version: 0.2.20
Libs: -L${libdir} -lopenblas_int64
Libs.private: -lm
Cflags: -I${includedir} -I${includedir}/openblas -DARCH_X86_64=1 -DOPENBLAS___64BIT__=1 -DOPENBLAS_USE64BITINT
~~~

#### `/usr/lib/pkgconfig/lapack-int64.pc`

~~~
libdir=/usr/lib64
includedir=/usr/include

Name: LAPACK-int64
Version: 3.8.0
Libs: -L${libdir} -lreflapack_int64
Requires.private: blas-int64
~~~
