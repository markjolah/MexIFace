/** @file MexIFace.h
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2013-2017
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief The class declaration and inline and templated functions for MexIFace.
 */

#ifndef _MEXIFACE_H
#define _MEXIFACE_H

#include <sstream>
#include <map>
#include <vector>
#include <list>
#include <algorithm>

#include <armadillo>

#include <boost/function.hpp>
#include <boost/bind.hpp>

#include "mex.h"
#include "hypercube.h"
#include "Handle.h"

#include "explore.h"
#include "MexUtils.h"

namespace mexiface {

/** @class MexIFace 
 * @brief Acts as a base class for implementing a C++ class <--> Matlab class interface.
 *
 * The MexIFace class provides a generic means of wrapping a C++ class as a Matlab MEX function, that
 * can then be exposed as a Matlab class.  This flexibility allows the code to be used in an
 * object-oriented style either from other C++ code or from Matlab.
 *
 * This type of interface is necessary because a Matlab .mex plug-in can only act as a Matlab function, not
 * a Matlab class.  The MexIFace class exposes a mexFunction method which takes in a variable number of arguments
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
 * arguments and return no arguments.  The matlab arguments are passed to these functions through the internal storage of the
 * MexIFace object's rhs and lhs member variables.
 *
 * A C++ class is wrapped by creating a new Iface class that inherits from MexIFace.  At a minimum
 * the Iface class must define the pure virtual functions objConstruct(), objDestroy(), and getObjectFromHandle().  It also
 * must implement the interface for any of the methods and static methods that are required.  Each of these methods in the
 * Iface class must process the passed matlab arguments in the rhs member variable and save outputs in the lhs member variable.
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
class MexIFace {
public:
    using IdxT = arma::uword; /* A logical type for an unsigned integer index */
    using BoolT = uint16_t;
    typedef std::map<std::string,double> StatsT; /**< A convenient form for reporting dictionaries of named FP data to matlab */
    typedef std::map<std::string,arma::Col<double>> VecStatsT; /**< A convenient form for reporting dictionaries of named FP vector (or) scalar data to matlab */
    template<class T> using VectorVector = std::vector<std::vector<T>>; //Alias template for a std::vector of std::vectors
    template<class T> using VectorList = std::vector<std::list<T>>; //Alias template for a std::vector of std::vectors
    template<class T> using VecField = arma::field<arma::Col<T>>; //Alias template for a field of vecs
    template<class T> using MatField = arma::field<arma::Mat<T>>; //Alias template for a field of mats
    template<class T> using CubeField = arma::field<arma::Cube<T>>; //Alias template for a field of cubes
    template<class T> using VecVector = std::vector<arma::Col<T>>; //Alias template for a std::vector of vecs
    template<class T> using MatVector = std::vector<arma::Mat<T>>; //Alias template for a std::vector of mats
    template<class T> using CubeVector = std::vector<arma::Cube<T>>; //Alias template for a std::vector of cubes
    
    
    std::string mex_name; /**< A name to use when reporting errors to Matlab */

    MexIFace(std::string name);
    void mexFunction(unsigned _nlhs, mxArray *_lhs[], unsigned _nrhs, const mxArray *_rhs[]);
protected:
    static unsigned constexpr MAX_STR_LEN=512; /**< Maximum length of string we will accept from Matlab */

    typedef std::map<std::string, boost::function<void()>> MethodMap; /**< The type of mapping for mapping names to member functions to call */
    MethodMap methodmap; /**< A map from names to wrapped member functions to be called */
    MethodMap staticmethodmap; /**< A map from names to wrapped static member functions to be called */

    unsigned nlhs; /**< The number of lhs (output) arguments asked for */
    mxArray **lhs; /**< The lhs (output) arguments to be returned */
    int lhs_idx=0; /**< The index of the next lhs argument to write as output */
    unsigned nrhs; /**< The number of rhs (input) arguments given */
    const mxArray **rhs; /**< The rhs (input) arguments given */
    int rhs_idx=0; /**< The index of the next rhs argument to read as input */

    /* Methods to be overloaded by subclass */

    /**
     * @brief Called when the mexFunction gets the \@new command, passing on the remaining input arguments.
     *
     * The rhs should have a single output argument which is the handle (number) which corresponds to the
     * wrapped object.
     *
     * This pure virtual function must be overloaded by the Iface subclass.
     */
    virtual void objConstruct() =0;

    /**
     * @brief Called when the mexFunction gets the \@delete command, passing on the remaining input arguments.
     *
     * The rhs should be empty, and the lhs (input) should only be given the object handle that was created by a
     * \@new command.
     *
     * This pure virtual function must be overloaded by the Iface subclass.
     */
    virtual void objDestroy()=0;

    /**
     * @brief This is a helper method which saves a pointer to the wrapped class's object in an internal member variable called obj.
     *
     * This is not templated on the wrapped class type, so it must be implemented by the IFace subclass.
     * @param mxhandle The mxArray where the handle is stored.
     */
    virtual void getObjectFromHandle(const mxArray *mxhandle) =0;

    void callMethod(std::string name);
    void callStaticMethod(std::string name);

    /* methods to check the number and shape of arguments */
    void checkMinNumArgs(int min_nlhs, int min_nrhs) const;
    void checkMaxNumArgs(int max_nlhs, int max_nrhs) const;
    void checkNumArgs(int nlhs, int nrhs) const;
    void checkSameLastDim(const mxArray *m1, const mxArray *m2) const;
    void checkDim(const mxArray *m, int rows, int cols) const;
    
    /* Methods to get simple datatypes from matlab */
    bool getBool(const mxArray *mxdata=nullptr);
    int getInt(const mxArray *mxdata=nullptr);
    unsigned getUnsigned(const mxArray *mxdata=nullptr);
    float getFloat(const mxArray *mxdata=nullptr);
    double getDouble(const mxArray *mxdata=nullptr);
    template<class ElemT> ElemT getScalar(const mxArray *mxdata=nullptr);
    
    std::string getString(const mxArray *mxdata=nullptr);
    StatsT getDoubleStruct(const mxArray *mxdata=nullptr);
    VecStatsT getDoubleVecStruct(const mxArray *mxdata=nullptr);
    
