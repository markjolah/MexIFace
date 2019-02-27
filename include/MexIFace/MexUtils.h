/** @file MexUtils.h
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2013-2017
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief Helper functions for working with Matlab mxArrays and mxClassIDs
 *
 */

#ifndef MEXIFACE_MEXUTILS_H
#define MEXIFACE_MEXUTILS_H

#include <cstdint>
#include <string>


#include "mex.h"

namespace mexiface {

/**
 * @brief Returns a string representation of the mxArray class name
 * @param array The mxArray to analyze
 * @returns String giving class name of array
 */
const char* get_mx_class_name(const mxArray *array);

/**
 * @brief Returns a string representation of the class with given mxClassID
 * @param id The mxClassID to get name for
 * @returns String giving name of matlab data class id.
 */
const char* get_mx_class_name(mxClassID id);

/**
 * @brief Templated function to returns the matlab mxClassID for given C++ data type.
 * @returns mxClassID for templated C++ class type.
 */
template<class T> mxClassID get_mx_class();

/* Declaration of template specializations */
template<> mxClassID get_mx_class<double>();
template<> mxClassID get_mx_class<float>();
template<> mxClassID get_mx_class<int8_t>();
template<> mxClassID get_mx_class<int16_t>();
template<> mxClassID get_mx_class<int32_t>();
template<> mxClassID get_mx_class<int64_t>();
template<> mxClassID get_mx_class<uint8_t>();
template<> mxClassID get_mx_class<uint16_t>();
template<> mxClassID get_mx_class<uint32_t>();
template<> mxClassID get_mx_class<uint64_t>();
//In 64-bit mode the the headers use "typedef long int64_t" and "typedef unsigned long uint64_t"
//So, we need to add the typedefs for long long and unsigned long long also since they don't match int64_t or uint64_t
template<> mxClassID get_mx_class<long long>();
template<> mxClassID get_mx_class<unsigned long long>();
/* Generic template definition */
template<class T> mxClassID get_mx_class(){return mxUNKNOWN_CLASS;}

/**
 * @brief Given the arguments to a matlab mex function call, print out the details of each arguments
 * @param nargs Number of arguments
 * @param args Array of pointers to mxArray's that were given as arguments to a function call
 *
 * Uses the explore.cpp methods as provided my Matlab.  This is just an interface that is callable
 * without using it directlty as a mexFunction.
 */
void exploreMexArgs(int nargs, const mxArray *args[] );


inline
const char* get_mx_class_name(const mxArray *array)
{
    return get_mx_class_name(mxGetClassID(array));
}

std::string demangle(const char* name);

template<class T>
std::string type_name(const T&t) { return demangle(typeid(t).name()); }
template<class T>
std::string type_name() { return demangle(typeid(T).name()); }

} /* namespace mexiface */

#endif /* MEXIFACE_MEXUTILS_H */
