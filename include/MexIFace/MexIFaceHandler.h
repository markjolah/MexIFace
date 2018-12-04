/** @file MexIFaceHandler.h
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2013-2017
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief class MexIFaceBase declaration.
 */

#ifndef MEXIFACE_MEXIFACEHANDLER_H
#define MEXIFACE_MEXIFACEHANDLER_H

#include "MexIFace/Handle.h"
#include "MexIFace/MexIFaceBase.h"

namespace mexiface 
{
/** @brief Class encompassing the MexIFace type-dependent operations.  Must be inherited from to form a concrete MexIFace. 
 * The class encapsulates the management of the Handle<T> type to hide it from the end user.
 * @param ObjT Wrapped C++ class type. 
 */
template<class ObjT>
class MexIFaceHandler : public virtual MexIFaceBase
{
protected:
    MexIFaceHandler();
    
    ObjT *obj=nullptr;
    /** @brief Called when the mexFunction gets the \@delete command
     *
     * This pure virtual function is implemented in the MexIFaceHandler class template.
     * @param mxhandle scalar array where the handle is stored
     */
    void objDestroy(const mxArray *mxhandle) override final;

    /** @brief Helper method which saves a pointer to the wrapped class's object in an internal member variable called obj.
     *
     * This pure virtual function is implemented in the MexIFaceHandler class template.
     * @param mxhandle scalar array where the handle is stored
     */
    void getObjectFromHandle(const mxArray *mxhandle) override final;
    
    std::string obj_name() const override final;
    
    /** @brief Should be called from all and only from objConstructor() implementations.
     *
     * Takes over the memory management of the object for the remainder of its lifetime over multiple calls
     * to the mex function untill the \@delete command is sent
     * 
     * @param obj pointer to newly created object of type obj.
     */
    void outputHandle(ObjT* obj);
private:
    std::string _obj_name;
};

template<class ObjT>
MexIFaceHandler<ObjT>::MexIFaceHandler() : 
    _obj_name(std::type_index(typeid(ObjT)).name())
{ }

template<class ObjT>
void MexIFaceHandler<ObjT>::getObjectFromHandle(const mxArray *mxhandle)
{
    obj = Handle<ObjT>::getObject(mxhandle);
}

template<class ObjT>
void MexIFaceHandler<ObjT>::objDestroy(const mxArray *mxhandle)
{
    Handle<ObjT>::destroyObject(mxhandle);
}

template<class ObjT>
std::string MexIFaceHandler<ObjT>::obj_name() const
{
    return _obj_name;
}


template<class ObjT>
void MexIFaceHandler<ObjT>::outputHandle(ObjT* obj)
{
    output(Handle<ObjT>::makeHandle(obj));
}

    
} /* namespace mexiface */

#endif // MEXIFACE_MEXIFACEHANDLER_H
