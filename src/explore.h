/** @file explore.h
 *
 * A header file for the functions provided by Matlab in explore.cpp.
 * See: explore.cpp for copyright notice and documentation
 */


#ifndef _MEXIFACE_EXPLORE_H
#define _MEXIFACE_EXPLORE_H

#include "mex.h"
namespace mexiface{
    namespace explore{
        void analyze_cell(const mxArray *cell_array_ptr);
        void analyze_structure(const mxArray *structure_array_ptr);
        void analyze_string(const mxArray *string_array_ptr);
        void analyze_sparse(const mxArray *array_ptr);
        void analyze_int8(const mxArray *array_ptr);
        void analyze_uint8(const mxArray *array_ptr);
        void analyze_int16(const mxArray *array_ptr);
        void analyze_uint16(const mxArray *array_ptr);
        void analyze_int32(const mxArray *array_ptr);
        void analyze_uint32(const mxArray *array_ptr);
        void analyze_int64(const mxArray *array_ptr);
        void analyze_uint64(const mxArray *array_ptr);
        void analyze_single(const mxArray *array_ptr);
        void analyze_double(const mxArray *array_ptr);
        void analyze_logical(const mxArray *array_ptr);
        void analyze_full(const mxArray *numeric_array_ptr);
        void display_subscript(const mxArray *array_ptr, mwSize index);
        void get_characteristics(const mxArray *array_ptr);
        mxClassID analyze_class(const mxArray *array_ptr);
    } /* namespace mexiface::explore */
} /* namespace mexiface */

#endif /* _MEXIFACE_EXPLORE_H */
