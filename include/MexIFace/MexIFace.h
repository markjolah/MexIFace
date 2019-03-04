/** @file MexIFace.h
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2013-2019
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief The class declaration and inline and templated functions for MexIFace.
 */

#ifndef MEXIFACE_MEXIFACE_H
#define MEXIFACE_MEXIFACE_H

#include <sstream>
#include <map>
#include <vector>
#include <list>
#include <algorithm>
#include <functional>
#include <armadillo>

#include "mex.h"

#include "MexIFace/MexIFaceError.h"
#include "MexIFace/hypercube.h"
#include "MexIFace/MexUtils.h"
#include "MexIFace/MexIFaceBase.h"
#include "MexIFace/MexIFaceHandler.h"

namespace mexiface  {

/** @class MexIFace 
 * @brief Base class for the C++ side of a MexIFace interface class.
 *
 * The MexIFace class is responsible for managing the C++ side of the MEX interface.
 * The primary entry point from Matlab is the MexIFace::mexFunction method which takes in a variable number of arguments
 * and returns a variable number of arguments.  The first input argument is always a string that gives the command name.
 * If it the special command "\@new" or "\@delete" a C++ instance is created or destroyed.  The \@new command
 * returns a unique handle (number)
 * which can be held onto by the Matlab IfaceMixin base class.  This C++ object then remains in memory until the
 * \@delete command is called on the MexIFace, which then frees the underlying C++ class from memory.
 *
 * The special command "\@static" allows static C++ methods to be called by the name passed as the second argument,
 * and there is no need to have a existing object to call the method on because it is static.
 * 
 * Otherwise the command is interpreted as a named method which is registered in the methodmap,
 * internal data structure which maps strings to callable member functions of the interface object which take in no
 * arguments and return no arguments.  The Matlab arguments are passed to these functions through the internal storage of the
 * MexIFace object's rhs and lhs member variables.
 *
 * A C++ class is wrapped by creating a new Iface class that inherits from MexIFace.  At a minimum
 * the Iface class must define the pure virtual functions objConstruct(), objDestroy(), and getObjectFromHandle().  It also
 * must implement the interface for any of the methods and static methods that are required.  Each of these methods in the
 * Iface class must process the passed Matlab arguments in the rhs member variable and save outputs in the lhs member variable.
 *
 * In general the Iface mex modules are not intended to be used directly, but rather are paired with a special Matlab
 * class that inherits from the IfaceMixin.m base class.
 *
 * Design decision:  Because of the complexities of inheriting from a templated base class with regard to name lookups
 * in superclasses, we chose to keep this MexIFace class non-templated.  For this reason any methods and member variables which
 * specifically mention the type of the wrapped class must be defined in the subclass of MexIFace.
 *
 * Finally we provide many get* and make* which allow the lhs and rhs arguments to be interpreted as armadillo arrays on the C++ side.
 * These methods are part of what makes this interface efficient as we don't need to create new storage and copy data, instead we just use
 * the matlab memory directly, and matlab does all the memory management of parameters passed in and out.
 */
class MexIFace : public virtual MexIFaceBase {
public:
    using MXArgCountT = int; /**< Type for the mexFunction arg counts and associated nrhs and nlhs data members  */
    using IdxT = arma::uword; /**< A logical type for an IdxT integer index */
    
    template<class T> using Vec = arma::Col<T>;
    template<class T> using Mat = arma::Mat<T>;
    template<class T> using Cube = arma::Cube<T>;
    template<class T> using Hypercube = Hypercube<T>;
    
    template<class T> using Dict = std::map<std::string,T>; /**< A convenient form for reporting dictionaries of named FP data to matlab */
    
    template<class T> using IsArithmeticT = typename std::enable_if<std::is_arithmetic<T>::value>::type;
    template<class T> using IsNotArithmeticT = typename std::enable_if<!std::is_arithmetic<T>::value>::type;
    template<class T> using IsIntegralT = typename std::enable_if< std::is_integral<T>::value >::type;
    template<class T> using IsUnsignedIntegralT = typename std::enable_if< std::is_integral<T>::value && std::is_same<T, typename std::make_unsigned<T>::type>::value >::type;
    template<class T> using IsFloatingPointT = typename std::enable_if< std::is_floating_point<T>::value >::type;
    
    MexIFace();

    void mexFunction(MXArgCountT _nlhs, mxArray *_lhs[], MXArgCountT _nrhs, const mxArray *_rhs[]);
    
    /* Public Static methods */

    //@{
    /** Test doc here. And more here */
    template<class ElemT> static void checkType(const mxArray *m);
    static void checkType(const mxArray *m, mxClassID classid);
    static void checkNdim(const mxArray *m, mwSize expected_dim);
    static void checkMaxNdim(const mxArray *m, mwSize max_expected_dim);
    static void checkScalarSize(const mxArray *m);
    static void checkVectorSize(const mxArray *m);
    static void checkVectorSize(const mxArray *m, mwSize expected_numel);
    static void checkMatrixSize(const mxArray *m, mwSize expected_rows, mwSize expected_cols);
    static void checkSameLastDim(const mxArray *m1, const mxArray *m2);
    //@}

    
    /* Unchecked converters allowing direct access to mxArray */
    template<class ElemT=double, typename=IsArithmeticT<ElemT>> 
    static ElemT toScalar(const mxArray *m);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static Vec<ElemT> toVec(const mxArray *m);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static Mat<ElemT> toMat(const mxArray *m);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static Cube<ElemT> toCube(const mxArray *m);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static Hypercube<ElemT> toHypercube(const mxArray *m);
    
    template<class ElemT=double, typename=IsArithmeticT<ElemT>> 
    static ElemT checkedToScalar(const mxArray *m);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static Vec<ElemT> checkedToVec(const mxArray *m);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static Mat<ElemT> checkedToMat(const mxArray *m);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static Cube<ElemT> checkedToCube(const mxArray *m);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static Hypercube<ElemT> checkedToHypercube(const mxArray *m);
    
    static mxArray* toMXArray(bool val);
    static mxArray* toMXArray(const char* val);
    static mxArray* toMXArray(std::string val);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static mxArray* toMXArray(ElemT val);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static mxArray* toMXArray(const Vec<ElemT> &arr);

    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static mxArray* toMXArray(const Mat<ElemT> &arr);

    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static mxArray* toMXArray(const Cube<ElemT> &arr);

    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static mxArray* toMXArray(const Hypercube<ElemT> &arr);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>> 
    static mxArray* toMXArray(const arma::SpMat<ElemT> &arr);
    
    template<class ElemT, typename=IsArithmeticT<ElemT>>
    static mxArray* toMXArray(const std::list<ElemT> &arr);

    template<class ConvertableT> 
    static mxArray* toMXArray(const Dict<ConvertableT> &arr);

