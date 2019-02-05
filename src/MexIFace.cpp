/** @file MexIFace.cpp
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2013-2017
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief The class definition for MexIFace.
 */

#include "MexIFace/MexIFace.h"
#include "MexIFace/explore.h"


namespace mexiface {

MexIFace::MexIFace()
{
//     #ifndef WIN32
//     //This sets the openmp thread count to the same as the hardware concurrency
//     omp_set_num_threads(std::thread::hardware_concurrency());
//     #endif
}

/** @brief Reports an error condition to Matlab using the mexErrMsgIdAndTxt function
 *
 * @param condition String describing the error condition encountered.
 * @param message Informative message to accompany the error.
 */
void MexIFace::error(std::string condition, std::string message) const
{
    std::string message_id =remove_alphanumeric(obj_name())+":"+remove_alphanumeric(condition);
    mexErrMsgIdAndTxt(message_id.c_str(),message.c_str());
}

/** @brief Reports an error condition in a specified component to Matlab using the mexErrMsgIdAndTxt function
 *
 * @param component String describing the component in which the error was encountered.
 * @param condition String describing the error condition encountered.
 * @param message Informative message to accompany the error.
 */
void MexIFace::error(std::string component, std::string condition, std::string message) const
{
    mexErrMsgIdAndTxt((remove_alphanumeric(obj_name())+":"+remove_alphanumeric(component)+":"+remove_alphanumeric(condition)).c_str(), 
                      message.c_str());
}

std::string MexIFace::remove_alphanumeric(std::string name)
{
    auto nonalphanumeric = [](const char &c) {return !isalnum(c);};
    name.erase(std::remove_if(name.begin(), name.end(), nonalphanumeric), name.end());
    name.erase(name.begin(),std::find_if(name.begin(), name.end(),isalpha)); //delete any numerals preceeding name.
    return name;
}

/** @brief Reads a mxArray as a string.
 *
 * @param m Pointer to the mxArray to interpret.
 *
 * Throws an error if the conversion cannot be made.
 */
std::string MexIFace::getString(const mxArray *m)
{
    if(m == nullptr) m = rhs[rhs_idx++];
    checkType(m,mxCHAR_CLASS); //Only accept char arrays as strings
    checkVectorSize(m); //Should be 1D
    auto cstr = mxArrayToString(m);
    std::string str(cstr);
    mxFree(cstr);
    return str;
}


/**
 * @brief The mexFunction that will be exposed as the entry point for the .mex file
 *
 * @param[in] _nlhs The number of left-hand-side (input) arguments passed from the Matlab side of the Iface.
 * @param[in] _lhs The input arguments passed from the Matlab side of the Iface.
 * @param[in] _nrhs The number of right-hand-side (output) arguments requested from the Matlab side of the Iface.
 * @param[in,out] _rhs The output arguments requested from the Matlab side of the Iface to be filled in.
 *
 * This command is the main entry point for the .mex file, and allows the mexFunction to act like a class interface.
 * Special \@new, \@delete, \@static strings allow objects to be created and destroyed and static functions to be called
 * otherwise the command is interpreted as a member function to be called on the given object handle which is expected
 * to be the second argument.
 *
 */
void MexIFace::mexFunction(MXArgCountT _nlhs, mxArray *_lhs[], MXArgCountT _nrhs, const mxArray *_rhs[])
{
    setArguments(_nlhs,_lhs,_nrhs,_rhs);
    checkMinNumArgs(0,1);
    auto command = getString(rhs[0]);
    popRhs();//remove command from RHS
//     std::cout<<"Command called: "<<command<<std::endl;
//     exploreMexArgs(_nrhs,_rhs);
//     std::cout<<std::endl;
    if (command=="@new") {
        objConstruct();
    } else if (command=="@delete") {
        checkMinNumArgs(0,1);
        objDestroy(rhs[0]); 
    } else if (command=="@static") {
        checkMinNumArgs(0,1);
        auto command = getString(rhs[0]);
        popRhs();//remove real command name from RHS
        callMethod(command,staticmethodmap);
    } else {
        checkMinNumArgs(0,1);
        getObjectFromHandle(rhs[0]); //Prepare object for use.
        popRhs();//remove handle from RHS
        callMethod(command,methodmap);
    }
}

/**
 * @brief Calls a named member function on the instance of the wrapped class.
 *
 * @param name The name of the method to call, as given to the mexFunction call.
 *
 * Throws an error if the name is not in the methodmap std::map data structure.
 */
void MexIFace::callMethod(std::string name,const MethodMap &map)
{
    auto it = methodmap.find(name);
    if (it == methodmap.end()){
        #if defined(DEBUG)            
        mexPrintf("[MexIFace::callMethod] --- Unknown Method Name\n");
        mexPrintf("  MexName: %s\n",obj_name().c_str());
        mexPrintf("  MethodName: %s\n",name.c_str());
        std::string method_names;
        method_names.reserve(16*map.size());
        for(auto& method : map) {
            if(!method_names.empty()) method_names.append(",");
            method_names.append(method.first);
        }
        mexPrintf("  MappedMethods: [%s]\n",method_names.c_str());

        mexPrintf("%s]\n");
        exploreMexArgs(nrhs, rhs);
        #endif
        error("callMethod","UnknownMethod",name);
    } else {
        try {
            it->second();
        } catch (MexIFaceError &e) {
            #if defined(DEBUG)            
            mexPrintf("[MexIFace::callMethod] --- MexIFaceError Caught\n");
            mexPrintf("  MexName: %s\n",obj_name().c_str());
            mexPrintf("  MethodName: %s\n",name.c_str());
            mexPrintf("  Exception.condition: %s\n",e.condition());
            mexPrintf("  Exception.what: %s\n",e.what());
            mexPrintf("  Exception.Backtrace:\n%s\n\n",e.backtrace());
            #endif
            error(name,e.condition(),e.what());
        } catch (backtrace_exception::BacktraceException &e) {
            #if defined(DEBUG)            
            mexPrintf("[MexIFace::callMethod] --- BacktraceException Caught\n");
            mexPrintf("  MexName: %s\n",obj_name().c_str());
            mexPrintf("  MethodName: %s\n",name.c_str());
            mexPrintf("  Exception.condition: %s\n",e.condition());
            mexPrintf("  Exception.what: %s\n",e.what());
            mexPrintf("  Exception.Backtrace:\n%s\n\n",e.backtrace());
            #endif
            error(name,e.condition(),e.what());
        } catch (std::exception &e) {
            #if defined(DEBUG)            
            mexPrintf("[MexIFace::callMethod] --- std::exception Caught\n");
            mexPrintf("  MexName: %s\n",obj_name().c_str());
            mexPrintf("  MethodName: %s\n",name.c_str());
            mexPrintf("  Exception.what: %s\n",e.what());
            #endif
            error(name,e.what());
        } catch (...) {
            #if defined(DEBUG)            
            mexPrintf("[MexIFace::callMethod] --- Unknown Exception Caught\n");
            mexPrintf("  MexName: %s\n",obj_name().c_str());
            mexPrintf("  MethodName: %s\n",name.c_str());
            #endif
            error(name,"UnknownException");
        }
    }
}

} /* namespace mexiface */
