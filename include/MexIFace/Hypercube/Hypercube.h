/** @file Hypercube.h
 * @author Mark J. Olah (mjo\@cs.unm DOT edu)
 * @date 2013-2019
 * @copyright Licensed under the Apache License, Version 2.0.  See LICENSE file.
 * @brief The class declaration and inline and templated functions for hypercube.
 */

#ifndef HYPERCUBE_HYPERCUBE_H
#define HYPERCUBE_HYPERCUBE_H
#include <armadillo>
#include <memory>
#include <vector>
#include <stdexcept>

namespace hypercube {

/**
 * @brief A class to create a 4D armadillo array that can use externally allocated memory.
 *
 * TODO: Do a single allocation for 4D data.
 *
 * This class provides a way to manipulate externally allocated 4D column-major arrays as
 * a armadillo-like Array object.  Really we just store a vector of arma::Cube's each of which
 * has been initialized with the correct 3D chunk from the 4D external array.  This allows us
 * to work directly with Matlab allocated 4D arrays in C++.  Unfortunately most of the armadillo
 * functions won't work with this hypercube, but the slice method allows easy access to the actual
 * armadillo Cubes that make up the Hypercube.
 *
 */
template <class ElemT>
class Hypercube {
    using Cube = arma::Cube<ElemT> ;
    using CubeVecT = std::vector<std::unique_ptr<Cube>> ;

public:
    using IdxT=arma::uword;
    /**
     * @brief Create an empty hypercube of specified size
     * @param sX The x coordinate (1st dim).
     * @param sY The y coordinate (2nd dim).
     * @param sZ The z coordinate (3rd dim).
     * @param sN The n (hyperslice) coordinate (4th dim).
     */
    Hypercube(IdxT sX, IdxT sY, IdxT sZ, IdxT sN)
        : sX(sX),sY(sY),sZ(sZ),sN(sN), n_slices(sN),
          hcube(CubeVecT(sN))
    {
        for(IdxT i=0;i<sN;i++) hcube[i] = std::make_unique<Cube>(sX,sY,sZ);
    }

    /**
     * @brief Create a hypercube of specified size using externally allocated
     *      4D column-major array data.
     * @param mem Pointer to external memory of a 4D column-major array, that this
     *      hypercube will give access to
     * @param sX The x coordinate (1st dim).
     * @param sY The y coordinate (2nd dim).
     * @param sZ The z coordinate (3rd dim).
     * @param sN The n (hyperslice) coordinate (4th dim).
     */
    Hypercube(void *mem, IdxT sX, IdxT sY, IdxT sZ, IdxT sN)
        : sX(sX),sY(sY),sZ(sZ),sN(sN), n_slices(sN)
    {
        IdxT sz = subcube_size();
        auto dmem = static_cast<ElemT*>(mem);
        for(IdxT i=0;i<sN;i++) {
            hcube.push_back(std::make_unique<Cube>(dmem,sX,sY,sZ, false));
            dmem+=sz;
        }
    }

    /**
     * @brief Zero out all cubes in this hypercube
     */
    void zeros() { for(auto cube: hcube) cube->zeros();}

    /**
     * @brief Get a subcube with index i.
     * @param i the sub-cube index, in the 4-th dim.
     * @returns A constant reference to the subcube
     */
    const Cube& slice(IdxT i) const
    {
        if(i >= sN) throw std::out_of_range("Hypercube","hyperslice out of bounds");
        return *hcube[i];
    }

    /**
     * @brief Get a subcube with index i.
     * @param i the sub-cube index, in the 4-th dim.
     * @returns A reference to the subcube
     */
    Cube& slice(IdxT i)
    {
        if(i >= sN) throw std::out_of_range("Hypercube","hyperslice out of bounds");
        return *hcube[i];
    }

    /**
     * @brief Access element at coords
     * @param iX The x coordinate (1st dim).
     * @param iY The y coordinate (2nd dim).
     * @param iZ The z coordinate (3rd dim).
     * @param iN The n (hyperslice) coordinate (4th dim).
     * @returns A reference to the element
     */
    ElemT& operator()(IdxT iX, IdxT iY, IdxT iZ, IdxT iN) const
    {
        if(iN >= sN) throw std::out_of_range("Hypercube","hyperslice out of bounds");
        return (*hcube[iN])(iX,iY,iZ);
    }

    /**
     * @brief Get the number of elements in each subcube
     */
    IdxT subcube_size() const
    {
        return sX*sY*sZ;
    }

    /**
     * @brief Get the number of elements in this hypercube
     */
    IdxT size() const
    {
        return sX*sY*sZ*sN;
    }

    /* Member variables */

    const IdxT sX,sY,sZ,sN;
    /**
     * @brief This member variable matches the n_slices member of arma::Cube's and
     * allows us to have a hypercube stand in for a cube in templated code that can
     * work on 2D or 3D sub-slices
     */
    const IdxT n_slices;
private:
    CubeVecT hcube; /**< The vector of cubes that stores the data */
};

/* Declare Explicit Template Instantiation */
typedef Hypercube<double> hypercube;
typedef Hypercube<float>  fhypercube;

} /* namespace hypercube */

#endif /* HYPERCUBE_HYPERCUBE_H */
