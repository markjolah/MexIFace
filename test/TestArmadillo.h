/** @file TestArmadillo.h
 * @author Mark J. Olah (mjo\@cs.unm.edu)
 * @date 12-2018
 * @brief A very simple test class for MexIFace.
 */

#ifndef MEXIFACE_TEST_ARMADILLO_H
#define MEXIFACE_TEST_ARMADILLO_H

#include <armadillo>

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

#endif /* MEXIFACE_TEST_ARMADILLO_H */