    template<template<typename...> class Array, class ConvertableT>
    static mxArray* toMXArray(const Array<ConvertableT> &arr);

    template<class SrcIntT,class DestIntT,typename=IsIntegralT<SrcIntT>,typename=IsIntegralT<DestIntT>>
    static DestIntT checkedIntegerToIntegerConversion(const mxArray *m);
    
    template<class SrcFloatT,class DestIntT,typename=IsFloatingPointT<SrcFloatT>,typename=IsIntegralT<DestIntT>>
    static DestIntT checkedFloatToIntegerConversion(const mxArray *m);
    
    template<class SrcIntT,class DestFloatT,typename=IsIntegralT<SrcIntT>,typename=IsFloatingPointT<DestFloatT>>
    static DestFloatT checkedIntegerToFloatConversion(const mxArray *m);
    
    template<class SrcFloatT,class DestFloatT,typename=IsFloatingPointT<SrcFloatT>,typename=IsFloatingPointT<DestFloatT>>
    static DestFloatT checkedFloatToFloatConversion(const mxArray *m);
    
protected:
    using MethodMap = std::map<std::string, std::function<void()>>; /**< The type of mapping for mapping names to member functions to call */    
    
    MethodMap methodmap; ///< Maps names (std::string) to member functions (std::function<void()>)
    MethodMap staticmethodmap; ///< Maps names (std::string) to static member functions (std::function<void()>)

    MXArgCountT nlhs; ///< Number of left-hand-side (output) arguments passed to MexIFace::mexFunction
    mxArray **lhs; ///< Left-hand-side (output) argument array.  Size=nlhs
    IdxT lhs_idx; ///< Index of the next left-hand-side argument to write as output
    MXArgCountT nrhs; ///< Number of right-hand-side (input) arguments passed to MexIFace::mexFunction
    const mxArray **rhs; ///< Right-hand-side (input) argument array.  Size=nrhs
    IdxT rhs_idx; ///< Index of the next right-hand-side argument to read as input

    /* methods to check the number and shape of arguments */
    void checkNumArgs(MXArgCountT expected_nlhs, MXArgCountT expected_nrhs) const;
    void checkMinNumArgs(MXArgCountT min_nlhs, MXArgCountT min_nrhs) const;
    void checkMaxNumArgs(MXArgCountT max_nlhs, MXArgCountT max_nrhs) const;
    void checkInputArgRange(MXArgCountT min_nrhs, MXArgCountT max_nrhs) const;
    void checkOutputArgRange(MXArgCountT min_nlhs, MXArgCountT max_nlhs) const;
    
    /* getAs methods attempt to convert from whatever matlab type is in the mxArray
     * and report an error if conversion would lead to data loss.
     */
    template<class ElemT=double> 
    ElemT getAsScalar(const mxArray *m=nullptr);
    
    bool getAsBool(const mxArray *m=nullptr);
    template<class IntT=int64_t, typename = IsIntegralT<IntT>>
    IntT getAsInt(const mxArray *m=nullptr);
    template<class UnsignedT=uint64_t, typename=IsUnsignedIntegralT<UnsignedT>>
    UnsignedT getAsUnsigned(const mxArray *m=nullptr);
    template<class FloatT=double, typename = IsFloatingPointT<FloatT>>
    FloatT getAsFloat(const mxArray *m=nullptr);

    template<class ElemT=double>
    Dict<ElemT> getAsScalarDict(const mxArray *m=nullptr);
    template<template<typename...> class Array = std::vector,class ElemT=double>
    Array<ElemT> getAsScalarArray(const mxArray *m=nullptr);

    /* get methods do not convert any arguments and will throw an exception if the types are not uniform */
    std::string getString(const mxArray *mxdata=nullptr);
    template<template<typename...> class Array = std::vector>
    Array<std::string> getStringArray(const mxArray *mxdata=nullptr);

    template<class ElemT=double, typename=IsArithmeticT<ElemT>>
    ElemT getScalar(const mxArray *mxdata=nullptr);
    template<class ElemT=double, typename=IsArithmeticT<ElemT>>
    Vec<ElemT> getVec(const mxArray *mxdata=nullptr);
    template<class ElemT=double, typename=IsArithmeticT<ElemT>>
    Mat<ElemT> getMat(const mxArray *mxdata=nullptr);
    template<class ElemT=double, typename=IsArithmeticT<ElemT>> 
    Cube<ElemT> getCube(const mxArray *mxdata=nullptr);
    template<class ElemT=double, typename=IsArithmeticT<ElemT>> 
    Hypercube<ElemT> getHypercube(const mxArray *mxdata=nullptr);
    
    template<template<typename> class NumericArrayT, class ElemT=double>
    NumericArrayT<ElemT> getNumeric(const mxArray *m=nullptr);

    template<template<typename...> class Array = std::vector, class ElemT=double>
    Array<ElemT> getScalarArray(const mxArray *mxdata=nullptr);
    template<template<typename> class Array = std::vector, class ElemT=double, typename=IsArithmeticT<ElemT>>
    Array<Vec<ElemT>> getVecArray(const mxArray *mxdata=nullptr);
    template<template<typename> class Array = std::vector, class ElemT=double, typename=IsArithmeticT<ElemT>> 
    Array<Mat<ElemT>> getMatArray(const mxArray *mxdata=nullptr);
    template<template<typename> class Array = std::vector, class ElemT=double, typename=IsArithmeticT<ElemT>> 
    Array<Cube<ElemT>> getCubeArray(const mxArray *mxdata=nullptr);
    template<template<typename> class Array = std::vector, class ElemT=double, typename=IsArithmeticT<ElemT>> 
    Array<Hypercube<ElemT>> getHypercubeArray(const mxArray *mxdata=nullptr);
  
    /* Get a matlab structure of common types as a C++ Dict (aka. std::map<string,T>)*/
    template<class ElemT=double, typename=IsArithmeticT<ElemT>>
    Dict<ElemT> getScalarDict(const mxArray *mxdata=nullptr);
    template<class ElemT=double, typename=IsArithmeticT<ElemT>>
    Dict<Vec<ElemT>> getVecDict(const mxArray *mxdata=nullptr);
    template<class ElemT=double, typename=IsArithmeticT<ElemT>>
    Dict<Mat<ElemT>> getMatDict(const mxArray *mxdata=nullptr);
    template<class ElemT=double, typename=IsArithmeticT<ElemT>>
    Dict<Cube<ElemT>> getCubeDict(const mxArray *mxdata=nullptr);
    template<class ElemT=double, typename=IsArithmeticT<ElemT>>
    Dict<Hypercube<ElemT>> getHypercubeDict(const mxArray *mxdata=nullptr);
  
