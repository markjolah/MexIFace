/** @file TestArmadilloIFace.cpp
 *  @author Mark J. Olah (mjo\@cs.unm.edu)
 *  @date 2018-2019
 */

#include <functional>
#include "TestArmadillo.h"
#include "MexIFace/MexIFace.h"

/**
 * In this example we aim to wrap the pure C++ class TestArmadillo.  The TestArmadilloIFace class is the C++ side of the
 * MexIFace interface.  Separating TestArmadilloIFace from TestArmadillo allows C++ consumers of TestArmadillo to
 * be completely independent of the Matlab interface managed by TestArmadilloIFace.
 *
 * The mexiface::MexIFace base class contains all of the member functions that are useful in marshaling data
 * into and out of member functions.  The checkNumArgs(), getXYZ(), and output() methods, and nrhs, and nlhs member variables
 * are all that are needed to pass array and scalar augments back and forth in member functions with variadic inputs and outputs.
 *
 * The mexiface::MexIFaceHandler<TestArmadillo> subclass is a templated class that manages the object handle this->obj,
 * which is available for use in all non-constructor and non-static mapped methods.  The templated type argument of MexIFaceHandler is
 * the specific type mapped by this MexIFace subclass.  There is a 1-1 correspondence between Mapped types and their MexIFace type, although
 * a templated MexIFace subclass can be used to instantiate multiple MexIFace interfaces.
 *
 * While the TestArmadillo class is a very silly class that just does trivial manipulations with armadillo arrays,
 * a simple C++ Armadillo library can be wrapped using mainly the MexIFace methods used as example here.
 * And a larger application can wrap arbitrarily complex classes or sets of classes or even C-style or Fortran
 * interfaces if their behavior can be wrapped in a pure C++ class, which can then be wrapped by MexIFace.
 *
 * Note that in each MEX module there will be a single global instance of the IFace class type.  This interface
 * should be called directly by the single mexFunction() allowed by matlab.  This single global IFace manages
 * all calls to all objects of the wrapped type.  In terms of this class that means there is a single global TestArmadilloIFace,
 * that manages creation, method calls and deletion for multiple ArmadilloIFace objects.
 */
class TestArmadilloIFace : public mexiface::MexIFace, public mexiface::MexIFaceHandler<TestArmadillo>
{
public:
    TestArmadilloIFace(); /* Do method map and global setup. */
private:
    void objConstruct(); /* Create a new TestArmadillo C++ object */
    void objAdd();
    void objRet();
    void objInc();
    void objEchoArray();
    /* static methods */
    void staticVecSum();
};

TestArmadilloIFace::TestArmadilloIFace()
{
    /* The constructor of a MexIFace object must initialize the method maps for normal and static methods.
     *
     * The names given in the map will correspond to the name used in the MexIFaceMixin.call(name,...) method.
     * Each method is implemented by a member function of the IFace class, this allows the use of the MexIFace
     * member functions which give access to the function left-hand and right-hand arguments and methods for
     * accessing the Matlab objects as C++ and Armadillo objects and subsequently returning C++ objects as Matlab
     * objects.
     *
     * To accomplish this we use std::bind, with the member function pointer and the 'this' pointer, which will
     * return required std::function<void()> type.
     */
    methodmap["add"] = std::bind(&TestArmadilloIFace::objAdd, this);
    methodmap["inc"] = std::bind(&TestArmadilloIFace::objInc, this);
    methodmap["ret"] = std::bind(&TestArmadilloIFace::objRet, this);
    methodmap["echoArray"] = std::bind(&TestArmadilloIFace::objEchoArray, this);
    staticmethodmap["vecSum"] = std::bind(&TestArmadilloIFace::staticVecSum, this);
}

/* Constuctor.  This mapped method is called by Matlab when a new object
 * of the MexIFace type is to be constructed.  Arguments are passed.  A new object of the type
 * passed as the MexIFaceHandler
 *
 */
void TestArmadilloIFace::objConstruct()
{
    checkNumArgs(1,1); //(#out, #in)
    TestArmadillo::VecT v = getVec();
    outputHandle(new TestArmadillo(v));
}

void TestArmadilloIFace::objInc()
{
    checkNumArgs(0,1); //(#out, #in)
    obj->inc(getVec());
}

void TestArmadilloIFace::objRet()
{
    checkNumArgs(1,0); //(#out, #in)
    output(obj->ret());
}

void TestArmadilloIFace::objAdd()
{
    checkNumArgs(1,1); //(#out, #in)
    output(obj->add(getVec())); // 1-liner
}

void TestArmadilloIFace::objEchoArray()
{
    checkNumArgs(0,1); //(#out, #in)
    auto arr = getStringArray();
    std::cout<<"Got Array of strings.\n";
    for(arma::uword n=0;n<arr.size();n++) std::cout<<"["<<n<<"]: "<<arr[n]<<std::endl;
}

/* Static methods of the Matlab IFace class are mapped to non-static methods of the C++ IFace class,
 * as they still need access to the variable input and output methods of MexIFace.  The static nature
 * comes into play in that they cannot use this->obj, which will be null.
 */
void TestArmadilloIFace::staticVecSum()
{
    checkNumArgs(1,2); //(#out, #in)
    auto a=getVec();
    auto b=getVec();
    output((a+b).eval());
}

/* Each source code file that is to generate a MEX dynamic library file must contain two items.
 * 1. A global variable of "IFace" type to be used in every call to the mexFunction from matlab
 * 2. A function void mexFunction(int nlhs, mxArray *lhs[], int nrhs, const mxArray *rhs[]),
 *    which should do nothing other than pass its arguments to iface.mexFunction().
 * These items intercept the mexFunction call and propagate it through the MexIFace wrapper system.
 */
TestArmadilloIFace iface; /**< Global iface object provides a iface.mexFunction */

void mexFunction(int nlhs, mxArray *lhs[], int nrhs, const mxArray *rhs[])
{
    iface.mexFunction(nlhs, lhs, nrhs, rhs);
}
