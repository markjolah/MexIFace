## Matlab and MEX linking

Each matlab release  contains within it an entire set of compiled open-source libraries and binaries for each of the platforms it supports: Linux, OSX, and Win64.

|Directory    | Files |
|-------------|-------|
|/bin/        |      |
|/bin/<arch>/ | Executables and shared |

It uses the various mechanisms available on those platforms to attempt to force dynamically loaded MEX modules to use those built-in libraries to varying degrees of success.  For simple libraries that rely mainly on the Matlab C API, correctly linking a
MEX module is relatively straightforward, and there is even a built-in Matlab command [`mex`](https://www.mathworks.com/help/matlab/ref/mex.html) that wraps calls to GCC.

However, complex applications with external dependencies run into several problems


### Linux: RPATH and dynamic library dependency resolution

On Linux, MEX modules have `.mexa64` suffixes, but they are nothing more than renamed shared library (.so) files in the ELF format.
When the MEX function is called, the main Matlab executable `$MATLAB_ROOT/bin/glnxa64/MATLAB` uses the [`dlopen()`](http://man7.org/linux/man-pages/man3/dlopen.3.html) function to dynamically load the MEX file and looks for a symbol with the name `mexFunction` to call.  Basically any shared library with a `mexFunction` symbol and the right file extension could potentially work as a Matlab MEX module, but that's the easy part.

The difficulties begin as soon as a MEX module has it's own shared library dependencies.

The Linux dynamic library loading dependency resolution procedure depends on the executable making the `dlopen` calls.  In this case, `readelf -d  bin/glnxa64/MATLAB` has the following relevant lines:
```diff
...
 0x0000000000000001 (NEEDED)             Shared library: [libmwi18n.so]
 0x0000000000000001 (NEEDED)             Shared library: [libmwmvm.so]
 0x0000000000000001 (NEEDED)             Shared library: [libmwservices.so]
 0x0000000000000001 (NEEDED)             Shared library: [libmwboost_system.so.1.65.1]
 0x0000000000000001 (NEEDED)             Shared library: [libmwcpp11compat.so]
 0x0000000000000001 (NEEDED)             Shared library: [libpthread.so.0]
 0x0000000000000001 (NEEDED)             Shared library: [libstdc++.so.6]
 0x0000000000000001 (NEEDED)             Shared library: [libgcc_s.so.1]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
 0x000000000000000f (RPATH)              Library rpath: [$ORIGIN:$ORIGIN/../../sys/os/glnxa64]
...
```
The last line indicated that the `MATLAB` executable sets the `DT_RPATH` attribute for the runtime path.  This has important implications for MEX librararies as unlike the similar `DT_RUNPATH` attribute, the `DT_RPATH` has a recursive effect on the dependency resolution order.  This is not at all clear from the [dlopen() man page](http://man7.org/linux/man-pages/man3/dlopen), which

On Linux when a library is dynamically loaded the following proceedure is followed:
* If the executable calling program (Matlab)

On Linux the matlab executable is `$MATLAB_ROOT/bin/glnxa64/MATLAB`.

Unless loading object has RUNPATH:
  RPATH of the loading object,
    then the RPATH of its loader (unless it has a RUNPATH), ...,
    until the end of the chain, which is either the executable
    or an object loaded by dlopen
  Unless executable has RUNPATH:
    RPATH of the executable
LD_LIBRARY_PATH
RUNPATH of the loading object
ld.so.cache
default dirs


![Dependency tree and RPATHs](/doc/images/mexiface-dep-search.png)
![Dependency tree and RPATHs](/doc/images/mexiface-dep-structure.png)

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

