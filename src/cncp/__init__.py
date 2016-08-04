# Initialisation for "Complex networks, complex processes" package
#
# Copyright (C) 2014-2016 Simon Dobson
# 
# Licensed under the Creative Commons Attribution-Noncommercial-Share
# Alike 3.0 Unported License (https://creativecommons.org/licenses/by-nc-sa/3.0/).
#

# regular networks
from .lattice import lattice_graph, draw_lattice
from .ernetworks import erdos_renyi_graph_from_scratch

# networks with dynamical processes
from .networkdynamics import Dynamics
from .synchronousdynamics import SynchronousDynamics
from .stochasticdynamics import StochasticDynamics

# SIR processes under different dynamics
from .sirsynchronousdynamics import SIRSynchronousDynamics
from .sirstochasticdynamics import SIRStochasticDynamics


