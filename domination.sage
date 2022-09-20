
import itertools
import geogebra_graph

def test_dominated(G, domination_set, dominated_set):
	for v in dominated_set:
		#print("Testing if", v, "is dominated")
		v_dominated = False
		if v in domination_set:
			v_dominated = True
			#print(v, "is in the domination set")
		else:
			for u in G.neighbors(v):
				if u in domination_set:
					v_dominated = True
					#print(v, "is dominated by", u)
					break
		if not v_dominated:
			#print(v, "is not dominated")
			return False
	return True

def domination_reducible(big_graph, small_graph, precolor_verts, reducer_verts, extend_verts):
	print("small graph: ", small_graph.graph6_string())
	print("big graph: ", big_graph.graph6_string())
	num_domination_verts = (big_graph.num_verts() - small_graph.num_verts())//3
	
	poss_dominating = list(set().union(precolor_verts,reducer_verts))

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
			#print("Dominating precolors: ", dominating_precolors)

			# try to dominate what is not already being dominated by adding dominating vertices to the extender verts, using num_dominating_in_reducer + num_domination_verts
			flag = False
			#print("Trying to dominate big graph with ", num_dominating_in_reducer + num_domination_verts, " verts")
			for test_dominating in itertools.combinations(extend_verts, num_dominating_in_reducer + num_domination_verts):
				#print("Trying...", test_dominating)
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
	precolor_verts = [v for v in G.vertices() if v not in extend_verts and v not in reducer_verts] # rest of vertices

	new_order = precolor_verts + reducer_verts + extend_verts # the new order of the vertices
	new_permutation = {v:i for i,v in enumerate(new_order)}
	G.relabel(perm = new_permutation, inplace=True)
	new_precolor_verts = list(range(len(precolor_verts)))
	new_reducer_verts = list(range(len(precolor_verts), len(precolor_verts)+len(reducer_verts)))
	new_extend_verts = list(range(len(precolor_verts)+len(reducer_verts), G.num_verts()))

	reducer_edges = [e for e in G.edges() if e[2]['color'][:3] == (255,0,0)] # red edges

	precolor_graph = G.subgraph(vertices = new_precolor_verts + new_reducer_verts)
	extend_graph = G.subgraph(vertices = new_precolor_verts + new_extend_verts)
	extend_graph.delete_edges(reducer_edges)

	return extend_graph, precolor_graph, new_precolor_verts, new_reducer_verts, new_extend_verts

#############################################################################
#
#add this code into sage (need to do this every time you boot up sage)
#sage: attach("domination.sage")
#
#configurations are encoded in geogebra files
#green vertices are in the big graph (in S, removed)
#red vertices are in the small graph (what we replace S with)
#default color vertices are the rest of the graph
#red edges are in the small graph (added when we remove S)
#
#check if a configuration is reducible
#sage: domination_reducible(*geogebra_extract(filename))
