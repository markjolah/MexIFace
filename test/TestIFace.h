/** @file TestIFace.h
 * @author Mark J. Olah (mjo\@cs.unm.edu)
 * @date 12-2018
 * @brief A test class for MexIFace.
 */

#ifndef MEXIFACE_TESTIFACE_H
#define MEXIFACE_TESTIFACE_H

#include <armadillo>

#include "MexIFace/MexIFace.h"

class TestArmadillo
{
public:
    using VecT = arma::Col<double>;
    TestArmadillo(VecT v) : v(v) {}
    VecT add(const VecT &o) const {return o+v;}
    VecT ret() const {return v;}
    void inc(const VecT &o) { v+=o; }
private:
    VecT v;
};


class TestIFace : public mexiface::MexIFace, public mexiface::MexIFaceHandler<TestArmadillo>
{
public:
    TestIFace();
private:
    void objConstruct();
    void objAdd();
    void objRet();
    void objInc();
};

#endif /* MEXIFACE_TESTIFACE_H */