    arma::Col<uint16_t> getU16Vec(const mxArray *mxdata=nullptr);
    arma::Col<uint32_t> getUVec(const mxArray *mxdata=nullptr);
    arma::Col<int32_t> getIVec(const mxArray *mxdata=nullptr);
    arma::Col<float> getFVec(const mxArray *mxdata=nullptr);
    arma::Col<double> getDVec(const mxArray *mxdata=nullptr);
    template<class ElemT> arma::Col<ElemT> getVec(const mxArray *mxdata=nullptr);
    arma::Mat<uint16_t> getU16Mat(const mxArray *mxdata=nullptr);
    arma::Mat<uint32_t> getUMat(const mxArray *mxdata=nullptr);
    arma::Mat<int32_t> getIMat(const mxArray *mxdata=nullptr);
    arma::Mat<float> getFMat(const mxArray *mxdata=nullptr);
    arma::Mat<double> getDMat(const mxArray *mxdata=nullptr);
    template<class ElemT> arma::Mat<ElemT> getMat(const mxArray *mxdata=nullptr);
    arma::Cube<uint16_t> getU16Stack(const mxArray *mxdata=nullptr);
    arma::Cube<uint32_t> getUStack(const mxArray *mxdata=nullptr);
    arma::Cube<int32_t> getIStack(const mxArray *mxdata=nullptr);
    arma::Cube<float> getFStack(const mxArray *mxdata=nullptr);
    arma::Cube<double> getDStack(const mxArray *mxdata=nullptr);
    template<class ElemT> arma::Cube<ElemT> getStack(const mxArray *mxdata=nullptr);
    Hypercube<uint16_t> getU16HyperStack(const mxArray *mxdata=nullptr);
    Hypercube<uint32_t> getUHyperStack(const mxArray *mxdata=nullptr);
    Hypercube<int32_t> getIHyperStack(const mxArray *mxdata=nullptr);
    Hypercube<float> getFHyperStack(const mxArray *mxdata=nullptr);
    Hypercube<double> getDHyperStack(const mxArray *mxdata=nullptr);
    template<class ElemT> Hypercube<ElemT> getHyperStack(const mxArray *mxdata=nullptr);

    
    
    template<class ElemT> VecField<ElemT> getVecField(const mxArray *mxdata=nullptr);
    template<class ElemT> MatField<ElemT> getMatField(const mxArray *mxdata=nullptr);
    template<class ElemT> CubeField<ElemT> getCubeField(const mxArray *mxdata=nullptr);
    template<class ElemT> VecVector<ElemT> getVecVector(const mxArray *mxdata=nullptr);
    template<class ElemT> MatVector<ElemT> getMatVector(const mxArray *mxdata=nullptr);
    template<class ElemT> CubeVector<ElemT> getCubeVector(const mxArray *mxdata=nullptr);
    
    
    /* methods to make matlab objects */

    arma::Col<uint32_t> makeUVec(unsigned rows);
    arma::Col<int32_t> makeIVec(unsigned rows);
    arma::Col<float> makeFVec(unsigned rows);
    arma::Col<double> makeDVec(unsigned rows);
    template<class ElemT> arma::Col<ElemT> makeVec(unsigned nelem);

    arma::Mat<uint32_t> makeUMat(unsigned rows, unsigned cols);
    arma::Mat<int32_t> makeIMat(unsigned rows, unsigned cols);
    arma::Mat<float> makeFMat(unsigned rows, unsigned cols);
    arma::Mat<double> makeDMat(unsigned rows, unsigned cols);
    template<class ElemT> arma::Mat<ElemT> makeMat(unsigned rows, unsigned cols);

    arma::Cube<uint32_t> makeUStack(unsigned rows, unsigned cols, unsigned slices);
    arma::Cube<int32_t> makeIStack(unsigned rows, unsigned cols, unsigned slices);
    arma::Cube<float> makeFStack(unsigned rows, unsigned cols, unsigned slices);
    arma::Cube<double> makeDStack(unsigned rows, unsigned cols, unsigned slices);
    template<class ElemT> arma::Cube<ElemT> makeStack(unsigned rows, unsigned cols, unsigned slices);

    Hypercube<uint16_t> makeU16HyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices);
    Hypercube<uint32_t> makeUHyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices);
    Hypercube<int32_t> makeIHyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices);
    Hypercube<float> makeFHyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices);
    Hypercube<double> makeDHyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices);
    template<class ElemT> Hypercube<ElemT> makeHyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices);

    void outputMXArray(mxArray *m);

    template<class ElemT> void outputVec(const arma::Col<ElemT> &arr);
    void outputDouble(double val);
    void outputInt(int32_t val);
    void outputBool(bool val);
    
    void outputStatsToStruct(const StatsT &stats);
    void outputStatsToDoubleVecStruct(const VecStatsT &stats);
    
    void outputFVec(const arma::Col<float> &arr);
    template<int N> void outputDVec(const arma::Col<double>::fixed<N> &arr);
    void outputDVec(const arma::Col<double> &arr);

    template<class ElemT> void outputMat(const arma::Mat<ElemT> &arr);
    void outputIMat(const arma::Mat<int32_t> &arr);
    void outputDMat(const arma::Mat<double> &arr);

    template<class ElemT> void outputStack(const arma::Cube<ElemT> &arr);

    template<class ElemT> void outputSparse(const arma::SpMat<ElemT> &arr);

    template<class ElemT> void outputVecCellArray(const VectorVector<ElemT> &list);
    template<class ElemT> void outputVecCellArray(const VectorList<ElemT> &list);
    
    template<class ElemT> void outputVecCellArray(const VecVector<ElemT> &field);
    template<class ElemT> void outputMatCellArray(const MatVector<ElemT> &field);
    template<class ElemT> void outputCubeCellArray(const CubeVector<ElemT> &field);
    
    template<class ElemT> void outputVecCellArray(const VecField<ElemT> &field);
    template<class ElemT> void outputMatCellArray(const MatField<ElemT> &field);
    template<class ElemT> void outputCubeCellArray(const CubeField<ElemT> &field);
    


    /* Error reporting */
    void error(std::string condition, std::string message) const;
    void component_error(std::string component,std::string condition, std::string message) const;

    /* methods to manipulate the arguments */
    void popRhs();
    void setArguments(unsigned _nlhs, mxArray *_lhs[], unsigned _nrhs, const mxArray *_rhs[]);
private:
    mxArray* makeDouble(double val)const;
    std::string make_valid_error_mesgid(std::string component, std::string condition) const;
};


