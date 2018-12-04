/** @file MexIFaceBase.h
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2013-2017
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief class MexIFaceBase declaration.
 */

#ifndef MEXIFACE_MEXIFACEBASE_H
#define MEXIFACE_MEXIFACEBASE_H

#include <string>

#include "mex.h"

namespace mexiface 
{
/** @brief Base class defining the virtual functions that will be implemented by MexIFaceHandler and the concrete subclasses of MexIFace.
 * 
 */
class MexIFaceBase
{
protected:
    /** @brief Called when the mexFunction gets the \@new command, passing on the remaining input arguments.
     *
     * The rhs should have a single output argument which is the handle (number) which corresponds to the
     * wrapped object.
     *
     * This pure virtual function must be overloaded by the concrete MexIFace subclass that can use the get<> methods
     * to take in arbitrary parameters for whatever constrctor(s) exists for that wrapped class.
     */
    virtual void objConstruct() = 0;
    
    /** @brief Called when the mexFunction gets the \@delete command
     *
     * This pure virtual function is implemented in the MexIFaceHandler class template.
     * @param mxhandle scalar array where the handle is stored
     */

    virtual void objDestroy(const mxArray *mxhandle) = 0;

    /** @brief Helper method which saves a pointer to the wrapped class's object in an internal member variable called obj.
     *
     * This pure virtual function is implemented in the MexIFaceHandler class template.
     * @param mxhandle scalar array where the handle is stored
     */
    virtual void getObjectFromHandle(const mxArray *mxhandle) = 0;

    /** @brief Append a generic mxArray to the output arguments
     * This is virtual because MexIFaceHandler need to use it to output a Handle pointer
     * @param m Array to append to output arguments.
     */
    virtual void output(mxArray *m) = 0;
  
    /** @brief Get the name of the class of the stored object. */
    virtual std::string obj_name() const = 0;

    virtual ~MexIFaceBase()=default;
};
    
    
} /* namespace mexiface */

#endif // MEXIFACE_MEXIFACEBASE_H
