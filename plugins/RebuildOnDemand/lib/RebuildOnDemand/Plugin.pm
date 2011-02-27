# DynamicMTML (C) 2010 Alfasado Inc.
# This program is distributed under the terms of the
# GNU General Public License, version 2.

package RebuildOnDemand::Plugin;
use strict;

sub _build_file_filter {
    my ( $eh, %args ) = @_;
    my $app = MT->instance();
    if ( ( ref $app ) ne 'MT::App::CMS' ) {
        return 1;
    }
    my $template = $args{ template };
    if (! $template->rebuild_od ) {
        return 1;
    }
    my $file = $args{ file };
    if (-e $file ) {
        unlink $file;
    }
    return 0;
}

sub _edit_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $plugin = MT->component( 'RebuildOnDemand' );
    my $pointer_node = $tmpl->getElementById( 'linked_file' );
    return unless $pointer_node;
    my $tg = $param->{ template_group };
    if ( ( $tg ne 'index' ) && ( $tg ne 'archive' ) ) {
        return;
    }
    my $blog = $app->blog;
    return unless $blog;
    my $node = $tmpl->createElement( 'app:setting', {
        label => $plugin->translate( 'Rebuild On Demand' ),
        id => 'rebuild_od',
        show_label => 0,
        label_class => 'top-level',
    } );
    my $label = $plugin->translate( 'Rebuild this template on demand' );
    my $inner = <<MTML;
    <label><input type="checkbox" name="rebuild_od" id="rebuild_od" value="1" <mt:if name="rebuild_od">checked="checked"</mt:if> /> $label</label>
    <input type="hidden" name="rebuild_od" value="0" />
<script type="text/javascript">
    jQuery( document ).ready( function() {
    jQuery( '#build-type' ).change( function() {
        if ( this.value == 3 ) {
            getByID('rebuild_od').checked = false;
            getByID('rebuild_od-field').style.display = 'none';
        } else {
            getByID('rebuild_od-field').style.display = 'block';
        }
    } );
    } );
</script>
<mt:if name="build_type_3">
<script type="text/javascript">
    getByID('rebuild_od-field').style.display = 'none';
</script>
</mt:if>
MTML
    $node->innerHTML( $inner );
    $tmpl->insertAfter( $node, $pointer_node );
    if ( my $id = $app->param( 'id' ) ) {
        require MT::Template;
        my $tmplate = MT::Template->load( $id );
        return unless $tmplate;
        my $site_url = $blog->site_url || '';
        $site_url .= '/' if $site_url !~ m!/$!;
        my $url = $site_url . $tmplate->outfile;
        $param->{ published_url } = $url;
    }
}

sub _template_table_source {
    my ( $cb, $app, $tmpl ) = @_;
    my $pointer = quotemeta( '<td class="publishing-method">' );
    my $insert = <<MTML;
    <td class="on-demand" style="text-align:center">
        <mt:if name="rebuild_od">
        <img src="<mt:var name="static_uri">images/status_icons/invert-flag.gif" alt="<__trans phrase="Enable">" title="<__trans phrase="Enable">" width="9" height="9" />
        <mt:else> - </mt:if>
    </td>
MTML
    $$tmpl =~ s/($pointer)/$insert$1/g;
    $pointer = quotemeta( '<th class="publishing-method"><__trans phrase="Publish"></th>' );
    $insert  = '<__trans_section component="RebuildOnDemand"><th class="on-demand"><__trans phrase="On Demand"></th></__trans_section>';
    $$tmpl =~ s/($pointer)/$insert$1/;
}

1;