template<class ElemT>
ElemT MexIFace::getScalar(const mxArray *mxdata)
{
    if(mxdata==nullptr) mxdata=rhs[rhs_idx++];
    std::ostringstream msg;
    int ndims=mxGetNumberOfDimensions(mxdata);
    int M=mxGetM(mxdata);
    int N=mxGetN(mxdata);
    mxClassID classid=get_mx_class<ElemT>();
    if (mxGetClassID(mxdata)!=classid) {
        msg<<"getScalar: Expected Type:"<<get_mx_class_name(classid)<<" Got:"<<get_mx_class_name(mxdata);
        error("InputType",msg.str());
    } else if (ndims!=2) {
        msg<<"getScalar: Expected #dims==2. Got:"<<ndims;
        error("InputShape",msg.str());
    } else if (M>1 || N>1) {
        msg<<"getScalar: Expected scalar vector Got:("<<M<<" X "<<N<<")";
        error("InputShape",msg.str());
    }
    return *static_cast<ElemT*>(mxGetData(mxdata));
}


/**
 *@brief Create an armadillo Column vector to directly work with the Matlab data for a 1D array of
 *   arbitrary element type.
 *
 * Uses the ability of the armadillo arrays to interpret raw data passed to it as preallocated
 * column major format.   This allows us to open the array data in C++ using Matlab's memory
 * directly instead of having to allocate a separate space and copy.
 *
 * @param mxdata The pointer to the mxArray that is to be interpreted as an armadillo array.
 * @returns A new armadillo array that interprets the data stored in the mxdata pointer.
 */
template<class ElemT>
arma::Col<ElemT> MexIFace::getVec(const mxArray *mxdata)
{
    if(mxdata==nullptr) mxdata=rhs[rhs_idx++];
    std::ostringstream msg;
    int ndims=mxGetNumberOfDimensions(mxdata);
    int M=mxGetM(mxdata);
    int N=mxGetN(mxdata);
    mxClassID classid=get_mx_class<ElemT>();
    if (mxGetClassID(mxdata)!=classid) {
        msg<<"getVec: Expected Type:"<<get_mx_class_name(classid)<<" Got:"<<get_mx_class_name(mxdata);
        error("InputType",msg.str());
    } else if (ndims!=2) {
        msg<<"getVec: Expected #dims==2. Got:"<<ndims;
        error("InputShape",msg.str());
    } else if (M>1 && N>1) {
        msg<<"getVec: Expected 1D vector Got:("<<M<<" X "<<N<<")";
        error("InputShape",msg.str());
    }
    return arma::Col<ElemT>(static_cast<ElemT*>(mxGetData(mxdata)), mxGetNumberOfElements(mxdata), false);
}

/* Template specializations for various element types */
inline arma::Col<uint16_t> MexIFace::getU16Vec(const mxArray *mxdata) {return getVec<uint16_t>(mxdata);}
inline arma::Col<uint32_t> MexIFace::getUVec(const mxArray *mxdata) {return getVec<uint32_t>(mxdata);}
inline arma::Col<int32_t> MexIFace::getIVec(const mxArray *mxdata) {return getVec<int32_t>(mxdata);}
inline arma::Col<float> MexIFace::getFVec(const mxArray *mxdata) {return getVec<float>(mxdata);}
inline arma::Col<double> MexIFace::getDVec(const mxArray *mxdata) {return getVec<double>(mxdata);}


/**
 * @brief Create an armadillo Mat object to directly work with the Matlab data for a 2D array of
 *   arbitrary element type.
 *
 * Uses the ability of the armadillo arrays to interpret raw data passed to it as preallocated
 * column major format.   This allows us to open the array data in C++ using Matlab's memory
 * directly instead of having to allocate a separate space and copy.
 *
 * @param mxdata The pointer to the mxArray that is to be interpreted as an armadillo array.
 * @returns A new armadillo array that interprets the data stored in the mxdata pointer.
 */
template<class ElemT>
arma::Mat<ElemT> MexIFace::getMat(const mxArray *mxdata)
{
    if(mxdata==nullptr) mxdata=rhs[rhs_idx++];
    std::ostringstream msg;
    int ndims=mxGetNumberOfDimensions(mxdata);
    int M=mxGetM(mxdata);
    int N=mxGetN(mxdata);
    mxClassID classid=get_mx_class<ElemT>();
    if (mxGetClassID(mxdata)!=classid) {
        msg<<"getMat: Expected Type:"<<get_mx_class_name(classid)<<" Got:"<<get_mx_class_name(mxdata);
        error("InputType",msg.str());
    } else if (ndims!=2) {
        msg<<"getMat: Expected #dims==2. Got:"<<ndims;
        error("InputShape",msg.str());
    }
    return arma::Mat<ElemT>(static_cast<ElemT*>(mxGetData(mxdata)), M, N,false);
}

/* Template specializations for various element types */
inline arma::Mat<uint16_t> MexIFace::getU16Mat(const mxArray *mxdata) {return getMat<uint16_t>(mxdata);}
inline arma::Mat<uint32_t> MexIFace::getUMat(const mxArray *mxdata) {return getMat<uint32_t>(mxdata);}
inline arma::Mat<int32_t> MexIFace::getIMat(const mxArray *mxdata) {return getMat<int32_t>(mxdata);}
inline arma::Mat<float> MexIFace::getFMat(const mxArray *mxdata) {return getMat<float>(mxdata);}
inline arma::Mat<double> MexIFace::getDMat(const mxArray *mxdata) {return getMat<double>(mxdata);}




/**
* @brief Create an armadillo Cube object to directly work with the Matlab data for a 3D array of
*   arbitrary element type.
*
* Uses the ability of the armadillo arrays to interpret raw data passed to it as preallocated
* column major format.   This allows us to open the array data in C++ using Matlab's memory
* directly instead of having to allocate a separate space and copy.
*
* @param mxdata The pointer to the mxArray that is to be interpreted as an armadillo array.
* @returns A new armadillo array that interprets the data stored in the mxdata pointer.
*/
template<class ElemT>
arma::Cube<ElemT> MexIFace::getStack(const mxArray *mxdata)
{
    if(mxdata==nullptr) mxdata=rhs[rhs_idx++];
    std::ostringstream msg;
    int ndims=mxGetNumberOfDimensions(mxdata);
    int M=mxGetM(mxdata);
    int N=mxGetN(mxdata);
    mxClassID classid=get_mx_class<ElemT>();
    if (mxGetClassID(mxdata)!=classid) {
        msg<<"getStack: Expected Type:"<<get_mx_class_name(classid)<<"  Got:"<<get_mx_class_name(mxdata);
        error("InputType",msg.str());
    } else if (ndims>3) {
        msg<<"getStack: Expected #dims==3.  Got:"<<ndims;
        error("InputShape",msg.str());
    } else if (M<=1 || N<=1) {
        msg<<"getStack: Expected 3D stack Got:("<<M<<" X "<<N<<")";
        error("InputShape",msg.str());
    } else if (ndims==2) {
        //This is effectively a 1slice-stack.
        //Matlab automatically removes extra dims of size 1.
        return arma::Cube<ElemT>(static_cast<ElemT*>(mxGetData(mxdata)),M,N,1,false);
    }
    const mwSize *size=mxGetDimensions(mxdata);
    return arma::Cube<ElemT>(static_cast<ElemT*>(mxGetData(mxdata)),size[0],size[1],size[2], false);
}

