#!/bin/bash
#
# Usage: $0 <Contents Directory> <Title> <Author>
# It will create epub and epub.source
#
DIR="$1"
TITLE="$2"
AUTHOR="$3"
ID=`echo urn:uuid:\`date "+%s"\`.\`whoami\`.\`hostname\``
DATE=`date "+%Y-%m-%d"`

WORK="$TITLE.epub.source"
rm -rf $WORK
mkdir -v $WORK
mkdir -vp "$WORK/OEBPS/image"

cat <<EOF > $WORK/OEBPS/content.opf
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="2.0">
<metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:opf="http://www.idpf.org/2007/opf">
<dc:title>$TITLE</dc:title>
<dc:creator>$AUTHOR</dc:creator>
<dc:language>ja</dc:language>
<dc:identifier id="BookId">$ID</dc:identifier>
</metadata>
<manifest>
EOF
echo created content.ncx

cat <<EOF >$WORK/OEBPS/toc.ncx
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" xml:lang="ja" version="2005-1">
<head>
<meta name="dtb:uid" content="$ID" />
<meta name="dtb:depth" content="1" />
<meta name="dtb:totalPageCount" content="0" />
<meta name="dtb:maxPageNumber" content="0" />
</head>
<docTitle>
<text>$TITLE</text>
</docTitle>
<navMap>
EOF
echo created toc.ncx


for file in $DIR/*{.jpg,.png,.jpeg}
do
	if [ -e $file ]
	then
		cp $file $WORK/OEBPS/image/
		basename=$(basename $file)
		basename=${basename%.jpg}
		htmlname=$WORK/OEBPS/$basename.html
	echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
	<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
	<html xmlns=\"http://www.w3.org/1999/xhtml\">
	<head>
	<meta http-equiv=\"Content-Type\" content=\"application/xhtml+xml; charset=utf-8\" />
	<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />
	<title>$basename</title>
	</head>
	<body>
	<img src=\"image/$(basename $file)\" alt=\"$basename\" class=\"content\" />
	</body>
	</html>
	" > $htmlname
	echo created $htmlname

	#HTMLNAME=`echo $ | sed -e "s/.html//"`
	echo "<item id=\"$basename\" href=\"$basename.html\" media-type=\"application/xhtml+xml\" />" \
	>> $WORK/OEBPS/content.opf
	echo "<item id=\"$(basename $file)\" href=\"image/$(basename $file)\" media-type=\"image/jpeg\" />" \
	>> $WORK/OEBPS/content.opf
	fi
done

cat <<EOF >> $WORK/OEBPS/content.opf
<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />
<item id="style" href="style.css" media-type="text/css" />
</manifest>
<spine toc="ncx">
EOF


i=0
for file in $WORK/OEBPS/*.html
do
	i=$(( $i+1 ))
	echo "<itemref idref=\"$(basename $file)\" />" >> $WORK/OEBPS/content.opf

	cat <<EOF >> $WORK/OEBPS/toc.ncx
	<navPoint id="$(basename $file)" playOrder="$i">
	<navLabel>
	<text>Page $i</text>
	</navLabel>
	<content src="$(basename $file)" />
	</navPoint>" 
EOF
done

cat <<EOF >> $WORK/OEBPS/content.opf
    </spine>
</package> 
EOF

cat <<EOF >> $WORK/OEBPS/toc.ncx
    </navMap>
</ncx>
EOF

cat <<EOF > $WORK/OEBPS/style.css
body {
text-align: center;
margin: 0px;
padding: 0px;
}
img.content{
height: 99%;
}
EOF

echo "application/epub+zip" > $WORK/mimetype

mkdir $WORK/META-INF
cat <<EOF > $WORK/META-INF/container.xml
<?xml version="1.0" ?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
<rootfiles>
<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
</rootfiles>
</container>
EOF

pushd $WORK
zip -0 ../$TITLE.epub mimetype
zip -r -0 ../$TITLE.epub * -x mimetype
popd 


exit 0
