using PyCall

# -*- Python Simmulated Annealing -*-
py"""
import time
import neal

def py_simulated_annealing(Q, c = 0.0, **params):
    '''

    Parameters
    ----------
    Q: dict[tuple, float]

    c: float = 0.0
        Base energy (QUBO constant term)

    Returns
    -------
    samples: list[tuple[list[int], int, float]]
        List of sample tuples
            states: list[int]
                Binary states
            amount: int
                Sampling frequency for the given state
            energy: float
                Total energy for the given state
    delta_t: float
        Annealing (Sampling) Time
    '''
    sampler = neal.SimulatedAnnealingSampler()
    
    t_0 = time.perf_counter()
    results = sampler.sample_qubo(Q, **params)
    t_1 = time.perf_counter()
    
    samples = [(list(map(int, s)), int(n), float(e)) for (s, e, n) in results.record]
    delta_t = t_1 - t_0

    return (samples, delta_t)

def py_quantum_annealing(Q, c = 0.0, **params):
    '''
        1. Connect to D-Wave Leap API
    '''
    raise NotImplementedError()
"""