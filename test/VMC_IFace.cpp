/** @file TestArmadilloIFace.cpp
 *  @author Mark J. Olah (mjo\@cs.unm.edu)
 *  @date 2018-2019
 */
#include <omp.h>
#include <functional>
#include "TestArmadillo.h"
#include "MexIFace/MexIFace.h"

/* vector, matrix, cube test */
class TestVMC
{
public:
    using VecT = arma::Col<double>;
    using MatT = arma::Mat<double>;
    using CubeT = arma::Cube<double>;
    using StatsT = std::map<std::string,double>;

    TestVMC(VecT v, MatT m, CubeT c) : v(v), m(m), c(c) {}
    void set_vec(const VecT &v_) { v = v_; }
    void set_mat(const MatT &m_) { m = m_; }
    void set_cube(const CubeT &c_) { c = c_; }

    const VecT& get_vec() { return v; }
    const MatT& get_mat() { return m; }
    const CubeT& get_cube() { return c; }

    void add_vec(const VecT &v_) { v+=v_; }
    void add_mat(const MatT &m_) { m+=m_; }
    void add_cube(const CubeT &c_) { c+=c_; }

    MatT solve_mat(const MatT &B) { return arma::solve(m,B); }
    void svd_mat(MatT &U, VecT &s, MatT &V) const { arma::svd(U,s,V,m); }

    StatsT get_stats() {
        StatsT stats;
        stats["v.n_elem"]=v.n_elem;
        stats["m.n_rows"]=m.n_rows;
        stats["m.n_cols"]=m.n_cols;
        stats["c.n_rows"]=c.n_rows;
        stats["c.n_cols"]=c.n_cols;
        stats["c.n_slices"]=c.n_slices;
        return stats;
    }
private:
    VecT v;
    MatT m;
    CubeT c;
};


/* Testing interface
 * Add more methods as needed to achieve full testing coverage.
 * Currently tests
 *  - Object constriction and data storage
 *  - vector/matric/cube argument passing
 *  - Dictionary (std::map) arguments
 *  - Static methods
 */
class VMC_IFace : public mexiface::MexIFace, public mexiface::MexIFaceHandler<TestVMC>
{
public:
    VMC_IFace();
private:
    using VecT=typename TestVMC::VecT;
    using MatT=typename TestVMC::MatT;
    using CubeT=typename TestVMC::CubeT;
    void objConstruct();
    void objGetVec();
    void objGetMat();
    void objGetCube();
    void objGet();

    void objSetVec();
    void objSetMat();
    void objSetCube();
    void objSet();

    void objAdd();
    void objSolve();
    void objSolveOMP();
    void objSvd();
    void objGetStats();

    /* static methods */
    void staticVecSum();
    void staticMatProd();
};

VMC_IFace::VMC_IFace()
{
    methodmap["getVec"] = std::bind(&VMC_IFace::objGetVec, this);
    methodmap["getMat"] = std::bind(&VMC_IFace::objGetMat, this);
    methodmap["getCube"] = std::bind(&VMC_IFace::objGetCube, this);
    methodmap["get"] = std::bind(&VMC_IFace::objGet, this);

    methodmap["setVec"] = std::bind(&VMC_IFace::objGetVec, this);
    methodmap["setMat"] = std::bind(&VMC_IFace::objGetMat, this);
    methodmap["setCube"] = std::bind(&VMC_IFace::objGetCube, this);
    methodmap["set"] = std::bind(&VMC_IFace::objGet, this);

    methodmap["add"] = std::bind(&VMC_IFace::objAdd, this);
    methodmap["solve"] = std::bind(&VMC_IFace::objSolve, this);
    methodmap["solveOMP"] = std::bind(&VMC_IFace::objSolveOMP, this);
    methodmap["svd"] = std::bind(&VMC_IFace::objSvd, this);
    methodmap["getStats"] = std::bind(&VMC_IFace::objGetStats, this);

    staticmethodmap["vecSum"] = std::bind(&VMC_IFace::staticVecSum, this);
    staticmethodmap["matProd"] = std::bind(&VMC_IFace::staticMatProd, this);
}

void VMC_IFace::objConstruct()
{
    checkNumArgs(1,3); //(#out, #in)
    auto v = getVec();
    auto m = getMat();
    auto c = getCube();
    outputHandle(new TestVMC(v,m,c));
}

