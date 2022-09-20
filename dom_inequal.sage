
import itertools
import geogebra_graph

# initialize p
P = MixedIntegerLinearProgram()
V = P.new_variable(real=True, nonnegative=False)

# basic inequalities
P.add_constraint(V[0] >= 1)
P.add_constraint(V[1] >= 0.5)
P.add_constraint(V[2] >= 0.5)
P.add_constraint(V[2] - 1/3 <= V["max 1"])
P.add_constraint(V[1] - V[2] <= V["max 1"])
P.add_constraint(V[0] - V[1] <= V["max 1"])
P.add_constraint(V[2] - 1/3 <= V["max 2"])
P.add_constraint(V[1] - V[2] <= V["max 2"])


def add_reducible(big_graph, small_graph, rest_of_graph_verts, rest_big_deg_verts, small_graph_verts, big_graph_verts):
	w_0_coeff = 0
	w_1_coeff = 0
	w_2_coeff = 0
	w_3_coeff = 0
	m_1_coeff = 0
	m_2_coeff = 0

	for v in rest_of_graph_verts:
		deg_change = big_graph.degree(v) - small_graph.degree(v)
		if deg_change > 0:
			m_1_coeff += 1
		elif deg_change == 0:
			m_1_coeff += 0

	for v in rest_big_deg_verts:
		deg_change = big_graph.degree(v) - small_graph.degree(v)
		if deg_change > 0:
			m_2_coeff += 1
		elif deg_change == 0:
			m_2_coeff += 0

	for v in small_graph_verts:
		vert_deg = small_graph.degree(v)
		if vert_deg == 0:
			w_0_coeff -= 1
		elif vert_deg == 1:
			w_1_coeff -= 1
		elif vert_deg == 2:
			w_2_coeff -= 1
		elif vert_deg == 3:
			w_3_coeff -= 1

	for v in big_graph_verts:
		vert_deg = big_graph.degree(v)
		if vert_deg == 0:
			w_0_coeff += 1
		elif vert_deg == 1:
			w_1_coeff += 1
		elif vert_deg == 2:
			w_2_coeff += 1
		elif vert_deg == 3:
			w_3_coeff += 1

	# max_val is max of size of dominating set in big graph minus size of dominating set in the small graph over all possible dominating sets in small graph

	max_val = 0

	# find all possible dominating sets in small_graph
	poss_dominating = list(set().union(rest_of_graph_verts, small_graph_verts))

	for r in range(0, len(poss_dominating)+1):
		for dominating in itertools.combinations(poss_dominating,r):
			# check if the small_graph_verts are dominated
			if not test_dominated(small_graph, dominating, small_graph_verts):
				continue

			# what rest_of_graph_verts are dominated
			dominated_precolors = []
			for v in dominating:
				for u in small_graph.neighbors(v):
					if u in rest_of_graph_verts and u not in dominating:
						dominated_precolors.append(u)

			# what rest_of_graph_verts are dominating
			dominating_precolors = tuple(set(dominating).intersection(rest_of_graph_verts))

			# find minimum dominating set in big_graph which dominates the big_graph_verts and the dominated_precolors
			flag = False
			for s in range(0, len(big_graph_verts)+1):
				for test_dominating in itertools.combinations(big_graph_verts,s):
					# check if big_graph_verts and dominated_precolors are dominated by dominating_precolors and test_dominated
					if test_dominated(big_graph, dominating_precolors + test_dominating, big_graph_verts + dominated_precolors):
						flag = True
						if s - r > max_val:
							max_val = s - r
						break
				if flag:
					break
			if not flag:
				print("Catastrophe! This is not reducible!")
				return

	P.add_constraint(w_0_coeff*V[0] + w_1_coeff*V[1] + w_2_coeff*V[2] + w_3_coeff/3 >= max_val + m_1_coeff*V["max 1"] + m_2_coeff*V["max 2"])

	return

def test_dominated(G, domination_set, dominated_set):
	for v in dominated_set:
		v_dominated = False
		if v in domination_set:
			v_dominated = True
		else:
			for u in G.neighbors(v):
				if u in domination_set:
					v_dominated = True
					break
		if not v_dominated:
			return False
	return True

def solve():
	P.solve()

def get_values():
	print("Weight 0:", P.get_values(V[0]))
	print("Weight 1:", P.get_values(V[1]))
	print("Weight 2:", P.get_values(V[2]))
	print("Weight 3:", float(1/3))
	print("Max 1:", P.get_values(V["max 1"]))
	print("Max 2:", P.get_values(V["max 2"]))

def remove_last():
	index = P.number_of_constraints() - 1
	P.remove_constraint(index)

def geogebra_extract(filename):
	# assumes geogebra file has all the information to determine big_graph, small_graph, and rest_of_graph_verts
	G = geogebra_graph.geogebra_to_graph(filename)

	big_graph_verts = [v for v in G.vertices() if G.get_vertex(v)['color'][:3] == (0,255,0)] # green vertices
	small_graph_verts = [v for v in G.vertices() if G.get_vertex(v)['color'][:3] == (255,0,0)] # red vertices
	rest_big_deg_verts = [v for v in G.vertices() if G.get_vertex(v)['color'][:3] == (255,0,255)] # magenta vertices
	rest_of_graph_verts = [v for v in G.vertices() if v not in big_graph_verts and v not in small_graph_verts] # rest of vertices

	new_order = rest_of_graph_verts + small_graph_verts + big_graph_verts # the new order of the vertices
	new_permutation = {v:i for i,v in enumerate(new_order)}
	G.relabel(perm = new_permutation, inplace=True)
	new_rest_of_graph_verts = list(range(len(rest_of_graph_verts)))
	new_small_graph_verts = list(range(len(rest_of_graph_verts), len(rest_of_graph_verts)+len(small_graph_verts)))
	new_big_graph_verts = list(range(len(rest_of_graph_verts)+len(small_graph_verts), G.num_verts()))

	new_rest_big_deg_verts = [v for v in G.vertices() if G.get_vertex(v)['color'][:3] == (255,0,255)] # magenta vertices

	reducer_edges = [e for e in G.edges() if e[2]['color'][:3] == (255,0,0)] # red edges

	small_graph = G.subgraph(vertices = new_rest_of_graph_verts + new_rest_big_deg_verts + new_small_graph_verts)
	big_graph = G.subgraph(vertices = new_rest_of_graph_verts + new_rest_big_deg_verts + new_big_graph_verts)
	big_graph.delete_edges(reducer_edges)

	return big_graph, small_graph, new_rest_of_graph_verts, new_rest_big_deg_verts, new_small_graph_verts, new_big_graph_verts

#############################################################################
#
#to add this code into sage
#sage: attach("dom_inequal.sage")
#
#reducible configurations are encoded as geogebra files
#green vertices are in the big graph (set S, being removed)
#red vertices are in the small graph (what we replace S with)
#default color vertices are the rest of the graph
#magenta vertices are the rest of the graph but guarenteed to have degree at least 2
#red edges are in the small graph (added when we remove S)
#
#to add a reducible configuration to the system of inequalities
#sage: add_reducible(*geogebra_extract(filename))
#
#to solve to system of inequalities
#sage: solve()
#no output means there is a solution
#lots of output means errors occurred; no solution
#
#remove the last inequality added (can be used iteratively to remove multiple inequalities)
#sage: remove_last()
#
#print the current values of the weights
#sage: get_values()
