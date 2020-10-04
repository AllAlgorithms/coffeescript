# G = [vertices]
# vertex = {
#   adjacency_list: [vertex_ids]
#   color: one of ["WHITE", "GRAY", "BLACK"]
#   parent: vertex
#   d: discovery time
#   f: finish time
# }

DFS_VISIT = (G, u) ->
  module.exports.time++
  u.d = module.exports.time
  u.color = "GRAY"
  for v_id in u.adjacency_list
    v = G[v_id]
    if v.color == "WHITE"
      v.parent = u
      DFS_VISIT(G, v)
  u.color = "BLACK"
  module.exports.time++
  u.f = module.exports.time

module.exports =
  time: null
  test: ->
    u0 = {adjacency_list: [1,3]}
    u1 = {adjacency_list: [0,2]}
    u2 = {adjacency_list: [1]}
    u3 = {adjacency_list: [0,2]}
    g = [u0, u1, u2, u3]
    return module.exports.DFS g
  ###
     u0
    / \
   u3 u1
    \ /
    u2
  ###
  DFS: (G) ->
    for u in G
      u.color = "WHITE"
      u.parent = undefined
    module.exports.time = 0
    for u in G
      if u.color == "WHITE"
        DFS_VISIT(G, u)
    return G
