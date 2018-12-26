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
    using VecT = arma::Col<double>;
    VecT v;
public:
    TestArmadillo(VecT v) : v(v) {}
    VecT add(const VecT &o) {return o+v;}
};


class TestIFace : public mexiface::MexIFace
{
public:
    TestIFace();
private:
    int max_threads;
    
    TrackerT *obj;
    //Abstract member functions inherited from Mex_Iface
    void objConstruct();
    void objAdd();
};

#endif /* MEXIFACE_TESTIFACE_H */
