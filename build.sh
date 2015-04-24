#!/bin/bash -ue                                   
# build rpm packages of tengine from tengine github repo
# simple, probably wip
# Christian Bryn 2013-2015

function print_usage {
  cat <<EOF
Usage: ${0} [-h|-t]

  -h    This helpful text.
  -t    Fresh clone (build in temp dir)

EOF
}

# defaults
temp_build="false"
new_build="false"

while getopts hnt o
do
  case $o in
    h)
      print_usage ; exit ;;
    n)
      new_build="true" ;;
    t)
      # do fresh clone
      temp_build="true" ;;
  esac
done
shift $(($OPTIND-1))

yum install -y pcre-devel openssl-devel jemalloc-devel rpmdevtools

if [ "${temp_build}" == "true" ]
then
  tmp_clone_dir=$( mktemp -d )
  ( cd ${tmp_clone_dir} && git clone git://github.com/alibaba/tengine.git )
  cd ${tmp_clone_dir}/tengine
else
  if [[ "${new_build}" == "true" ]]; then
    git clone git://github.com/alibaba/tengine.git
    cd tengine
  fi
  [ -d .git ] || { echo "This does not look like a GIT repo"; echo "Change dir or use -n (new) or -t (temp dir build) ?"; exit 1; }
fi

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
which toilet >/dev/null && print='toilet'

echo "> Built RPM of Tengine ${build_version}"
$print "YAY"
