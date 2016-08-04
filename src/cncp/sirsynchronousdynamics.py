# SIR simulator with synchronous dynamics
#
# Copyright (C) 2014-2016 Simon Dobson
# 
# Licensed under the Creative Commons Attribution-Noncommercial-Share
# Alike 3.0 Unported License (https://creativecommons.org/licenses/by-nc-sa/3.0/).
#

import cncp
import epyc
import networkx
import numpy


class SIRSynchronousDynamics(cncp.SynchronousDynamics):
    '''A synchronous SIR dynamics. We use probabilities
    to express infection and recovery per timestep, and run the system
    using synchronous dynamics.'''
    
    # the possible dynamics states of a node for SIR dynamics
    SUSCEPTIBLE = 'S'
    INFECTED = 'I'
    RECOVERED = 'R'
        
    def __init__( self, g = None ):
        '''Generate an SIR dynamics.
        
        g: the graph to run over (optional)'''
        super(SIRSynchronousDynamics, self).__init__(g)

        # list of infected nodes, the sites of all the dynamics
        self._infected = []

    def setUp( self, params ):
        '''Seed the network with infected nodes, and mark all edges
        as unoccupied by the dynamics.

        params: the parameters of the simulation'''
        super(SIRSynchronousDynamics, self).setUp(params)
        
        g = self.network()
        pInfected = params['pInfected']
        
        # in case we re-run from a dirty intermediate state
        self._infected = []
        
        # seed the network with infected nodes, making all the other susceptible
        for n in g.node.keys():
            if numpy.random.random() <= pInfected:
                self._infected.insert(0, n)
                g.node[n][self.DYNAMICAL_STATE] = self.INFECTED
            else:
                g.node[n][self.DYNAMICAL_STATE] = self.SUSCEPTIBLE
                
        # mark all edges as unoccupied
        for (n, m, data) in g.edges_iter(data = True):
            data[self.OCCUPIED] = False

    def dynamics( self, params ):
        '''Optimised per-step dynamics that only runs the model at infected
        nodes, since they're the only places where state changes originate. At the
        end of each timestep we re-build the infected node list.
        
        params: the parameters of the simulation
        returns: the number of events that happened in this timestep'''
        g = self.network()
        events = 0
        
        # run model dynamics on infected nodes only
        for n in self._infected:
            events = events + self.model(n, params)
    
        # remove any nodes that are no longer infected from the infected list
        self._infected = [ n for n in self._infected if g.node[n][self.DYNAMICAL_STATE] == self.INFECTED ]
        
        return events
            
    def model( self, n, params ):
        '''Apply the SIR dynamics to node n. From the re-definition of dynamics_step()
        we already know this node is infected.

        params: the parameters of thje simulation
        n: the node
        returns: the number of changes made'''
        g = self.network()
        events = 0
        
        # infect susceptible neighbours with probability pInfect
        for (_, m, data) in g.edges_iter(n, data = True):
            if g.node[m][self.DYNAMICAL_STATE] is self.SUSCEPTIBLE:
                if numpy.random.random() <= params['pInfect']:
                    events = events + 1
                    
                    # infect the node
                    g.node[m][self.DYNAMICAL_STATE] = self.INFECTED
                    self._infected.insert(0, m)
                        
                    # label the edge we traversed as occupied
                    data[self.OCCUPIED] = True
    
        # recover with probability pRecover
        if numpy.random.random() <= params['pRecover']:
            # recover the node
            events = events + 1
            g.node[n][self.DYNAMICAL_STATE] = self.RECOVERED
                
        return events
            
    def at_equilibrium( self, t ):
        '''SIR dynamics is at equilibrium if there are no more infected nodes
        left in the network or if we've hit the default equilibrium conditions.
        
        returns: True if the model has stopped'''
        if (len(self._infected) == 0):
            return True
        else:
            return super(SIRSynchronousDynamics, self).at_equilibrium(t)
            
    def do( self, params ):
        '''Returns statistics of outbreak sizes. This skeletonises the
        network, so it can't have any further dynamics run on it.
        
        params: parameters of the simulation
        returns: a dict of statistical properties'''
        
        # run the basic dynamics
        rc = super(SIRSynchronousDynamics, self).do(params)
        
        # compute the limits and means
        cs = sorted(networkx.connected_components(self.skeletonise()), key = len, reverse = True)
        max_outbreak_size = len(cs[0])
        max_outbreak_proportion = (max_outbreak_size + 0.0) / self.network().order()
        mean_outbreak_size = numpy.mean([ len(c) for c in cs ])
        
        # add  metrics for this simulation run
        rc['mean_outbreak_size'] = mean_outbreak_size,
        rc['max_outbreak_size'] = max_outbreak_size,
        rc['max_outbreak_proportion'] = max_outbreak_proportion
        return rc
    
