#!/usr/bin/env python

import spot
spot.setup()
import matplotlib.pyplot as plt
import numpy as np
import random
import argparse

def ltl_to_automaton(formula=None, ap_split_indx=None, desired_plan=None):
    if formula is None:
        # specifying reactive success criteria for scooping task in linear temporal logic
        # atomic propositions (AP) a, b, c, d correspond to free mode, scooping mode, transfer mode, and done mode. 
        desired_plan = ['a', 'b', 'c', 'd']
        # Boolean AP r, s, t denote sensing the spoon reaching the soup, soup on the spoon, and task success respectively.
        formula = spot.formula('a & G Fd \
                               & G(a <-> (!r & !s & !t)) \
                               & G(b <->(r& !s & !t)) \
                               & G(c<-> (!r & s & !t)) \
                               & G(d<-> (!r&s&t)) \
                               & G((a&!b&!c&!d) | (!a&b&!c&!d) | (!a&!b&c&!d) | (!a&!b&!c&d)) \
                               & G(a->(Xa | Xb)) \
                               & G(b->(Xb|Xc|Xa)) \
                               & G(c->(Xa|Xb|Xc|Xd)) \
                               & G(d->(Xd))')
        # we know how to split APs into robot and env APs since the formula is given by humans
        ap_split_index = 4 # index where to split list of all APs into robot APs and env APs, 

    # spot translates LTL to an actionable automaton
    a = spot.translate(formula, 'ba', 'small', 'high')
    # list of atomic propositions
    APs = sorted([str(p) for p in a.ap()]) 
    robot_APs = APs[:ap_split_index] # [a, b, c, d]
    env_APs = APs[ap_split_index:] # [r, s, t]
    # map numeric index of a node to a robot AP
    node_to_mode = {}
    for i in range(a.num_edges()): 
        edge = a.edge_storage(i+1) # 1 indexed
        destination_node = edge.dst
        bdd = spot.bdd_format_formula(a.get_dict(), edge.cond)
        for p in robot_APs: # only one robot_ap will be true, i.e. one and only one mode at a time
            if '!'+p in bdd: # false assignment to p
                pass
            else: # true assignment to p. If p is not in bdd, we assume p has been and stays true
                node_to_mode[destination_node] = p
    node_to_mode[1] = desired_plan[0] # since node 1 is a placeholder, we add it to the starting mode

    # extracting the spot automaton into an operationable dictionary
    automaton_dict = {} 
    for mode in robot_APs:
        automaton_dict[mode] = {}
        
    # polulate automaton_dict with transitions in spot automaton
    for i in range(a.num_edges()): 
        edge = a.edge_storage(i+1) # 1 indexed
        source_node = edge.src
        bdd = spot.bdd_format_formula(a.get_dict(), edge.cond)
        for p in robot_APs: # only one robot_ap will be true, i.e. one and only one mode at a time
            if '!'+p in bdd: # false assignment to p
                pass
            else: # true assignment to p. If p is not in bdd, we assume p has been and stays true
                sensor_vec = ''
                for q in env_APs:
                    if '!'+q in bdd:
                        sensor_vec+='0'
                    else:
                        sensor_vec+='1'
                automaton_dict[node_to_mode[source_node]][sensor_vec] = p

    init_mode = node_to_mode[a.get_init_state_number()]
    return automaton_dict, desired_plan, init_mode

def simulate(A, desired_plan, init_mode, seed=0):
    # simulate a receding horizon controller at the discrete mode level
    # given an automaton A, this function generates a reactive plan despite task-level perturbations
    random.seed(seed)
    curr_mode = init_mode
    history = curr_mode
    while True:
        print('Activating continuous policy associated with mode ' + curr_mode +'...')
        # sample legal sensor measurements considering potential perturbations
        while True:
            sensor_measurement = random.sample(A[curr_mode].keys(), 1)[0]
            if curr_mode != A[curr_mode][sensor_measurement]: # remove self-transition to reduce printing clutter
                break
        curr_mode = A[curr_mode][sensor_measurement]
        history += '_' + sensor_measurement + '->' + curr_mode
        print('...'+history[-80:]+'\n')
        if curr_mode == desired_plan[-1]:
            break

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--seed', type=int, default=0)
    parser.add_argument('-f', '--formula', type=str, default=None)
    parser.add_argument('-i', '--index', default=None)
    parser.add_argument('-p', '--plan', default=None)
    args = parser.parse_args()

    automaton, plan, init_mode = ltl_to_automaton(args.formula, args.index, args.plan)
    simulate(automaton, plan, init_mode, args.seed)