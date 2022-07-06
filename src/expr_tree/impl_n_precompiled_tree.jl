module M_implementation_pre_n_compiled_tree

using ..M_abstract_expr_node, ..M_trait_tree, ..M_implementation_expr_tree, ..M_trait_expr_node, ..M_abstract_expr_tree

mutable struct New_field
  op::M_abstract_expr_node.Abstract_expr_node
end

@inline create_New_field(op::M_abstract_expr_node.Abstract_expr_node) = New_field(op)

@inline get_op_from_field(field::New_field) = field.op

"""
    Eval_n_node{Y <: Number}

Represent a node with:

* `field::New_field` an operator;
* `vec_tmp_children::Vector{Vector{M_abstract_expr_node.MyRef{Y}}}` the value of the children;
* `vec_tmp_n_eval::Vector{Vector{M_abstract_expr_node.MyRef{Y}}}` the value of the current node;
* `children::Vector{Eval_n_node{Y}}` the children of the current node;
* `length_children::Int` the number of children;
* `length_n_eval::Int` the number of simultaneous evaluation supported.
"""
mutable struct Eval_n_node{Y <: Number}
  field::New_field
  vec_tmp_children::Vector{Vector{M_abstract_expr_node.MyRef{Y}}}
  vec_tmp_n_eval::Vector{Vector{M_abstract_expr_node.MyRef{Y}}}
  children::Vector{Eval_n_node{Y}}
  length_children::Int
  length_n_eval::Int
end

"""
    Pre_n_compiled_tree{Y <: Number} <: AbstractExprTree

Represent an expression tree that can be evaluate simultaneously by several points.
It has the fields:

* `root::Eval_n_node{Y}` the root of the expression tree;
* `multiple_x::Vector{AbstractVector{Y}}` the multiple inputs `x` of the `Pre_n_compiled_tree`
* `multiple::Int` the number of simultaneous evaluation supported;
* `vec_tmp::Vector{M_abstract_expr_node.MyRef{Y}}` the result of the `multiple` evaluations.
"""
mutable struct Pre_n_compiled_tree{Y <: Number} <: AbstractExprTree
  root::Eval_n_node{Y}
  multiple_x::Vector{AbstractVector{Y}}
  multiple::Int
  vec_tmp::Vector{M_abstract_expr_node.MyRef{Y}}
end

@inline get_root(tree::Pre_n_compiled_tree{Y}) where {Y <: Number} = tree.root

@inline get_multiple(tree::Pre_n_compiled_tree{Y}) where {Y <: Number} = tree.multiple

@inline get_multiple_x(tree::Pre_n_compiled_tree{Y}) where {Y <: Number} = tree.multiple_x

function set_multiple_x!(
  tree::Pre_n_compiled_tree{Y},
  new_multiple_x::Vector{Vector{Y}},
) where {Y <: Number}
  n = length(new_multiple_x)
  n == length(tree.multiple_x) || error("error set_multiple_x!")
  for i = 1:n
    tree.multiple_x[i] .= new_multiple_x[i]
  end
end

function set_multiple_x!(
  tree::Pre_n_compiled_tree{T},
  new_multiple_x::Vector{SubArray{T, 1, Array{T, 1}, N, false}},
) where {N} where {T <: Number}
  n = length(new_multiple_x)
  n == length(tree.multiple_x) || error("error set_multiple_x!")
  for i = 1:n
    tree.multiple_x[i] .= new_multiple_x[i]
  end
end

@inline get_vec_tmp(tree::Pre_n_compiled_tree{Y}) where {Y <: Number} = tree.vec_tmp

@inline get_field_from_node(node::Eval_n_node{Y}) where {Y <: Number} = node.field

@inline get_children_vector_from_node(node::Eval_n_node{Y}) where {Y <: Number} = node.children

@inline get_children_from_node(node::Eval_n_node{Y}, i::Int) where {Y <: Number} = node.children[i]

@inline get_vec_tmp_children(node::Eval_n_node{Y}) where {Y <: Number} = node.vec_tmp_children

