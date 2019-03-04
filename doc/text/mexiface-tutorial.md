## MexIFace overview

The goal of MexIFace is to build a complete Matlab class with a C++ backend class.  The Matlab and C++ wrapper classes work in tandem to implement constructor and destructor operations as well as normal methods (member functions) and static methods (static member functions).

To wrap an ordinary C++ class, a user creates a Matlab class inheriting from MexIFace.IFaceMixin and a C++  with the desired methods and

a C++ *Interface* class and a Matlab

A matlab object of a MexIFace class appears in matlab like a normal object, but behind the scenes the MexIFace.MexIFaceMixin Matlab base class communicates with the C++ [`mexiface::MexIFaceBase`] class to emulate a full object-like interface.  The C


uses a MEX file as an inttype can maintain state in C++ between calls to the MEX function-based interface.

In this example we aim to wrap the pure C++ class TestArmadillo.  The TestArmadilloIFace class is the C++ side of the
 MexIFace interface.  Separating TestArmadilloIFace from TestArmadillo allows C++ consumers of TestArmadillo to
 be completely independent of the Matlab interface managed by TestArmadilloIFace.

 The mexiface::MexIFace base class contains all of the member functions that are useful in marshaling data
 into and out of member functions.  The checkNumArgs(), getXYZ(), and output() methods, and nrhs, and nlhs member variables
 are all that is needed to pass array and scalar augments back and forth in member functions with variadic inputs and outputs.

 The mexiface::MexIFaceHandler<TestArmadillo> subclass is a templated class that manages the object handle this->obj,
 which is available for use in all non-constructor and non-static mapped methods.  The templated type argument of MexIFaceHandler is
 the specific type mapped by this MexIFace subclass.  There is a 1-1 correspondence between Mapped types and their MexIFace type, although
 a templated MexIFace subclass can be used to instantiate multiple MexIFace interfaces.

 While the TestArmadillo class is a very silly class that just does trivial manipulations with armadillo arrays,
 a simple C++ Armadillo library can be wrapped using mainly the MexIFace methods used as example here.
 And a larger application can wrap arbitrarily complex classes or sets of classes or even C-style or Fortran
 interfaces if their behavior can be wrapped in a pure C++ class, which can then be wrapped by MexIFace.

 Note that in each MEX module there will be a single global instance of the IFace class type.  This interface
 should be called directly by the single mexFunction() allowed by matlab.  This single global IFace manages
 all calls to all objects of the wrapped type.  In terms of this class that means there is a single global TestArmadilloIFace,
 that manages creation, method calls and deletion for multiple ArmadilloIFace objects.