    /* make methods use matlab to allocate the data as mxArrays and then
     * share the pointer access through a armadillo object for maximum speed */
    template<class ElemT=double, typename=IsArithmeticT<ElemT>> 
    Vec<ElemT> makeOutputArray(IdxT nelem);
    template<class ElemT=double, typename=IsArithmeticT<ElemT>> 
    Mat<ElemT> makeOutputArray(IdxT rows, IdxT cols);
    template<class ElemT=double, typename=IsArithmeticT<ElemT>> 
    Cube<ElemT> makeOutputArray(IdxT rows, IdxT cols, IdxT slices);
    template<class ElemT=double, typename=IsArithmeticT<ElemT>> 
    Hypercube<ElemT> makeOutputArray(IdxT rows, IdxT cols, IdxT slices, IdxT hyperslices);

    /* ouptput methods make a new matlab object copying in data from arguments
     */
    void output(mxArray *m) override final;
    template<class ConvertableT>
    void output(ConvertableT&& val);
    
    /* Error reporting */    
    void error(std::string condition, std::string message) const;
    void error(std::string component,std::string condition, std::string message) const;

private:
    void callMethod(std::string name, const MethodMap &map);
    void popRhs();
    void setArguments(MXArgCountT _nlhs, mxArray *_lhs[], MXArgCountT _nrhs, const mxArray *_rhs[]);    
    
    /* Private Static */
    static std::string remove_alphanumeric(std::string name);
    
    template<template<typename> class Array, class ElemT>
    struct GetNumericFunctor;

    template<class ElemT>
    struct GetNumericFunctor<Vec,ElemT>
    {
        Vec<ElemT> operator()(MexIFace *obj, const mxArray *m) const { return obj->template getVec<ElemT>(m); }
    };
    
    template<class ElemT>
    struct GetNumericFunctor<Mat,ElemT>
    {
        Mat<ElemT> operator()(MexIFace *obj, const mxArray *m) const { return obj->template getMat<ElemT>(m); }
    };

    template<class ElemT>
    struct GetNumericFunctor<Cube,ElemT>
    {
        Cube<ElemT> operator()(MexIFace *obj, const mxArray *m) const { return obj->template getCube<ElemT>(m); }
    };

