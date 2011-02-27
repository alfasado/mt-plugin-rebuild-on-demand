<?php
function rebuildondemand_post_init( $mt, &$ctx, &$args ) {
    $app = $ctx->stash( 'bootstrapper' );
    $request = $app->stash( 'request' );
    $file = $app->stash( 'file' );
    if ( file_exists( $file ) ) return;
    $fileinfo = $mt->resolve_url( $mt->db()->escape( urldecode( $request ) ), array( 1, 2, 4 ) );
    if (! $fileinfo ) return;
    if ( $fileinfo->virtual ) return;
    $app->stash( 'fileinfo', $fileinfo );
    $language = $app->config( 'RebuildLanguage' );
    if ( $language == 'PHP' ) {
        $output = $app->rebuild_from_fileinfo( $fileinfo );
        if ( is_string( $output ) ) {
            $app->write2file( $file, $output );
        }
    } elseif ( $language == 'Perl' ) {
        $mt_dir = $app->stash( 'mt_dir' );
        $perl_script = $mt_dir . DIRECTORY_SEPARATOR . 'tools' . DIRECTORY_SEPARATOR . 'rebuild-from-fileinfo';
        if ( file_exists( $perl_script ) ) {
            $fileinfo_id = $fileinfo->fileinfo_id;
            $command = '.' . DIRECTORY_SEPARATOR . 'tools' . DIRECTORY_SEPARATOR . 'rebuild-from-fileinfo';
            $command = escapeshellcmd( $command );
            $ctx->force_compile = true;
            $res = exec( "cd $mt_dir;$command $fileinfo_id 1;" );
        }
    }
}
?>