/* Template specializations for various element types */
inline arma::Cube<uint16_t> MexIFace::getU16Stack(const mxArray *mxdata) {return getStack<uint16_t>(mxdata);}
inline arma::Cube<uint32_t> MexIFace::getUStack(const mxArray *mxdata) {return getStack<uint32_t>(mxdata);}
inline arma::Cube<int32_t> MexIFace::getIStack(const mxArray *mxdata) {return getStack<int32_t>(mxdata);}
inline arma::Cube<float> MexIFace::getFStack(const mxArray *mxdata) {return getStack<float>(mxdata);}
inline arma::Cube<double> MexIFace::getDStack(const mxArray *mxdata) {return getStack<double>(mxdata);}

/**
* @brief Create an Hypercube object to directly work with the Matlab data for a 4D array of
*   arbitrary element type.
*
* Uses the ability of the armadillo arrays to interpret raw data passed to it as preallocated
* column major format.   This allows us to open the array data in C++ using Matlab's memory
* directly instead of having to allocate a separate space and copy.
*
* @param mxdata The pointer to the mxArray that is to be interpreted as an armadillo array.
* @returns A new Hypercube that interprets the data stored in the mxdata pointer.
*/
template<class ElemT>
Hypercube<ElemT> MexIFace::getHyperStack(const mxArray *mxdata)
{
    if(mxdata==nullptr) mxdata=rhs[rhs_idx++];
    std::ostringstream msg;
    int ndims=mxGetNumberOfDimensions(mxdata);
    const mwSize *size=mxGetDimensions(mxdata);
    mxClassID classid=get_mx_class<ElemT>();
    if (mxGetClassID(mxdata)!=classid) {
        msg<<"getHyperStack: Expected Type:"<<get_mx_class_name(classid)<<" Got:"<<get_mx_class_name(mxdata);
        error("InputType",msg.str());
    } else if (ndims<3 || ndims>4)  {
        msg<<"getHyperStack: Expected #dims==4. Got:"<<ndims;
        error("InputShape",msg.str());
    } else if (size[0]<=1 || size[1]<=1) {
        msg<<"getHyperStack: Expected 4D stack Got Dim:"<<ndims<<" size:("<<size[0]<<","<<size[1]<<","<<size[2];
        if(ndims==4)  msg<<","<<size[3];
        msg<<")";
        error("InputShape",msg.str());
    } else if (ndims==3) {
        //This is effectively a 1slice-stack.
        //Matlab automatically removes extra dims of size 1.
        return Hypercube<ElemT>(static_cast<ElemT*>(mxGetData(mxdata)),size[0],size[1],size[2],1);
    }
    return Hypercube<ElemT>(static_cast<ElemT*>(mxGetData(mxdata)),size[0],size[1],size[2],size[3]);
}

/* Template specializations for various element types */
inline Hypercube<uint16_t> MexIFace::getU16HyperStack(const mxArray *mxdata) {return getHyperStack<uint16_t>(mxdata);}
inline Hypercube<uint32_t> MexIFace::getUHyperStack(const mxArray *mxdata) {return getHyperStack<uint32_t>(mxdata);}
inline Hypercube<int32_t> MexIFace::getIHyperStack(const mxArray *mxdata) {return getHyperStack<int32_t>(mxdata);}
inline Hypercube<float> MexIFace::getFHyperStack(const mxArray *mxdata) {return getHyperStack<float>(mxdata);}
inline Hypercube<double> MexIFace::getDHyperStack(const mxArray *mxdata) {return getHyperStack<double>(mxdata);}





template<class ElemT> 
MexIFace::VecField<ElemT> 
MexIFace::getVecField(const mxArray *mxdata)
{
    if(mxdata==nullptr) mxdata=rhs[rhs_idx++];  //Default to first unhandled rhs argument
    std::ostringstream msg;
    mwSize nfields = mxGetNumberOfElements(mxdata);
    int ndims = mxGetNumberOfDimensions(mxdata);
    int M = mxGetM(mxdata);
    int N = mxGetN(mxdata);
    if (mxGetClassID(mxdata)!=mxCELL_CLASS) {
        msg<<"getVecField: Expected Type Cell array, but Got:"<<get_mx_class_name(mxdata);
        error("InputType",msg.str());
    } else if (ndims!=2) {
        msg<<"getVecField: Expected #dims==2.  Got:"<<ndims;
        error("InputShape",msg.str());
    } else if (M>1 && N>1) {
        msg<<"getVecField: Expected 1D vector Got:("<<M<<" X "<<N<<")";
        error("InputShape",msg.str());
    }
    
    VecField<ElemT> field(nfields); //Make new vector field
    mxClassID classid=get_mx_class<ElemT>();
    for(mwSize n=0; n<nfields; n++){
        const mxArray *arr = mxGetCell(mxdata,n);
        ndims = mxGetNumberOfDimensions(arr);
        M = mxGetM(arr);
        N = mxGetN(arr);
        if (mxGetClassID(arr)!=classid) {
            msg<<"getVecField: Element:"<<n+1<<" Expected Type: "<<get_mx_class_name(classid)<<" Got:"<<get_mx_class_name(arr);
            error("InputType",msg.str());
        } else if (ndims!=2) {
            msg<<"getVecField: Expected #dims==2.  Got:"<<ndims;
            error("InputShape",msg.str());
        } else if (M>1 && N>1) {
            msg<<"getVecField: Expected 1D cell-array Got:("<<M<<" X "<<N<<")";
            error("InputShape",msg.str());
        }
        field(n) = arma::Col<ElemT>(static_cast<ElemT*>(mxGetData(arr)), mxGetNumberOfElements(arr), false);
    }
    return field;
}

