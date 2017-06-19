# Copyright 2013-2017 
# Author: Mark J. Olah
# Email: (mjo@cs.unm DOT edu)

## Source Files ##
set(MEXIFACE_SRCS MexIFace.cpp MexUtils.cpp explore.cpp)
## Include Files ##
set(MEXIFACE_INCLUDES MexIFace.h MexUtils.h hypercube.h Handle.h explore.h)

## Iface Core Object librarary. ##
add_library( iface-core OBJECT ${MEX_IFACE_SRCS} )
