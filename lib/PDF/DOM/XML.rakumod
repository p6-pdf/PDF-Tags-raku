unit class PDF::DOM::XML;

use PDF::Annot;
use PDF::DOM :StructNode;
use PDF::DOM::Elem;
use PDF::DOM::Item;
use PDF::DOM::ObjRef;
use PDF::DOM::Root;
use PDF::DOM::Tag;
use PDF::DOM::Text;

has UInt $.max-depth = 16;
has Bool $.render = True;
has Bool $.atts = True;
has Bool $.debug = False;
has Bool $.skip = False;

sub line(UInt $depth, Str $s = '') { ('  ' x $depth) ~ $s ~ "\n" }

sub html-escape(Str $_) {
    .trans:
        /\&/ => '&amp;',
        /\</ => '&lt;',
        /\>/ => '&gt;',
        
}
sub str-escape(Str $_) {
    html-escape($_).trans: /\"/ => '&quote;';
}

multi method Str(PDF::DOM::Root $_, :$depth = 0) {
    .kids.map({self.Str($_, :$depth)}).join;
}

sub atts-str(%atts) {
    %atts.pairs.sort.map({ " {.key}=\"{str-escape(.value)}\"" }).join;
}

method !skip($tag) { $!skip && $tag eq 'Span' }

multi method Str(PDF::DOM::Elem $node, UInt :$depth is copy = 0) {
    my @frag;
    if $!debug {
        @frag.push: line($depth, "<!-- elem {.obj-num} {.gen-num} R ({.WHAT.^name})) -->")
            given $node.item;
    }
    my $tag = $node.tag;
    my $att = do if $!atts {
        my %attributes = $node.attributes;
        %attributes<O>:delete;
        atts-str(%attributes);
    }
    else {
        $tag = $_
            with $node.dom.role-map{$tag};
        ''
    }


    if $depth >= $!max-depth {
        @frag.push: line($depth, "<$tag$att/> <!-- depth exceeded, see {$node.item.obj-num} {$node..item.gen-num} R -->");
    }
    else {
        with $node.actual-text {
            @frag.push: line($depth, '<!-- actual text -->')
                if $!debug;
            given trim($_) {
                @frag.push: $_ eq ''
                            ?? line($depth, "<$tag$att/>")
                            !! line($depth, self!skip($tag) ?? $_ !! "<$tag$att>{html-escape($_) }</$tag>");
            }
        }
        else {
            my $elems = $node.elems;
            if $elems {
                @frag.push: line($depth++, "<$tag$att>")
                    unless self!skip($tag);
        
                for 0 ..^ $elems {
                    @frag.push: self.Str($node.kids[$_], :$depth);
                }

                @frag.push: line(--$depth, "</$tag>")
                    unless self!skip($tag);
            }
            else {
                @frag.push: line($depth, "<$tag$att/>")
                    unless self!skip($tag);
            }
        }
    }
    @frag.join;
}

multi method Str(PDF::DOM::ObjRef $_, :$depth!) {
    ($!debug ?? line($depth, "<!-- OBJR {.object.obj-num} {.object.gen-num} R -->") !! '')
     ~ self.dump-object(.object, :$depth);
}

multi method Str(PDF::DOM::Tag $node, :$depth!) {
    my @frag;
    if $!debug {
        @frag.push: line($depth, "<!-- tag <{.name}> ({.WHAT.^name})) -->")
            given $node.item;
    }
    if $!render {
        with $node.item.?Stm {
            warn "can't handle marked content streams yet";
        }
        else {
            @frag.push: line($depth, self!tag-content($node, :$depth));
        }
    }
    @frag.join;
}

multi method Str(PDF::DOM::Text $_, :$depth!) {
    line($depth, .Str)
}

method !tag-content(PDF::DOM::Tag $node, :$depth!) is default {
    # join text strings. discard this, and child marked content tags for now
    my $text = $node.actual-text // do {
        my @text = $node.kids.map: {
            when PDF::DOM::Tag {
                my $text = trim(self!tag-content($_, :$depth));
            }
            when PDF::DOM::Text { html-escape(.Str) }
            default { die "unhandled tagged content: {.WHAT.perl}"; }
        }
        @text.join;
    }
    my $tag = $node.tag;
    my $atts = atts-str($node.attributes);
    ($!skip
     && ($node.tag eq 'Document'
         || self!skip($tag)
         || $node.item ~~ PDF::Content::Tag::Marked && $node.tag eq $node.parent.tag))
        ?? $text
        !! ($text ?? "<$tag$atts>"~$text~"</$tag>" !! "<$tag$atts/>");
}

multi method dump-object(PDF::Field $_, :$depth!) {
    warn "todo: dump field obj" if $!debug; '';
}

multi method dump-object(PDF::Annot $_, :$depth!) {
    warn "todo: dump annot obj: " ~ .perl if $!debug;
    '';
}