    template<class ElemT>
    struct GetNumericFunctor<Hypercube,ElemT>
    {
        Hypercube<ElemT> operator()(MexIFace *obj, const mxArray *m) const { return obj->template getHypercube<ElemT>(m); }
    };
};

template<class ElemT>
void MexIFace::checkType(const mxArray *m)
{
    checkType(m, get_mx_class<ElemT>());
}

inline
void MexIFace::checkType(const mxArray *m, mxClassID expected_classid)
{
    mxClassID m_id=mxGetClassID(m);
    if (m_id != expected_classid) {
        std::ostringstream msg;
        msg<<"Expected Type="<<get_mx_class_name(expected_classid)<<" (id:"<<expected_classid<<") "<<" | Got Type="<<get_mx_class_name(m)<<" (id:"<<m_id<<")";
        throw MexIFaceError("BadType",msg.str());
    }
}

inline
void MexIFace::checkNdim(const mxArray *m, mwSize expected_dim)
{
    mwSize ndims = mxGetNumberOfDimensions(m);
    if (ndims != expected_dim) {        
        std::ostringstream msg;
        msg<<"Expected #dims="<<expected_dim<<" | Got #dims="<<ndims;
        throw MexIFaceError("BadDimensionality",msg.str());
    }
}

inline
void MexIFace::checkMaxNdim(const mxArray *m, mwSize max_expected_dim)
{
    mwSize ndims = mxGetNumberOfDimensions(m);
    if (ndims > max_expected_dim) {        
        std::ostringstream msg;
        msg<<"Expected #dims <="<<max_expected_dim<<" | Got #dims="<<ndims;
        throw MexIFaceError("BadDimensionality",msg.str());
    }
}

inline
void MexIFace::checkScalarSize(const mxArray *m)
{
    mwSize M = mxGetM(m);
    mwSize N = mxGetN(m);
    if (M>1 || N>1) {
        std::ostringstream msg;
        msg<<"Expected scalar vector | Got size:["<<M<<" X "<<N<<"]";
        throw MexIFaceError("BadSize",msg.str());
    }
}

inline
void MexIFace::checkVectorSize(const mxArray *m)
{
    mwSize M = mxGetM(m);
    mwSize N = mxGetN(m);
    if (M>1 && N>1) {
        std::ostringstream msg;
        msg<<"Expected 1D vector | Got size:["<<M<<" X "<<N<<"]";
        throw MexIFaceError("BadSize",msg.str());
    }
}

/** @brief Checks that a matlab mxArray object has the correct 2D dimensions
 * @param m A pointer to the mxArray to check
 * @param expected_numel the expected number of elements
 */
inline
void MexIFace::checkVectorSize(const mxArray *m, mwSize expected_numel)
{
    mwSize M = mxGetM(m);
    mwSize N = mxGetN(m);
    if ((M>1 && N>1) || (N>1 && N != expected_numel) || (M>1 && M != expected_numel)) {
        std::ostringstream msg;
        msg<<"Expected vector size:"<<expected_numel<<" | Got size:["<<M<<" X "<<N<<"]";
        throw MexIFaceError("BadSize",msg.str());
    }
}

/** @brief Checks that a matlab mxArray object has the correct 2D dimensions
 * @param m A pointer to the mxArray to check
 * @param expected_rows the expected number of rows 
 * @param expected_cols the expected number of cols 
 */
inline
void MexIFace::checkMatrixSize(const mxArray *m, mwSize expected_rows, mwSize expected_cols)
{
    mwSize M = mxGetM(m);
    mwSize N = mxGetN(m);
    if ((M != expected_rows) || (N != expected_cols)) {
        std::ostringstream msg;
        msg<<"Expected matrix size: ["<<expected_rows<<","<<expected_cols<<"] | Got size:["<<M<<" X "<<N<<"]";
        throw MexIFaceError("BadSize",msg.str());
    }
}

/**
 * @brief Checks that two matlab mxArray objects have the same sized last dimension.
 * @param m1 A pointer to the first mxArray to check
 * @param m2 A pointer to the second mxArray to check
 *
 * Throws an exception if the last dimensions do not match.
 */
inline
void MexIFace::checkSameLastDim(const mxArray *m1, const mxArray *m2)
{
    mwSize nd1 = mxGetNumberOfDimensions(m1);
    mwSize nd2 = mxGetNumberOfDimensions(m2);
    mwSize last1 = mxGetDimensions(m1)[nd1-1];
    mwSize last2 = mxGetDimensions(m2)[nd2-1];
    if (last1 != last2){
        std::ostringstream msg;
        msg<<"Got last dim1:"<<last1<<"Not matching last dim2:"<<last2;
        throw MexIFaceError("BadSize",msg.str());
    }
}

inline
void MexIFace::checkInputArgRange(MXArgCountT min_nrhs, MXArgCountT max_nrhs) const
{
    if( nrhs < min_nrhs || nrhs > max_nrhs) {
        std::ostringstream msg;
        msg<<"Expected #RHS(in) Args: "<<min_nrhs<<" - "<<max_nrhs<<" Got #RHS:"<<nrhs;
        throw MexIFaceError("BadNumInputArgs",msg.str());
    }
}

inline
void MexIFace::checkOutputArgRange(MXArgCountT min_nlhs, MXArgCountT max_nlhs) const
{
    if( nlhs < min_nlhs || nlhs > max_nlhs) {
        std::ostringstream msg;
        msg<<"Expected #LHS(out) Args: "<<min_nlhs<<" - "<<max_nlhs<<" Got #LHS:"<<nlhs;
        throw MexIFaceError("BadNumOutputArgs",msg.str());
    }
}

/** @brief Checks the mex function was called with a minimum number of input and output arguments.
 * @param min_nlhs Minimum number of left hand side (output) arguments required.
 * @param min_nrhs Minimum number of right hand side (input) arguments required.
 */
inline
void MexIFace::checkMinNumArgs(MXArgCountT min_nlhs, MXArgCountT min_nrhs) const
{
    if (nlhs < min_nlhs) {
        std::ostringstream msg;
        msg<<"Expected #LHS(out) Args >= "<<min_nlhs<<" | Got #LHS:"<<nlhs;
        throw MexIFaceError("BadNumOutputArgs",msg.str());
    }
    if (nrhs < min_nrhs) {
        std::ostringstream msg;
        msg<<"Expected #RHS(in) Args >= "<<min_nrhs<<" | Got #RHS:"<<nrhs;
        throw MexIFaceError("BadNumInputArgs",msg.str());
    }
}

/** @brief Checks the mex function was called with a maximum number of input and output arguments.
 * @param max_nlhs Maxmum number of left hand side (output) arguments required.
 * @param max_nrhs Maxmum number of right hand side (input) arguments required.
 */
inline
void MexIFace::checkMaxNumArgs(MXArgCountT max_nlhs,MXArgCountT max_nrhs) const
{
    if (nlhs > max_nlhs) {
        std::ostringstream msg;
        msg<<"Expected #LHS(out) Args <= "<<max_nlhs<<" | Got #LHS:"<<nlhs;
        throw MexIFaceError("BadNumOutputArgs",msg.str());
    }
    if (nrhs > max_nrhs) {
        std::ostringstream msg;
        msg<<"Expected #RHS(in) Args <= "<<max_nrhs<<" | Got #RHS:"<<nrhs;
        throw MexIFaceError("BadNumInputArgs",msg.str());
    }
}

/** @brief Checks the mex function was called with an exact number of input and output arguments.
 * @param expected_nlhs Expected number of left hand side (output) arguments required.
 * @param expected_nrhs Expected  number of right hand side (input) arguments required.
 */
inline
void MexIFace::checkNumArgs(MXArgCountT expected_nlhs, MXArgCountT expected_nrhs) const
{
    if (nlhs != expected_nlhs) {
        std::ostringstream msg;
        msg<<"Expected #LHS(out) Args = "<<expected_nlhs<<" | Got #LHS:"<<nlhs;
        throw MexIFaceError("BadNumOutputArgs",msg.str());
    }
    if (nrhs != expected_nrhs) {
        std::ostringstream msg;
        msg<<"Expected #RHS(in) Args = "<<expected_nrhs<<" | Got #RHS:"<<nrhs;
        throw MexIFaceError("BadNumInputArgs",msg.str());
    }
}


template<class ElemT, typename> 
ElemT MexIFace::toScalar(const mxArray *m)
{
    return *static_cast<ElemT*>(mxGetData(m));
}

/*
 * 
 * Uses the ability of the armadillo arrays to interpret raw data passed to it as preallocated
 * data.   This allows the array data to be used directly as an armadillo array using Matlab's 
 * memory directly instead of having to allocate a separate space and copy.
 *
 */
template<class ElemT, typename> 
MexIFace::Vec<ElemT> MexIFace::toVec(const mxArray *m)
{
    return {static_cast<ElemT*>(mxGetData(m)), mxGetNumberOfElements(m), false};
}

template<class ElemT, typename> 
MexIFace::Mat<ElemT> MexIFace::toMat(const mxArray *m)
{
    return {static_cast<ElemT*>(mxGetData(m)), mxGetM(m), mxGetN(m),false};
}

template<class ElemT, typename> 
MexIFace::Cube<ElemT> MexIFace::toCube(const mxArray *m)
{
    if ( mxGetNumberOfDimensions(m) == 2) { // Single slice cube. Matlab automatically removes extra dims of size 1.
        return {static_cast<ElemT*>(mxGetData(m)), mxGetM(m), mxGetN(m), 1, false};
    } else {
        const mwSize *sz = mxGetDimensions(m);
        return {static_cast<ElemT*>(mxGetData(m)), sz[0], sz[1], sz[2], false};
    }
}

template<class ElemT, typename> 
Hypercube<ElemT> MexIFace::toHypercube(const mxArray *m)
{
    int ndims = mxGetNumberOfDimensions(m);
    const mwSize *sz = mxGetDimensions(m);
    if ( ndims == 2) { // Single slice and single hyper-slice cube. Matlab automatically removes extra dims of size 1.
        return {static_cast<ElemT*>(mxGetData(m)), mxGetM(m), mxGetN(m), 1, 1};
    } else if ( ndims == 3) { // Single hyper-slice cube. Matlab automatically removes extra dims of size 1.
        return {static_cast<ElemT*>(mxGetData(m)), sz[0], sz[1], sz[2], 1};
    } else {
        return {static_cast<ElemT*>(mxGetData(m)), sz[0], sz[1], sz[2], sz[3]};
    }
}

template<class ElemT, typename> 
ElemT MexIFace::checkedToScalar(const mxArray *m)
{
    checkType<ElemT>(m);
    checkScalarSize(m);
    return toScalar<ElemT>(m);    
}

template<class ElemT, typename> 
MexIFace::Vec<ElemT> MexIFace::checkedToVec(const mxArray *m)
{
    checkType<ElemT>(m);
    checkVectorSize(m);
    return toVec<ElemT>(m);
}

template<class ElemT, typename> 
MexIFace::Mat<ElemT> MexIFace::checkedToMat(const mxArray *m)
{
    checkType<ElemT>(m);
    checkNdim(m,2);
    return toMat<ElemT>(m);
}

template<class ElemT, typename> 
MexIFace::Cube<ElemT> MexIFace::checkedToCube(const mxArray *m)
{
    checkType<ElemT>(m);
    checkMaxNdim(m,3);
    return toCube<ElemT>(m);
}

template<class ElemT, typename> 
MexIFace::Hypercube<ElemT> MexIFace::checkedToHypercube(const mxArray *m)
{
    checkType<ElemT>(m);
    checkMaxNdim(m,4);
    return toHypercube<ElemT>(m);
}

template<class SrcIntT,class DestIntT, typename, typename>
DestIntT MexIFace::checkedIntegerToIntegerConversion(const mxArray *m)
{
    if(std::is_same<SrcIntT,DestIntT>::value) return *static_cast<SrcIntT*>(mxGetData(m));
    auto src_max = std::numeric_limits<SrcIntT>::max();
    auto src_min = std::numeric_limits<SrcIntT>::min();
    auto dest_max = std::numeric_limits<DestIntT>::max();
    auto dest_min = std::numeric_limits<DestIntT>::min();
    if (dest_max < src_max) {
        auto val = *static_cast<SrcIntT*>(mxGetData(m));
        if (dest_max < val || dest_min > val) {
            std::ostringstream msg;
            msg<<"Conversion from:"<<get_mx_class_name(m)<<"("<<val<<") to:"<<get_mx_class_name(get_mx_class<DestIntT>())<<" Forbidden. Will cause loss of data.";
            throw MexIFaceError("BadTypeConversion",msg.str());
        }
        return val;
    } else if (dest_min > src_min) {
        auto val = *static_cast<SrcIntT*>(mxGetData(m));
        if (dest_min > val) {
            std::ostringstream msg;
            msg<<"Conversion from:"<<get_mx_class_name(m)<<"("<<val<<") to:"<<get_mx_class_name(get_mx_class<DestIntT>())<<" Forbidden. Will cause loss of data.";
            throw MexIFaceError("BadTypeConversion",msg.str());
        }        
        return val;
    }
    return *static_cast<SrcIntT*>(mxGetData(m));
}


template<class SrcFloatT,class DestIntT, typename, typename>
DestIntT MexIFace::checkedFloatToIntegerConversion(const mxArray *m)
{
    auto dest_max = std::numeric_limits<DestIntT>::max();
    auto dest_min = std::numeric_limits<DestIntT>::min();
    auto val = *static_cast<SrcFloatT*>(mxGetData(m));
    if (dest_max < val || dest_min > val || !std::isfinite(val)) {
        std::ostringstream msg;
        msg<<"Conversion from:"<<get_mx_class_name(m)<<"("<<val<<") to:"<<get_mx_class_name(get_mx_class<DestIntT>())<<" Forbidden. Will cause loss of data.";
        throw MexIFaceError("BadTypeConversion",msg.str());
    }
    return val;    
}

template<class SrcIntT,class DestFloatT, typename, typename>
DestFloatT MexIFace::checkedIntegerToFloatConversion(const mxArray *m)
{
    int64_t dest_max_int= 1ull << (std::numeric_limits<DestFloatT>::digits+1);//maximum representable integer
    int64_t dest_min_int = -dest_max_int;
    auto val = *static_cast<SrcIntT*>(mxGetData(m));
    if (dest_max_int < val || dest_min_int > val) {
        std::ostringstream msg;
        msg<<"Conversion from:"<<get_mx_class_name(m)<<"("<<val<<") to:"<<get_mx_class_name(get_mx_class<DestFloatT>())<<" Forbidden. Will cause loss of data.";
        throw MexIFaceError("BadTypeConversion",msg.str());
    }
    return val;    
}

template<class SrcFloatT,class DestFloatT,typename,typename>
DestFloatT MexIFace::checkedFloatToFloatConversion(const mxArray *m)
{
    auto val = *static_cast<SrcFloatT*>(mxGetData(m));
    if(std::is_same<SrcFloatT,DestFloatT>::value) return val;
    if(std::is_same<double,DestFloatT>::value) return val;
    auto dest_max = std::numeric_limits<DestFloatT>::max();
    auto dest_min = std::numeric_limits<DestFloatT>::min();
    if (dest_max < val || (dest_min!=0 && dest_min > std::fabs(val))) {
        std::ostringstream msg;
        msg<<"Conversion from:"<<get_mx_class_name(m)<<"("<<val<<") to:"<<get_mx_class_name(get_mx_class<DestFloatT>())<<" Forbidden. Will cause loss of data.";
        throw MexIFaceError("BadTypeConversion",msg.str());
    }
    return val;    
}

inline
mxArray* MexIFace::toMXArray(bool val)
{
    auto m = mxCreateLogicalMatrix(1,1);
    *static_cast<mxLogical*>(mxGetData(m)) = static_cast<mxLogical>(val);
    return m;
}

inline
mxArray* MexIFace::toMXArray(const char* val)
{
    return mxCreateString(val);
}

inline
mxArray* MexIFace::toMXArray(std::string val)
{
    return mxCreateString(val.c_str());
}


template<class ElemT, typename> 
mxArray* MexIFace::toMXArray(ElemT val)
{
    auto m = mxCreateNumericMatrix(1,1,get_mx_class<ElemT>(), mxREAL);
    *static_cast<ElemT*>(mxGetData(m)) = val; //copy
    return m;
}

template<class ElemT, typename> 
mxArray* MexIFace::toMXArray(const Vec<ElemT> &in_arr)
{
    auto m = mxCreateNumericMatrix(in_arr.n_elem, 1, get_mx_class<ElemT>(), mxREAL);
    auto out_arr = toVec<ElemT>(m);
    out_arr = in_arr; //copy
    return m;
}

template<class ElemT, typename> 
mxArray* MexIFace::toMXArray(const Mat<ElemT> &in_arr)
{
    auto m = mxCreateNumericMatrix(in_arr.n_rows, in_arr.n_cols, get_mx_class<ElemT>(), mxREAL);
    auto out_arr = toMat<ElemT>(m);
    out_arr = in_arr; //copy
    return m;
}

template<class ElemT, typename> 
mxArray* MexIFace::toMXArray(const Cube<ElemT> &in_arr)
{
    const mwSize size[3] = {in_arr.n_rows, in_arr.n_cols, in_arr.n_slices};
    auto m = mxCreateNumericArray(3,size,get_mx_class<ElemT>(), mxREAL);
    auto out_arr = toCube<ElemT>(m);
    out_arr = in_arr; //copy
    return m;
}

template<class ElemT, typename> 
mxArray* MexIFace::toMXArray(const Hypercube<ElemT> &in_arr)
{
    const mwSize size[4] = {in_arr.n_rows, in_arr.n_cols, in_arr.n_slices, in_arr.n_hyperslices};
    auto m = mxCreateNumericArray(4,size,get_mx_class<ElemT>(), mxREAL);
    auto out_arr = toHypercube<ElemT>(m);
    out_arr = in_arr; //copy
    return m;
}

template<class ElemT, typename> 
mxArray* MexIFace::toMXArray(const arma::SpMat<ElemT> &arr)
{
    auto nnz = arr.n_nonzero;
    mxArray *out_arr=mxCreateSparse(arr.n_rows, arr.n_cols, arr.n_nonzero, mxREAL);
    double  *out_values  = mxGetPr(out_arr);
    mwIndex *out_row_ind = mxGetIr(out_arr);
    mwIndex *out_col_ptr = mxGetJc(out_arr);
    const ElemT *const values = arr.values;
    const arma::uword *const row_ind = arr.row_indices;
    const arma::uword *const col_ptr = arr.col_ptrs;
    //Copy values and row indicies
    for(int n=0; n<nnz; n++){
        out_values[n] = static_cast<double>(values[n]);
        out_row_ind[n] = static_cast<mwIndex>(row_ind[n]);
    }
    //Copy column pointers
    int nrows = static_cast<int>(arr.n_rows);
    for(int n=0; n<=nrows; n++) out_col_ptr[n] = static_cast<mwIndex>(col_ptr[n]);
    return out_arr;
}

template<class ElemT, typename>
mxArray* MexIFace::toMXArray(const std::list<ElemT> &arr)
{
    auto N = arr.size();
    auto m = mxCreateNumericMatrix(N, 1, get_mx_class<ElemT>(), mxREAL);
    auto out_arr = toVec<ElemT>(m);
    std::copy_n(arr.cbegin(),N,out_arr.begin());  //copy
    return m;
}

template<class ConvertableT> 
mxArray* MexIFace::toMXArray(const Dict<ConvertableT> &dict)
{
    auto nfields = dict.size();
    const char **fnames = new const char*[nfields];
    IdxT i=0;
    for(auto &entry: dict) fnames[i++] = entry.first.c_str();
    
    auto m = mxCreateStructMatrix(1,1,nfields,fnames);
    delete[] fnames;
    for(auto &entry: dict) mxSetField(m, 0, entry.first.c_str(), toMXArray(entry.second));
    return m;
}

template<template<typename...> class Array, class ConvertableT>
mxArray* MexIFace::toMXArray(const Array<ConvertableT> &arr)
{
    auto nCells = arr.size();
    auto m = mxCreateCellMatrix(nCells, 1);
    for(int i=0;i<nCells;i++) mxSetCell(m, i, toMXArray(arr[i]));
    return m;
}



/************ getAs methods **************/
    

template<class ElemT> 
ElemT MexIFace::getAsScalar(const mxArray *m)
{
    if(std::is_same<ElemT,bool>::value) return getAsBool(m);
    else if(std::is_integral<ElemT>::value) return getAsInt<ElemT>(m);
    else if(std::is_floating_point<ElemT>::value) return getAsFloat<ElemT>(m);
    else {
        std::ostringstream msg;
        msg<<"Expected numeric or bool C++ type | Got type:"<<std::type_index(typeid(ElemT)).name();
        throw MexIFaceError("BadType",msg.str());
        return {};
    }
}


bool MexIFace::getAsBool(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    switch (mxGetClassID(m)) {
        case mxINT8_CLASS:    return !!(*static_cast<int8_t *>(mxGetData(m)));
        case mxUINT8_CLASS:   return !!(*static_cast<uint8_t *>(mxGetData(m)));
        case mxINT16_CLASS:   return !!(*static_cast<int16_t *>(mxGetData(m)));
        case mxUINT16_CLASS:  return !!(*static_cast<uint16_t *>(mxGetData(m)));
        case mxINT32_CLASS:   return !!(*static_cast<int32_t *>(mxGetData(m)));
        case mxUINT32_CLASS:  return !!(*static_cast<uint32_t *>(mxGetData(m)));
        case mxINT64_CLASS:   return !!(*static_cast<int64_t *>(mxGetData(m)));
        case mxUINT64_CLASS:  return !!(*static_cast<uint64_t *>(mxGetData(m)));
        case mxSINGLE_CLASS:  return !!(*static_cast<float *>(mxGetData(m)));
        case mxDOUBLE_CLASS:  return !!(*static_cast<double *>(mxGetData(m)));
        case mxLOGICAL_CLASS: return !!(*static_cast<mxLogical *>(mxGetData(m)));
        default: break;
    }
    std::ostringstream msg;
    msg<<"Expected numeric or logical class. | Got class:"<<get_mx_class_name(m);
    throw MexIFaceError("BadType",msg.str());
    return 0; //never get here
}

/** @brief Reads a mxArray as a scalar C++ int32_t type.
 *
 * @param m The pointer to the mxArray to interpret.
 *
 * The mxArray must be a signed 32 or 64 bit integer type.
 *
 * Throws an error if the conversion cannot be made.
 */
template<class IntT, typename>
IntT MexIFace::getAsInt(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    switch (mxGetClassID(m)) {
        case mxINT8_CLASS:   return checkedIntegerToIntegerConversion<int8_t,IntT>(m);
        case mxUINT8_CLASS:  return checkedIntegerToIntegerConversion<uint8_t,IntT>(m);
        case mxINT16_CLASS:  return checkedIntegerToIntegerConversion<int16_t,IntT>(m);
        case mxUINT16_CLASS: return checkedIntegerToIntegerConversion<uint16_t,IntT>(m);
        case mxINT32_CLASS:  return checkedIntegerToIntegerConversion<int32_t,IntT>(m);
        case mxUINT32_CLASS: return checkedIntegerToIntegerConversion<uint32_t,IntT>(m);
        case mxINT64_CLASS:  return checkedIntegerToIntegerConversion<int64_t,IntT>(m);
        case mxUINT64_CLASS: return checkedIntegerToIntegerConversion<uint64_t,IntT>(m);
        case mxSINGLE_CLASS: return checkedFloatToIntegerConversion<float,IntT>(m);
        case mxDOUBLE_CLASS: return checkedFloatToIntegerConversion<double,IntT>(m);
        default: break;
    }
    std::ostringstream msg;
    msg<<"Expected numeric class. | Got class:"<<get_mx_class_name(m);
    throw MexIFaceError("BadType",msg.str());
    return 0; //never get here
}

template<class UnsignedT, typename>
UnsignedT MexIFace::getAsUnsigned(const mxArray *m)
{
    return getAsInt<UnsignedT>(m);
}

template<class FloatT, typename>
FloatT MexIFace::getAsFloat(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    switch (mxGetClassID(m)) {
        case mxINT8_CLASS:   return checkedIntegerToFloatConversion<int8_t,FloatT>(m);
        case mxUINT8_CLASS:  return checkedIntegerToFloatConversion<uint8_t,FloatT>(m);
        case mxINT16_CLASS:  return checkedIntegerToFloatConversion<int16_t,FloatT>(m);
        case mxUINT16_CLASS: return checkedIntegerToFloatConversion<uint16_t,FloatT>(m);
        case mxINT32_CLASS:  return checkedIntegerToFloatConversion<int32_t,FloatT>(m);
        case mxUINT32_CLASS: return checkedIntegerToFloatConversion<uint32_t,FloatT>(m);
        case mxINT64_CLASS:  return checkedIntegerToFloatConversion<int64_t,FloatT>(m);
        case mxUINT64_CLASS: return checkedIntegerToFloatConversion<uint64_t,FloatT>(m);
        case mxSINGLE_CLASS: return checkedFloatToFloatConversion<float,FloatT>(m);
        case mxDOUBLE_CLASS: return checkedFloatToFloatConversion<double,FloatT>(m);
        default: break;
    }
    std::ostringstream msg;
    msg<<"Expected numeric class. | Got class:"<<get_mx_class_name(m);
    throw MexIFaceError("BadType",msg.str());
    return 0; //never get here
}

template<template<typename...> class Array, class ElemT>
Array<ElemT> MexIFace::getAsScalarArray(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    checkType(m,mxCELL_CLASS); //Only accept cell arrays
    checkVectorSize(m);
    auto nfields = mxGetNumberOfElements(m);
    Array<ElemT> array(nfields);
    for(mwSize n=0; n<nfields; n++) array[n] = getAsScalar<ElemT>(mxGetCell(m,n));
    return array;
}

template<class ElemT>
MexIFace::Dict<ElemT> MexIFace::getAsScalarDict(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    checkType(m,mxSTRUCT_CLASS); //Only accept structs arrays
    checkScalarSize(m); //Should be a scalar struct not a struct array
    Dict<ElemT> dict;
    for(int i=0; i<mxGetNumberOfFields(m); i++)
        dict[mxGetFieldNameByNumber(m,i)] = getAsScalar<ElemT>(mxGetFieldByNumber(m,0,i));
    return dict;

}


template<template<typename...> class Array>
Array<std::string>  MexIFace::getStringArray(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];  //Default to first unhandled rhs argument
    checkType(m,mxCELL_CLASS);
    checkVectorSize(m); //Should be 1D
    auto nfields = mxGetNumberOfElements(m);
    Array<std::string> array(nfields);
    for(mwSize n=0; n<nfields; n++) array[n] = getString(mxGetCell(m,n));
    return array;
}


