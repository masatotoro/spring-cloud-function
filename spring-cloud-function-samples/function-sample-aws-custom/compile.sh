#!/usr/bin/env bash

MAINCLASS=com.example.LambdaApplication
ARTIFACT=function-sample-aws-custom
VERSION=3.0.0.RELEASE

rm -rf target
mkdir -p target/native-image

echo "Packaging $ARTIFACT with Maven"
# mvn -ntp package > target/native-image/output.txt
mvn package > target/native-image/output.txt


JAR="$ARTIFACT-$VERSION.jar"
rm -f $ARTIFACT
echo "Unpacking $JAR"
cd target/native-image || exit 1
jar -xvf ../$JAR >/dev/null 2>&1
cp -R META-INF BOOT-INF/classes

LIBPATH=$(find BOOT-INF/lib | tr '\n' ':')
CP=BOOT-INF/classes:$LIBPATH

GRAALVM_VERSION=$(native-image --version)
echo "Compiling $ARTIFACT with $GRAALVM_VERSION"

{ time native-image \
       --verbose \
       --enable-url-protocols=http \
       -H:Name=$ARTIFACT \
       -Dspring.native.remove-yaml-support=true \
       -cp "$CP" $MAINCLASS >> output.txt ; } 2>> output.txt

if [[ -f $ARTIFACT ]]
then

    echo "# SUCCESS"
    mv ./$ARTIFACT ..
    cd ../../
    mvn package -P native
    exit 0
else
    cat output.txt
    echo "# FAIL"
    exit 1
fi
