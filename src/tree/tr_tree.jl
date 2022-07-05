module M_trait_tree

import ..M_abstract_tree.AbstractTree
import ..M_interface_tree: _get_node, _get_children

export get_node
export get_children

"""Type instantiated dynamically that checks if an argument is a tree."""
struct Type_trait_tree end
"""Type instantiated dynamically that checks if an argument is not a tree."""
struct Type_not_trait_tree end

"""
    Type_trait_tree = is_type_trait_tree(a::AbstractTree)
    Type_trait_tree = is_type_trait_tree(a::Expr)
    Type_trait_tree = is_type_trait_tree(a::Number)
    Type_not_trait_tree = is_type_trait_tree(a::Any)

Return a `Type_trait_tree` only for `AbstractTree, Expr` or `Number` (a leaf of a tree).
In the other cases it returns `Type_not_trait_tree`.
"""
@inline is_type_trait_tree(a::AbstractTree) = Type_trait_tree()
@inline is_type_trait_tree(a::Expr) = Type_trait_tree()
@inline is_type_trait_tree(a::Number) = Type_trait_tree()
@inline is_type_trait_tree(a::Any) = Type_not_trait_tree()

"""
    node = get_node(tree)

Get the current `node` as a part of `tree`.
"""
@inline get_node(a) = _get_node(a, is_type_trait_tree(a))
@inline _get_node(a, b::Type_trait_tree) = _get_node(a)
@inline _get_node(a, b::Type_not_trait_tree) = error(" The parameter is not a Tree")

"""
    children = get_children(tree)

Get the `children` from the current node as part of `tree`.
"""
@inline get_children(a) = _get_children(a, is_type_trait_tree(a))
@inline _get_children(a, ::Type_trait_tree) = _get_children(a)
@inline _get_children(a, ::Type_not_trait_tree) = error(" The parameter is not a Tree")

end  # module trait_tree

module algo_tree

using ..M_trait_tree
export printer_tree

function printer_tree(tree, deepth = 0)
  ident = "\t"^deepth
  nd = get_node(tree)
  println(ident, nd)
  ch = get_children(tree)
  printer_tree.(ch, deepth + 1)
end

end
