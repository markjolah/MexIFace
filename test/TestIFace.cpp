/** @file TestIFace.cpp
 * @author Mark J. Olah (mjo\@cs.unm.edu)
 * @date 2018
 */

#include <functional>
#include "TestArmadillo.h"
#include "MexIFace/MexIFace.h"

class TestIFace : public mexiface::MexIFace, public mexiface::MexIFaceHandler<TestArmadillo>
{
public:
    TestIFace();
private:
    void objConstruct();
    void objAdd();
    void objRet();
    void objInc();
    void objEchoArray();
    /* static methods */
    void staticVecSum();
};

TestIFace::TestIFace()
{
    methodmap["add"] = std::bind(&TestIFace::objAdd, this);
    methodmap["inc"] = std::bind(&TestIFace::objInc, this);
    methodmap["ret"] = std::bind(&TestIFace::objRet, this);
    methodmap["echoArray"] = std::bind(&TestIFace::objEchoArray, this);
    staticmethodmap["vecSum"] = std::bind(&TestIFace::staticVecSum, this);
}

void TestIFace::objConstruct()
{
    checkNumArgs(1,1); //(#out, #in)
    TestArmadillo::VecT v = getVec();
    outputHandle(new TestArmadillo(v));
}

void TestIFace::objInc()
{
    checkNumArgs(0,1); //(#out, #in)
    obj->inc(getVec());
}

void TestIFace::objRet()
{
    checkNumArgs(1,0); //(#out, #in)
    output(obj->ret());
}

void TestIFace::objAdd()
{
    checkNumArgs(1,1); //(#out, #in)
    output(obj->add(getVec())); // 1-liner
}

void TestIFace::objEchoArray()
{
    checkNumArgs(0,1); //(#out, #in)
    auto arr = getStringArray();
    std::cout<<"Got Array of strings.\n";
    for(arma::uword n=0;n<arr.size();n++) std::cout<<"["<<n<<"]: "<<arr[n]<<std::endl;
}

void TestIFace::staticVecSum()
{
    checkNumArgs(1,2); //(#out, #in)
    auto a=getVec();
    auto b=getVec();
    output((a+b).eval());
}

TestIFace iface; /**< Global iface object provides a iface.mexFunction */

void mexFunction(int nlhs, mxArray *lhs[], int nrhs, const mxArray *rhs[])
{
    iface.mexFunction(nlhs, lhs, nrhs, rhs);
}
