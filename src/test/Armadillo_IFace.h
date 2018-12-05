/** @file ArmadilloIFace.h
 * @author Mark J. Olah (mjo\@cs.unm.edu)
 * @date 04-2015
 * @brief A demo class for 
 */

#ifndef ARMADILLO_IFACE_H
#define ARMADILLO_IFACE_H

#include <armadillo>

#include "MexIFace/MexIFace.h"


class ArmadilloIface : public MexIFace
{
public:
    ArmadilloIface(int max_threads);
private:
    int max_threads;
    
    TrackerT *obj;
    //Abstract member functions inherited from Mex_Iface
    void objConstruct();
    void objDestroy();
    void getObjectFromHandle(const mxArray *mxhandle);
    //Exposed method calls
    void objInitializeTracks();
    void objGetTracks();
    void objDebugF2F();
    void objLinkF2F();
    void objCloseGaps();
    void objDebugCloseGaps();
    void objGenerateTracks();
    void objGetStats();
};

template<class TrackerT>
Tracker_Iface<TrackerT>::Tracker_Iface(std::string name) 
    : Mex_Iface(name)
{
    methodmap["initializeTracks"] = boost::bind(&Tracker_Iface::objInitializeTracks, this);
    methodmap["debugF2F"] = boost::bind(&Tracker_Iface::objDebugF2F, this);
    methodmap["debugCloseGaps"] = boost::bind(&Tracker_Iface::objDebugCloseGaps, this);
    methodmap["linkF2F"] = boost::bind(&Tracker_Iface::objLinkF2F, this);
    methodmap["closeGaps"] = boost::bind(&Tracker_Iface::objCloseGaps, this);
    methodmap["getTracks"] = boost::bind(&Tracker_Iface::objGetTracks, this);
    methodmap["getStats"] = boost::bind(&Tracker_Iface::objGetStats, this);
    methodmap["generateTracks"] = boost::bind(&Tracker_Iface::objGenerateTracks, this);
}

template<class TrackerT>
void Tracker_Iface<TrackerT>::objConstruct()
{
    // args:
    // [params] - struct of named doubles doubles.
    this->checkNumArgs(1,1);
    auto params=this->getDoubleVecStruct();
    TrackerT *tk = new TrackerT(params);
    this->outputMXArray(Handle<TrackerT>::makeHandle(tk));
}

template<class TrackerT>
void Tracker_Iface<TrackerT>::objInitializeTracks()
{
    // [in]
    //  frameIdx - vector giving frame of each localization (1-based)
    //  positions - matrix of positions and standard errors columns: [x y SE_x SE_y].
    //  features - [optional] matrix of features and SE's columns [L SE_L];
    auto frameIdx = this->getIVec();
    auto position = this->getDMat();
    auto SE_position = this->getDMat();
    if(this->nrhs==3) {
        obj->initializeTracks(frameIdx,position, SE_position);
    } else if(this->nrhs==5){
        auto feature = this->getDMat();
        auto SE_feature = this->getDMat();
        obj->initializeTracks(frameIdx,position, SE_position, feature, SE_feature);
    } else {
        this->error("NArgs","Invalid number of arguments!");
    }
}

template<class TrackerT>
void Tracker_Iface<TrackerT>::objLinkF2F()
{
    // [out]
    //  nTracks - number of tracks after frame2frame (-1 for error)
    this->checkNumArgs(1,0);
    obj->linkF2F();
    this->outputInt(obj->tracks.size());
}

template<class TrackerT>
void Tracker_Iface<TrackerT>::objCloseGaps()
{
    // [out]
    //  nTracks - number of tracks after gapClose (-1 for error)
    this->checkNumArgs(1,0);
    obj->closeGaps();
    this->outputInt(obj->tracks.size());
}

template<class TrackerT>
void Tracker_Iface<TrackerT>::objGenerateTracks()
{
    // [out]
    //  tracks - cell array of vectors.  Each vector is one track and lists the indexs of the localizations.
    this->checkNumArgs(1,0);
    obj->generateTracks();
    outputVecCellArray(obj->tracks);
}

template<class TrackerT>
void Tracker_Iface<TrackerT>::objGetTracks()
{
    //Get the current state of the tracks, which can be called between calls to linkF2F() and closeGaps()
    //[out]
    //  tracks - cell array of vectors.  Each vector is one track and lists the indexs of the localizations.
    this->checkNumArgs(1,0);
    outputVecCellArray(obj->tracks);
}

template<class TrackerT>
void Tracker_Iface<TrackerT>::objDebugF2F()
{
    // [in]
    //  frameIdx - integer
    // [out]
    //  cur_locs - indexs of current frame localizations
    //  next_locs - indexs of next frame localizations
    //  costs - cost matrix
    //  connections - 2xn matrix of connections.  -1 represents birth or death
    //  conn_costs - Costs for selected connections
    this->checkNumArgs(5,1);
    int frameIdx = this->getInt();
    typename TrackerT::IVecT cur_locs;
    typename TrackerT::IVecT next_locs;
    typename TrackerT::SpMatT costs;
    typename TrackerT::IMatT connections;
    typename TrackerT::VecT conn_costs;
    obj->debugF2F(frameIdx, cur_locs, next_locs, costs, connections, conn_costs);
    this->outputVec(cur_locs);
    this->outputVec(next_locs);
    this->outputSparse(costs);
    this->outputMat(connections);
    this->outputVec(conn_costs);
}

template<class TrackerT>
void Tracker_Iface<TrackerT>::objDebugCloseGaps()
{
    // [in]
    //   -
    // [out]
    //  costs - cost matrix
    //  connections - 2xn matrix of connections.  0 represents birth or death
    //  conn_costs - Costs for selected connections
    this->checkNumArgs(3,0);
    typename TrackerT::SpMatT costs;
    typename TrackerT::IMatT connections;
    typename TrackerT::VecT conn_costs;
    obj->debugCloseGaps(costs, connections, conn_costs);
    this->outputSparse(costs);
    this->outputMat(connections);
    this->outputVec(conn_costs);
}

template<class TrackerT>
void Tracker_Iface<TrackerT>::objGetStats()
{
    // [out]
    //  stats - struct of named doubles with params and various statistics on the tracks
    this->checkNumArgs(1,0);
    this->outputStatsToDoubleVecStruct(obj->getStats());
}

template<class TrackerT>
inline
void Tracker_Iface<TrackerT>::getObjectFromHandle(const mxArray *mxhandle)
{
    obj = Handle<TrackerT>::getObject(mxhandle);
}


template<class TrackerT>
void Tracker_Iface<TrackerT>::objDestroy()
{
    if(!nrhs) component_error("Destructor","NumInputArgs","No object handle given");
    Handle<TrackerT>::destroyObject(rhs[0]);
}

#endif /* ARMADILLO_IFACE_H */