void VMC_IFace::objGetVec()
{
    checkNumArgs(1,0); //(#out, #in)
    output(obj->get_vec());
}

void VMC_IFace::objGetMat()
{
    checkNumArgs(1,0); //(#out, #in)
    output(obj->get_mat());
}

void VMC_IFace::objGetCube()
{
    checkNumArgs(1,0); //(#out, #in)
    output(obj->get_cube());
}

void VMC_IFace::objGet()
{
    checkMaxNumArgs(3,0); //(#out, #in)
    if(nlhs>0) output(obj->get_vec());
    if(nlhs>1) output(obj->get_mat());
    if(nlhs>2) output(obj->get_cube());

}

void VMC_IFace::objSetVec()
{
    checkNumArgs(0,1); //(#out, #in)
    obj->set_vec(getVec());
}

void VMC_IFace::objSetMat()
{
    checkNumArgs(0,1); //(#out, #in)
    obj->set_mat(getMat());
}

void VMC_IFace::objSetCube()
{
    checkNumArgs(0,1); //(#out, #in)
    obj->set_cube(getCube());
}

void VMC_IFace::objSet()
{
    checkMinNumArgs(0,1); //(#out, #in)
    checkMaxNumArgs(0,3); //(#out, #in)
    obj->set_vec(getVec());
    if(nrhs>1) obj->set_mat(getMat());
    if(nrhs>2) obj->set_cube(getCube());
}

void VMC_IFace::objAdd()
{
    checkMinNumArgs(0,1); //(#out, #in)
    checkMaxNumArgs(3,3); //(#out, #in)
    obj->add_vec(getVec());
    if(nrhs>1) obj->add_mat(getMat());
    if(nrhs>2) obj->add_cube(getCube());
    //output
    if(nlhs>0) output(obj->get_vec());
    if(nlhs>1) output(obj->get_mat());
    if(nlhs>2) output(obj->get_cube());
}

void VMC_IFace::objSolve()
{
    checkNumArgs(1,1); //(#out, #in)
    const auto &m = obj->get_mat();
    auto N = m.n_rows;
    auto B = getMat();
    if(N!=B.n_rows) error("svd","BadShape","m and B must have same number of rows");
    output(arma::solve(m,B).eval());
}

void VMC_IFace::objSolveOMP()
{
    checkNumArgs(1,1); //(#out, #in)
    const auto &m = obj->get_mat();
    auto N = m.n_rows;
    auto B = getCube();
    auto X = makeOutputArray(B.n_rows,B.n_cols,B.n_slices);
    if(N!=B.n_rows) error("svd","BadShape","m and B must have same number of rows");
    #pragma omp parallel
    {
        MatT x;
        #pragma omp for
        for(arma::uword i=0; i<B.n_slices; i++){
            arma::solve(x,m,B.slice(i));
            if(x.is_empty()) X.slice(i).zeros();
            else X.slice(i) = x;
        }
    }
}

void VMC_IFace::objSvd()
{
    checkNumArgs(3,1); //(#out, #in)
    const auto &m = obj->get_mat();
    auto N = m.n_rows;
    if(m.n_cols != N) error("svd","BadShape","m is not square");
    MatT U(N,N), V(N,N);
    VecT s(N);
    arma::svd(U,s,V,m);
    if(U.is_empty()) error("svd","NumericalErrror","SVD failure");
    output(U);
    output(s);
    output(V);
}

void VMC_IFace::objGetStats()
{
    output(obj->get_stats());
}



void VMC_IFace::staticVecSum()
{
    checkNumArgs(1,2); //(#out, #in)
    auto a = getVec();
    auto b = getVec();
    if(a.n_elem!=b.n_elem) error("vecSum","BadSize","#elem must match");
    output((a+b).eval());
}

void VMC_IFace::staticMatProd()
{
    checkNumArgs(1,2); //(#out, #in)
    auto A = getMat();
    auto B = getMat();
    if(A.n_cols!=B.n_rows) error("matProd","BadSize","#cols must match #rows");
    auto C = makeOutputArray(A.n_rows,A.n_cols);
    C=A*B;
}


VMC_IFace iface; /**< Global iface object provides a iface.mexFunction */

void mexFunction(int nlhs, mxArray *lhs[], int nrhs, const mxArray *rhs[])
{
    iface.mexFunction(nlhs, lhs, nrhs, rhs);
}
