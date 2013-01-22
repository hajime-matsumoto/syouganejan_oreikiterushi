変換方法
=============

変換
--------
convert -channel Red -separate -modulate 110 -threshold 50000 -quality 30 0120.jpg 0120-m110.jpg

置き換え
-----------
mogrify -channel Red -separate -modulate 110 -threshold 50000 -quality 30 *

Acrobat Pro PPI
================
Acrobat	数値変換後
28.35 ピクセル/cm	72 ppi
37.80 ピクセル/cm	96 ppi
59.06 ピクセル/cm	150 ppi
118.11 ピクセル/cm	300 ppi
236.22 ピクセル/cm	600 ppi
472.44 ピクセル/cm	1200 ppi
944.88 ピクセル/cm	2400 ppi

ワーク例
=================
* ../本文.pdfを236.22 ピクセル/cm 600ppi程度で出力する。
* 保存先をPDFJPGSなどとする

    cd PDFJPGS/
    mkdir ../JPG
    i=0 ls *.jpg | while read file
    do
    i=$(( $i+1 ))
    new=$(printf 010_%04d.jpg $i)
    cp -v $file ../JPG/$new
    done
    
    cd ../JPG
    mogrify -channel Red -separate -modulate 110 -threshold 50000 -quality 30 *
		
		sh epubsh.sh しょうがねぇじゃん俺生きてるし 松本創

変換スクリプト epubsh.sh
===================
    TITLE="$1"
    AUTHOR="$2"
    PWDIR=`pwd`
    
    if [ -z $3 ]; then
    DIR=`pwd`
    else
    cd "$3"
    DIR=`pwd`
    fi
    
    
    ID=`echo urn:uuid:\`date "+%s"\`.\`whoami\`.\`hostname\``
    DATE=`date "+%Y-%m-%d"`
    
    
    cd "/tmp"
    mkdir -p "epubwork/OEBPS/image"
    
    cd epubwork/OEBPS
    cp "$DIR"/*.jpg "$DIR"/*.jpeg "$DIR"/*.png image
    cd image
    for FILE in *
    do
    mv "$FILE" `echo $FILE | tr ' ' '_'`
    done
    cd ..
    
    for IMG in $( ls image )
    do
    basename=`echo $IMG | sed -e "s/.jpg//" | sed -e "s/.png//" | sed -e "s/.jpeg//"`
    echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
    <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
    <html xmlns=\"http://www.w3.org/1999/xhtml\">
    <head>
    <meta http-equiv=\"Content-Type\" content=\"application/xhtml+xml; charset=utf-8\" />
    <link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\" />
    <title>$basename</title>
    </head>
    <body>
    <img src=\"image/$IMG\" alt=\"$basename\" class=\"content\" />
    </body>
    </html>
    " > "$basename".html
    done
    
    
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <package xmlns=\"http://www.idpf.org/2007/opf\" unique-identifier=\"BookId\" version=\"2.0\">
    <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:opf=\"http://www.idpf.org/2007/opf\">
    <dc:title>$TITLE</dc:title>
    <dc:creator>$AUTHOR</dc:creator>
    <dc:language>ja</dc:language>
    <dc:identifier id=\"BookId\">$ID</dc:identifier>
    </metadata>
    <manifest>" > content.opf
    
    
    echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
    <!DOCTYPE ncx PUBLIC \"-//NISO//DTD ncx 2005-1//EN\" \"http://www.daisy.org/z3986/2005/ncx-2005-1.dtd\">
    <ncx xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" xml:lang=\"ja\" version=\"2005-1\">
    <head>
    <meta name=\"dtb:uid\" content=\"$ID\" />
    <meta name=\"dtb:depth\" content=\"1\" />
    <meta name=\"dtb:totalPageCount\" content=\"0\" />
    <meta name=\"dtb:maxPageNumber\" content=\"0\" />
    </head>
    <docTitle>
    <text>$TITLE</text>
    </docTitle>
    <navMap>" > toc.ncx
    
    
    for HTML in $( ls *.html )
    do
    HTMLNAME=`echo $HTML | sed -e "s/.html//"`
    echo "    <item id=\"$HTMLNAME\" href=\"$HTML\" media-type=\"application/xhtml+xml\" />" >> content.opf
    done
    
    for IMG in $( ls image )
    do
    echo "    <item id=\"$IMG\" href=\"image/$IMG\" media-type=\"image/jpeg\" />" >> content.opf
    done
    
    
    echo "    <item id=\"ncx\" href=\"toc.ncx\" media-type=\"application/x-dtbncx+xml\" />
    <item id=\"style\" href=\"style.css\" media-type=\"text/css\" />
    </manifest>
    <spine toc=\"ncx\">" >> content.opf
    
    
    COUNT=0
    
    
    for HTML in $( ls *.html )
    do
    COUNT=`expr $COUNT + 1`
    HTMLNAME=`echo $HTML | sed -e "s/.html//"`
    echo "    <itemref idref=\"$HTMLNAME\" />" >> content.opf
    echo "    <navPoint id=\"$HTMLNAME\" playOrder=\"$COUNT\">
    <navLabel>
    <text>Page $COUNT</text>
    </navLabel>
    <content src=\"$HTML\" />
    </navPoint>" >> toc.ncx
    done
    
    
    echo "  </spine>
    </package>" >> content.opf
    
    echo " </navMap>
    </ncx>" >> toc.ncx
    
    
    echo "body {
    text-align: center;
    margin: 0px;
    padding: 0px;
    }
    
    img.content{
    height: 99%;
    }" > style.css
    
    
    cd ..
    
    
    echo "application/epub+zip" > mimetype
    
    mkdir META-INF
    cd META-INF
    
    echo "<?xml version=\"1.0\" ?>
    <container version=\"1.0\" xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\">
    <rootfiles>
    <rootfile full-path=\"OEBPS/content.opf\" media-type=\"application/oebps-package+xml\"/>
    </rootfiles>
    </container>" > container.xml
    
    
    cd ..
    zip -0 "$TITLE.epub" mimetype
    zip -r -0 "$TITLE.epub" * -x mimetype -x *.epub -x *.sh
    mv "$TITLE.epub" "$DIR"
    cd "$DIR"
    #rm -rf "/tmp/epubwork"