template<class ElemT> 
MexIFace::MatField<ElemT> 
MexIFace::getMatField(const mxArray *mxdata)
{
    if(mxdata==nullptr) mxdata=rhs[rhs_idx++];  //Default to first unhandled rhs argument
    std::ostringstream msg;
    mwSize nfields = mxGetNumberOfElements(mxdata);
    int ndims = mxGetNumberOfDimensions(mxdata);
    int M = mxGetM(mxdata);
    int N = mxGetN(mxdata);
    if (mxGetClassID(mxdata)!=mxCELL_CLASS) {
        msg<<"getMatField: Expected Type Cell array, but Got:"<<get_mx_class_name(mxdata);
        error("InputType",msg.str());
    } else if (ndims!=2) {
        msg<<"getMatField: Expected #dims==2.  Got:"<<ndims;
        error("InputShape",msg.str());
    } else if (M>1 && N>1) {
        msg<<"getMatField: Expected 1D cell-array Got:("<<M<<" X "<<N<<")";
        error("InputShape",msg.str());
    }
    
    VecField<ElemT> field(nfields); //Make new vector field
    mxClassID classid=get_mx_class<ElemT>();
    for(mwSize n=0; n<nfields; n++){
        const mxArray *arr = mxGetCell(mxdata,n);
        ndims = mxGetNumberOfDimensions(arr);
        M = mxGetM(arr);
        N = mxGetN(arr);
        if (mxGetClassID(arr)!=classid) {
            msg<<"getMatField: Expected Type:"<<get_mx_class_name(classid)<<" Got:"<<get_mx_class_name(arr);
            error("InputType",msg.str());
        } else if (ndims!=2) {
            msg<<"getMatField: Expected #dims==2. Got:"<<ndims;
            error("InputShape",msg.str());
        }
        field(n) = arma::Mat<ElemT>(static_cast<ElemT*>(mxGetData(arr)), M, N,false);
    }
    return field;
}

template<class ElemT> 
MexIFace::CubeField<ElemT> 
MexIFace::getCubeField(const mxArray *mxdata)
{
    if(mxdata==nullptr) mxdata=rhs[rhs_idx++];  //Default to first unhandled rhs argument
    std::ostringstream msg;
    mwSize nfields = mxGetNumberOfElements(mxdata);
    int ndims = mxGetNumberOfDimensions(mxdata);
    int M = mxGetM(mxdata);
    int N = mxGetN(mxdata);
    if (mxGetClassID(mxdata)!=mxCELL_CLASS) {
        msg<<"getCubeField: Expected Type Cell array, but Got:"<<get_mx_class_name(mxdata);
        error("InputType",msg.str());
    } else if (ndims!=2) {
        msg<<"getCubeField: Expected #dims==2.  Got:"<<ndims;
        error("InputShape",msg.str());
    } else if (M>1 && N>1) {
        msg<<"getCubeField: Expected 1D cell-array Got:("<<M<<" X "<<N<<")";
        error("InputShape",msg.str());
    }
    
    VecField<ElemT> field(nfields); //Make new vector field
    mxClassID classid=get_mx_class<ElemT>();
    for(mwSize n=0; n<nfields; n++){
        const mxArray *arr = mxGetCell(mxdata,n);
        ndims = mxGetNumberOfDimensions(arr);
        M = mxGetM(arr);
        N = mxGetN(arr);
        if (mxGetClassID(arr)!=classid) {
            msg<<"getCubeField: Expected Type:"<<get_mx_class_name(classid)<<"  Got:"<<get_mx_class_name(arr);
            error("InputType",msg.str());
        } else if (ndims>3) {
            msg<<"getCubeField: Expected #dims==3.  Got:"<<ndims;
            error("InputShape",msg.str());
        } else if (M<=1 || N<=1) {
            msg<<"getCubeField: Expected 3D stack Got:("<<M<<" X "<<N<<")";
            error("InputShape",msg.str());
        } else if (ndims==2) {
            //This is effectively a 1slice-stack.
            //Matlab automatically removes extra dims of size 1.
            field(n) = arma::Cube<ElemT>(static_cast<ElemT*>(mxGetData(arr)),M,N,1,false);
        } else {
            const mwSize *size = mxGetDimensions(arr);
            field(n) = arma::Cube<ElemT>(static_cast<ElemT*>(mxGetData(arr)),size[0],size[1],size[2], false);
        }
    }
    return field;
}

template<class ElemT> 
MexIFace::VecVector<ElemT> 
MexIFace::getVecVector(const mxArray *mxdata)
{
    if(mxdata==nullptr) mxdata=rhs[rhs_idx++];  //Default to first unhandled rhs argument
    std::ostringstream msg;
    mwSize nfields = mxGetNumberOfElements(mxdata);
    int ndims = mxGetNumberOfDimensions(mxdata);
    int M = mxGetM(mxdata);
    int N = mxGetN(mxdata);
    if (mxGetClassID(mxdata)!=mxCELL_CLASS) {
        msg<<"getVecVector: Expected Type Cell array, but Got:"<<get_mx_class_name(mxdata);
        error("InputType",msg.str());
    } else if (ndims!=2) {
        msg<<"getVecVector: Expected #dims==2.  Got:"<<ndims;
        error("InputShape",msg.str());
    } else if (M>1 && N>1) {
        msg<<"getVecVector: Expected 1D vector Got:("<<M<<" X "<<N<<")";
        error("InputShape",msg.str());
    }
    
    VecVector<ElemT> vec; //Make new vector 
    mxClassID classid=get_mx_class<ElemT>();
    for(mwSize n=0; n<nfields; n++){
        const mxArray *arr = mxGetCell(mxdata,n);
        ndims = mxGetNumberOfDimensions(arr);
        M = mxGetM(arr);
        N = mxGetN(arr);
        if (mxGetClassID(arr)!=classid) {
            msg<<"getVecVector: Element:"<<n+1<<" Expected Type: "<<get_mx_class_name(classid)<<" Got:"<<get_mx_class_name(arr);
            error("InputType",msg.str());
        } else if (ndims!=2) {
            msg<<"getVecVector: Expected #dims==2.  Got:"<<ndims;
            error("InputShape",msg.str());
        } else if (M>1 && N>1) {
            msg<<"getVecVector: Expected 1D cell-array Got:("<<M<<" X "<<N<<")";
            error("InputShape",msg.str());
        }
        vec.emplace_back(static_cast<ElemT*>(mxGetData(arr)), mxGetNumberOfElements(arr), false);
    }
    return vec;
}

