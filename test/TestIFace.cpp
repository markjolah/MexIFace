/** @file TestIFace.cpp
 * @author Mark J. Olah (mjo\@cs.unm.edu)
 * @date 2018
 */

#include <functional>
#include "TestIFace.h"

TestIFace::TestIFace()
{
    methodmap["add"] = std::bind(&TestIFace::objAdd, this);
    methodmap["inc"] = std::bind(&TestIFace::objInc, this);
    methodmap["ret"] = std::bind(&TestIFace::objRet, this);
}

void TestIFace::objConstruct()
{
    this->checkNumArgs(1,1); //(#out, #in)
    TestArmadillo::VecT v = getVec();
//     auto v = this->getVec<double>();
    this->outputHandle(new TestArmadillo(v));
}

void TestIFace::objInc()
{
    this->checkNumArgs(0,1); //(#out, #in)
    obj->inc(this->getVec());
}

void TestIFace::objRet()
{
    this->checkNumArgs(1,0); //(#out, #in)
    this->output(obj->ret());
}


void TestIFace::objAdd()
{
    this->checkNumArgs(1,1); //(#out, #in)
    TestArmadillo::VecT o = this->getVec();
    this->output(obj->add(o));
}

TestIFace iface; /**< Global iface object provides a iface.mexFunction */

void mexFunction(int nlhs, mxArray *lhs[], int nrhs, const mxArray *rhs[])
{
    iface.mexFunction(nlhs, lhs, nrhs, rhs);
}