@inline get_vec_tmp_n_eval(node::Eval_n_node{Y}) where {Y <: Number} = node.vec_tmp_n_eval

@inline get_tmp_for_n_eval_child(node::Eval_n_node{Y}, i::Int) where {Y <: Number} =
  get_vec_tmp_n_eval(node)[i]

@inline get_tmp_eval_node(node::Eval_n_node{Y}, i::Int) where {Y <: Number} =
  get_vec_tmp_children(node)[i]

@inline get_op_from_node(node::Eval_n_node{Y}) where {Y <: Number} =
  get_op_from_field(get_field_from_node(node))

@inline get_length_children(node::Eval_n_node{Y}) where {Y <: Number} = node.length_children

@inline get_length_n_eval(node::Eval_n_node{Y}) where {Y <: Number} = node.length_n_eval

@inline create_eval_n_node(
  field::New_field,
  vec_tmp_children::Vector{Vector{MyRef{Y}}},
  vec_tmp_n_eval::Vector{Vector{MyRef{Y}}},
  children::Vector{Eval_n_node{Y}},
  n_children::Int,
  n_eval::Int,
) where {Y <: Number} =
  Eval_n_node{Y}(field, vec_tmp_children, vec_tmp_n_eval, children, n_children, n_eval)

function create_eval_n_node(
  field::New_field,
  children::Vector{Eval_n_node{Y}},
  n_eval::Int,
) where {Y <: Number}
  n_children = length(children)
  vec_tmp_children = M_abstract_expr_node.create_vector_of_vector_myRef(n_eval, n_children, Y)
  vec_tmp_n_eval = M_abstract_expr_node.create_vector_of_vector_myRef(n_children, n_eval, Y)
  M_abstract_expr_node.equalize_vec_vec_myRef!(vec_tmp_n_eval, vec_tmp_children)
  return create_eval_n_node(field, vec_tmp_children, vec_tmp_n_eval, children, n_children, n_eval)
end

@inline create_eval_n_node(field::New_field, n_eval::Int, type::DataType = Float64) =
  create_eval_n_node(field, Vector{Eval_n_node{type}}(undef, 0), n_eval)

function create_pre_n_compiled_tree(
  tree::M_implementation_expr_tree.Type_expr_tree,
  multiple_x_view::Vector{SubArray{T, 1, Array{T, 1}, N, false}},
) where {N} where {T <: Number}
  view_of_view = big_view(multiple_x_view)
  compiled_tree = _create_pre_n_compiled_tree(tree, view_of_view)
  tmp = create_new_vector_myRef(length(view_of_view), T)
  Pre_n_compiled_tree{T}(compiled_tree, view_of_view, length(multiple_x_view), tmp)
end

function big_view(
  multiple_x_view::Vector{SubArray{T, 1, Array{T, 1}, N, false}},
) where {N} where {T <: Number}
  n = length(multiple_x_view)
  res = Vector{SubArray{T, 1, Array{T, 1}, N, false}}(undef, n)
  for i = 1:n
    nᵢ = length(multiple_x_view[i])
    res[i] = view(multiple_x_view[i], [1:nᵢ;])::SubArray{T, 1, Array{T, 1}, N, false}
  end
  return res
end

function _create_pre_n_compiled_tree(
  tree::M_implementation_expr_tree.Type_expr_tree,
  multiple_x_view::Vector{SubArray{T, 1, Array{T, 1}, N, false}},
) where {N} where {T <: Number}
  nd = M_trait_tree.get_node(tree)
  ch = M_trait_tree.get_children(tree)
  n_eval = length(multiple_x_view)
  if isempty(ch)
    new_op = M_abstract_expr_node.create_node_expr(nd, multiple_x_view)
    New_field = create_New_field(new_op)
    new_node = create_eval_n_node(New_field, n_eval, T)
    return new_node
  else
    new_ch = map(child -> _create_pre_n_compiled_tree(child, multiple_x_view), ch)
    New_field = create_New_field(nd)
    return create_eval_n_node(New_field, new_ch, n_eval)
  end