template<class ElemT> 
MexIFace::MatVector<ElemT> 
MexIFace::getMatVector(const mxArray *mxdata)
{
    if(mxdata==nullptr) mxdata=rhs[rhs_idx++];  //Default to first unhandled rhs argument
    std::ostringstream msg;
    mwSize nfields = mxGetNumberOfElements(mxdata);
    int ndims = mxGetNumberOfDimensions(mxdata);
    int M = mxGetM(mxdata);
    int N = mxGetN(mxdata);
    if (mxGetClassID(mxdata)!=mxCELL_CLASS) {
        msg<<"getMatVector: Expected Type Cell array, but Got:"<<get_mx_class_name(mxdata);
        error("InputType",msg.str());
    } else if (ndims!=2) {
        msg<<"getMatVector: Expected #dims==2.  Got:"<<ndims;
        error("InputShape",msg.str());
    } else if (M>1 && N>1) {
        msg<<"getMatVector: Expected 1D cell-array Got:("<<M<<" X "<<N<<")";
        error("InputShape",msg.str());
    }
    
    MatVector<ElemT> vec; //Make new vector field
    mxClassID classid=get_mx_class<ElemT>();
    for(mwSize n=0; n<nfields; n++){
        const mxArray *arr = mxGetCell(mxdata,n);
        ndims = mxGetNumberOfDimensions(arr);
        M = mxGetM(arr);
        N = mxGetN(arr);
        if (mxGetClassID(arr)!=classid) {
            msg<<"getMatVector: Expected Type:"<<get_mx_class_name(classid)<<" Got:"<<get_mx_class_name(arr);
            error("InputType",msg.str());
        } else if (ndims!=2) {
            msg<<"getMatVector: Expected #dims==2. Got:"<<ndims;
            error("InputShape",msg.str());
        }
        vec.emplace_back(static_cast<ElemT*>(mxGetData(arr)), M, N,false);
    }
    return vec;
}

template<class ElemT> 
MexIFace::CubeVector<ElemT> 
MexIFace::getCubeVector(const mxArray *mxdata)
{
    if(mxdata==nullptr) mxdata=rhs[rhs_idx++];  //Default to first unhandled rhs argument
    std::ostringstream msg;
    mwSize nfields = mxGetNumberOfElements(mxdata);
    int ndims = mxGetNumberOfDimensions(mxdata);
    int M = mxGetM(mxdata);
    int N = mxGetN(mxdata);
    if (mxGetClassID(mxdata)!=mxCELL_CLASS) {
        msg<<"getCubeVector: Expected Type Cell array, but Got:"<<get_mx_class_name(mxdata);
        error("InputType",msg.str());
    } else if (ndims!=2) {
        msg<<"getCubeVector: Expected #dims==2.  Got:"<<ndims;
        error("InputShape",msg.str());
    } else if (M>1 && N>1) {
        msg<<"getCubeVector: Expected 1D cell-array Got:("<<M<<" X "<<N<<")";
        error("InputShape",msg.str());
    }
    
    CubeVector<ElemT> vec; //Make new vector field
    mxClassID classid=get_mx_class<ElemT>();
    for(mwSize n=0; n<nfields; n++){
        const mxArray *arr = mxGetCell(mxdata,n);
        ndims = mxGetNumberOfDimensions(arr);
        M = mxGetM(arr);
        N = mxGetN(arr);
        if (mxGetClassID(arr)!=classid) {
            msg<<"getCubeVector: Expected Type:"<<get_mx_class_name(classid)<<"  Got:"<<get_mx_class_name(arr);
            error("InputType",msg.str());
        } else if (ndims>3) {
            msg<<"getCubeVector: Expected #dims==3.  Got:"<<ndims;
            error("InputShape",msg.str());
        } else if (M<=1 || N<=1) {
            msg<<"getCubeVector: Expected 3D stack Got:("<<M<<" X "<<N<<")";
            error("InputShape",msg.str());
        } else if (ndims==2) {
            //This is effectively a 1slice-stack.
            //Matlab automatically removes extra dims of size 1.
            vec.emplace_back(static_cast<ElemT*>(mxGetData(arr)),M,N,1,false);
        } else {
            const mwSize *size = mxGetDimensions(arr);
            vec.emplace_back(static_cast<ElemT*>(mxGetData(arr)),size[0],size[1],size[2], false);
        }
    }
    return vec;
}


/**
 * @brief Helper function to set the internal copies of the left-hand-side and right-hand-side parameters
 *  as they were passed to the mexFunction.
 */
inline
void MexIFace::setArguments(unsigned _nlhs, mxArray *_lhs[], unsigned _nrhs, const mxArray *_rhs[])
{
    nlhs=_nlhs;
    lhs=_lhs;
    nrhs=_nrhs;
    rhs=_rhs;
}

/**
 * @brief Remove the first right-hand-side (input) argument as it has already been used to find the correct command
 */
inline
void MexIFace::popRhs()
{
    nrhs--; 
    rhs+=1;
}


/* Inline functions and function templates */

template<class ElemT>
inline
arma::Col<ElemT>
MexIFace::makeVec(unsigned nelem)
{
    mxArray *arr=mxCreateNumericMatrix(nelem, 1,get_mx_class<ElemT>(), mxREAL);
    lhs[lhs_idx++]=arr;
    return getVec<ElemT>(arr);
}


template<class ElemT>
inline
arma::Mat<ElemT>
MexIFace::makeMat(unsigned rows, unsigned cols)
{
    mxArray *arr=mxCreateNumericMatrix(rows, cols, get_mx_class<ElemT>(), mxREAL);
    lhs[lhs_idx++]=arr;
    return getMat<ElemT>(arr);
}

template<class ElemT>
inline
arma::Cube<ElemT>
MexIFace::makeStack(unsigned rows, unsigned cols, unsigned slices)
{
    const mwSize size[3]={rows,cols,slices};
    mxArray *arr=mxCreateNumericArray(3,size,get_mx_class<ElemT>(), mxREAL);
    lhs[lhs_idx++]=arr;
    return getStack<ElemT>(arr);
}


template<class ElemT>
inline
Hypercube<ElemT>
MexIFace::makeHyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices)
{
    const mwSize size[4]={rows,cols,slices,hyperslices};
    mxArray *arr=mxCreateNumericArray(4,size,get_mx_class<ElemT>(), mxREAL);
    lhs[lhs_idx++]=arr;
    return getHyperStack<ElemT>(arr);
}

