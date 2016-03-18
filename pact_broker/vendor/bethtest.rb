require 'set'

class Link
  def initialize from, to
    @from = from
    @to = to
  end

  def include? endpoint
    @from == endpoint || @to == endpoint
  end

  def connected? other
    (self.to_a & other.to_a).any?
  end

  def to_s
    "#{@from} - #{@to}"
  end

  def to_a
    [@from, @to]
  end

end

def unique_nodes links
  links.collect(&:to_a).flatten.uniq.sort
end

def nodes_connected_to_node node, links
  unique_nodes links.select{|l|l.include?(node)}
end

def connected_links link, link_pool
  link_pool.select{|l| l.connected?(link)}
end

def nodes_connected_to_nodes_within_pool nodes, links, node_pool
  nodes.collect{ | node | nodes_connected_to_node(node, links) }.flatten & node_pool
end

def connected_links_still_within_pool links, link_pool
  links.collect{ | link | connected_links(link, link_pool) }.flatten.uniq
end

def split_into_clusters_of_nodes links
  node_pool =  unique_nodes links
  groups = []

  while node_pool.any?
    group = []
    groups << group
    connected_nodes = [node_pool.first]

    while connected_nodes.any?
      group.concat(connected_nodes)
      node_pool = node_pool - connected_nodes
      connected_nodes = nodes_connected_to_nodes_within_pool connected_nodes, links, node_pool
    end
  end

  groups
end

def recurse link, link_pool
  connected_links = link_pool.select{ | candidate| candidate.connected?(link) }
  if connected_links.empty?
    [link]
  else
    ([link] + connected_links.map{| connected_link| recurse(connected_link, link_pool - connected_links)}.flatten).uniq
  end
end

def recurse_groups groups, link_pool
  if link_pool.empty?
    groups
  else
    first, *rest = *link_pool
    group = recurse first, rest
    recurse_groups(groups + [group], link_pool - group)
  end
end

def split_into_clusters_of_links links
  recurse_groups [], links.dup
end

links = [Link.new('A', 'B'), Link.new('A', 'C'), Link.new('C', 'D'), Link.new('D', 'E'), Link.new('E','A'),
  Link.new('Y', 'Z'), Link.new('X', 'Y'),
  Link.new('M', 'N'), Link.new('N', 'O'), Link.new('O', 'P'), Link.new('P','Q')]


groups = split_into_clusters_of_nodes links

puts groups.collect{ | group| "group = #{group.join(" ")}"}

groups = split_into_clusters_of_links links
puts groups.collect{ | group| "group = #{group.join(", ")}"}




