/** @file MexIFaceError.h
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2013-2017
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief Exception classes for MexIFace
 *
 */

#ifndef _MEXIFACE_MEXIFACEERROR_H
#define _MEXIFACE_MEXIFACEERROR_H

#include <exception>
#include <string>

namespace mexiface {


class MexIFaceError : public std::exception
{
public:
    MexIFaceError(std::string condition, std::string what);
    virtual const char* condition() const noexcept;
    virtual const char* what() const noexcept;
    virtual const char* backtrace() const noexcept;
    static std::string print_backtrace(); 
protected:
    std::string _condition;
    std::string _what;
    std::string _backtrace;
};

inline
const char* MexIFaceError::condition() const noexcept
{ return _condition.c_str(); }

inline
const char* MexIFaceError::what() const noexcept
{ return _what.c_str(); }

inline
const char* MexIFaceError::backtrace() const noexcept
{ return _backtrace.c_str(); }

    
} /* namespace mexiface */

#endif /* _MEXIFACE_MEXIFACEERROR_H */
