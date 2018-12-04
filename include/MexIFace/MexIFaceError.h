/** @file MexIFaceError.h
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2013-2017
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief Exception classes for MexIFace
 *
 */

#ifndef MEXIFACE_MEXIFACEERROR_H
#define MEXIFACE_MEXIFACEERROR_H

#include <BacktraceException/BacktraceException.h>

namespace mexiface {


class MexIFaceError : public backtrace_exception::BacktraceException
{
public:
    MexIFaceError(std::string condition, std::string what) : BacktraceException(condition, what) {}
    MexIFaceError(std::string component, std::string condition, std::string what) : BacktraceException(component+":"+condition, what) {}
};


} /* namespace mexiface */

#endif /* MEXIFACE_MEXIFACEERROR_H */
