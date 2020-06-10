module convexity_detection

    using ..implementation_convexity_type
    using ..abstract_expr_tree
    using ..trait_tree, ..trait_expr_tree, ..trait_expr_node
    using ..implementation_tree, ..implementation_complete_expr_tree
    using ..bound_propagations


    convexity_tree{T} = implementation_tree.type_node{implementation_convexity_type.convexity_wrapper}


    create_convex_tree( tree :: implementation_tree.type_node) =  convexity_tree( implementation_convexity_type.init_conv_status(), create_convex_tree.(trait_tree.get_children(tree)))
    create_convex_tree( cst :: T) where T <: Number =  convexity_tree( implementation_convexity_type.init_conv_status(), [])
    get_convexity_status( cvx_tree :: convexity_tree) = implementation_convexity_type.get_convexity_wrapper(trait_tree.get_node(cvx_tree))

    constant_type() = implementation_convexity_type.constant_type()
    linear_type() = implementation_convexity_type.linear_type()
    convex_type() = implementation_convexity_type.convex_type()
    concave_type() = implementation_convexity_type.concave_type()
    unknown_type() = implementation_convexity_type.unknown_type()

    function set_convexity!( tree :: implementation_tree.type_node, cvx_tree :: convexity_tree, bounds_tree)
        node = trait_tree.get_node(tree)
        if trait_expr_node.node_is_operator(node) == false
            (length(trait_tree.get_children(tree)) == length(trait_tree.get_children(cvx_tree))) || error("le fils n'est pas vide set_convexity!")
            convex_wrapper = trait_tree.get_node(cvx_tree)
            status = trait_expr_node.node_convexity(node)
            implementation_convexity_type.set_convexity_wrapper!(convex_wrapper, status)
            # implementation_tree.set_convexity_wrapper(convex_wrapper, implementation_tree.linear_type())
        else
            children_tree = trait_tree.get_children(tree)
            children_convex_tree = trait_tree.get_children(cvx_tree)
            children_bounds_tree = trait_tree.get_children(bounds_tree)
            n = length(children_tree)
            (n == length(children_convex_tree) && n == length(children_bounds_tree) ) || error("different shape between trees set_convexity!")
            for i in 1:n
                set_convexity!(children_tree[i], children_convex_tree[i], children_bounds_tree[i])
            end
            son_cvxs = (x :: convexity_tree -> implementation_convexity_type.get_convexity_wrapper(trait_tree.get_node(x))).(children_convex_tree)
            convex_wrapper = trait_tree.get_node(cvx_tree)
            son_bounds = ( x -> bound_propagations.bound_to_tuple(trait_tree.get_node(x)) ).(children_bounds_tree)
            status = trait_expr_node.node_convexity(node, son_cvxs, son_bounds)
            implementation_convexity_type.set_convexity_wrapper!(convex_wrapper, status)
        end
    end




end