/** Get exact type.  No conversions.
 * 
 */
template<class ElemT, typename> 
ElemT MexIFace::getScalar(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    return checkedToScalar<ElemT>(m);
}

/** @brief Create a armadillo Column vector to directly use the Matlab data for a 1D array of
 *   arbitrary element type.
 *
 * @param m Pointer to the mxArray to be interpreted.  (Default=nullptr).  If nullptr then use next rhs param.
 * @returns New armadillo array that re-uses the same data stored in the m pointer.
 */
template<class ElemT, typename> 
MexIFace::Vec<ElemT> MexIFace::getVec(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    return checkedToVec<ElemT>(m);
}


/** @brief Create an armadillo Mat object to directly work with the Matlab data for a 2D array of
 *   arbitrary element type.
 *
 * @param m The pointer to the mxArray that is to be interpreted as an armadillo array.
 * @returns A new armadillo array that interprets the data stored in the m pointer.
 */
template<class ElemT, typename> 
MexIFace::Mat<ElemT> MexIFace::getMat(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    return checkedToMat<ElemT>(m);
}

/** @brief Create an armadillo Cube object to directly work with the Matlab data for a 3D array of
*   arbitrary element type.
*
* @param m The pointer to the mxArray that is to be interpreted as an armadillo array.
* @returns A new armadillo array that interprets the data stored in the m pointer.
*/
template<class ElemT, typename> 
MexIFace::Cube<ElemT> MexIFace::getCube(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    return checkedToCube<ElemT>(m);
}


