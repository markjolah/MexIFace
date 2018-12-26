/** @file TestIFace.cpp
 * @author Mark J. Olah (mjo\@cs.unm.edu)
 * @date 2018
 */

#include "TestIFace.h"


TestIFace::TestIFace()
{
    methodmap["add"] = boost::bind(&Tracker_Iface::objAdd, this);
}

void TestIFace::objConstruct()
{
    this->checkNumArgs(1,1); //(#out, #in)
    TestArmadillo::VecT v = this->getVec();
//     auto v = this->getVec<double>();
    this->outputHandle(new TestArmadillo(v));
}

void TestIFace::objAdd()
{
    this->checkNumArgs(1,1); //(#out, #in)
    TestArmadillo::VecT o = this->getVec();
    this->outputVec(obj->add(o));
}
