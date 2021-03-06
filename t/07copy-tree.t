use v6;
use Test;
plan 3;

use lib 't';
use PDF::Class;
use PDF::Content::Tag :ParagraphTags, :InlineElemTags, :IllustrationTags, :StructureTags;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Mark;
use PDF::Tags::ObjRef;
use PDF::XObject;

my PDF::Class $pdf .= new;

my $page = $pdf.add-page;
my $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

my PDF::Tags $tags .= create: :$pdf;
my PDF::Tags::Elem $doc = $tags.add-kid: :name(Document);

$page.graphics: -> $gfx {
    my PDF::Tags::Elem $header;
    my PDF::Tags::Mark $mark;

    $header = $doc.add-kid: :name(Header1);
    $mark = $header.mark: $gfx, :name(Span), {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }
    my  PDF::XObject $Stm = $page.xobject-form: :BBox[0, 0, 200, 50];

    is $mark.xml.trim, '<Span/>';
    is $header.xml.trim, '<H1>Header text</H1>';
    my $copy = $header.copy-tree(:$Stm, :parent($doc));
    is $copy.xml.trim, '<H1>Header text</H1>';
}

done-testing;