/** @brief Create an Hypercube object to directly work with the Matlab data for a 4D array of
*   arbitrary element type.
*
* Uses the ability of the armadillo arrays to interpret raw data passed to it as preallocated
* column major format.   This allows us to open the array data in C++ using Matlab's memory
* directly instead of having to allocate a separate space and copy.
*
* @param m The pointer to the mxArray that is to be interpreted as an armadillo array.
* @returns A new Hypercube that interprets the data stored in the m pointer.
*/
template<class ElemT, typename> 
Hypercube<ElemT> MexIFace::getHypercube(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    return checkedToHypercube<ElemT>(m);
}

template<template<typename> class NumericArrayT, class ElemT>
NumericArrayT<ElemT> MexIFace::getNumeric(const mxArray *m)
{
    auto func=GetNumericFunctor<NumericArrayT,ElemT>();
    return func(this,m);
}

template<template<typename...> class Array, class ElemT>
Array<ElemT> MexIFace::getScalarArray(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];  //Default to first unhandled rhs argument
    checkType(m,mxCELL_CLASS);
    checkVectorSize(m); //Should be 1D
    auto nfields = mxGetNumberOfElements(m);
    Array<ElemT> array(nfields);
    for(mwSize n=0; n<nfields; n++) array[n] = getScalar<ElemT>(mxGetCell(m,n));
    return array;
}