/* Template specializations for various element types */
inline arma::Col<uint32_t> MexIFace::makeUVec(unsigned nelem) {return makeVec<uint32_t>(nelem);}
inline arma::Col<int32_t> MexIFace::makeIVec(unsigned nelem) {return makeVec<int32_t>(nelem);}
inline arma::Col<float> MexIFace::makeFVec(unsigned nelem) {return makeVec<float>(nelem);}
inline arma::Col<double> MexIFace::makeDVec(unsigned nelem) {return makeVec<double>(nelem);}

inline arma::Mat<uint32_t> MexIFace::makeUMat(unsigned rows, unsigned cols) {return makeMat<uint32_t>(rows, cols);}
inline arma::Mat<int32_t> MexIFace::makeIMat(unsigned rows, unsigned cols) {return makeMat<int32_t>(rows, cols);}
inline arma::Mat<float> MexIFace::makeFMat(unsigned rows, unsigned cols) {return makeMat<float>(rows, cols);}
inline arma::Mat<double> MexIFace::makeDMat(unsigned rows, unsigned cols) {return makeMat<double>(rows, cols);}

inline arma::Cube<uint32_t> MexIFace::makeUStack(unsigned rows, unsigned cols, unsigned slices) {return makeStack<uint32_t>(rows, cols, slices);}
inline arma::Cube<int32_t> MexIFace::makeIStack(unsigned rows, unsigned cols, unsigned slices) {return makeStack<int32_t>(rows, cols, slices);}
inline arma::Cube<float> MexIFace::makeFStack(unsigned rows, unsigned cols, unsigned slices) {return makeStack<float>(rows, cols, slices);}
inline arma::Cube<double> MexIFace::makeDStack(unsigned rows, unsigned cols, unsigned slices) {return makeStack<double>(rows, cols, slices);}

inline Hypercube<uint16_t> MexIFace::makeU16HyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices) {return makeHyperStack<uint16_t>(rows, cols, slices, hyperslices);}
inline Hypercube<uint32_t> MexIFace::makeUHyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices) {return makeHyperStack<uint32_t>(rows, cols, slices, hyperslices);}
inline Hypercube<int32_t> MexIFace::makeIHyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices) {return makeHyperStack<int32_t>(rows, cols, slices, hyperslices);}
inline Hypercube<float> MexIFace::makeFHyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices) {return makeHyperStack<float>(rows, cols, slices, hyperslices);}
inline Hypercube<double> MexIFace::makeDHyperStack(unsigned rows, unsigned cols, unsigned slices, unsigned hyperslices) {return makeHyperStack<double>(rows, cols, slices, hyperslices);}


inline 
mxArray* MexIFace::makeDouble(double val) const
{
    mxArray *m=mxCreateNumericMatrix(1,1,mxDOUBLE_CLASS, mxREAL);
    double *dptr=mxGetPr(m);
    *dptr=val;
    return m;
}

template<class ElemT>
void MexIFace::outputVec(const arma::Col<ElemT> &arr)
{
    mxArray *out_arr=mxCreateNumericMatrix(arr.n_elem, 1, get_mx_class<ElemT>(), mxREAL);
    lhs[lhs_idx++]=out_arr;
    auto out_vec=getVec<ElemT>(out_arr);
    out_vec=arr; //copy
}

inline 
void MexIFace::outputFVec(const arma::Col<float> &arr)
{
    mxArray *out_arr=mxCreateNumericMatrix(arr.n_elem, 1, mxSINGLE_CLASS, mxREAL);
    lhs[lhs_idx++]=out_arr;
    auto out_vec=getFVec(out_arr);
    out_vec=arr; //copy
}


template<int N>
inline 
void MexIFace::outputDVec(const arma::Col<double>::fixed<N> &arr)
{
    mxArray *out_arr=mxCreateNumericMatrix(N, 1, mxDOUBLE_CLASS, mxREAL);
    lhs[lhs_idx++]=out_arr;
    auto out_vec=getDVec(out_arr);
    out_vec=arr; //copy
}

inline 
void MexIFace::outputDVec(const arma::Col<double> &arr)
{
    mxArray *out_arr=mxCreateNumericMatrix(arr.n_elem, 1, mxDOUBLE_CLASS, mxREAL);
    lhs[lhs_idx++]=out_arr;
    auto out_vec=getDVec(out_arr);
    out_vec=arr; //copy
}

template<class ElemT>
void MexIFace::outputMat(const arma::Mat<ElemT> &arr)
{
    mxArray *out_arr=mxCreateNumericMatrix(arr.n_rows, arr.n_cols, get_mx_class<ElemT>(), mxREAL);
    lhs[lhs_idx++]=out_arr;
    auto out_vec=getMat<ElemT>(out_arr);
    out_vec=arr; //copy
}


inline 
void MexIFace::outputIMat(const arma::Mat<int32_t> &arr)
{
    mxArray *out_arr=mxCreateNumericMatrix(arr.n_rows, arr.n_cols, mxINT32_CLASS, mxREAL);
    lhs[lhs_idx++]=out_arr;
    auto out_mat=getIMat(out_arr);
    out_mat=arr; //copy
}


inline 
void MexIFace::outputDMat(const arma::Mat<double> &arr)
{
    mxArray *out_arr=mxCreateNumericMatrix(arr.n_rows, arr.n_cols, mxDOUBLE_CLASS, mxREAL);
    lhs[lhs_idx++]=out_arr;
    auto out_mat=getDMat(out_arr);
    out_mat=arr; //copy
}


template<class ElemT>
void MexIFace::outputStack(const arma::Cube<ElemT> &arr)
{
    const mwSize size[3]={arr.n_rows,arr.n_cols,arr.n_slices};
    mxArray *out_arr=mxCreateNumericArray(3,size,get_mx_class<ElemT>(), mxREAL);
    lhs[lhs_idx++]=out_arr;
    auto out_vec=getStack<ElemT>(out_arr);
    out_vec=arr; //copy
}

inline
void MexIFace::outputMXArray(mxArray *m)
{
    lhs[lhs_idx++]=m;
}

inline 
void MexIFace::outputDouble(double val)
{
    mxArray *m=mxCreateNumericMatrix(1,1,mxDOUBLE_CLASS, mxREAL);
    double *dptr=static_cast<double*>(mxGetData(m));
    *dptr=val;
    lhs[lhs_idx++]=m;
}

inline 
void MexIFace::outputInt(int32_t val)
{
    mxArray *m=mxCreateNumericMatrix(1,1,mxINT32_CLASS, mxREAL);
    int32_t *dptr=static_cast<int32_t*>(mxGetData(m));
    *dptr=val;
    lhs[lhs_idx++]=m;
}