end

function create_pre_n_compiled_tree(
  tree::M_implementation_expr_tree.Type_expr_tree,
  multiple_x::Vector{Vector{T}},
) where {T <: Number}
  new_multiple_x = copy(multiple_x)
  compiled_tree = _create_pre_n_compiled_tree(tree, new_multiple_x)
  tmp = create_new_vector_myRef(length(new_multiple_x), T)
  Pre_n_compiled_tree{T}(compiled_tree, new_multiple_x, length(new_multiple_x), tmp)
end

function _create_pre_n_compiled_tree(
  tree::M_implementation_expr_tree.Type_expr_tree,
  multiple_x::Vector{Vector{T}},
) where {T <: Number}
  nd = M_trait_tree.get_node(tree)
  ch = M_trait_tree.get_children(tree)
  n_eval = length(multiple_x)
  if isempty(ch)
    new_op = M_abstract_expr_node.create_node_expr(nd, multiple_x)
    New_field = create_New_field(new_op)
    new_node = create_eval_n_node(New_field, n_eval, T)
    return new_node
  else
    new_ch = map(child -> _create_pre_n_compiled_tree(child, multiple_x), ch)
    New_field = create_New_field(nd)
    return create_eval_n_node(New_field, new_ch, n_eval)
  end
end

function evaluate_pre_n_compiled_tree(
  tree::Pre_n_compiled_tree{T},
  multiple_x_view::Vector{SubArray{T, 1, Array{T, 1}, N, false}},
) where {N} where {T <: Number}
  n_eval = length(multiple_x_view)
  n_eval == get_multiple(tree) ||
    error("mismatch between the vector of points and the pre_compilation of the tree")
  set_multiple_x!(tree, multiple_x_view)
  root = get_root(tree)
  vec_tmp = get_vec_tmp(tree)
  evaluate_eval_n_node!(root, vec_tmp)
  length(vec_tmp) == 1 ? res = M_abstract_expr_node.get_myRef(vec_tmp[1])::T : res = sum(vec_tmp)::T
  return res::T
end

function evaluate_pre_n_compiled_tree(
  tree::Pre_n_compiled_tree{T},
  multiple_v::Vector{Vector{T}},
) where {T <: Number}
  n_eval = length(multiple_v)
  n_eval == get_multiple(tree) ||
    error("mismatch between the vector of points and the pre_compilation of the tree")
  set_multiple_x!(tree, multiple_v)
  root = get_root(tree)
  vec_tmp = get_vec_tmp(tree)
  evaluate_eval_n_node!(root, vec_tmp)
  length(vec_tmp) == 1 ? res = M_abstract_expr_node.get_myRef(vec_tmp[1])::T : res = sum(vec_tmp)::T
  return res::T
end

function evaluate_pre_n_compiled_tree(tree::Pre_n_compiled_tree{T}) where {T <: Number}
  root = get_root(tree)
  vec_tmp = get_vec_tmp(tree)
  evaluate_eval_n_node!(root, vec_tmp)
  length(vec_tmp) == 1 ? res = M_abstract_expr_node.get_myRef(vec_tmp[1])::T : res = sum(vec_tmp)::T
  return res::T
end

function evaluate_eval_n_node!(
  node::Eval_n_node{T},
  tmp::AbstractVector{MyRef{T}},
) where {T <: Number}
  op = get_op_from_node(node)
  if M_trait_expr_node.node_is_operator(op)::Bool == false
    M_trait_expr_node._evaluate_node!(op, tmp)
  else
    n = get_length_children(node)
    for i = 1:n
      child = get_children_from_node(node, i)
      vector_ref = get_tmp_for_n_eval_child(node, i)
      evaluate_eval_n_node!(child, vector_ref)
    end
    vec_values_children = get_vec_tmp_children(node)
    M_trait_expr_node._evaluate_node!(op, vec_values_children, tmp)
  end
end

end