// template<template<typename> class Array, class ElemT, typename>
// Array<ElemT> MexIFace::getScalarArray(const mxArray *m)
// {
//     if(m == nullptr) m = rhs[rhs_idx++];  //Default to first unhandled rhs argument
//     checkType(m,mxCELL_CLASS);
//     checkVectorSize(m); //Should be 1D
//     auto nfields = mxGetNumberOfElements(m);
//     Array<ElemT> array(nfields);
//     for(auto n=0; n<nfields; n++) array[n] = getScalar<ElemT>(mxGetCell(m,n));
//     return array;
// }

template<template<typename> class Array, class ElemT, typename> 
Array<MexIFace::Vec<ElemT>> MexIFace::getVecArray(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];  //Default to first unhandled rhs argument    
    checkType(m, mxCELL_CLASS);
    checkVectorSize(m); //Should be 1D
    auto nfields = mxGetNumberOfElements(m);
    Array<ElemT> array(nfields);
    for(mwSize n=0; n<nfields; n++) array[n] = getVec<ElemT>(mxGetCell(m,n));
    return array;
}

template<template<typename> class Array, class ElemT, typename> 
Array<MexIFace::Mat<ElemT>> MexIFace::getMatArray(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];  //Default to first unhandled rhs argument    
    checkType(m, mxCELL_CLASS);
    checkVectorSize(m); //Should be 1D
    auto nfields = mxGetNumberOfElements(m);
    Array<ElemT> array(nfields);
    for(mwSize n=0; n<nfields; n++) array[n] = getMat<ElemT>(mxGetCell(m,n));
    return array;
}