inline 
void MexIFace::outputBool(bool val)
{
    const mwSize size[2] = {1,1};
    mxArray *m = mxCreateLogicalArray(2,size);
    mxLogical *dptr = static_cast<mxLogical*>(mxGetData(m));
    dptr[0] = static_cast<mxLogical>(val);
    lhs[lhs_idx++] = m;
}


template<class ElemT>
void MexIFace::outputSparse(const arma::SpMat<ElemT> &arr)
{
    int nnz = static_cast<int>(arr.n_nonzero);
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
    lhs[lhs_idx++]=out_arr; //Save as output
}

/*
 * This is for a std::vector<std::vector<ElemT>> to be output as a cell-array of matlab column arrays.
 * 
 */
template<class ElemT> 
void MexIFace::outputVecCellArray(const VectorVector<ElemT> &list)
{
    int nCells = list.size();
    mxArray* arr=mxCreateCellMatrix(nCells, 1);
    for(int i=0;i<nCells;i++){
        mxArray *vec=mxCreateNumericMatrix(list[i].size(), 1, get_mx_class<ElemT>(), mxREAL);
        std::copy(list[i].cbegin(), list[i].cend(), getVec<ElemT>(vec).begin());
        mxSetCell(arr, i, vec);
    }
    lhs[lhs_idx++]=arr; //Save as output
}

/*
 * This is for a std::vector<std::vector<ElemT>> to be output as a cell-array of matlab column arrays.
 * 
 */
template<class ElemT> 
void MexIFace::outputVecCellArray(const VectorList<ElemT> &list)
{
    int nCells = list.size();
    mxArray* arr=mxCreateCellMatrix(nCells, 1);
    for(int i=0;i<nCells;i++){
        mxArray *vec=mxCreateNumericMatrix(list[i].size(), 1, get_mx_class<ElemT>(), mxREAL);
        std::copy(list[i].cbegin(), list[i].cend(), getVec<ElemT>(vec).begin());
        mxSetCell(arr, i, vec);
    }
    lhs[lhs_idx++]=arr; //Save as output
}

/* std::vector of arma::Col vectors to matlab cell-array of 1D column arrays */
template<class ElemT> 
void MexIFace::outputVecCellArray(const VecVector<ElemT> &list)
{
    int nCells = list.size();
    mxArray* arr = mxCreateCellMatrix(nCells, 1);
    for(int i=0;i<nCells;i++){
        mxArray *vec = mxCreateNumericMatrix(list[i].n_elem, 1, get_mx_class<ElemT>(), mxREAL);
        auto out_vec = getVec<ElemT>(vec); //Interpret output array as armadillo array
        out_vec = list[i]; //copy
        mxSetCell(arr, i, vec); //save in cell array
    }
    lhs[lhs_idx++] = arr; //Save cell-array as output
}

/* arma::field of arma::Col vectors to matlab cell-array of 1D column arrays */
template<class ElemT> 
void MexIFace::outputVecCellArray(const VecField<ElemT> &field)
{
    int nCells = static_cast<int>(field.n_elem);
    mxArray* arr = mxCreateCellMatrix(nCells, 1);
    for(int i=0;i<nCells;i++){
        mxArray *vec = mxCreateNumericMatrix(field(i).n_elem, 1, get_mx_class<ElemT>(), mxREAL);
        auto out_vec = getVec<ElemT>(vec); //Interpret output array as armadillo array
        out_vec = field(i); //copy
        mxSetCell(arr, i, vec); //save in cell array
    }
    lhs[lhs_idx++] = arr; //Save cell-array as output
}

template<class ElemT> 
void MexIFace::outputMatCellArray(const MatVector<ElemT> &list)
{
    int nCells = list.size();
    mxArray* arr = mxCreateCellMatrix(nCells, 1);
    for(int i=0;i<nCells;i++){
        mxArray *mat = mxCreateNumericMatrix(list[i].n_rows, list[i].n_cols, get_mx_class<ElemT>(), mxREAL);
        auto out_mat = getMat<ElemT>(mat); //Interpret output array as armadillo array
        out_mat = list[i]; //copy
        mxSetCell(arr, i, mat); //save in cell array
    }
    lhs[lhs_idx++] = arr; //Save cell-array as output
}

template<class ElemT> 
void MexIFace::outputMatCellArray(const MatField<ElemT> &field)
{
    int nCells = static_cast<int>(field.n_elem);
    mxArray* arr = mxCreateCellMatrix(nCells, 1);
    for(int i=0;i<nCells;i++){
        mxArray *mat = mxCreateNumericMatrix(field(i).n_rows, field(i).n_cols, get_mx_class<ElemT>(), mxREAL);
        auto out_mat = getMat<ElemT>(mat); //Interpret output array as armadillo array
        out_mat = field(i); //copy
        mxSetCell(arr, i, mat); //save in cell array
    }
    lhs[lhs_idx++] = arr; //Save cell-array as output
}

template<class ElemT> 
void MexIFace::outputCubeCellArray(const CubeVector<ElemT> &list)
{
    int nCells = list.size();
    mxArray* arr = mxCreateCellMatrix(nCells, 1);
    for(int i=0;i<nCells;i++){
        const mwSize size[3] = {list[i].n_rows,list[i].n_cols,list[i].n_slices};
        mxArray *cube = mxCreateNumericArray(3, size, get_mx_class<ElemT>(), mxREAL);
        auto out_cube = getStack<ElemT>(cube); //Interpret output array as armadillo array
        out_cube = list[i]; //copy
        mxSetCell(arr, i, cube); //save in cell array
    }
    lhs[lhs_idx++] = arr; //Save cell-array as output
}

template<class ElemT> 
void MexIFace::outputCubeCellArray(const CubeField<ElemT> &field)
{
    int nCells = static_cast<int>(field.n_elem);
    mxArray* arr = mxCreateCellMatrix(nCells, 1);
    for(int i=0;i<nCells;i++){
        const mwSize size[3] = {field(i).n_rows,field(i).n_cols,field(i).n_slices};
        mxArray *cube = mxCreateNumericArray(3, size, get_mx_class<ElemT>(), mxREAL);
        auto out_cube = getStack<ElemT>(cube); //Interpret output array as armadillo array
        out_cube = field(i); //copy
        mxSetCell(arr, i, cube); //save in cell array
    }
    lhs[lhs_idx++] = arr; //Save cell-array as output
}
} /* namespace mexiface */


#endif /* _MEXIFACE_H */
