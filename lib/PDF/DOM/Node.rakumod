use PDF::DOM::Item :&item-class, :&build-item;

class PDF::DOM::Node
    is PDF::DOM::Item {

    my subset NCName of Str where { !.defined || $_ ~~ /^<ident>$/ }

    has PDF::DOM::Item @.kids;
    has Hash $!store;
    has Bool $!loaded;
    has UInt $!elems;

    method elems {
        $!elems //= do with $.value.kids {
            when Hash { 1 }
            default { .elems }
        } // 0;
    }

    method AT-POS(UInt $i) {
        fail "index out of range 0 .. $.elems: $i" unless 0 <= $i < $.elems;
        my Any:D $value = $.value.kids[$i];
        @!kids[$i] //= build-item($value, :parent(self), :$.Pg, :$.dom);
    }
    method Array {
        $!loaded ||= do {
            self.AT-POS($_) for 0 ..^ $.elems;
            True;
        }
        @!kids;
    }
    method Hash handles <keys pairs> {
        $!store //= do {
            my %h;
            %h{.tag}.push: $_ for self.Array;
            %h;
        }
        $!store;
    }
    multi method AT-KEY(NCName:D $tag) {
        # special case to handle default namespaces without a prefix.
        # https://stackoverflow.com/questions/16717211/
        self.Hash{$tag};
    }
    multi method AT-KEY(Str:D $xpath) is default {
        $.xpath-context.AT-KEY($xpath);
    }
    method kids {
        my class Kids does Iterable does Iterator does Positional {
            has PDF::DOM::Item $.node is required handles<elems AT-POS>;
            has int $!idx = 0;
            method iterator { $!idx = 0; self}
            method pull-one {
                $!idx < $!node.elems ?? $!node.AT-POS($!idx++) !! IterationEnd;
            }
            method Array handles<List list values map grep> { $!node.Array }
        }
        Kids.new: :node(self);
    }

    method xpath-context {
        (require ::('PDF::DOM::XPath::Context')).new: :node(self);
    }
    method find($expr) { $.xpath-context.find($expr) }

    method first($expr) {
        self.find($expr)[0] // PDF::DOM::Node
    }
}