template<template<typename> class Array, class ElemT, typename> 
Array<MexIFace::Cube<ElemT>> MexIFace::getCubeArray(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];  //Default to first unhandled rhs argument    
    checkType(m, mxCELL_CLASS);
    checkVectorSize(m); //Should be 1D
    auto nfields = mxGetNumberOfElements(m);
    Array<ElemT> array(nfields);
    for(mwSize n=0; n<nfields; n++) array[n] = getCube<ElemT>(mxGetCell(m,n));
    return array;
}


template<template<typename> class Array, class ElemT, typename> 
Array<Hypercube<ElemT>> MexIFace::getHypercubeArray(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];  //Default to first unhandled rhs argument    
    checkType(m, mxCELL_CLASS);
    checkVectorSize(m); //Should be 1D
    auto nfields = mxGetNumberOfElements(m);
    Array<ElemT> array(nfields);
    for(mwSize n=0; n<nfields; n++) array[n] = getHypercube<ElemT>(mxGetCell(m,n));
    return array;
}

template<class ElemT, typename>
MexIFace::Dict<ElemT> MexIFace::getScalarDict(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    checkType(m, mxSTRUCT_CLASS); //Only accept structs arrays
    checkScalarSize(m); //Should be a scalar struct not a struct array
    Dict<ElemT> dict;
    for(auto i=0; i<mxGetNumberOfFields(m); i++)
        dict[mxGetFieldNameByNumber(m,i)] = getScalar<ElemT>(mxGetFieldByNumber(m,0,i));
    return dict;
}

template<class ElemT, typename>
MexIFace::Dict<MexIFace::Vec<ElemT>> MexIFace::getVecDict(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    checkType(m, mxSTRUCT_CLASS); //Only accept structs arrays
    checkScalarSize(m); //Should be a scalar struct not a struct array
    Dict<Vec<ElemT>> dict;
    for(auto i=0; i<mxGetNumberOfFields(m); i++)
        dict[mxGetFieldNameByNumber(m,i)] = getVec<ElemT>(mxGetFieldByNumber(m,0,i));
    return dict;
}

template<class ElemT, typename>
MexIFace::Dict<MexIFace::Mat<ElemT>> MexIFace::getMatDict(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    checkType(m, mxSTRUCT_CLASS); //Only accept structs arrays
    checkScalarSize(m); //Should be a scalar struct not a struct array
    Dict<Mat<ElemT>> dict;
    for(auto i=0; i<mxGetNumberOfFields(m); i++)
        dict[mxGetFieldNameByNumber(m,i)] = getMat<ElemT>(mxGetFieldByNumber(m,0,i));
    return dict;
}

template<class ElemT, typename>
MexIFace::Dict<MexIFace::Cube<ElemT>> MexIFace::getCubeDict(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    checkType(m, mxSTRUCT_CLASS); //Only accept structs arrays
    checkScalarSize(m); //Should be a scalar struct not a struct array
    Dict<Cube<ElemT>> dict;
    for(auto i=0; i<mxGetNumberOfFields(m); i++)
        dict[mxGetFieldNameByNumber(m,i)] = getCube<ElemT>(mxGetFieldByNumber(m,0,i));
    return dict;
}

template<class ElemT, typename>
MexIFace::Dict<Hypercube<ElemT>> MexIFace::getHypercubeDict(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    checkType(m, mxSTRUCT_CLASS); //Only accept structs arrays
    checkScalarSize(m); //Should be a scalar struct not a struct array
    Dict<Hypercube<ElemT>> dict;
    for(auto i=0; i<mxGetNumberOfFields(m); i++)
        dict[mxGetFieldNameByNumber(m,i)] = getHypercube<ElemT>(mxGetFieldByNumber(m,0,i));
    return dict;
}

/* make methods use matlab to allocate the data as mxArrays and then
 * share the pointer access through a armadillo object for maximum speed */

template<class ElemT, typename> 
MexIFace::Vec<ElemT> MexIFace::makeOutputArray(IdxT nelem)
{
    auto m = mxCreateNumericMatrix(nelem, 1,get_mx_class<ElemT>(), mxREAL);
    lhs[lhs_idx++] = m;
    return Vec<ElemT>(static_cast<ElemT*>(mxGetData(m)), nelem, false);
}

template<class ElemT, typename> 
MexIFace::Mat<ElemT> MexIFace::makeOutputArray(IdxT rows, IdxT cols)
{
    auto m = mxCreateNumericMatrix(rows, cols, get_mx_class<ElemT>(), mxREAL);
    lhs[lhs_idx++] = m;
    return Mat<ElemT>(static_cast<ElemT*>(mxGetData(m)), rows, cols, false);
}

template<class ElemT, typename> 
MexIFace::Cube<ElemT> MexIFace::makeOutputArray(IdxT rows, IdxT cols, IdxT slices)
{
    const mwSize size[3] = {rows,cols,slices};
    auto m = mxCreateNumericArray(3,size,get_mx_class<ElemT>(), mxREAL);
    lhs[lhs_idx++] = m;
    return Cube<ElemT>(static_cast<ElemT*>(mxGetData(m)),rows,cols,slices, false);
}

template<class ElemT, typename> 
Hypercube<ElemT> MexIFace::makeOutputArray(IdxT rows, IdxT cols, IdxT slices, IdxT hyperslices)
{
    const mwSize size[4] = {rows,cols,slices,hyperslices};
    auto m = mxCreateNumericArray(4,size,get_mx_class<ElemT>(), mxREAL);
    lhs[lhs_idx++] = m;
    return Hypercube<ElemT>(static_cast<ElemT*>(mxGetData(m)),rows,cols,slices,hyperslices);
}

/* ouptput methods make a new matlab object copying in data from arguments
 */

inline
void MexIFace::output(mxArray *m)
{
    lhs[lhs_idx++] = m;
}

template<class ConvertableT>
void MexIFace::output(ConvertableT&& val)
{
    output(toMXArray(std::forward<ConvertableT>(val)));
}

// template<template<typename> class ConvertableTemplateT>
// void MexIFace::output(ConvertableT&& val)
// {
//     output(toMXArray(std::forward<ConvertableT>(val)));
// }


/** @brief Helper function to set the internal copies of the left-hand-side and right-hand-side parameters
 *  as they were passed to the mexFunction.
 */
inline
void MexIFace::setArguments(MXArgCountT _nlhs, mxArray *_lhs[], MXArgCountT _nrhs, const mxArray *_rhs[])
{
    nlhs = _nlhs;
    lhs = _lhs;
    nrhs = _nrhs;
    rhs = _rhs;
    lhs_idx = 0;
    rhs_idx = 0;
}

/** @brief Remove the first right-hand-side (input) argument as it has already been used to find the correct command
 */
inline
void MexIFace::popRhs()
{
    nrhs--; 
    rhs += 1;
}


} /* namespace mexiface */


#endif /* MEXIFACE_MEXIFACE_H */
