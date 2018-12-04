/** @file MexUtils.cpp
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2013-2017
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief Helper functions for working with Matlab mxArrays and mxClassIDs
 */

#include "MexUtils.h"
#include "explore.h"

namespace mexiface {

const char* get_mx_class_name(mxClassID id)
{
    switch (id)  {
        case mxINT8_CLASS: return "int8";
        case mxUINT8_CLASS: return "uint8";
        case mxINT16_CLASS: return "int16";
        case mxUINT16_CLASS:return "uint16";
        case mxINT32_CLASS: return "int32";
        case mxUINT32_CLASS: return "uint32";
        case mxINT64_CLASS:  return "int64";
        case mxUINT64_CLASS:return "uint64";
        case mxSINGLE_CLASS: return "single";
        case mxDOUBLE_CLASS:return "double";
        case mxLOGICAL_CLASS: return "logical";
        case mxCHAR_CLASS:    return "char";
        case mxSTRUCT_CLASS: return "struct";
        case mxCELL_CLASS:   return "cell";
        case mxUNKNOWN_CLASS: return "unknownclass";
        default: return "mysteryclass???";
    }
}
template<> mxClassID get_mx_class<double>() {return mxDOUBLE_CLASS;}
template<> mxClassID get_mx_class<float>() {return mxSINGLE_CLASS;}
template<> mxClassID get_mx_class<int8_t>() {return mxINT8_CLASS;}
template<> mxClassID get_mx_class<int16_t>() {return mxINT16_CLASS;}
template<> mxClassID get_mx_class<int32_t>() {return mxINT32_CLASS;}
template<> mxClassID get_mx_class<int64_t>() {return mxINT64_CLASS;}
template<> mxClassID get_mx_class<uint8_t>() {return mxUINT8_CLASS;}
template<> mxClassID get_mx_class<uint16_t>() {return mxUINT16_CLASS;}
template<> mxClassID get_mx_class<uint32_t>() {return mxUINT32_CLASS;}
template<> mxClassID get_mx_class<uint64_t>() {return mxUINT64_CLASS;}

/* TODO Finish this method to replace matlab .c code dependencies */
// void get_characteristics(const mxArray *arr)
// {
//     auto ndims = mxGetNumberOfDimensions(arr);
//     auto size = mxGetDimensions(arr);
//     auto name = mxGetClassName(arr);
//     auto id = mxGetClassID(arr);
//     
// }

void exploreMexArgs(int nargs, const mxArray *args[] )
{
    mexPrintf("#Args: %d\n",nargs);
    for (int i=0; i<nargs; i++)  {
        mexPrintf("\n\n");
        mexPrintf("arg[%i]: ",i);
        explore::get_characteristics(args[i]);
        explore::analyze_class(args[i]);
    }
}

} /* namespace mexiface */

