#!/bin/bash -ue                                   
# build rpm packages of tengine from tengine github repo
# simple, probably wip
# Christian Bryn 2013
# Do what the fuck you want.

git clone git://github.com/alibaba/tengine.git


yum install pcre-devel openssl-devel jemalloc-devel rpmdevtools

cd tengine

# version number like this: take latest tag, add git commit
build_version=$( git tag | sort | tail -n 1 | awk -F "-" '{ print $NF }')
git_commit=$( git rev-parse HEAD )
./configure --with-jemalloc --prefix=/usr --conf-path=/etc/nginx/nginx.conf --dso-path=/usr/lib/nginx/modules
make
build_dir=$( mktemp -d )
trap "rm -rf ${build_dir} 2>/dev/null || true" EXIT
make install DESTDIR=${build_dir}

fpm -s dir -t rpm -n tengine -v ${build_version}_git~${git_commit} -C ${build_dir} etc usr

print='echo'
which figlet >/dev/null && print='figlet'
which toilet >/dev/null && print='figlet'

echo "> Built RPM of Tengine ${build_version}"
$print "YAY"
