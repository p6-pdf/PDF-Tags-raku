role PDF::Tags::Node::Root {
    use PDF::StructTreeRoot;
    method cos(--> PDF::StructTreeRoot) { callsame() }
    method parent      { fail "already at root" }
    method name        { '#root' }
    method read        {...}
    method raw         {...}
    method class-map   {...}
    method role-map    {...}
    method parent-tree {...}
}

=begin pod
=end pod
