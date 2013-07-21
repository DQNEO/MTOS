<?php

$url = $_GET['url'];
$html = file_get_contents($url);

if (!preg_match('#<title>(.+)</title>#', $html, $matched)) {
   echo "no title";
   exit;
}
$title = $matched[1];

if (preg_match('#charset=([a-z_\-]+)#i', $html, $matched)) {
   $encoding = $matched[1];
} else {
 $encoding = null;
}
//echo $encoding;
//exit;


echo mb_convert_encoding($title, 'utf-8', $encoding);			


exit;

