
import itertools
import geogebra_graph

weights = [6, 3, 3, 2]
multiplier = 6

def weight(G,focus_verts):
	res = 0
	for v in focus_verts:
		deg = G.degree(v)
		if deg == 0:
			res += weights[0]
		elif deg == 1:
			res += weights[1]
		elif deg == 2:
			res += weights[2]
		elif deg == 3:
			res += weights[3] 
	return res

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

def domination_reducible(big_graph, small_graph, precolor_verts, reducer_verts, extend_verts):
	print("small graph: ", small_graph.graph6_string())
	print("big graph: ", big_graph.graph6_string())

	print("weight of big graph:", weight(big_graph, extend_verts))
	print("weight of small graph:", weight(small_graph, reducer_verts))

	max_weight_change = 0
	for v in precolor_verts:
		deg_change = big_graph.degree(v) - small_graph.degree(v)
		if deg_change == 3:
			max_weight_change += min([weights[i] - weights[i-3] for i in [3]])
		elif deg_change == 2:
			max_weight_change += min([weights[i] - weights[i-2] for i in [3]])
		elif deg_change == 1:
			max_weight_change += min([weights[i] - weights[i-1] for i in [3]])
		else:
			max_weight_change += min([weights[i] - weights[i-0] for i in [3]])

	print("max weight change from precolors:", max_weight_change)
	num_domination_verts = (weight(big_graph, extend_verts) - weight(small_graph, reducer_verts) + max_weight_change)//multiplier

	print("num dominating is: ", num_domination_verts)
	
	poss_dominating = list(set().union(precolor_verts, reducer_verts))

	for r in range(0, len(poss_dominating)+1):
		for dominating in itertools.combinations(poss_dominating,r):
			# check if the reducer verts are dominated
			if not test_dominated(small_graph, dominating, reducer_verts):
				continue

			# we are removing the reducer vertices, so any dominating vertices from there are "free"
			num_dominating_in_reducer = len([i for i in dominating if i in reducer_verts])

			# what precolor_verts are dominated
			dominated_precolors = []
			for v in dominating:
				for u in small_graph.neighbors(v):
					if u in precolor_verts and u not in dominating:
						dominated_precolors.append(u)

			#print("Dominated precolors: ", dominated_precolors)

			dominating_precolors = tuple(set(dominating).intersection(precolor_verts))


			# try to dominate what is not already being dominated by adding dominating vertices to the extender verts, using num_dominating_in_reducer + num_domination_verts
			flag = False
			#print("Trying to dominate big graph with ", num_dominating_in_reducer + num_domination_verts, " verts")
			for test_dominating in itertools.combinations(extend_verts, num_dominating_in_reducer + num_domination_verts):
				if test_dominated(big_graph, dominating_precolors + test_dominating, extend_verts + dominated_precolors):
					flag = True
					print("When dominating is: ", dominating, " we can add the following: ", test_dominating)
					break
			if not flag:
				# fail in this case, so we fail totally
				print("Fail to be reducible when dominating is: ", dominating)
				return False
	return True

def geogebra_extract(filename):
	# assumes geogebra file has all the information to determine extend_graph, precolor_graph, and precolor_verts
	G = geogebra_graph.geogebra_to_graph(filename)

	extend_verts = [v for v in G.vertices() if G.get_vertex(v)['color'][:3] == (0,255,0)] # green vertices
	reducer_verts = [v for v in G.vertices() if G.get_vertex(v)['color'][:3] == (255,0,0)] # red vertices
	recolor_verts = [v for v in G.vertices() if G.get_vertex(v)['color'][:3] == (255,0,255)] # magenta vertices
	precolor_verts = [v for v in G.vertices() if v not in extend_verts and v not in reducer_verts] # rest of vertices

	new_order = precolor_verts + reducer_verts + extend_verts # the new order of the vertices
	new_permutation = {v:i for i,v in enumerate(new_order)}
	G.relabel(perm = new_permutation, inplace=True)
	new_precolor_verts = list(range(len(precolor_verts)))
	new_reducer_verts = list(range(len(precolor_verts), len(precolor_verts)+len(reducer_verts)))
	new_extend_verts = list(range(len(precolor_verts)+len(reducer_verts), G.num_verts()))

	new_recolor_verts = [v for v in G.vertices() if G.get_vertex(v)['color'][:3] == (255,0,255)] # magenta vertices
	new_extend_verts.extend(new_recolor_verts)
	new_reducer_verts.extend(new_recolor_verts)

	reducer_edges = [e for e in G.edges() if e[2]['color'][:3] == (255,0,0)] # red edges

	precolor_graph = G.subgraph(vertices = new_precolor_verts + new_reducer_verts)
	extend_graph = G.subgraph(vertices = new_precolor_verts + new_extend_verts)
	extend_graph.delete_edges(reducer_edges)

	return extend_graph, precolor_graph, new_precolor_verts, new_reducer_verts, new_extend_verts

#############################################################################
#
#weights can be changed at the top of this file look for the lines
#weights = [6, 3, 3, 2]
#multiplier = 6
#change the first to be [w0, w1, w2, w3], and the second to be the coeff on gamma
#
#add this code into sage (needs to be done every time you open sage)
#sage: attach("domination_weighted.sage")
#
#configurations are encoded in a geogebra file
#green vertices are in the big graph (in S, removed)
#red vertices are in the small graph (what replaces S)
#default color vertices are the rest of the graph
#red edges are in the small graph (added when we remove S)
#
#to test if a configuration is reducible
#sage: domination_reducible(*geogebra_extract(filename))
